// @Maintainer jwrl
// @Released 2020-11-29
// @Author jwrl
// @Created 2020-11-29
// @see https://www.lwks.com/media/kunena/attachments/6375/DVE_repeat_640.png

/**
 This a 2D DVE that performs in the same way as the Lightworks version does, but with
 some significant differences. First, there is no drop shadow support.  Second, the
 image can be duplicated as you zoom out either directly or as a mirrored image.  And
 third, all size adjustment now follows a square law.  The range you will see in your
 sequence is identical to what you see in the Lightworks effect, but the adjustment
 settings are from zero to the square root of ten.  This has been done to make size
 reduction more easily controllable.

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
// Built jwrl 2020-11-29.
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
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Crop : RenderColorTarget;

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

sampler s_Cropped = sampler_state
{
   Texture   = <Crop>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Repeats
<
   string Description = "Repeat mode";
   string Enum = "No repeats,Repeat mirrored,Repeat duplicated";
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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float _FgXScale = 1.0;     // If this is compiled in a version of Lightworks before 2021.1 the
float _FgYScale = 1.0;     // pre-loaded values will be used in place of the real scale factor.
float _FgWidth = 5000.0;
float _FgHeight = 5000.0;

float _OutputAspectRatio;

#define BLACK float2(0.0, 1.0).xxxy
#define EMPTY 0.0.xxxx

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

// This function performs any required duplication of the images as set in Repeats.

float4 fn_dup2D (sampler s, float2 uv)
{
   // If Repeats is set to zero (false) we just exit through the legal pixel function.

   if (!Repeats) return fn_tex2D (s, uv);

   // To adjust for the foreground geometry we centre the X and Y pixel coordinates and
   // scale them.  The X and Y ranges are then offset from the top left reference point.

   float2 Fs = float2 (_FgXScale, _FgYScale);
   float2 xy = ((uv - 0.5.xx) / Fs) + 0.5.xx;

   // If we are simply duplicating images we now get the fractional part of the address.
   // This gives us a range from zero to just under one.  Mirroring is more complex: it
   // requires every alternate overflow value to be inverted.  This does that.  Once
   // either is completed the X-Y coordinates are scaled back to their original ranges.

   xy = (Repeats == 2) ? frac (xy) : 1.0.xx - abs (2.0 * (frac (xy / 2.0) - 0.5.xx));
   xy = ((xy - 0.5.xx) * Fs) + 0.5.xx;

   // Now we exit through the legal pixel recovery function.

   return fn_tex2D (s, xy);
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

   // If we fall outside crop boundaries we return transparent black and quit here.

   if ((uv.x < Lcrop) || (uv.x > Rcrop) || (uv.y < Tcrop) || (uv.y > Bcrop)) return EMPTY;

   // Now we wind the crop values in by the precalculated border thickness.

   Rcrop -= BorderH;
   Lcrop += BorderH;
   Tcrop += BorderV;
   Bcrop -= BorderV;

   // If we land within the border zone we simply return the border colour and quit.

   if ((uv.x < Lcrop) || (uv.x > Rcrop) || (uv.y < Tcrop) || (uv.y > Bcrop)) return Colour;

   // After all that we get what's left - the cropped, bordered image.

   return tex2D (s_Foreground, uv);
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   // In the main shader we calculate X and Y scale factors, compensating for the foreground
   // image geometry.  We also square the scale parameters to make size reduction simpler.

   float scaleX = MasterScale * MasterScale;
   float scaleY = max (0.001, scaleX * YScale * YScale / _FgYScale);

   scaleX = max (0.001, scaleX * XScale * XScale / _FgXScale);

   // We now scale uv1 by the X and Y scale factors and put the result in xy1.  At this stage
   // we also include the position values in PosX and PosY, centred around the middle of frame.

   float2 xy1 = uv1 + float2 (0.5 - PosX, PosY - 0.5);

   xy1.x = ((xy1.x - 0.5) / scaleX) + 0.5;
   xy1.y = ((xy1.y - 0.5) / scaleY) + 0.5;

   // The value in xy1 is now used to recover the duplicated pixels using function fn_dup2D().
   // At the same time the background is recovered and mixed with opaque black.

   float4 Fgnd = fn_dup2D (s_Cropped, xy1);
   float4 Bgnd = lerp (BLACK, fn_tex2D (s_Background, uv2), Background);

   // he foreground is finally mixed over the background with alpha chnnel support.

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

