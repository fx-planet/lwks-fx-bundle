// @Maintainer jwrl
// @Released 2023-01-12
// @Author jwrl
// @Created 2023-01-12

/**
 This effect uses three possible profiles.  One partially inverts red, one partially inverts
 blue, and the third takes the red channel of an image and partially subtracts blue and
 green channels from it.  Highlights are then burned out, gamma is adjusted and video noise
 added.  Finally the image is softened and coloured green.  Because this type of effect will
 always be subjective, highlight burnout, gamma, grain, softness and green saturation and
 hue are all adjustable.  Hue adjustment ranges from yellow to cyan.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NightVision.fx
//
// Version history:
//
// Built 2023-01-12 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Night vision", "Stylize", "Video artefacts", "Simulates infra-red night time cinematography", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Filter", kNoGroup, 0, "Profile 1|Profile 2|Profile 3");

DeclareFloatParam (Burnout, "Burnout", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Gamma, "Gamma", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Grain, "Grain", kNoGroup, kNoFlags, 0.3333, 0.0, 1.0);
DeclareFloatParam (Softness, "Softness", kNoGroup, kNoFlags, 0.3333, 0.0, 1.0);
DeclareFloatParam (Saturation, "Saturation", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Hue, "Hue", kNoGroup, kNoFlags, 0.5, -1.0, 1.0);

DeclareFloatParam (_Progress);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUMA     float3(0.2989, 0.5866, 0.1145)
#define GB_LUMA  float2(0.81356, 0.18644)

#define P1_SCALE 3.0
#define P2_SCALE 1.54576
#define P3_SCALE 0.5

#define KNEE     0.85
#define KNEE_FIX 5.6666666667

#define LOOP     9
#define DIVIDE   73

#define RADIUS_1 0.002
#define RADIUS_2 2.5

#define ANGLE    0.3490658504

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_noise (sampler S, float2 xy)
{
   float4 Fgnd = ReadPixel (S, xy);

   float2 uv = saturate (xy + float2 (0.00013, 0.00123));

   float rand = frac ((dot (uv, float2 (uv.x + 123.0, uv.y + 13.0)) * ((Fgnd.g + 1.0) * uv.x)) + _Progress);

   rand = (rand * 1000.0) + sin (uv.x) + cos (uv.y);

   return saturate (frac (fmod (rand, 13.0) * fmod (rand, 123.0))).xxxx;
}

float4 fn_glow (sampler S1, sampler S2, float2 uv)
{
   float4 Fgnd = tex2D (S1, uv);
   float4 retval = Fgnd;

   float2 radius = float2 (1.0, _OutputAspectRatio) * RADIUS_1;
   float2 xy1, xy2;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy1.x, xy1.y);
      xy1 *= radius;
      xy2 = float2 (-xy1.x, xy1.y) * RADIUS_2;
      retval += tex2D (S1, uv + xy1);
      retval += tex2D (S1, uv - xy1);
      retval += tex2D (S1, uv + xy2);
      retval += tex2D (S1, uv - xy2);
      xy1 += xy1;
      xy2 += xy2;
      retval += tex2D (S1, uv + xy1);
      retval += tex2D (S1, uv - xy1);
      retval += tex2D (S1, uv + xy2);
      retval += tex2D (S1, uv - xy2);
   }

   retval = saturate (Fgnd + (retval * Burnout / DIVIDE));

   float3 vid_grain = tex2D (S2, (uv / 3.0)).rgb + retval.rgb - 0.5.xxx;

   return float4 (lerp (retval.rgb, vid_grain, Grain), retval.a);
}

float4 fn_main (sampler S, float2 uv, float2 uv_1)
{
   float4 retval = tex2D (S, uv);

   if (Softness > 0.0) {
      float2 radius = float2 (1.0, _OutputAspectRatio) * Softness * RADIUS_1;
      float2 blur = retval.ga;
      float2 xy1, xy2;

      for (int i = 0; i < LOOP; i++) {
         sincos ((i * ANGLE), xy1.x, xy1.y);
         xy1 *= radius;
         xy2 = float2 (-xy1.x, xy1.y) * RADIUS_2;
         blur += tex2D (S, uv + xy1).ga;
         blur += tex2D (S, uv - xy1).ga;
         blur += tex2D (S, uv + xy2).ga;
         blur += tex2D (S, uv - xy2).ga;
         xy1 += xy1;
         xy2 += xy2;
         blur += tex2D (S, uv + xy1).ga;
         blur += tex2D (S, uv - xy1).ga;
         blur += tex2D (S, uv + xy2).ga;
         blur += tex2D (S, uv - xy2).ga;
      }

      retval = saturate (blur / DIVIDE).xxxy;
   }

   retval.rb  = retval.g * float2 (0.2, 0.6);
   retval = float4 (lerp (retval.ggg, retval.rgb, Saturation), retval.a);

   if (Hue < 0.0) retval.r = lerp (retval.r, retval.g, abs (Hue));
   else retval.b = lerp (retval.b, retval.g, Hue);

   return IsOutOfBounds (uv_1) ? kTransparentBlack : retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Noise_0)
{ return fn_noise (Input, uv1); }

DeclarePass (Luma_0)
{
   float4 Fgnd = ReadPixel (Input, uv1);

   float luma  = dot (Fgnd.rgb, LUMA);
   float gamma = (Gamma > 0.0) ? Gamma * 0.8 : Gamma * 4.0;

   luma = abs (luma - Fgnd.b) * P1_SCALE;
   luma = saturate (pow (luma, (1.0 - gamma)));

   return float4 (luma.xxx, Fgnd.a);
}

DeclarePass (Glow_0)
{ return fn_glow (Luma_0, Noise_0, uv2); }

DeclareEntryPoint (NightVision_0)
{ return fn_main (Glow_0, uv2, uv1); }

//-----------------------------------------------------------------------------------------//

DeclarePass (Noise_1)
{ return fn_noise (Input, uv1); }

DeclarePass (Luma_1)
{
   float4 Fgnd = ReadPixel (Input, uv1);

   float luma = abs (dot (Fgnd.gb, GB_LUMA) - (Fgnd.r * P2_SCALE));
   float gamma = (Gamma > 0.0) ? Gamma * 0.8 : Gamma * 4.0;

   luma = saturate (pow (luma, (1.0 - gamma)));

   return float4 (luma.xxx, Fgnd.a);
}

DeclarePass (Glow_1)
{ return fn_glow (Luma_1, Noise_1, uv2); }

DeclareEntryPoint (NightVision_1)
{ return fn_main (Glow_1, uv2, uv1); }

//-----------------------------------------------------------------------------------------//

DeclarePass (Noise_2)
{ return fn_noise (Input, uv1); }

DeclarePass (Luma_2)
{
   float4 Fgnd = ReadPixel (Input, uv1);

   float luma  = dot (Fgnd.gb, GB_LUMA);
   float reds  = Fgnd.r * (2.0 - Fgnd.r);
   float gamma = (Gamma * 0.75) - 0.25;

   if (luma > KNEE) { luma = (1.0 - luma) * KNEE_FIX; }

   gamma *= (gamma > 0.0) ? 0.8 : 4.0;
   luma   = saturate (reds - (luma * P3_SCALE));
   luma   = saturate (pow (luma, (1.0 - gamma)));

   return float4 (luma.xxx, Fgnd.a);
}

DeclarePass (Glow_2)
{ return fn_glow (Luma_2, Noise_2, uv2); }

DeclareEntryPoint (nightVision_2)
{ return fn_main (Glow_2, uv2, uv1); }

