// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Blocks_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/BlockDissolve.mp4

/**
 This effect starts off by building blocks from the outgoing image for the first third of
 the effect, then dissolves to the new image for the next third, then loses the blocks
 over the remainder of the effect.

 The original block component of the effect has been rewritten, because when mixing between
 clips with differing aspect ratios the earlier version gave unpredictable results.  The
 rewrite has had the side effect of making that part of the process simpler.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Block_Dx.fx
//
// Version history:
//
// Rewrite 2021-07-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Block dissolve";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Builds the outgoing image into larger and larger blocks as it fades to the incoming";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputAspectRatio;

#define PI 3.1415926536

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Blocks, s_Blocks);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float blockSize
<
   string Description = "Block size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
//  Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mix (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);
   float4 Bgnd = GetPixel (s_Background, uv2);

   float dissolve = saturate ((Amount * 3.0) - 1.0);

   return lerp (Fgnd, Bgnd, dissolve);
}

float4 ps_main (float2 uv : TEXCOORD) : COLOR
{
   float2 xy;

   if (blockSize > 0.0) {
      float Xsize = max (1e-6, blockSize * sin (Amount * PI) * 0.1);
      float Ysize = Xsize * _OutputAspectRatio;

      xy.x = (floor ((uv.x - 0.5) / Xsize) * Xsize) + 0.5;
      xy.y = (floor ((uv.y - 0.5) / Ysize) * Ysize) + 0.5;
   }
   else xy = uv;

   return tex2D (s_Blocks, xy);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Block_Dx
{
   pass P_1 < string Script = "RenderColorTarget0 = Blocks;"; > ExecuteShader (ps_mix)
   pass P_2 ExecuteShader (ps_main)
}

