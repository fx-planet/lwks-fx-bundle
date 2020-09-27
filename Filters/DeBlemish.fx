// @Maintainer jwrl
// @Released 2020-09-27
// @Author jwrl
// @Created 2019-01-30
// @see https://www.lwks.com/media/kunena/attachments/6375/DeBlemish_640.png

/**
 This is a skin blemish removal tool similar in concept to "Skin smooth".  It uses a
 different technique than that effect to mask skin tones, which should make it easier
 to set up.  The default skin colour has been tested to work quite well with European
 and Asian flesh tones but will need adjustment with darker skins or poorly lit ones.

 The blur technique used is a variant of my radial blur, which also differs from the
 skin smooth effect.  The mask produced can be quite hard edged, as the mask will be
 blurred along with video ensuring a smooth blend.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DeBlemish.fx
//
// Version history:
//
// Update 2020-09-27 jwrl.
// Revised header block.
//
// Modified jwrl 2019-01-31:
// Relabelled "White levels" to "White clip" and changed the direction of operation.
// Relabelled "Black levels" to "Black crush".
// Added "Peak cleanup" to allow mask peaks exceeding the white clip to be set to zero.
//
// Modified jwrl 2019-02-04:
// Added a flesh tone color selector, "Skin colour".
// Added "Mask clip" to support it.
// Added a "Mask linearity" adjustment, which is really a gamma trim for the mask.
// Added a simple four-way crop to the mask.
// Removed the now redundant "Peak cleanup" setting.
// Commented the code to make it simpler for someone else to follow.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "De-blemish";
   string Category    = "Stylize";
   string SubCategory = "Filters";
   string Notes       = "Smooths skin tones to reduce visible skin blemishes using a radial blur";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Fgd : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Foreground = sampler_state
{
   Texture   = <Fgd>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Size
<
   string Description = "Blur strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Amount
<
   string Description = "Blur mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool ShowMask
<
   string Group = "Mask settings";
   string Description = "Show mask";
> = false;

float4 MaskColour
<
   string Group = "Mask settings";
   string Description = "Skin colour";
   bool SupportsAlpha = false;
> = { 0.945, 0.7765, 0.663, 1.0 };

float MaskClip
<
   string Group = "Mask settings";
   string Description = "Mask clip";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float MaskSep
<
   string Group = "Mask settings";
   string Description = "Mask separation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float MaskGamma
<
   string Group = "Mask settings";
   string Description = "Mask linearity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float MaskWhite
<
   string Group = "Mask settings";
   string Description = "White clip";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float MaskBlack
<
   string Group = "Mask settings";
   string Description = "Black crush";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropLeft
<
   string Group = "Mask crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropTop
<
   string Group = "Mask crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CropRight
<
   string Group = "Mask crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CropBottom
<
   string Group = "Mask crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define MIN_GAMMA 0.316227766
#define MAX_GAMMA 1.683772234

#define LEVELS    0.9
#define OFFSET    1.0 - LEVELS

#define LOOP      12
#define DIVIDE    49
#define ANGLE     0.2617993878
#define RADIUS    0.002

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 fn_hsv (float3 rgb)
{
   // This is a standard HSV converter, so it isn't commented except where it
   // differs from normal practice

   float val = max (rgb.r, max (rgb.g, rgb.b));
   float rng = val - min (rgb.r, min (rgb.g, rgb.b));
   float hue, sat = (rng / val).xx;

   if (sat == 0.0) { hue = 0.0; }
   else {
      if (rgb.r == val) {
         hue = (rgb.g - rgb.b) / rng;

         if (hue < 0.0) hue += 6.0;
      }
      else if (rgb.g == val) { hue = 2.0 + ((rgb.b - rgb.r) / rng); }
      else hue = 4.0 + ((rgb.r - rgb.g) / rng);

      // Normally we would have hue /= 6.0 here, but not doing that gives us
      // a steeper slope when we actually generate the key in the main code.
   }

   return float3 (hue, sat, val);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mask (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Input, uv);        // First get the input to process

   // Before we do anything set up the crop.  First invert the Y settings.

   float cropT = 1.0 - CropTop;
   float cropB = 1.0 - CropBottom;

   // If uv falls outside the crop boundaries set alpha to zero and quit.

   if ((uv.x < CropLeft) || (uv.x > CropRight) || (uv.y < cropT) || (uv.y > cropB))
      return float4 (Fgnd.rgb, 0.0);

   float3 Fhsv = fn_hsv (Fgnd.rgb);          // Convert it to our modified HSV
   float3 Chsv = fn_hsv (MaskColour.rgb);    // Do the same for the ref colour

   // Calculate the chroma difference.  Since what we want is actually the dark
   // sections of the mask, we double and clip it before any further processing.

   float cDiff = min (distance (Fhsv, Chsv) * 2.0, 1.0);

   // Now we generate the mask, adjusting clip and slope first then inverting it

   float mask  = 1.0 - smoothstep (MaskClip, MaskClip + MaskSep, cDiff);

   // Mask linearity is actually a gamma setting and runs from 0.01 to 4.0.  It's
   // also inverted at this stage, so that the power is actually from 100 to 0.25

   float gamma = 1.0 / pow (MIN_GAMMA + (MAX_GAMMA * MaskGamma), 2.0);

   // The black crush factor is limited to the range 0.0 - 0.9

   float black = saturate (MaskBlack) * LEVELS;

   // The mask is adjusted for gamma and black crush.

   mask = (pow (mask, gamma) - black) / (1.0 - black);

  // It is now white clipped and applied to the alpha channel of our image.

   Fgnd.a = saturate (mask / ((MaskWhite * LEVELS) + OFFSET));

   return Fgnd;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv); // Get the maked input

   if (ShowMask) return retval.aaaa;         // Show it if we need to

   float4 Fgnd = tex2D (s_Input, uv);        // Now get the raw input

   if ((Size > 0.0) && (Amount > 0.0)) {     // Process the image if required

      float angle = 0.0;                     // Set the blur rotation to zero

      // Calculate the blur radius based on size and aspect ratio.

      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Size * RADIUS;

      // In the blur loop we do two samples at 180 degree offsets, then another
      // two in which the sample offset is doubled, for a total of four samples
      // for each iteration of the loop.  Rather than multiply the angle by i
      // each time we go round we do a simple addition for the same result.

      for (int i = 0; i < LOOP; i++) {
         sincos (angle, xy.x, xy.y);
         xy *= radius;
         retval += tex2D (s_Foreground, uv + xy);
         retval += tex2D (s_Foreground, uv - xy);
         xy += xy;
         retval += tex2D (s_Foreground, uv + xy);
         retval += tex2D (s_Foreground, uv - xy);
         angle  += ANGLE;
      }

      retval /= DIVIDE;

      // The blurred flesh tones are now keyed into the original footage
      // using the blurred mask.  The original alpha value is preserved.

      Fgnd.rgb = lerp (Fgnd.rgb, retval.rgb, retval.a * Amount);
   }

   return Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DeBlemish
{
   pass P_1
   < string Script = "RenderColorTarget0 = Fgd;"; > 
   { PixelShader = compile PROFILE ps_mask (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
