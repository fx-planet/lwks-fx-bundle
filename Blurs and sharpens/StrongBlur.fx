// @Maintainer jwrl
// @Released 2021-08-31
// @Author jwrl
// @Created 2021-08-31
// @see https://www.lwks.com/media/kunena/attachments/6375/SuperBlur_640.png

/**
 This is a spin-off from my radial blur as used in several other effects.  This is a
 three or five pass blur, achieved by taking two or five passes through the one shader,
 then in the case of the standard blur, ending in a second shader.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect StrongBlur.fx
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
   string Description = "Strong blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This is an extremely smooth blur with two ranges, standard and super";
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

#define LOOP     12
#define DIVIDE   49

#define RADIUS_1 0.004
#define RADIUS_2 0.01
#define RADIUS_3 0.02
#define RADIUS_4 0.035
#define RADIUS_5 0.056

#define ANGLE    0.2617993878

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

int SetTechnique
<
   string Description = "Blur strength";
   string Enum = "Standard blur,Super blur";
> = 1;

float Size
<
   string Description = "Radius";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float Amount
<
   string Description = "Amount";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_RawInp, uv); }

float4 ps_std (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   if (Overflow (uv1)) return EMPTY;

   float4 retval = tex2D (s_Blur_2, uv2);

   if ((Size > 0.0) && (Amount > 0.0)) {
      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Size * RADIUS_3;

      for (int i = 0; i < LOOP; i++) {
         sincos ((i * ANGLE), xy.x, xy.y);
         xy *= radius;
         retval += tex2D (s_Blur_2, uv2 + xy);
         retval += tex2D (s_Blur_2, uv2 - xy);
         xy += xy;
         retval += tex2D (s_Blur_2, uv2 + xy);
         retval += tex2D (s_Blur_2, uv2 - xy);
      }

      retval /= DIVIDE;

      if (Amount < 1.0)
         return lerp (tex2D (s_Input, uv2), retval, Amount);
   }

   return retval;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2,
                uniform sampler blurSampler, uniform float blurRadius) : COLOR
{
   if (Overflow (uv1)) return EMPTY;

   float4 retval = tex2D (blurSampler, uv2);

   if ((Size > 0.0) && (Amount > 0.0)) {
      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Size * blurRadius;

      for (int i = 0; i < LOOP; i++) {
         sincos ((i * ANGLE), xy.x, xy.y);
         xy *= radius;
         retval += tex2D (blurSampler, uv2 + xy);
         retval += tex2D (blurSampler, uv2 - xy);
         xy += xy;
         retval += tex2D (blurSampler, uv2 + xy);
         retval += tex2D (blurSampler, uv2 - xy);
      }

      retval /= DIVIDE;

      if ((blurRadius == RADIUS_5) && (Amount < 1.0))
         return lerp (tex2D (s_Input, uv2), retval, Amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique StrongBlur_0
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1
   < string Script = "RenderColorTarget0 = blur_1;"; > Execute2param (ps_main, s_Input, RADIUS_1)
   pass P_2
   < string Script = "RenderColorTarget0 = blur_2;"; > Execute2param (ps_main, s_Blur_1, RADIUS_2)
   pass P_3 ExecuteShader (ps_std)
}

technique StrongBlur_1
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1
   < string Script = "RenderColorTarget0 = blur_1;"; > Execute2param (ps_main, s_Input, RADIUS_1)
   pass P_2
   < string Script = "RenderColorTarget0 = blur_2;"; > Execute2param (ps_main, s_Blur_1, RADIUS_2)
   pass P_3
   < string Script = "RenderColorTarget0 = blur_1;"; > Execute2param (ps_main, s_Blur_2, RADIUS_3)
   pass P_4
   < string Script = "RenderColorTarget0 = blur_2;"; > Execute2param (ps_main, s_Blur_1, RADIUS_4)
   pass P_5 Execute2param (ps_main, s_Blur_2, RADIUS_5)
}

