// @Maintainer jwrl
// @Released 2021-08-31
// @Author jwrl
// @Author Jerker
// @Author khaver
// @Created 2017-06-06
// @see https://www.lwks.com/media/kunena/attachments/6375/UnsharpMask_640.png

/**
 A simple unsharp mask.  Probably redundant, since the Lightworks effect does pretty much
 the same thing.  I've kept it because I prefer the look of this one.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Unsharp_mask.fx
//
// *********************************** ORIGINAL HEADER **************************************
//
// Unsharp Mask by Jerker (Sound and Vision Unit) - was based on Big Blur by khaver,
// see below - borrowed the main blur algorithm but simplified it by taking away the
// individual color settings.  http://software.soundandvision.se
//
// Original description: Big Blur by khaver
//
// Smooth blur using a 12 tap circular kernel that rotates 5 degrees for each of 6
// passes.  There's a checkbox for a 10 fold increase in the blur amount.  (This was
// actually reduced to 5 in Jerker's effect - jwrl)
//
// This was then totally rewritten 19 July 2017 by jwrl.  I decided to rewrite the effect
// from the ground up because of assumptions made about the way that shaders functioned
// in Lightworks which at best could only be described as coincidental if it was at all
// true.  This includes the blur section which took khaver's original big blur effect
// and heavily optimised it to reduce GPU loading.
//
// The original unsharpen shader has been discarded all together. I have gone back to
// first principles and created an algorithm that produces the sharpening using
// luminance.  There is also edge gain and contrast provided, which the original effect
// didn't have.
//
// ******************************** END OF ORIGINAL HEADER **********************************
//
// Version history:
//
// Updated 2021-08-31 jwrl:
// Partial rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 2020-11-09:
// Various updates mainly to improve cross-platform performance.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Unsharp mask";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "Try the Lightworks sharpen effects first and use this only if those don't have enough range";
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
#define ExecuteParam(SHD,PRM) { PixelShader = compile PROFILE SHD (PRM); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

#define LUMA_DOT  float3(1.1955,2.3464,0.4581)
#define GAMMA_VAL 1.666666667

float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

SetInputMode (Input, s_RawInp, Mirror);

SetTargetMode (FixInp, s0, Mirror);
SetTargetMode (Pass1, s1, Mirror);
SetTargetMode (Pass2, s2, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float BlurAmt
<
   string Description = "Unsharp radius";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float Threshold
<
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float EdgeGain
<
   string Description = "Edge gain";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float EdgeGamma
<
   string Description = "Edge contrast";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Amount
<
   string Description = "Mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_RawInp, uv); }

float4 ps_blur_1 (float2 uv : TEXCOORD2) : COLOR
{  
   float4 orig = tex2D (s0, uv);

   if (BlurAmt <= 0.0) return orig;

   float angle, radius = BlurAmt * 100.0;

   float2 pixsize = 1.0.xx / float2 (_OutputWidth, _OutputHeight);
   float2 halfpix = pixsize / 2.0;
   float2 xy2, xy1 = uv + halfpix;

   float4 cOut = tex2D (s0, xy1);

   for (int tap = 0; tap < 12; tap++) {
      angle = radians (float (tap) * 30.0);
      sincos (angle, xy2.y, xy2.x);                             
      xy1 = uv + (halfpix * xy2 * radius);

      cOut += tex2D (s0, xy1);
   }

   cOut /= 13.0;

   return cOut;
}

float4 ps_blur_2 (float2 uv : TEXCOORD2, uniform float ang) : COLOR
{  
   float4 orig = tex2D (s1, uv);

   if (BlurAmt <= 0.0) return orig;

   float angle, radius = BlurAmt * 100.0;

   float2 pixsize = 1.0.xx / float2 (_OutputWidth, _OutputHeight);
   float2 halfpix = pixsize / 2.0;
   float2 xy2, xy1 = uv + halfpix;

   float4 cOut = tex2D (s1, xy1);

   for (int tap = 0; tap < 12; tap++) {
      angle = radians ((float (tap) * 30.0) + (ang * 5.0));
      sincos (angle, xy2.y, xy2.x);                             
      xy1 = uv + (halfpix * xy2 * radius);

      cOut += tex2D (s1, xy1);
   }

   cOut /= 13.0;

   return cOut;
}

float4 ps_blur_3 (float2 uv : TEXCOORD2, uniform float ang) : COLOR
{  
   float4 orig = tex2D (s2, uv);

   if (BlurAmt <= 0.0) return orig;

   float angle, radius = BlurAmt * 100.0;

   float2 pixsize = 1.0.xx / float2 (_OutputWidth, _OutputHeight);
   float2 halfpix = pixsize / 2.0;
   float2 xy2, xy1 = uv + halfpix;

   float4 cOut = tex2D (s2, xy1);

   for (int tap = 0; tap < 12; tap++) {
      angle = radians ((float (tap) * 30.0) + (ang * 10.0));
      sincos (angle, xy2.y, xy2.x);                             
      xy1 = uv + (halfpix * xy2 * radius);

      cOut += tex2D (s2, xy1);
   }

   cOut /= 13.0;

   return cOut;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   if (Overflow (uv1)) return EMPTY;

   float4 retval = tex2D (s0, uv2);

   if (Amount <= 0.0) return retval;

   float sharpMask = dot (retval.rgb, LUMA_DOT);
   float maskGamma = min (1.15, 1.1 - min (1.05, EdgeGamma)) * GAMMA_VAL;
   float maskGain  = EdgeGain * 2.0;

   sharpMask -= dot (tex2D (s1, uv2).rgb, LUMA_DOT);
   maskGamma *= maskGamma;

   float sharp_pos = pow (max (0.0, sharpMask - Threshold), maskGamma) * maskGain;
   float sharp_neg = pow (max (0.0, -sharpMask - Threshold), maskGamma) * maskGain;

   float4 sharp = float4 (retval.rgb + (sharp_pos - sharp_neg).xxx, retval.a);

   return lerp (retval, sharp, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P1 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteShader (ps_blur_1)

   pass P2 < string Script = "RenderColorTarget0 = Pass2;"; > ExecuteParam (ps_blur_2, 1)
   pass P3 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (ps_blur_3, 1)
   pass P4 < string Script = "RenderColorTarget0 = Pass2;"; > ExecuteParam (ps_blur_2, 3)
   pass P5 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (ps_blur_3, 2)
   pass P6 < string Script = "RenderColorTarget0 = Pass2;"; > ExecuteParam (ps_blur_2, 5)

   pass P7 ExecuteShader (ps_main)
}

