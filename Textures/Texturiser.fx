// @Maintainer jwrl
// @Released 2021-10-29
// @Author jwrl
// @Created 2021-10-29
// @see https://www.lwks.com/media/kunena/attachments/6375/Texturizer_640.png

/**
 This effect is designed to modulate the input with a texture from an external piece of
 art.  The texture may be coloured but only the luminance value will be used.  New in
 this version is a means of applying an offset to the texture depending on the luminance
 of the texture.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Texturiser.fx
//
// Version history:
//
// Rewrite 2021-10-29 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Texturiser";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "Generates bump mapped textures on an image using external texture artwork";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and constants
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

#define AMT         0.2            // Amount scale factor

#define DPTH        1.5            // Depth scale factor

#define SIZE        0.75           // Size scale factor

#define REDUCTION   0.9            // Foreground reduction for texture add

#define RED_LUMA    0.3
#define GREEN_LUMA  0.59
#define BLUE_LUMA   0.11

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

SetInputMode (Art, s_RawArt, Mirror);
SetInputMode (Inp, s_RawInp, Mirror);

SetTargetMode (RawArt, s_Artwork, Mirror);
SetTargetMode (RawInp, s_Input, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Overlay";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Size
<
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Depth
<
   string Description = "Depth";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float OffsetX
<
   string Group = "Offset";
   string Description = "X";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

float OffsetY
<
   string Group = "Offset";
   string Description = "Y";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_RawArt, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return tex2D (s_RawInp, uv); }

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amt = Amount * AMT;

   float2 xy1 = uv3 - 0.5.xx;
   float2 xy2 = float2 (OffsetX, -OffsetY) / 100.0;

   xy1 *= 1.0 - (Size * SIZE);
   xy1 += 0.5.xx;

   float4 Img = tex2D (s_Artwork, xy1);

   float luma = dot (Img.rgb, float3 (RED_LUMA, GREEN_LUMA, BLUE_LUMA)) * (Depth * DPTH);

   Img.rgb = luma.xxx;

   float4 Fgd = (tex2D (s_Input, uv3 + (luma * xy2)) * REDUCTION);

   Fgd = saturate (Fgd + (Img * amt));
   Fgd = lerp (Fgd, Img, amt);

   float alpha = tex2D (s_Input, uv3).a;

   return Overflow (uv2) ? EMPTY : float4 (Fgd.rgb, alpha);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Texturiser
{
   pass P_1 < string Script = "RenderColorTarget0 = RawArt;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawInp;"; > ExecuteShader (ps_initBg)
   pass P_3 ExecuteShader (ps_main)
}

