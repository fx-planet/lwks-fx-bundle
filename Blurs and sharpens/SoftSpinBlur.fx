// @Maintainer jwrl
// @Released 2021-08-31
// @Author jwrl
// @Created 2021-08-31
// @see https://www.lwks.com/media/kunena/attachments/6375/SoftSpinBlur_640.png

/**
 During the development of this effect particular attention has been given to the blur
 sample rate.  The effect achieves 108 samples by using three consecutive passes of
 36 samples each at finer and finer pitch.  This is an oversampling technique which
 results in a theoretical sample rate of greater than 45,000.  As a result a full 180
 degrees of arc can be blurred without the sampling becoming too obvious even if the
 blur centre is at the corner of the frame.

 The blur arc method used is bi-directional and produces a symmetrical blur.  For
 example, a 30 degree arc is produced by applying dual 15 degree clockwise and anti-
 clockwise blurs.  A level tracking parameter has been included to compensate for the
 inevitable upward drift in blacks and downward drift in whites that such a strong
 blur can cause.

 Blur density reduces the blur effect to zero.  Blur aspect ratio is set in percentage
 change values and swings between 1:5 and 5:1.  The blur centring can be set either by
 means of the sliders or by dragging with the mouse in the edit sequence viewer.  Blurs
 cannot be dragged off screen, but manually entering values will allow this if desired.

 NOTE:  With resolution independence an issue has arisen that means that mixing frames
 of differing aspect ratios will cause the centre point of the spin to jump.  There is
 no way that I have been able to find that prevents this.  I have supplied this version
 despite this flaw, but as soon as I can find a fix that doesn't involve dummy inputs
 and the like I will update it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftSpinBlur.fx
//
// The impetus to develop this spin blur effect was triggered by windsturm's effect,
// FxSpinBlur.  Since this was written from the ground up any similarity to that work
// is entirely coincidental.  In the interests of interface consistency an attempt was
// made to match the parameters in that effect.  Due to other design decisions that has
// not been completely possible.
//
// Version history:
//
// Rewrite 2021-08-31 jwrl:
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Soft spin blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This effect uses a bidirectional blur to give an extremely smooth spin blur";
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
#define Execute2param(SHD,P1,P2) { PixelShader = compile PROFILE SHD (P1, P2); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

#define STEPS   18
#define DIVISOR 18.975

#define SCALE_1 36
#define SCALE_2 108
#define SCALE_3 324

#define WEIGHT  1.0
#define WT_DIFF 0.0555556

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

SetInputMode (Inp, s_RawInp, Mirror);

SetTargetMode (FixInp, s_Input, Mirror);

SetTargetMode (blur_1, s_Blur_1, Mirror);
SetTargetMode (blur_2, s_Blur_2, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Arc
<
   string Description = "Blur arc degrees";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 45.0;

float Amount
<
   string Description = "Blur density";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Aspect
<
   string Description = "Aspect ratio";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreX
<
   string Description = "Blur centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CentreY
<
   string Description = "Blur centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Tracking
<
   string Description = "Level tracking";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_RawInp, uv); }

float4 ps_Blur (float2 uv : TEXCOORD2, uniform sampler blurSampler, uniform int scale) : COLOR
{
   if ((Amount == 0.0) || (Arc == 0.0)) return tex2D (s_Input, uv);

   float4 retval = EMPTY;

   float spin   = radians (Arc) / scale;
   float weight = WEIGHT;
   float angle  = 0.0;
   float C, S;

   float2 blur_aspect  = float2 (1.0, (1.0 - (max (Aspect, 0.0) * 0.8) - (min (Aspect, 0.0) * 4.0)) * _OutputAspectRatio);
   float2 fxCentre = float2 (CentreX, 1.0 - CentreY);
   float2 xy1, xy2, xy = (uv - fxCentre) / blur_aspect;
   float2 xyC, xyS;

   for (int i = 0; i < STEPS; i++) {
      sincos (angle, S, C);

      xyC = xy * C;
      xyS = float2 (xy.y, -xy.x) * S;
      xy1 = (xyC + xyS) * blur_aspect + fxCentre;
      xy2 = (xyC - xyS) * blur_aspect + fxCentre;

      retval += ((tex2D (blurSampler, xy1) + tex2D (blurSampler, xy2)) * weight);

      weight -= WT_DIFF;
      angle  += spin;
   }

   return retval / DIVISOR;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   if (Overflow (uv1)) return EMPTY;

   float offset = 0.7 - (Arc / 600.0);
   float adjust = 1.0 + (Arc / 270.0);

   float4 retval = tex2D (s_Blur_1, uv2);
   float4 repair = float4 (((retval.rgb - offset.xxx) * adjust) + offset.xxx, retval.a);

   retval = lerp (retval, repair, Tracking);

   return lerp (tex2D (s_Input, uv2), retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SoftSpinBlur
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1
   < string Script = "RenderColorTarget0 = blur_1;"; > Execute2param (ps_Blur, s_Input, SCALE_1)
   pass P_2
   < string Script = "RenderColorTarget0 = blur_2;"; > Execute2param (ps_Blur, s_Blur_1, SCALE_2)
   pass P_3
   < string Script = "RenderColorTarget0 = blur_1;"; > Execute2param (ps_Blur, s_Blur_2, SCALE_3)
   pass P_4 ExecuteShader (ps_main)
}

