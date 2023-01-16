// @Maintainer jwrl
// @Released 2022-12-31
// @Author jwrl
// @Created 2022-12-31

/**
 Edge glow (EdgeGlowFx.fx) is an effect that can use image levels or the edges of the
 image to produce a glow effect.  The resulting glow can be applied to the image using
 any of five blend modes.

 The glow can use the native image colours, a preset colour, or two colours which cycle.
 Cycle rate can be adjusted, and the detected edges can be mixed back over the effect.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect EdgeGlow.fx
//
// Version history:
//
// Built 2022-12-31 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Edge glow", "Stylize", "Art Effects", "Adds a level-based or edge-based glow to an image", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (lCycle, "Mode", "Glow", 1, "Luminance|Edge detect");
DeclareFloatParam (lRate, "Sensitivity", "Glow", kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (Size, "Size", "Glow", kNoFlags, 0.15, 0.0, 1.0);
DeclareFloatParam (EdgeMix, "Edge mix", "Glow", kNoFlags, 0.0, 0.0, 1.0);

DeclareIntParam (cCycle, "Mode", "Glow colour", 1, "Image colour|Colour 1|Cycle colours");
DeclareIntParam (SetTechnique, "Blend", "Glow colour", 0, "Add|Screen|Lighten|Soft glow|Vivid light");
DeclareFloatParam (cRate, "Cycle rate", "Glow colour", kNoFlags, 0.2, 0.0, 1.0);
DeclareColourParam (Colour_1, "Colour 1", "Glow colour", kNoFlags, 1.0, 0.75, 0.0, 1.0);
DeclareColourParam (Colour_2, "Colour 2", "Glow colour", kNoFlags, 1.0, 1.0, 0.0, 1.0);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LOOP     12
#define DIVIDE   49

#define RADIUS_1 4.0
#define RADIUS_2 10.0
#define RADIUS_3 20.0
#define RADIUS_4 35.0

#define ANGLE    0.2617993878

#define R_VALUE  0.3
#define G_VALUE  0.59
#define B_VALUE  0.11

#define L_RATE   0.002
#define G_SIZE   0.0005

#define HALF_PI  1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_get_luma (sampler s, float2 xy)
{
   float4 Fgd = tex2D (s, xy);

   return (Fgd.r + Fgd.g + Fgd.b) / 3.0;
}

float4 fn_getEdge (sampler Inp, float2 uv)
{
   if (IsOutOfBounds (uv)) return kTransparentBlack;

   float4 Fgd = tex2D (Inp, uv);
   float edges, pattern;

   if (lCycle == 1) {
      float nVal = 0.0;
      float xVal = L_RATE * lRate;
      float yVal = xVal * _OutputAspectRatio;

      float p2 = -1.0 * fn_get_luma (Inp, uv + float2 (xVal, yVal));
      float p1 = p2;

      p1 += fn_get_luma (Inp, uv - float2 (xVal, yVal));
      p1 += fn_get_luma (Inp, uv - float2 (xVal, -yVal));
      p1 -= fn_get_luma (Inp, uv + float2 (xVal, -yVal));
      p1 -= fn_get_luma (Inp, uv + float2 (xVal, nVal)) * 2.0;
      p1 += fn_get_luma (Inp, uv - float2 (xVal, nVal)) * 2.0;

      p2 += fn_get_luma (Inp, uv - float2 (xVal, yVal));
      p2 -= fn_get_luma (Inp, uv - float2 (xVal, -yVal));
      p2 += fn_get_luma (Inp, uv + float2 (xVal, -yVal));
      p2 -= fn_get_luma (Inp, uv + float2 (nVal, yVal)) * 2.0;
      p2 += fn_get_luma (Inp, uv - float2 (nVal, yVal)) * 2.0;

      edges = saturate (p1 * p1 + p2 * p2);
   }
   else {
      edges = dot (Fgd.rgb, float3 (R_VALUE, G_VALUE, B_VALUE));

      if (edges < (1.0 - lRate)) edges = 0.0;
   }

   pattern = _Progress * _Length * (1.0 + (cRate * 20.0));

   if (cCycle == 0) return lerp (kTransparentBlack, Fgd, edges);

   float4 part_1 = edges * Colour_1;
   float4 part_2 = edges * Colour_2;

   pattern = (cCycle == 2) ? (sin (pattern) * 0.5) + 0.5 : 0.0;

   return lerp (part_1, part_2, pattern);
}

float4 fn_glow (sampler gloSampler, float2 uv, float base)
{
   if (IsOutOfBounds (uv)) return kTransparentBlack;

   float4 retval = tex2D (gloSampler, uv);

   if (Size <= 0.0) return retval;

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * base * Size * G_SIZE;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      retval += tex2D (gloSampler, uv + xy);
      retval += tex2D (gloSampler, uv - xy);
      xy += xy;
      retval += tex2D (gloSampler, uv + xy);
      retval += tex2D (gloSampler, uv - xy);
   }

   return retval / DIVIDE;
}

float4 fn_fullGlow (sampler gloSampler, sampler s_Edge, float2 uv)
{
   if (IsOutOfBounds (uv)) return kTransparentBlack;

   float4 retval = tex2D (gloSampler, uv);

   float sizeComp = saturate (Size * 4.0);

   sizeComp = sin (sizeComp * HALF_PI);
   retval = lerp (kTransparentBlack, retval, sizeComp);

   if (lCycle != 1) return retval;

   float4 Glow = max (retval, tex2D (s_Edge, uv));

   return lerp (retval, Glow, EdgeMix);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Vid_A)
{ return ReadPixel (Input, uv1); }

DeclarePass (A_0)
{ return fn_getEdge (Vid_A, uv2); }

DeclarePass (A_1)
{ return fn_glow (A_0, uv2, RADIUS_1); }

DeclarePass (A_2)
{ return fn_glow (A_1, uv2, RADIUS_2); }

DeclarePass (A_3)
{ return fn_glow (A_2, uv2, RADIUS_3); }

DeclarePass (A_4)
{ return fn_glow (A_3, uv2, RADIUS_4); }

DeclarePass (A_Glow)
{ return fn_fullGlow (A_4, Vid_A, uv2); }

DeclareEntryPoint (EdgeGlowAdd)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Fgnd = tex2D (Vid_A, uv2);
   float4 Glow = saturate (Fgnd + tex2D (A_Glow, uv2));

   Glow.a = Fgnd.a;

   return lerp (Fgnd, Glow, tex2D (Mask, uv2));
}

DeclarePass (Vid_S)
{ return ReadPixel (Input, uv1); }

DeclarePass (S_0)
{ return fn_getEdge (Vid_S, uv2); }

DeclarePass (S_1)
{ return fn_glow (S_0, uv2, RADIUS_1); }

DeclarePass (S_2)
{ return fn_glow (S_1, uv2, RADIUS_2); }

DeclarePass (S_3)
{ return fn_glow (S_2, uv2, RADIUS_3); }

DeclarePass (S_4)
{ return fn_glow (S_3, uv2, RADIUS_4); }

DeclarePass (S_Glow)
{ return fn_fullGlow (S_4, Vid_S, uv2); }

DeclareEntryPoint (EdgeGlowScreen)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Fgnd   = tex2D (Vid_S, uv2);
   float4 Glow   = tex2D (S_Glow, uv2);
   float4 retval = saturate (Fgnd + Glow - (Fgnd * Glow));

   retval.a = Fgnd.a;

   return lerp (Fgnd, retval, tex2D (Mask, uv2));
}

DeclarePass (Vid_L)
{ return ReadPixel (Input, uv1); }

DeclarePass (L_0)
{ return fn_getEdge (Vid_L, uv2); }

DeclarePass (L_1)
{ return fn_glow (L_0, uv2, RADIUS_1); }

DeclarePass (L_2)
{ return fn_glow (L_1, uv2, RADIUS_2); }

DeclarePass (L_3)
{ return fn_glow (L_2, uv2, RADIUS_3); }

DeclarePass (L_4)
{ return fn_glow (L_3, uv2, RADIUS_4); }

DeclarePass (L_Glow)
{ return fn_fullGlow (L_4, Vid_L, uv2); }

DeclareEntryPoint (EdgeGlowLighten)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Fgnd = tex2D (Vid_L, uv2);
   float4 Glow = max (Fgnd, tex2D (L_Glow, uv2));

   Glow.a = Fgnd.a;

   return lerp (Fgnd, Glow, tex2D (Mask, uv2));
}

DeclarePass (Vid_SG)
{ return ReadPixel (Input, uv1); }

DeclarePass (SG_0)
{ return fn_getEdge (Vid_SG, uv2); }

DeclarePass (SG_1)
{ return fn_glow (SG_0, uv2, RADIUS_1); }

DeclarePass (SG_2)
{ return fn_glow (SG_1, uv2, RADIUS_2); }

DeclarePass (SG_3)
{ return fn_glow (SG_2, uv2, RADIUS_3); }

DeclarePass (SG_4)
{ return fn_glow (SG_3, uv2, RADIUS_4); }

DeclarePass (SG_Glow)
{ return fn_fullGlow (SG_4, Vid_SG, uv2); }

DeclareEntryPoint (EdgeGlowSoftGlow)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Fgnd   = tex2D (Vid_SG, uv2);
   float4 Glow   = Fgnd * tex2D (SG_Glow, uv2);
   float4 retval = saturate (Fgnd + Glow - (Fgnd * Glow));

   retval.a = Fgnd.a;

   return lerp (Fgnd, retval, tex2D (Mask, uv2));
}

DeclarePass (Vid_VL)
{ return ReadPixel (Input, uv1); }

DeclarePass (VL_0)
{ return fn_getEdge (Vid_VL, uv2); }

DeclarePass (VL_1)
{ return fn_glow (VL_0, uv2, RADIUS_1); }

DeclarePass (VL_2)
{ return fn_glow (VL_1, uv2, RADIUS_2); }

DeclarePass (VL_3)
{ return fn_glow (VL_2, uv2, RADIUS_3); }

DeclarePass (VL_4)
{ return fn_glow (VL_3, uv2, RADIUS_4); }

DeclarePass (VL_Glow)
{ return fn_fullGlow (VL_4, Vid_VL, uv2); }

DeclareEntryPoint (EdgeGlowVividLight)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Fgnd = tex2D (Vid_VL, uv2);
   float4 Glow = saturate ((tex2D (VL_Glow, uv2) * 2.0) + Fgnd - 1.0.xxxx);

   Glow.a = Fgnd.a;

   return lerp (Fgnd, Glow, tex2D (Mask, uv2));
}

