// @Maintainer jwrl
// @Released 2021-10-29
// @Author khaver
// @Created 2017-05-05
// @see https://www.lwks.com/media/kunena/attachments/6375/VariFilmGrain_640.png

/**
 Author's note:  This effect is based on my earlier Grain (Variable) effect.  This effect
 rolls-off the strength of the grain as the luma values in the image approach 0 and 1,
 much like real film.

 Controls are:
   STRENGTH:         controls the amount of grain added.
   SIZE:             controls the size of the grain.
   DISTRIBUTION:     controls the space between grains.
   ROLL-OFF BIAS:    contols the roll-off curve between pure white and pure black.
   GRAIN BLUR:       adds blur to the grain.
   SHOW GRAIN:       lets you see just the grain.
   ALPHA GRAIN ONLY: replaces the source alpha channel with the grain passing the
                     RGB channels through from the source image untouched.
   ALPHA ADJUSTMENT: tweaks the alpha channel grain.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Variable_Film_Grain.fx
//
// Version history:
//
// Update 2021-10-29 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Variable Film Grain";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "This effect reduces the grain as the luminance values approach their limits";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define HALF_PI 1.5707963268

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

float2 _TexelKernel[13] = { { -6.0, 0.0 }, { -5.0, 0.0 }, { -4.0, 0.0 }, { -3.0, 0.0 },
                            { -2.0, 0.0 }, { -1.0, 0.0 }, {  0.0, 0.0 }, {  1.0, 0.0 },
                            {  2.0, 0.0 }, {  3.0, 0.0 }, {  4.0, 0.0 }, {  5.0, 0.0 },
                            {  6.0, 0.0 } };

float _BlurWeights[13] = { 0.002216, 0.008764, 0.026995, 0.064759, 0.120985,  0.176033,
                           0.199471, 0.176033, 0.120985, 0.064759, 0.026995, 0.008764,
                           0.002216 };

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input,  s_Input);

SetTargetMode (Tex1, Samp1, Wrap);
SetTargetMode (Tex2, Samp2, Wrap);
SetTargetMode (Tex3, Samp3, Wrap);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Size
<
   string Description = "Size";
   float MinVal = 0.25;
   float MaxVal = 4.0;
> = 0.67;

float Shape
<
   string Description = "Distribution";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float Bias
<
   string Description = "Roll-off Bias";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

float blur
<
   string Description = "Grain Blur";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

bool show
<
   string Description = "Show grain";
> = false;

bool agrain
<
   string Description = "Alpha grain only";
   string Group = "Alpha";
> = false;

float aadjust
<
   string Description = "Alpha adjustment";
   string Group = "Alpha";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float _rand (float2 co, float seed)
{
   return frac ((dot (co.xy, float2 (co.x + 123.0, co.y + 13.0))) * seed + _Progress);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 Grain (float2 uv : TEXCOORD0) : COLOR
{
   float2 xy = saturate (uv + float2 (0.00013, 0.00123));

   float x = sin (xy.x) + cos (xy.y) + _rand (xy, ((xy.x + 1.123) * (xy.x + xy.y))) * 1000.0;
   float grain = frac (fmod(x, 13.0) * fmod (x, 123.0));

   if (grain > Shape || grain < (1.0 - Shape)) grain = 0.5;

   return (((grain - 0.5) * (Strength * 5.0)) + 0.5).xxxx;
}

float4 Blurry1 (float2 uv : TEXCOORD2) : COLOR
{  
   float blurpix = blur / _OutputWidth;

   float2 xy = ((uv - 0.5.xx) / Size) + 0.5.xx;

   float4 Color = EMPTY;

   for (int i = 0; i < 13; i++) {    
      Color += tex2D (Samp1, xy + (_TexelKernel [i].yx * blurpix)) * _BlurWeights [i];
   }

   return Color;
}

float4 Blurry2 (float2 uv : TEXCOORD2) : COLOR
{  
   float blurpix = _OutputAspectRatio * blur / _OutputWidth;

   float2 xy = ((uv - 0.5.xx) / Size) + 0.5.xx;

   float4 Color = EMPTY;

   for (int i = 0; i < 13; i++) {    
      Color += tex2D (Samp2, xy + (_TexelKernel [i] * blurpix)) * _BlurWeights [i];
   }

   return Color;
}

float4 Combine (float2 uv1 : TEXCOORD1, float2 xy : TEXCOORD2) : COLOR
{
   float4 source = GetPixel (s_Input, uv1);

   float lum = (source.r + source.g + source.b) / 3.0;

   lum = lum > Bias ? sin ((1.0 - lum) * HALF_PI / (1.0 - Bias))
       : lum < Bias ? sin (lum * HALF_PI / Bias) : 1.0;

   float4 grainblur = (tex2D (Samp3, xy) - 0.5.xxxx) * lum;

   if (show) return grainblur + 0.5.xxxx;

   return agrain ? float4 (source.rgb, (grainblur.a * 2.0) + aadjust) : source + grainblur;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique VariGrain
{
   pass P_1 < string Script = "RenderColorTarget0 = Tex1;"; > ExecuteShader (Grain)
   pass P_2 < string Script = "RenderColorTarget0 = Tex2;"; > ExecuteShader (Blurry1)
   pass P_3 < string Script = "RenderColorTarget0 = Tex3;"; > ExecuteShader (Blurry2)
   pass P_4 ExecuteShader (Combine)
}

