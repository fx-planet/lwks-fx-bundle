// @Maintainer jwrl
// @Released 2020-11-11
// @Author windsturm
// @OriginalAuthor "Ian McEwan"
// @Created 2012-10-25
// @see https://www.lwks.com/media/kunena/attachments/6375/FxRefraction_640.png

/**
 Simulates the distortion effect of an image seen through textured glass.  The rippling
 is derived for a random noise generator.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RefractionFx.fx
//-----------------------------------------------------------------------------------------//

//-----------------------------------------------------------------------------------------//
// Description : Array and textureless GLSL 3D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110409 (stegu)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//
// https://github.com/ashima/webgl-noise
//-----------------------------------------------------------------------------------------//

 /**
  * FxRefraction.
  * Refraction effect.
  * 
  * @param <noisePhase>  noise animation parameter
  * @param <noiseSize> noise size
  * @param <strength> refraction rate
  * @param <noiseX> Noise X coordinate
  * @param <noiseY> noise Y coordinate
  * @param <AR> aspect ratio 1:x
  * @param <exportImage> switch the export image
  * @param <useExternalImage> external noise image
  * @forked Windsturm
  * @version 1.0.0
  */

//-----------------------------------------------------------------------------------------//
// This conversion for ps_2_b compliance by Lightworks user jwrl, 5 February 2016.
//
// Version history:
//
// Update 2020-11-11 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 2018-12-23 jwrl:
// Changed subcategory.
// Added creation date.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14.5 update 5 December 2017 by jwrl.
// Added LINUX and OSX test to allow support for changing "Clamp" to "ClampToEdge" on
// those platforms.  It will now function correctly when used with Lightworks versions
// 14.5 and higher under Linux or OS-X and fixes a bug associated with using this
// effect with transitions on those platforms.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles interlaced media.
//
// Version 14 update 18 Feb 2017 jwrl - added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RefractionFx";
   string Category    = "Stylize";
   string SubCategory = "Distortion";
   string Notes       = "Simulates the distortion effect of an image seen through textured glass";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture InputTex;
texture MaskTex;

texture NoiseTex : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef OSX
#define Clamp ClampToEdge
#endif

