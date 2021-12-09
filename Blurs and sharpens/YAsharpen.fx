// @Maintainer jwrl
// @Released 2021-12-09
// @Author jwrl
// @Created 2021-12-09
// @see https://forum.lwks.com/attachments/yasharpen_480-png.39977/

/**
 First, there is no such thing as the perfect edge sharpening effect.  They all have
 artefacts of one sort or another.  However this one is designed to give very clean
 results.  It does this by sampling the current pixel at a small offset in both X
 and Y directions and deriving an edge signal directly from that by subtracting the
 original video.  The offset amount is adjustable, and the edge component derived
 from this process can be clamped to control its visibility.  While this is similar
 in operation to an unsharp mask it will usually give much finer edges.

 Because of the known limitations of Lightworks' resolution independence, depending on
 where this effect is applied in an effects chain there may be visible asymmetry in the
 enhancement of portrait images.  If this is the case the sampling should be rotated
 through 90 degrees using the sample rotation parameter.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect YAsharpen.fx
//
// Version history:
// Built 2021-12-09 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Yet another sharpen";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "A sharpen utility that can give extremely clean results";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define LUMA float3(0.897, 1.761, 0.342)

float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int Rotation
<
   string Group = "Parameters";
   string Description = "Sample rotation";
   string Enum = "Normal,90 degrees";
> = 0;

float Offset
<
   string Group = "Parameters";
   string Description = "Sample offset";
   float MinVal = 0.0;
   float MaxVal = 6.0;
> = 2.0;

float EdgeClamp
<
   string Group = "Parameters";
   string Description = "Edge clamp";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.125;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 sampleX = float2 (Offset, 0.0);
   float2 sampleY = float2 (0.0, Offset);

   if (Rotation == 0) {
      sampleX /= _OutputWidth;
      sampleY /= _OutputHeight;
   }
   else {
      sampleX /= _OutputHeight;
      sampleY /= _OutputWidth;
   }

   float clamp = max (1.0e-6, EdgeClamp);

   float4 luma_val = float4 (LUMA * Amount / clamp, 0.5);
   float4 retval = GetPixel (s_Input, uv);
   float4 edges = GetPixel (s_Input, uv + sampleY);

   edges += GetPixel (s_Input, uv - sampleX);
   edges += GetPixel (s_Input, uv + sampleX);
   edges += GetPixel (s_Input, uv - sampleY);
   edges = retval - (edges / 4.0);
   edges.a = 1.0;

   retval.rgb += ((saturate (dot (edges, luma_val)) * clamp * 2.0) - clamp).xxx;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique YAsharpen { pass P_1 ExecuteShader (ps_main) }

