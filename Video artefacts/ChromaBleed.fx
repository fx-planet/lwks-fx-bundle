// @Maintainer jwrl
// @Released 2021-11-01
// @Author jwrl
// @Created 2021-11-01
// @see https://www.lwks.com/media/kunena/attachments/6375/ChromaSmear_640.png

/**
 This simulates the "colour under/pilot tone colour" of early helical scan recorders.
 It does this by blurring the image chroma and re-applying it to the luminance.  This
 effect is resolution locked to the sequence in which it is used.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromaBleed.fx
//
// Version history:
//
// Rewrite 2021-11-01 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chroma bleed";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Gives the horizontal smeared colour look of early helical scan recorders";
   bool CanSize       = false;
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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define LOOP   12
#define DIVIDE 49

#define LUMA   float3(0.2989, 0.5866, 0.1145)

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

DefineTarget (Smr, s_Smear);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Smear
<
   string Description = "Smear";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Saturation
<
   string Description = "Chroma boost";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_spread (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   if ((Smear > 0.0) && (Amount > 0.0)) {

      float2 xy = 0.0.xx;
      float2 spread = float2 (Smear * 0.003, 0.0);

      for (int i = 0; i < LOOP; i++) {
         xy += spread;
         retval = max (retval, tex2D (s_Input, uv + xy));
         retval = max (retval, tex2D (s_Input, uv - xy));
         xy += spread;
         retval = max (retval, tex2D (s_Input, uv + xy));
         retval = max (retval, tex2D (s_Input, uv - xy));
      }
   }

   return Overflow (uv) ? EMPTY : retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = GetPixel (s_Input, uv);

   if ((Smear > 0.0) && (Amount > 0.0)) {
      float4 chroma = tex2D (s_Smear, uv);

      float2 xy = 0.0.xx;
      float2 spread = float2 (Smear * 0.000375, 0.0);

      for (int i = 0; i < LOOP; i++) {
         xy += spread;
         chroma += tex2D (s_Input, uv + xy);
         chroma += tex2D (s_Input, uv - xy);
         xy += spread;
         chroma += tex2D (s_Input, uv + xy);
         chroma += tex2D (s_Input, uv - xy);
      }

      chroma /= DIVIDE;

      float luma = dot (chroma.rgb, LUMA);

      chroma.rgb -= luma.xxx;
      chroma.rgb *= 1.0 + Saturation;
      luma = dot (retval.rgb, LUMA);
      chroma.rgb = saturate (chroma.rgb + luma.xxx);

      retval = Overflow (uv) ? EMPTY : lerp (retval, chroma, Amount);
   }
   else {
      float amt = Amount * Saturation;

      retval.rgb = saturate (retval.rgb + (retval.rgb - dot (retval.rgb, LUMA).xxx) * amt);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ChromaBleed
{
   pass P_1 < string Script = "RenderColorTarget0 = Smr;"; > ExecuteShader (ps_spread)
   pass P_2 ExecuteShader (ps_main)
}

