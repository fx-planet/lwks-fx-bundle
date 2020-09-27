// @Maintainer jwrl
// @Released 2020-09-27
// @Author jwrl
// @Created 2018-03-20
// @see https://www.lwks.com/media/kunena/attachments/6375/LumakeyDVE_640.png

/**
 DESCRIPTION:
 This is a luminance key similar to the Lightworks effect, but with some differences.  A crop
 function and a simple DVE have been included to provide these often-needed functions without
 the need to add any external effects.

 DIFFERENCES:
 The most obvious difference from the Lightworks version is in the way that the parameters
 are identified.  "Tolerance" is labelled "Key clip" in this effect, "Edge Softness" is now
 "Key Softness" and "Invert" has become "Invert key".  These are the industry standard terms
 used for these functions, so this change makes the effect more consistent with any existing
 third party key software.

 Regardless of whether the key is inverted or not, the clip setting in this keyer always works
 from black at 0% to white at 100%.  In the Lightworks effect the equivalent setting changes
 sense when the key is inverted.  This is unexpected to say the least and has been avoided.
 Key softness in this effect is symmetrical around the key edge.  This is consistent with the
 way that a traditional analog luminance keyer works.  The alpha signal produced can either
 replace any existing foreground alpha or be gated with it.  It can then be used to key the
 foreground over the background or passed on to other effects.  Any background image will be
 suppressed in this mode.

 DVE AND CROP COMPONENTS:
 Cropping can be set up by dragging the upper left and lower right corners of the crop area
 on the edit viewer, or in the normal way by dragging the sliders.  The crop is a simple hard
 edged one, and operates before the DVE.  The DVE is a simple 2D DVE, but zooming is achieved
 by Z-axis adjustment.  This is treated as an offset from zero, and has limted range only.
 Negative values give size reduction which strictly speaking is incorrect, but feels more
 natural - smaller numbers equal smaller images.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LumakeyWithDVE.fx
//
// NOTE:  This keyer uses an algorithm derived from the LWKS Software Ltd lumakey effect,
// but this implementation is entirely my own.
//
// Version history:
//
// Update 2020-09-27 jwrl.
// Revised header block.
//
// Modified 4 May 2020 by user jwrl:
// Combined crop with main luminance key and DVE code.
//
// Modified 23 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 26 Nov 2018 by user schrauber:
// Changed subcategory from "User Effects" to "Key Extras".
//
// Modified 29 September 2018 jwrl.
// Added notes to header.
//
// Modified 22 April 2018 jwrl.
// Merged DVE operation with main shader, reducing the number of passes required by one
// and the samplers required by one also.
// No longer explicitly define addressing/filtering of Fg and Bg.  Defaults are OK here.
// Changed the exit implementation - logically the same, cosmetically different.
// Range limited the crop settings.  It's no longer possible to exceed frame boundaries.
// Restored comments to the code to assist anyone trying to work out what on earth I did.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lumakey with DVE";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "A keyer which respects any existing foreground alpha and can pass the generated alpha to external effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state { Texture = <Bg>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.0;

int KeyMode
<
   string Group = "Key settings";
   string Description = "Mode";
   string Enum = "Lumakey,Lumakey and Fg alpha,Lumakey (no background),Lumakey and Fg alpha (no Bg)";
> = 0;

float KeyClip
<
   string Group = "Key settings";
   string Description = "Key clip";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Softness
<
   string Group = "Key settings";
   string Description = "Key softness";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

bool InvertKey
<
   string Group = "Key settings";
   string Description = "Invert key";
> = false;

bool ShowAlpha
<
   string Group = "Key settings";
   string Description = "Display alpha channel";
> = false;

float CentreX
<
   string Description = "DVE position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreY
<
   string Description = "DVE position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreZ
<
   string Description = "DVE position";
   string Flags = "SpecifiesPointZ";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropLeft
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropTop
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CropRight
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CropBottom
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define R_LUMA    0.2989
#define G_LUMA    0.5866
#define B_LUMA    0.1145

#define EMPTY     (0.0).xxxx

#define ADD_ALPHA_W_BGD  1
#define HIDE_BGD         2
#define ADD_ALPHA_NO_BGD 3

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   // Calculate the crop boundaries.  These are limited to the edge of frame so that no
   // illegal addresses for the input sampler ranges can ever be produced.

   float L = max (0.0, CropLeft);
   float R = min (1.0, CropRight);
   float T = max (0.0, 1.0 - CropTop);
   float B = min (1.0, 1.0 - CropBottom);

   // Set up range limited DVE scaling.  Values of zero or below will be ignored if
   // input manually.  The minimum value will be limited to 0.0001.

   float scale = pow (max ((CentreZ + 2.0) * 0.5, 0.0001), 4.0);

   // Set up pixel addressing for the Fgd parameter to produce the DVE effect

   float2 xy3 = ((xy1 - 0.5.xx) / scale) + float2 (-CentreX, CentreY) + 0.5.xx;

   // Recover background and foreground, limiting the foreground to legal addresses.  This
   // is done to ensure that the differences in cross platform edge clamping are bypassed.
   // It also gives us the cropping that we want.

   float4 Bgd = (KeyMode < HIDE_BGD) ? tex2D (s_Background, xy2) : EMPTY;
   float4 Fgd = (xy3.x >= L) && (xy3.x <= R) && (xy3.y >= T) && (xy3.y <= B)
              ? tex2D (s_Foreground, xy3) : EMPTY;

   // Set up the key clip and softness from the Fgd luminance

   float luma  = dot (Fgd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   float edge  = max (0.00001, Softness);
   float clip  = (KeyClip * 1.0002) - (edge * 0.5) - 0.0001;
   float alpha = saturate ((luma - clip) / edge);

   // Invert the alpha if needed and optionally gate it with Fgd.a then quit

   if (InvertKey) alpha = 1.0 - alpha;

   if ((KeyMode == ADD_ALPHA_W_BGD) || (KeyMode == ADD_ALPHA_NO_BGD))
      alpha = min (Fgd.a, alpha);

   return (ShowAlpha) ? float4 (alpha.xxx, 1.0) : lerp (Bgd, Fgd, alpha * Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LumakeyWithDVE
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
