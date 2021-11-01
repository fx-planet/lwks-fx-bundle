// @Maintainer jwrl
// @Released 2021-11-01
// @Author windsturm
// @Created 2012-08-02
// @see https://www.lwks.com/media/kunena/attachments/6375/FxNoise_640.png

/**
 This does exactly what it says - generates both monochrome and colour video noise.
 Because this effect needs to be able to precisely manage pixel weight no matter what
 the original clip size or aspect ratio is it has not been possible to make it truly
 resolution independent.  What it does is lock the clip resolution to sequence
 resolution instead.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VideoNoise.fx (FxNoise)
//-----------------------------------------------------------------------------------------//

/*
  * FxNoise.
  * Noise effect.
  * 
  * @param <Color Type> "Monochrome" or "Color"
  * @param <Noise Size> Noise block size
  * @param <Opacity>    Degree to which blended with the image
  * @param <Alpha>      Alpha blending 
  * @param <Seed>       Random seed
  * @author Windsturm
  * @version 1.1.0
*/

//-----------------------------------------------------------------------------------------//
// This conversion for ps_2_b compliance by Lightworks user jwrl, 4 February 2016.
//
// Version history:
//
// Update 2021-11-01 jwrl.
// Updated the original effect to better support LW v2021 and higher.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Video noise";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Generates either monochrome or colour video noise";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _Progress;

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Color Type";
   string Enum = "Monochrome,Color";
> = 0;

float Size
<
   string Description = "Size";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.0;

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Alpha
<
   string Description = "Alpha";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Seed
<
   string Description = "Random Seed";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float rand (float2 uv, float seed)
{
   return frac (sin (dot (uv, float2 (12.9898,78.233)) + seed) * (43758.5453));
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 FxNoiseMono (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;

   if (Size != 0.0) {
      float xSize = Size;
      float ySize = xSize * _OutputAspectRatio;

      xy = float2 (round ((uv.x - 0.5) / xSize) * xSize, round ((uv.y - 0.5) / ySize) * ySize);
   }
   else xy = uv;

   float c = rand (xy, rand (xy, Seed + _Progress));

   float4 ret = GetPixel (s_Input, uv);

   ret = ret.a == 0.0 ? EMPTY : lerp (ret, float2 (c, 1.0).xxxy, Opacity);

   return float4 (ret.rgb, ret.a * Alpha);
}

float4 FxNoiseColor (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;

   if (Size != 0.0) {
      float xSize = Size;
      float ySize = xSize * _OutputAspectRatio;

      xy = float2 (round ((uv.x - 0.5) / xSize) * xSize, round ((uv.y - 0.5) / ySize) * ySize);
   }
   else xy = uv;

   float s = Seed + _Progress;
   float t = s + 1.0;
   float u = s + 2.0;

   float3 c = float3 (rand (xy, rand (xy, s)), rand (xy, rand (xy, t)), rand (xy, rand (xy, u)));

   float4 ret = GetPixel (s_Input, uv);

   ret = ret.a == 0.0 ? EMPTY : lerp (ret, float4 (c, 1.0), Opacity);

   return float4 (ret.rgb, ret.a * Alpha);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Monochrome { pass SinglePass ExecuteShader (FxNoiseMono) }

technique Color { pass SinglePass ExecuteShader (FxNoiseColor) }

