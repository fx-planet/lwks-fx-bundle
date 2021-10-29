// @Maintainer jwrl
// @Released 2021-10-29
// @Author khaver
// @Created 2011-04-22
// @see https://www.lwks.com/media/kunena/attachments/6375/VariGrain_640.png

/**
 This effect is an extended flexible means of adding grain to an image.  As well as
 intensity adjustment it's also possible to adjust the size and softness of the grain.
 The grain can be applied to the alpha channel alone with variable transparency.  This
 is designed to help with grain blending when combined with other video sources.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Grain_Variable.fx
//
// Version history:
//
// Update 2021-10-29 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Grain (Variable)";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "A flexible means of adding grain to an image";
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

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

DefineTarget (Tex1, Samp1);
DefineTarget (Tex2, Samp2);
DefineTarget (Tex3, Samp3);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 100.0;
> = 0.0;

float Size
<
   string Description = "Size";
   float MinVal = 1.0;
   float MaxVal = 10.0;
> = 1.0;

float blur
<
   string Description = "Grain Blur";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

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

float4 Grain (float2 xy : TEXCOORD1) : COLOR
{
   float2 loc = saturate (xy + float2 (0.00013, 0.00123));

   float4 source = GetPixel (s_Input, xy);

   float x = sin (loc.x) + cos (loc.y) + _rand (loc, ((source.g + 1.0) * (loc.x + loc.y))) * 1000.0;
   float grain = (frac (fmod (x, 13.0) * fmod (x, 123.0)) - 0.5) * (Strength / 100.0) + 0.5;

   return grain.xxxx;
}

float4 Blurry1 (float2 Tex : TEXCOORD2) : COLOR
{  
   float xpix = 1.0 / _OutputWidth;
   float ypix = xpix * _OutputAspectRatio;

   float2 TexelKernel[13] = { { 0.0, -6.0 }, { 0.0, -5.0 }, { 0.0, -4.0 }, { 0.0, -3.0 },
                              { 0.0, -2.0 }, { 0.0, -1.0 }, { 0.0,  0.0 }, { 0.0,  1.0 },
                              { 0.0,  2.0 }, { 0.0,  3.0 }, { 0.0,  4.0 }, { 0.0,  5.0 },
                              { 0.0,  6.0 } };

   const float BlurWeights[13] = { 0.002216, 0.008764, 0.026995, 0.064759, 0.120985,
                                   0.176033, 0.199471, 0.176033, 0.120985, 0.064759,
                                   0.026995, 0.008764, 0.002216 };
   float4 Color = EMPTY;
   float4 Orig = tex2D (Samp1, Tex);

   for (int i = 0; i < 13; i++) {
      Color += tex2D (Samp1, Tex + (TexelKernel [i] * ypix)) * BlurWeights [i];
   }

   return Color;
}

float4 Blurry2 (float2 Tex : TEXCOORD2) : COLOR
{  
   float xpix = 1.0 / _OutputWidth;
   float ypix = xpix * _OutputAspectRatio;

   float2 TexelKernel[13] = { { -6.0, 0.0 }, { -5.0, 0.0 }, { -4.0, 0.0 }, { -3.0, 0.0 },
                              { -2.0, 0.0 }, { -1.0, 0.0 }, {  0.0, 0.0 }, {  1.0, 0.0 },
                              {  2.0, 0.0 }, {  3.0, 0.0 }, {  4.0, 0.0 }, {  5.0, 0.0 },
                              {  6.0, 0.0 } };

   const float BlurWeights[13] = { 0.002216, 0.008764, 0.026995, 0.064759, 0.120985,
                                   0.176033, 0.199471, 0.176033, 0.120985, 0.064759,
                                   0.026995, 0.008764, 0.002216 };
   float4 Color = EMPTY;
   float4 Orig = tex2D (Samp2, Tex);

   for (int i = 0; i < 13; i++) {
      Color += tex2D (Samp2, Tex + (TexelKernel [i] * xpix)) * BlurWeights [i];
   }

   return Color;
}

float4 Combine( float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 source = GetPixel (s_Input, uv1);
   float4 grainblur = tex2D (Samp3, ((uv2 - 0.5.xx) / Size) + 0.5.xx);
   float4 grainorg = tex2D (Samp1, ((uv2 - 0.5.xx) / Size) + 0.5.xx);
   float4 graintex = lerp (grainorg, grainblur, blur);

   return (!agrain) ? source + graintex - 0.5.xxxx : float4 (source.rgb, graintex.a + aadjust);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique VariGrain
{
   pass Pass1 < string Script = "RenderColorTarget0 = Tex1;"; > ExecuteShader (Grain)
   pass Pass2 < string Script = "RenderColorTarget0 = Tex2;"; > ExecuteShader (Blurry1)
   pass Pass3 < string Script = "RenderColorTarget0 = Tex3;"; > ExecuteShader (Blurry2)
   pass Pass4 ExecuteShader (Combine)
}

