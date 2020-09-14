// @Maintainer jwrl
// @Released 2020-09-14
// @Author jwrl
// @Created 2020-09-14
// @see https://www.lwks.com/media/kunena/attachments/6375/3Dbevel_640.png

/**
 This is a crop tool that provides a 3D bevelled border.  The lighting of the bevel can
 be adjusted in intensity, and the lighting angle can be changed.  Fill lighting is also
 included to soften the shaded areas of the bevel.  A hard-edged outer border is also
 included which simply shades the background by an adjustable amount.

 X-Y positioning of the border and its contents has been included, and simple scaling has
 been provided.  This is not intended as a comprehensive DVE replacement so no X-Y scale
 factors nor rotation has been provided.

 NOTE:  Any alpha information in the foreground is discarded by this effect.  It would
 be hard to maintain in a way that would make sense for all possible needs in any case.
 This means that wherever the foreground and bevelled border appears will be completely
 opaque.  The background alpha is preserved.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 3Dbevel.fx
//
// Version history:
//
// Built jwrl 2020-09-14.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "3D bevelled crop";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "This provides a simple crop with an inner 3D bevelled edge and a flat coloured outer border";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Bvl : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Bevel = sampler_state
{
   Texture   = <Bvl>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Scale
<
   string Group = "Foreground size and position";
   string Description = "Size";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.1;
   float MaxVal = 5.0;
> = 1.0;

float PosX
<
   string Group = "Foreground size and position";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosY
<
   string Group = "Foreground size and position";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CropLeft
<
   string Group = "Foreground crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float CropTop
<
   string Group = "Foreground crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropRight
<
   string Group = "Foreground crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropBottom
<
   string Group = "Foreground crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Border
<
   string Group = "Border settings";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float4 Colour
<
   string Group = "Border settings";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.375, 0.125, 0.0, 1.0 };

float Bevel
<
   string Group = "Bevel settings";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.125;

float Bstrength
<
   string Group = "Bevel settings";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Intensity
<
   string Group = "Bevel settings";
   string Description = "Light level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.45;

float Angle
<
   string Group = "Bevel settings";
   string Description = "Light angle";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 80.0;

float4 Light
<
   string Group = "Bevel settings";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 1.0, 0.66666667, 0.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY  0.0.xxxx

#define SCALE  0.1
#define BORDER 0.0125

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 fn_rgb2hsv (float3 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float3 hsv  = float3 (0.0.xx, Cmax);

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float3 fn_hsv2rgb (float3 hsv)
{
   if (hsv.y == 0.0) return hsv.zzz;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (2.0 - hsv.y) - q;

   if (i == 0) return float3 (hsv.z, r, p);
   if (i == 1) return float3 (q, hsv.z, p);
   if (i == 2) return float3 (p, hsv.z, r);
   if (i == 3) return float3 (p, q, hsv.z);
   if (i == 4) return float3 (r, p, hsv.z);

   return float3 (hsv.z, p, q);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   // Get the foreground but discard the alpha channel

   float3 retval = tex2D (s_Foreground, uv).rgb;

   // Now set up the crop boundaries, the size of the border and the  bevel.

   float2 cropAspect = float2 (1.0, _OutputAspectRatio);
   float2 centreCrop = float2 (abs (CropRight - CropLeft), abs (CropTop - CropBottom));
   float2 cropBevel  = centreCrop - (cropAspect * Bevel * SCALE);
   float2 cropBorder = centreCrop + (cropAspect * Border * BORDER);

   // Because we have to be able to obtain an accurate 45 degree angle at the corners
   // of the bevel we need to set up several xy coordinates.  For ease of later maths
   // we swing uv around the mid point of the crop and put that value in xy1.  This
   // will be used later to determine which quadrant we're working in.

   float2 xy1 = uv - float2 (CropRight + CropLeft, 2.0 - CropTop - CropBottom) / 2.0;

   // The absolute value of xy1 is doubled and stored in xy2.  This can be used to
   // help produce the crop very simply.

   float2 xy2 = abs (xy1) * 2.0;

   // The bevel size is then subtracted from xy2 and clamped between 0 and 1.  By
   // doing this we can reliably calculate the corner angle without resorting to
   // trig functions or distance calculations.  The X coordinate is corrected for
   // the project aspect ratio.

   float2 xy3 = saturate (xy2 - cropBevel);

   xy3.x *= _OutputAspectRatio;

   // The next section calculates the bevel colours.  If either component of xy2 exceeds
   // the bevel boundary we replace the border colour in retval with our derived bevel
   // colour.  This is reasonably complex to do because we need to be able to change the
   // angle of the bevel lighting in a way logical for the user.

   if ((xy2.x > cropBevel.x) || (xy2.y > cropBevel.y)) {

      // Bevel lighting is calculated in the hue/sat/value domain.  While it would be
      // possible to do this in the RGB domain, this way is much simpler.  Luminance
      // and saturation values are reduced to make the colour a light wash.

      float3 hsv = fn_rgb2hsv (Light.rgb);

      hsv.y *= 0.25;
      hsv.z *= 0.75;

      // The lit values of the X and Y planes are calculated trigonometrically.  This
      // is the only time that a trig function is required in this routine.  Instead of
      // swinging between +1 and -1 we need to swing from 0 to 1 for later level maths.

      float2 lit;

      sincos (radians (Angle), lit.x, lit.y);
      lit = (lit + 1.0.xx) * 0.5;

      // This sets up the amount by which to adjust the bevel colour.  If xy1.y is less
      // than zero we're in the lower half of the border, and the light amount, amt, can
      // be set to lit.y.  Otherwise it is inverted by subtracting lit.y from 1.0.

      float amt = (xy1.y > 0.0) ? 1.0 - lit.y : lit.y;

      // The values of amt at either side are now set up.  If we're on the left hand
      // side and if xy3.x is greater than xy3.y we invert the value in lit.x and put
      // it in amt.  Because of the earlier clamping and scaling of xy3 this gives us
      // an accurate 45 degree angle at top and bottom left corners.  A similar test
      // is used to replace amt with the value in lit.x on the right hand side.

      if (xy3.x > xy3.y) { amt = (xy1.x > 0.0) ? lit.x : 1.0 - lit.x; }

      // The border amount is now scaled by the intensity and the fill is added.  Both
      // are adjusted before application so that the parameter settings make sense to
      // the user.  The result is then inverted, clamped and scaled by 6.

      amt = (amt * Intensity * 2.0) + 0.55;
      amt = saturate (1.5 - amt) * 6.0;

      // This test converts amt to swing between 0.25 and 1.0 for positive exposure
      // values, and between 1.0 and 4.0 for negative exposure.

      amt = (amt >= 3.0) ? amt - 2.0 : 1.0 / (4.0 - amt);

      // The border value is halved and amt is used as the power to raise it to.  It's
      // then checked for overflow to see if we also need to desaturate then doubled.
      // Both value and saturation are clamped between 0 and 1 after adjustment.

      hsv.z = pow (hsv.z * 0.5, amt);

      if (hsv.z > 0.5) hsv.y = saturate (hsv.y - hsv.z + 0.5);

      hsv.z = saturate (hsv.z * 2.0);

      // The completed border including the bevel is converted and placed in retval.

      retval = lerp (retval, fn_hsv2rgb (hsv), (Bstrength * 0.5) + 0.25);
   }

   // We now apply the border colour outside the cropped area.

   if ((xy2.x > centreCrop.x) || (xy2.y > centreCrop.y)) { retval = Colour.rgb; }

   // Alpha is turned on, outside the border is blanked and the result is returned.

   return ((xy2.x > cropBorder.x) || (xy2.y > cropBorder.y)) ? EMPTY : float4 (retval, 1.0);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   // We first calculate the position offset and scale factor and put it in xy.

   float2 xy = ((uv - float2 (PosX, 1.0 - PosY)) / max (1e-6, Scale)) + 0.5.xx;

   // The foreground is recovered from s_Bevel using the positioned and scaled xy.

   float4 Fgnd = tex2D (s_Bevel, xy);

   // The result is overlaid over the background.

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Bevel3D
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bvl;"; > 
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