sampler InputSampler = sampler_state
{
	Texture   = <InputTex>;
	AddressU  = Clamp;
	AddressV  = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler maskSampler = sampler_state {
	Texture   = <MaskTex>;
	AddressU  = Clamp;
	AddressV  = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler noiseSampler = sampler_state {
	Texture   = <NoiseTex>;
	AddressU  = Clamp;
	AddressV  = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float noisePhase
<
   string Group       = "Noise Parameter";
   string Description = "Phase";
   float MinVal = 0.0;
   float MaxVal = 100.0;
> = 0.0;

float noiseSize
<
   string Group       = "Noise Parameter";
   string Description = "Size";
   float MinVal = 0.00;
   float MaxVal = 200.00;
> = 10.0;

float strength
<
   string Group       = "Noise Parameter";
   string Description = "Strength";
   float MinVal = 0.0000;
   float MaxVal = 2.0000;
> = 0.1;

float noiseX
<
   string Group       = "Noise Parameter";
   string Description = "Position X";
   string Flags       = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float noiseY
<
   string Group       = "Noise Parameter";
   string Description = "Position Y";
   string Flags       = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float AR
<
   string Group       = "Noise Parameter";
   string Description = "AspectRatio 1:x";
   float MinVal = 0.01;
   float MaxVal = 10.00;
> = 0.1;

int exportImage
<
   string Description = "Export Image";
   string Enum = "Result,Source,Noise";
> = 0;

bool useExternalImage
<
   string Description = "Use External Image";
> = false;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 permute (float4 x)
{
   return fmod ((((x * 34.0) + 1.0.xxxx) * x), 289.0);
}

float snoise (float3 v)
{
   const float2 C = float2 (1.0, 2.0) / 6.0;
   const float4 D = float4 (0.0, 0.5, 1.0, 2.0);

   // First corner

   float3 i  = floor (v + dot (v, C.yyy).xxx);
   float3 x0 = v - i + dot (i, C.xxx).xxx;

   // Other corners

   float3 g  = step (x0.yzx, x0.xyz);
   float3 l  = 1.0.xxx - g;
   float3 i1 = min (g.xyz, l.zxy);
   float3 i2 = max (g.xyz, l.zxy);

   float3 x1 = x0 - i1  + C.xxx;
   float3 x2 = x0 - i2  + 2.0 * C.xxx;
   float3 x3 = x0 - 1.0.xxx + 3.0 * C.xxx;

   // Permutations

   i = fmod (i, 289.0);

   float4 p = permute (permute (permute (i.z + float4 (0.0, i1.z, i2.z, 1.0))
                                       + i.y + float4 (0.0, i1.y, i2.y, 1.0))
                                       + i.x + float4 (0.0, i1.x, i2.x, 1.0));

   // Gradients
   // (N*N points uniformly over a square, mapped onto an octahedron.)

   float  n_ = 1.0 / 7.0;                                // N = 7
   float3 ns = n_ * D.wyz - D.xzx;

   float4 j  = p - 49.0 * floor (p * ns.z *ns.z);        //  mod (p, N * N)

   float4 x_ = floor (j * ns.z);
   float4 y_ = floor (j - 7.0 * x_);                     // mod (j, N)

   float4 x  = x_ * ns.x + ns.yyyy;
   float4 y  = y_ * ns.x + ns.yyyy;
   float4 h  = 1.0.xxxx - abs (x) - abs (y);

   float4 b0 = float4 (x.xy, y.xy);
   float4 b1 = float4 (x.zw, y.zw);

   float4 s0 = floor (b0) * 2.0 + 1.0.xxxx;
   float4 s1 = floor (b1) * 2.0 + 1.0.xxxx;
   float4 sh = -step (h, float4 ( 0.0, 0.0, 0.0, 0.0 ));

   float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
   float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

   float3 p0 = float3 (a0.xy, h.x);
   float3 p1 = float3 (a0.zw, h.y);
   float3 p2 = float3 (a1.xy, h.z);
   float3 p3 = float3 (a1.zw, h.w);

   // Normalise gradients

   float4 norm = float4 (1.79284291400159 - 0.85373472095314 * float4 (dot (p0, p0), dot (p1, p1), dot (p2, p2), dot (p3, p3)));

   p0 *= norm.x;
   p1 *= norm.y;
   p2 *= norm.z;
   p3 *= norm.w;

   // Mix final noise value

   float4 m = max (0.6 - float4 (dot (x0, x0), dot (x1, x1), dot (x2, x2), dot (x3, x3)), 0.0);

   m = m * m;

   return 42.0 * dot (m * m, float4 (dot (p0, x0), dot (p1, x1), dot (p2, x2), dot (p3, x3)));
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 createNoise (float2 xy : TEXCOORD1) : COLOR
{
   if (noiseSize <= 0.0) return float2 (0.0, 1.0).xxxy;

   float2 outputAspect = float2 (1.0, _OutputAspectRatio);
   float2 blueAspect   = float2 (1.0, 1.0 * AR);

   xy -= float2 (noiseX, 1.0 - noiseY);
   xy = xy / outputAspect / blueAspect;

   float3 coord = float3 ((xy * noiseSize), noisePhase * 0.1);

   float n = 0.7  * abs (snoise (coord));

   n += 0.25 * abs (snoise (coord * 2.0));

   return float4 (n.xxx, 1.0);
}

float4 FxRefraction (float2 xy : TEXCOORD1) : COLOR
{
   sampler nSampler;

   if (exportImage == 1) return tex2D (InputSampler, xy);

   if (exportImage == 2) {

      if (useExternalImage) return tex2D (maskSampler,xy);

      return tex2D(noiseSampler,xy);
   }

   float4 Color;

   // Create NormalMap

   float2 shiftXY[4];

   shiftXY[0] = float2 (-1.0 / _OutputWidth, 0.0);
   shiftXY[1] = float2 (1.0 / _OutputWidth, 0.0);
   shiftXY[2] = float2 (0.0, -_OutputAspectRatio / _OutputWidth);
   shiftXY[3] = float2 (0.0, _OutputAspectRatio / _OutputWidth);

   float3 shiftColor[4];

   if (useExternalImage) {
      shiftColor[0] = 2.0 * tex2D (maskSampler, xy + shiftXY[0]) - 1.0;
      shiftColor[1] = 2.0 * tex2D (maskSampler, xy + shiftXY[1]) - 1.0;
      shiftColor[2] = 2.0 * tex2D (maskSampler, xy + shiftXY[2]) - 1.0;
      shiftColor[3] = 2.0 * tex2D (maskSampler, xy + shiftXY[3]) - 1.0;
   }
   else {
      shiftColor[0] = 2.0 * tex2D (noiseSampler, xy + shiftXY[0]) - 1.0;
      shiftColor[1] = 2.0 * tex2D (noiseSampler, xy + shiftXY[1]) - 1.0;
      shiftColor[2] = 2.0 * tex2D (noiseSampler, xy + shiftXY[2]) - 1.0;
      shiftColor[3] = 2.0 * tex2D (noiseSampler, xy + shiftXY[3]) - 1.0;
   }

   float3 u = float3 (1.0, 0.0, 0.5 * (shiftColor[1].x - shiftColor[0].x));
   float3 v = float3 (0.0, 1.0, 0.5 * (shiftColor[3].x - shiftColor[2].x));

   float4 nColor = float4 (0.5 * normalize (cross (u, v)) + 0.5, 1.0);

   float2 r;

   r.x = xy.x + (cos (radians (nColor.r * 180)) * strength);
   r.y = xy.y + (cos (radians (nColor.r * 180)) * strength);

   return tex2D (InputSampler, r);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass SinglePass0
   <
      string Script = "RenderColorTarget0 = NoiseTex;";
   >
   {
      PixelShader = compile PROFILE createNoise ();
   }

   pass SinglePass1
   {
      PixelShader = compile PROFILE FxRefraction ();
   }
}
