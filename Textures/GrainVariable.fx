// @Maintainer jwrl
// @Released 2023-05-16
// @Author khaver
// @Created 2011-04-22

/**
 This effect is an extended flexible means of adding grain to an image.  As well as
 intensity adjustment it's also possible to adjust the size and softness of the grain.
 The grain can be applied to the alpha channel alone with variable transparency.  This
 is designed to help with grain blending when combined with other video sources.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GrainVariable.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-12 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Grain (Variable)", "Stylize", "Textures", "A flexible means of adding grain to an image", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 0.0, 0.0, 100.0);
DeclareFloatParam (Size, "Size", kNoGroup, kNoFlags, 1.0, 1.0, 10.0);
DeclareFloatParam (blur, "Grain Blur", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (agrain, "Alpha grain only", "Alpha", false);

DeclareFloatParam (aadjust, "Alpha adjustment", "Alpha", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float _rand (float2 co, float seed)
{
   return frac ((dot (co.xy, float2 (co.x + 123.0, co.y + 13.0))) * seed + _Progress);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Samp1)
{
   float2 loc = saturate (uv0 + float2 (0.00013, 0.00123));

   float4 source = ReadPixel (Input, uv1);

   float x = sin (loc.x) + cos (loc.y) + _rand (loc, ((source.g + 1.0) * (loc.x + loc.y))) * 1000.0;
   float grain = (frac (fmod (x, 13.0) * fmod (x, 123.0)) - 0.5) * (Strength / 100.0) + 0.5;

   return grain.xxxx;
}

DeclarePass (Samp2)
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
   float4 Color = kTransparentBlack;
   float4 Orig = tex2D (Samp1, uv2);

   for (int i = 0; i < 13; i++) {
      Color += tex2D (Samp1, uv2 + (TexelKernel [i] * ypix)) * BlurWeights [i];
   }

   return Color;
}

DeclarePass (Samp3)
{  
   float xpix = 1.0 / _OutputWidth;
   float ypix = xpix * _OutputAspectRatio;

   float2 TexelKernel[13] = { { -6.0, 0.0 }, { -5.0, 0.0 }, { -4.0, 0.0 }, { -3.0, 0.0 },
                              { -2.0, 0.0 }, { -1.0, 0.0 }, {  0.0, 0.0 }, {  1.0, 0.0 },
                              {  2.0, 0.0 }, {  3.0, 0.0 }, {  4.0, 0.0 }, {  5.0, 0.0 },
                              {  6.0, 0.0 } };

   float BlurWeights[13] = { 0.002216, 0.008764, 0.026995, 0.064759, 0.120985, 0.176033, 0.199471,
                             0.176033, 0.120985, 0.064759, 0.026995, 0.008764, 0.002216 };

   float4 Color = kTransparentBlack;
   float4 Orig = tex2D (Samp2, uv2);

   for (int i = 0; i < 13; i++) {
      Color += tex2D (Samp2, uv2 + (TexelKernel [i] * xpix)) * BlurWeights [i];
   }

   return Color;
}

DeclareEntryPoint (GrainVariable)
{
   float4 source = tex2D (Input, uv1);

   if (source.a == 0.0) return kTransparentBlack;

   float4 grainblur = tex2D (Samp3, ((uv2 - 0.5.xx) / Size) + 0.5.xx);
   float4 grainorg = tex2D (Samp1, ((uv2 - 0.5.xx) / Size) + 0.5.xx);
   float4 graintex = lerp (grainorg, grainblur, blur);

   return (!agrain) ? source + graintex - 0.5.xxxx : float4 (source.rgb, graintex.a + aadjust);
}

