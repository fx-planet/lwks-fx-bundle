// @Maintainer jwrl
// @Released 2021-10-29
// @Author jwrl
// @Created 2021-10-29
// @see https://www.lwks.com/media/kunena/attachments/6375/Acidulate_640.png

/**
 I was going to call this LSD, but this name will do.  Original effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AcidulateFx.fx
//
// Version history:
//
// Rewrite 2021-10-29 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Acidulate";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "I was going to call this LSD, but this name will do";
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Standard input preamble for dealing with inputs at sequence resolution
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, s_Input);
DefineTarget (Image, s_Image);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return BdrPixel (s_RawInp, uv); }

float4 ps_proc (float2 uv : TEXCOORD2) : COLOR
{
   float4 Img = GetPixel (s_Input, uv);

   if (Amount == 0.0) return Img;

   float2 xy = float2 (Img.b - Img.r, Img.g);

   return GetPixel (s_Input, frac (abs (uv + frac (xy * Amount))));
}

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   float4 Img = GetPixel (s_Image, uv);

   if (Amount == 0.0) return Img;

   float2 xy = float2 (Img.b, Img.g - Img.r - 1.0);

   return GetPixel (s_Image, frac (abs (uv + frac (xy * Amount))));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique AcidulateFx
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Image;"; > ExecuteShader (ps_proc)
   pass P_3 ExecuteShader (ps_main)
}

