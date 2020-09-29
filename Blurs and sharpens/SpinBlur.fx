// @Maintainer jwrl
// @Released 2020-09-29
// @Author rakusan/windsturm
// @Created 2012-05-15
// @see https://www.lwks.com/media/kunena/attachments/6375/FxSpinBlur_640.png

/**
 This applies a rotary blur with adjustable aspect ratio and centring.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SpinBlur.fx
//
// Original code by rakusan http://kuramo.ch/webgl/videoeffects/ translated by windsturm.
//
// @param <threshold>  Blur length parameters
// @param <CX> Center point of the spin, the X coordinate
// @param <CY> Center point of the spin, the Y coordinate
// @param <AR> AspectRatio 1:x
// @version 1.0 (only version posted by windsturm - jwrl).
//
// Cross-platform port by Lightworks forum moderator jwrl May 3 2016.
//
// Version history:
//
// Modified jwrl 2020-09-29:
// Reformatted the effect header.
//
// Modified by LW user jwrl 23 December 2018.
// Added creation date.
// Renamed from FxSpinBlur.fx to SpinBlur.fx.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//
// Bug fix June 28 2017 by jwrl.
// An arithmetic bug which arose during the cross platform conversion was detected and
// fixed.  The bug resulted in a noticeable drop in video levels and severe highlight
// compression.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Spin blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This applies a rotary blur with adjustable aspect ratio and centring";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture prelim : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state
{
   Texture = <Input>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler partSampler = sampler_state
{
   Texture = <prelim>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float threshold
<
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 20.0;

float CX
<
   string Description = "Center";
   string Flags = "SpecifiesPointX";
   float MinVal = -0.50;
   float MaxVal = 1.50;
> = 0.5;

float CY
<
   string Description = "Center";
   string Flags = "SpecifiesPointY";
   float MinVal = -0.50;
   float MaxVal = 1.50;
> = 0.5;

float AR
<
   string Description = "AspectRatio 1:x";
   float MinVal = 0.01;
   float MaxVal = 10.00;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLUR_PART 15
#define BLUR_SAMP 30
#define BLUR_DIV  11.6

#define WAIT_1    1.0
#define WAIT_2    0.5

#define INTERVAL  0.033333

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1, uniform bool pass2) : COLOR
{
   if (threshold == 0.0) return tex2D (InputSampler, xy);

   float2 angXY;
   float Tcos, Tsin;

   float4 color = 0.0.xxxx;

   float2 outputAspect = float2 (1.0, _OutputAspectRatio);
   float2 blueAspect = float2 (1.0, AR);
   float2 center = float2 (CX, 1.0 - CY );
   float2 uv = (xy - center) / outputAspect / blueAspect;

   float amount = radians (threshold) / BLUR_SAMP;
   float wait = pass2 ? WAIT_2 : WAIT_1;

   int start_count = pass2 ? BLUR_PART : 0;
   int end_count = pass2 ? BLUR_SAMP : BLUR_PART;

   float ang = amount * start_count;

   for (int i = start_count; i < end_count; i++) {
      sincos (ang, Tsin, Tcos);
      angXY = center + float2 ((uv.x * Tcos - uv.y * Tsin),
              (uv.x * Tsin + uv.y * Tcos) * outputAspect.y) * blueAspect;

      color += (tex2D (InputSampler, angXY) * wait);

      wait -= INTERVAL;
      ang += amount;
   }

   color /= BLUR_DIV;

   if (pass2) color = (color + tex2D (partSampler, xy)) * 0.75;

   return color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FxSpinBlur
{
   pass Pass_1
   <
      string Script = "RenderColorTarget0 = prelim;";
   >
   {
      PixelShader = compile PROFILE ps_main (false);
   }

   pass Pass_2
   {
      PixelShader = compile PROFILE ps_main (true);
   }
}
