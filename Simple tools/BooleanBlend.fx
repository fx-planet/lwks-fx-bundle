// @Maintainer jwrl
// @Released 2021-10-19
// @Author jwrl
// @Created 2021-10-19
// @see https://www.lwks.com/media/kunena/attachments/6375/BooleanBlend_640.png

/**
 This arose out of a need to combine two images with alpha channels using the analogue
 equivalent of a digital AND gate.  AND, OR, NAND, NOR and XOR have been implemented
 while the analogue levels of the alpha channel have been maintained.  The video is
 always just OR-ed while the logic is fully implemented only in the alpha channel.

 To ensure that transparency is shown as black as far as the gating is concerned, RGB
 is multiplied by alpha.  The levels of the A and B inputs can be adjusted.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BooleanBlend.fx
//
// Version history:
//
// Rewrite 2021-10-19 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Boolean blend";
   string Category    = "Mix";
   string SubCategory = "Simple tools";
   string Notes       = "Combines two images with transparency using boolean logic.";
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

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (A, s_RawFg);
DefineInput (B, s_RawBg);

DefineTarget (RawFg, Sampler_A);
DefineTarget (RawBg, Sampler_B);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Boolean expression";
   string Enum = "AND,OR,NAND,NOR,XOR"; 
> = 0;

float Amount_A
<
   string Description = "A amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amount_B
<
   string Description = "B amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_AND (float2 uv : TEXCOORD3) : COLOR
{
   float4 vidA = tex2D (Sampler_A, uv) * Amount_A;
   float4 vidB = tex2D (Sampler_B, uv) * Amount_B;

   vidA.rgb *= vidA.a;
   vidB.rgb *= vidB.a;

   float4 retval = max (vidA, vidB);

   retval.a = min (vidA.a, vidB.a);

   return retval;
}

float4 ps_OR (float2 uv : TEXCOORD3) : COLOR
{
   float4 vidA = tex2D (Sampler_A, uv) * Amount_A;
   float4 vidB = tex2D (Sampler_B, uv) * Amount_B;

   vidA.rgb *= vidA.a;
   vidB.rgb *= vidB.a;

   return max (vidA, vidB);
}

float4 ps_NAND (float2 uv : TEXCOORD3) : COLOR
{
   float4 vidA = tex2D (Sampler_A, uv) * Amount_A;
   float4 vidB = tex2D (Sampler_B, uv) * Amount_B;

   vidA.rgb *= vidA.a;
   vidB.rgb *= vidB.a;

   float4 retval = max (vidA, vidB);

   retval.a = 1.0 - min (vidA.a, vidB.a);

   return retval;
}

float4 ps_NOR (float2 uv : TEXCOORD3) : COLOR
{
   float4 vidA = tex2D (Sampler_A, uv) * Amount_A;
   float4 vidB = tex2D (Sampler_B, uv) * Amount_B;

   vidA.rgb *= vidA.a;
   vidB.rgb *= vidB.a;

   float4 retval = max (vidA, vidB);

   retval.a = 1.0 - retval.a;

   return retval;
}

float4 ps_XOR (float2 uv : TEXCOORD3) : COLOR
{
   float4 vidA = tex2D (Sampler_A, uv) * Amount_A;
   float4 vidB = tex2D (Sampler_B, uv) * Amount_B;

   vidA.rgb *= vidA.a;
   vidB.rgb *= vidB.a;

   float4 retval = max (vidA, vidB);

   float alpha = 1.0 - min (vidA.a, vidB.a);

   return float4 (retval.rgb, retval.a * alpha);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique AND 
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 ExecuteShader (ps_AND)
}

technique OR  
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 ExecuteShader (ps_OR)
}

technique NAND
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 ExecuteShader (ps_NAND)
}

technique NOR 
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 ExecuteShader (ps_NOR)
}

technique XOR 
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 ExecuteShader (ps_XOR)
}


