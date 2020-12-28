// @Maintainer jwrl
// @Released 2020-12-28
// @Author jwrl
// @Created 2020-11-29
// @see https://www.lwks.com/media/kunena/attachments/6375/DVE_repeat_640.png

/**
 This is a 2D DVE that has been engineered from the ground up to support Lightworks
 2021.1's resolution independence.  It will also compile on version 14.5 and 2020.1
 without that ability.  It performs in the same way as the Lightworks version does,
 but with some significant differences.  First, there is no drop shadow support.
 Second, instead of the drop shadow you get a border. And third and most importantly,
 the image can be duplicated as you zoom out either directly or as a mirrored image.
 Mirroring can be horizontal or vertical only, or both axes.

 Fourth, all size adjustment now follows a square law.  The range you will see in your
 sequence is identical to what you see in the Lightworks effect, but the adjustment
 settings are from zero to the square root of ten - a little over three.  This has been
 done to make size reduction more easily controllable.

 The image that leaves the effect has a composite alpha channel built from a combination
 of the background and foreground.  If the background has transparency it will be
 preserved wherever the foreground isn't present.

 There is one final difference when compared with the Lightworks 2D DVE: the background
 can be faded to black.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 2dDVEwithRepeats.fx
//
// Version history:
//
// Updated jwrl 2020-12-28.
// Corrected an issue that caused wrapped pixels to be displayed on Intel GPUs.
//
// Modified jwrl 2020-12-15.
// Two additional mirror modes added.
// Borders are now calculated outside the crop area rather than inside.
// Converted the frame duplication into in-line code in ps_main().  Previously it was a
// separate function which then called another function.  This is simpler.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "2D DVE with repeats";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "A 2D DVE that can duplicate the foreground image as you zoom out";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

float _BgXScale = 1.0;     // If this is compiled in a version of Lightworks before 2021.1
float _BgYScale = 1.0;     // the pre-loaded values will be used in place of the real scale
float _FgXScale = 1.0;     // factor.  Multiplying or dividing by one won't change a thing.
float _FgYScale = 1.0;

float _FgWidth = 5000.0;   // In earlier versions of Lightworks these values will produce
float _FgHeight = 5000.0;  // an offset of 0.0001 instead of half a pixel when cropping.

float _OutputAspectRatio;

#define BLACK float2(0.0, 1.0).xxxy
#define EMPTY 0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Crop, s_Cropped);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Repeats
<
   string Description = "Repeat mode";
   string Enum = "No repeats,Repeat mirrored,Repeat duplicated,Horizontal mirror,Vertical mirror";
> = 0;

float PosX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float PosY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float MasterScale
<
   string Description = "Master";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float XScale
<
   string Description = "X";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float YScale
<
   string Description = "Y";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float CropL
<
   string Description = "Left";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropT
<
   string Description = "Top";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropR
<
   string Description = "Right";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropB
<
   string Description = "Bottom";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Border
<
   string Description = "Width";
   string Group = "Border";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float4 Colour
<
   string Group = "Border";
   string Description = "Border colour";
   bool SupportsAlpha = true;
> = { 0.49, 0.561, 1.0, 1.0 };

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Background
<
   string Description = "Background";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// This is my standard legal pixel recovery function.  Anything that falls outside the
// legal address range is ignored and instead transparent black is returned.

float4 fn_tex2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   return (max (xy.x, xy.y) > 0.5) ? EMPTY : tex2D (s, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   // We first calculate the border theickness, allowing for all image scaling.

   float BorderH = Border * 0.25;
   float BorderV = BorderH * _OutputAspectRatio / _FgYScale;

   BorderH /= _FgXScale;

   // Because for some reason we get a one pixel undershoot at the edge of a foreground
   // image with an odd number of pixels the crop values are offset by half a pixel.
   // It's an empirical solution which seems to work reliably.

   float H_fix = 0.5 / _FgWidth;
   float V_fix = 0.5 / _FgHeight;

   // Crop values are limited to run between 0.0 and 1.0, then offset by plus or minus
   // half a pixel (see above).  Normally this will do nothing, but with an odd number
   // of pixels in the foreground width or height the extra pixel will be duplicated.

   float Rcrop = 1.0 - saturate (CropR) + H_fix;
   float Lcrop = saturate (CropL) - H_fix;
   float Tcrop = saturate (CropT) - V_fix;
   float Bcrop = 1.0 - saturate (CropB) + V_fix;

   // If we fall inside crop boundaries we return the selected pixel.

   if ((uv.x >= Lcrop) && (uv.x <= Rcrop) && (uv.y >= Tcrop) && (uv.y <= Bcrop))
      return fn_tex2D (s_Foreground, uv);

   // Now we wind the crop values out by the precalculated border thickness.

   Rcrop += BorderH;
   Lcrop -= BorderH;
   Tcrop -= BorderV;
   Bcrop += BorderV;

   // If we land outside the border zone we simply return transparent black and quit.

   if ((uv.x < Lcrop) || (uv.x > Rcrop) || (uv.y < Tcrop) || (uv.y > Bcrop)) return EMPTY;

   // After all that we get what's left - the border colour.

   return Colour;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   // In the main shader we calculate X and Y scale factors, compensating for the foreground
   // image geometry.  We also square the scale parameters to make size reduction simpler.

   float scaleX = MasterScale * MasterScale;
   float scaleY = max (0.001, scaleX * YScale * YScale / _FgYScale);

   scaleX = max (0.001, scaleX * XScale * XScale / _FgXScale);

   // Now ensure that the Fg image position is centred around the Bg centre then add the
   // revised centred position values to uv1.  The result is then stored in xy1.

   float2 BgS = float2 (_BgXScale, _BgYScale);
   float2 FgS = float2 (_FgXScale, _FgYScale);
   float2 xy1 = uv1 + (float2 (0.5 - PosX, PosY - 0.5) * BgS / FgS);

   // Scale xy1 by the previously calculated X and Y scale factors.

   xy1.x = ((xy1.x - 0.5) / scaleX) + 0.5;
   xy1.y = ((xy1.y - 0.5) / scaleY) + 0.5;

   // If Repeats isn't set to zero (false) we perform the required image duplication.

   if (Repeats) {
      xy1 = ((xy1 - 0.5.xx) / FgS) + 0.5.xx;

      float2 xy2 = frac (xy1);

      if (Repeats != 2) {
         float2 xy3 = 1.0.xx - abs (2.0 * (frac (xy1 / 2.0) - 0.5.xx));

         if (Repeats <= 3) xy2.x = xy3.x;
         if (Repeats != 3) xy2.y = xy3.y;
      }

      xy1 = ((xy2 - 0.5.xx) * FgS) + 0.5.xx;
   }

   // The value in xy1 is now used to index into the foreground using fn_tex2D().
   // The background is also recovered the same way and mixed with opaque black.

   float4 Fgnd = fn_tex2D (s_Cropped, xy1);
   float4 Bgnd = lerp (BLACK, fn_tex2D (s_Background, uv2), Background);

   // The duplicated foreground is finally blended with the background.

   return lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DVEwithRepeats
{
   pass P_1
   < string Script = "RenderColorTarget0 = Crop;"; > 
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
