// @Maintainer jwrl
// @Released 2021-08-31
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
// Updated 2021-08-31 jwrl:
// Updated to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 2020-11-09:
// Various updates mainly to improve cross-platform performance.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Spin blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This applies a rotary blur with adjustable aspect ratio and centring";
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

#define SetInputMode(TEX, SMPL, MODE) \
                                      \
 texture TEX;                         \
                                      \
 sampler SMPL = sampler_state         \
 {                                    \
   Texture   = <TEX>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define SetTargetMode(TGT, SMP, MODE) \
                                      \
 texture TGT : RenderColorTarget;     \
                                      \
 sampler SMP = sampler_state          \
 {                                    \
   Texture   = <TGT>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }
#define ExecuteParam(SHD,PRM) { PixelShader = compile PROFILE SHD (PRM); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

#define BLUR_PART 15
#define BLUR_SAMP 30
#define BLUR_DIV  11.6

#define WAIT_1    1.0
#define WAIT_2    0.5

#define INTERVAL  0.033333

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

SetInputMode (Input, s_RawInp, Mirror);

SetTargetMode (FixInp, InputSampler, Mirror);
SetTargetMode (prelim, partSampler, Mirror);

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
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_RawInp, uv); }

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, uniform bool pass2) : COLOR
{
   if (Overflow (uv1)) return EMPTY;

   if (threshold == 0.0) return tex2D (InputSampler, uv2);

   float2 angXY;
   float Tcos, Tsin;

   float4 color = EMPTY;

   float2 outputAspect = float2 (1.0, _OutputAspectRatio);
   float2 blueAspect = float2 (1.0, AR);
   float2 center = float2 (CX, 1.0 - CY );
   float2 xy = (uv2 - center) / outputAspect / blueAspect;

   float amount = radians (threshold) / BLUR_SAMP;
   float wait = pass2 ? WAIT_2 : WAIT_1;

   int start_count = pass2 ? BLUR_PART : 0;
   int end_count = pass2 ? BLUR_SAMP : BLUR_PART;

   float ang = amount * start_count;

   for (int i = start_count; i < end_count; i++) {
      sincos (ang, Tsin, Tcos);
      angXY = center + float2 ((xy.x * Tcos - xy.y * Tsin),
              (xy.x * Tsin + xy.y * Tcos) * outputAspect.y) * blueAspect;

      color += (tex2D (InputSampler, angXY) * wait);

      wait -= INTERVAL;
      ang += amount;
   }

   color /= BLUR_DIV;

   if (pass2) color = (color + tex2D (partSampler, uv2)) * 0.75;

   return color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FxSpinBlur
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pass_1 < string Script = "RenderColorTarget0 = prelim;"; > ExecuteParam (ps_main, false)

   pass Pass_2 ExecuteParam (ps_main, true)
}

