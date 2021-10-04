// @Maintainer jwrl
// @Released 2021-08-31
// @Author jwrl
// @Created 2021-08-31
// @see https://www.lwks.com/media/kunena/attachments/6375/SoftFoggyBlur_640.png

/**
 This blur effect mimics the classic "petroleum jelly on the lens" look.  It does this by
 combining a radial and a spin blur effect.  The spin component has an adjustable aspect
 ratio which can have significant effect on the final look.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftFoggyBlur.fx
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
   string Description = "Soft foggy blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This blur effect mimics the classic 'petroleum jelly on the lens' look";
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

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

#define DIV_1    18.5
#define DIV_2    18.975

#define SCALE_1  0.0027777778    // 0.1 / 36
#define SCALE_2  0.0009259259    // 0.1 / 108
#define SCALE_3  0.0096962736    // PI / 324

#define W_DIFF_1 0.0277777778
#define W_DIFF_2 0.0555555556

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

float Strength
<
   string Description = "Blur strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Amount
<
   string Description = "Blur density";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Aspect
<
   string Description = "Spin aspect 1:x";
   float MinVal = 0.2;
   float MaxVal = 5.0;
> = 1.0;

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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_RawInp, uv); }

float4 ps_radial_blur_1 (float2 uv : TEXCOORD2) : COLOR
{
   if ((Amount == 0.0) || (Strength == 0.0)) return tex2D (s_Input, uv);

   float4 retval = EMPTY;

   float2 center = float2 (CentreX, 1.0 - CentreY);
   float2 xy = uv - center;

   float S = Strength * SCALE_1;
   float Scale = 1.0;
   float weight = 1.0;

   for (int i = 0; i < 36; i++) {
      xy *= Scale;
      retval += tex2D (s_Input, xy + center) * weight;
      weight -= W_DIFF_1;
      Scale  -= S;
   }

   return retval / DIV_1;
}

float4 ps_radial_blur_2 (float2 uv : TEXCOORD2) : COLOR
{
   if ((Amount == 0.0) || (Strength == 0.0)) return tex2D (s_Input, uv);

   float4 retval = EMPTY;

   float2 center = float2 (CentreX, 1.0 - CentreY);
   float2 xy = uv - center;

   float S  = Strength * SCALE_2;
   float Scale = 1.0;
   float weight = 1.0;

   for (int i = 0; i < 36; i++) {
      xy *= Scale;
      retval += tex2D (s_Blur_1, xy + center) * weight;
      weight -= W_DIFF_1;
      Scale  -= S;
   }

   return retval / DIV_1;
}

float4 ps_spin_blur (float2 uv : TEXCOORD2) : COLOR
{
   if ((Amount == 0.0) || (Strength == 0.0)) return tex2D (s_Input, uv);

   float4 retval = EMPTY;

   float spin   = Strength * SCALE_3;
   float weight = 1.0;
   float angle  = 0.0;
   float C, S;

   float2 blur_aspect = float2 (1.0, max (Aspect, 0.0001)) * _OutputAspectRatio;
   float2 fxCentre     = float2 (CentreX, 1.0 - CentreY);
   float2 xy1, xy2, xy = (uv - fxCentre) / blur_aspect;
   float2 xyC, xyS;

   for (int i = 0; i < 18; i++) {
      sincos (angle, S, C);

      xyC = xy * C;
      xyS = float2 (xy.y, -xy.x) * S;
      xy1 = (xyC + xyS) * blur_aspect + fxCentre;
      xy2 = (xyC - xyS) * blur_aspect + fxCentre;

      retval += ((tex2D (s_Blur_2, xy1) + tex2D (s_Blur_2, xy2)) * weight);

      weight -= W_DIFF_2;
      angle  += spin;
   }

   return retval / DIV_2;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   if (Overflow (uv1)) return EMPTY;

   float offset = 0.7 - (Strength / 2.7777778);
   float adjust = 1.0 + (Strength / 1.5);

   float4 blurry = tex2D (s_Blur_1, uv2);
   float4 retval = lerp (blurry, float4 (((blurry.rgb - offset.xxx) * adjust) + offset.xxx, blurry.a), 0.1);

   return lerp (tex2D (s_Input, uv2), retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SoftFoggyBlur
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 < string Script = "RenderColorTarget0 = blur_1;"; > ExecuteShader (ps_radial_blur_1)
   pass P_2 < string Script = "RenderColorTarget0 = blur_2;"; > ExecuteShader (ps_radial_blur_2)
   pass P_3 < string Script = "RenderColorTarget0 = blur_1;"; > ExecuteShader (ps_spin_blur)
   pass P_4 ExecuteShader (ps_main)
}

