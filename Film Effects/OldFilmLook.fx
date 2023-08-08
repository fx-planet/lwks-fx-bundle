// @Maintainer jwrl
// @Released 2023-08-09
// @Author khaver
// @Author saabi
// @Created 2018-06-20

/**
 This effect simulates a black and white film with scratches, sprocket holes, weave and
 flicker.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect OldFilmLook.fx
//
//-----------------------------------------------------------------------------------------//
// Original Shadertoy author:
// saabi (2018-03-31) https://www.shadertoy.com/view/4dVcRy
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------------------------------------------//
// OldFilmLookFx.fx for Lightworks was adapted by user khaver 20 June 2018 from original
// code by the above author taken from the Shadertoy website:
// https://www.shadertoy.com/view/4dVcRy
//
// This adaptation retains the same Creative Commons license shown above.  It cannot be
// used for commercial purposes.
//
// note: code comments are from the original author(s).
//
// Version history:
//
// Updated 2023-08-09 jwrl.
// Corrected the category.  Changed it from "Colour" to "Stylize", which is what it
// was originally and should never have been changed.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Old film look", "Stylize", "Film Effects", "Simulates a black and white film with scratches, sprocket holes, weave and flicker.", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (scale, "Frame Zoom", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (sprockets, "Size", "Sprockets", kNoFlags, 6.72, 0.0, 20.0);
DeclareFloatParam (sprocket2, "Alignment", "Sprockets", kNoFlags, 3.19, 0.0, 10.0);
DeclareBoolParam (sprocket3, "Double Quantity", "Sprockets", false);

DeclareFloatParam (gstrength, "Grain Strength", "Flaws", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (ScratchAmount, "Scratch Amount", "Flaws", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (NoiseAmount, "Dirt Amount", "Flaws", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (smallJitterProbability, "Minor", "Jitter", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (largeJitterProbability, "Major", "Jitter", kNoFlags, 0.05, 0.0, 1.0);
DeclareFloatParam (angleProbability, "Rotational", "Jitter", kNoFlags, 0.15, 0.0, 1.0);

DeclareFloatParam (flicker, "Flicker Strength", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

DeclareFloatParam (_Frame);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define CTIME  (_Length * _Progress)
#define iFrame _Frame

float separation = 1.2;
float filmWidth = 1.4;

float2 smallJitterDisplacement = float2(0.003,0.003);
float2 largeJitterDisplacement = float2(0.03,0.03);

float angleJitter = 0.0349; //2.0*3.1415/180.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   return (max (xy.x, xy.y) > 0.5) ? kTransparentBlack : tex2D (s, uv);
}

float time () { return CTIME * 0.0101; }

float hash (float n) { return frac (cos (n * 89.42) * 343.42); }

float2 hash2 (float2 n)
{
   return float2 (hash ((n.x * 23.62) + (n.y * 34.35) - 300.0),
                  hash ((n.x * 45.13) + (n.y * 38.89) + 256.0));
}

float worley (float2 c, float time)
{
   float dis = 1.0;

   for (int x = -1; x <= 1; x++) {

      for (int y = -1; y <= 1; y++) {
         float2 p = floor (c) + float2 (x, y);
         float2 a = hash2 (p) * time;
         float2 rnd = 0.5 + (sin (a) * 0.5);

         float d = length (rnd + float2 (x,y) - frac (c));

         dis = min (dis, d);
      }
   }

   return dis;
}

float worley2 (float2 c, float time)
{
   float w = worley (c, time) / 2.0;

   return w + (worley (c + c, time + time) / 4.0);
}

float worley5 (float2 c, float time)
{
   float w = 0.0;
   float a = 0.5;

   for (int i = 0; i < 5; i++) {
      w += worley (c, time) * a;
      c += c;
      time += time;
      a *= 0.5;
   }

   return w;
}

float rand (float2 co)
{
   return frac (sin (dot (co.xy, float2 (12.9898, 78.233))) * 43758.5453);
}

float2 jitter (float2 uv, float2 s, float seed)
{
   return float2 (rand (float2 (time (), seed)) - 0.5, rand (float2 (time(), seed + 0.11)) - 0.5) * s;
}

float2 rot (float2 coord, float a)
{
   float sin_factor, cos_factor;

   sincos (a, sin_factor, cos_factor);

   coord.x *= _OutputAspectRatio * 2.0;
   coord = mul (coord, float2x2 (cos_factor, -sin_factor, sin_factor, cos_factor));
   coord.x /= _OutputAspectRatio * 2.0;

   return coord;
}

float4 vignette (float2 uv, float strength)
{
   float l = length (uv);

   l = pow (l, 2.25);

   return 1.0.xxxx - float4 (l.xxx * strength, 1.0);
}

float4 bw (float4 c)
{
   float v = c.r * 0.15 + c.g * 0.8 + c.b * 0.05;

   return float4 (v.xxx, 1.0);
}

float4 sepia (float4 c, float s)
{
   float or = (c.r * 0.393) + (c.g * 0.769) + (c.b * 0.189);
   float og = (c.r * 0.349) + (c.g * 0.686) + (c.b * 0.168);
   float ob = (c.r * 0.272) + (c.g * 0.534) + (c.b * 0.131);

   return float4 (float3 (or, og, ob) * s, 1.0);
}

float4 frame (float2 uv, float fn)
{
   if (any (abs (uv > 0.5))) return sepia (float4 (0.03, 0.02, 0.0, 0.02), 1.0);

   float strength = 64.0 * gstrength;
   float x = (uv.x + 4.0 ) * (uv.y + 4.0 ) * (CTIME + 10.0);

   float4 grain = float (fmod ((fmod (x, 13.0) + 1.0) * (fmod (x, 123.0) + 1.0), 0.01) - 0.005).xxxx * strength;
   float4 i = fn_tex2D (Input, uv + 0.5);

   float fnn = frac ((floor ((fn + 0.5) / separation) + CTIME) / 20.0);
   float fj = rand (float2 (fnn, 5.34)) * 2.0;

   float4 ic = float4 (lerp (i.rgb, i.rgb * fj, flicker), 1.0) * vignette (uv * 2.5, 0.25);
   float4 bwc = bw (ic);

   uv.x *= 100.0 + (CTIME * 0.1);
   uv.y *= 100.0;

   float dis = worley5 (uv / 64.0, CTIME * 50.0);

   float3 c = lerp (-1.0.xxx, 10.0.xxx, dis);

   float4 spots = float4 (saturate (c), 1.0);

   float noiseTrigger = rand (float2 (time () * 8.543, 2.658));

   spots = (noiseTrigger < NoiseAmount) ? spots : 1.0.xxxx;

   return sepia (bwc, 1.0) * (1.0 - grain) * spots;
}

float4 film (float2 uv)
{
   float wm = 0.5 + ((filmWidth - 1.0) / 4.0);
   float ww = (filmWidth - 1.0) * 0.1;
   float ax = abs (uv.x);
   float sprc = sprocket3 ? 2.0 : 4.0;

   if (ax > filmWidth / 2.0 || (ax > wm - ww && ax < wm + ww && fmod (floor ((uv.y + sprocket2) * sprockets), sprc) == 1.0))
      return 1.0.xxxx;

   uv.x *= 2000.1;
   uv.y *= 5.0;

   float disw = worley2 (uv / 164.0, floor (CTIME * 10.389) * 50.124);

   float3 cw = lerp (1.0.xxx, -30.6.xxx, disw);

   cw = saturate (1.0.xxx - (cw * cw));

   float scratchTrigger = rand (float2 (time() * 2.543, 0.823));

   cw = scratchTrigger < ScratchAmount ? cw : 0.0.xxx;

   return float4 (cw * 2.0, (cw.x < 0.5) ? 0.0 : 1.0);
}

float4 final (float2 uv, float aspect)
{
   float smallJitterTrigger = rand (float2 (time (), 0.125));
   float largeJitterTrigger = rand (float2 (time (), 0.122));

   float2 juv = float2 (uv.x - 0.5, uv.y);

   juv += (smallJitterTrigger > smallJitterProbability ? 0.0.xx : jitter (uv, smallJitterDisplacement, 0.01));
   juv += (largeJitterTrigger > largeJitterProbability ? 0.0.xx : jitter (uv, largeJitterDisplacement, 0.01));

   float rotationTrigger = rand (float2 (time (), 0.123));

   if (rotationTrigger <= angleProbability) juv = rot (juv, (rand (float2 (time (), 0.14)) - 0.5) * angleJitter);

   float2 fuv = float2 (juv.x * aspect, (fmod (juv.y + 1.705, separation) - 0.5));

   float4 flm = film (float2 (juv.x * aspect, juv.y + 100.0));

   if (flm.a == 1.0) return frame (fuv, juv.y) + flm;

   return float4 (frame (fuv, juv.y).rgb - (flm.rgb * 2.0), 1.0);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Film)
{
   // Normalized pixel coordinates (from 0 to 1)

   float scl = (scale * 1.05) + 0.75;

   float2 uv = uv1 - 0.5.xx;

   uv.y *= _OutputAspectRatio;
   uv /= scl;
   uv.y += 0.695;
   uv += 0.5.xx;

   // Output to screen

   return final (uv, _OutputAspectRatio);
}

DeclareEntryPoint (OldFilmLook)
{
   float4 c = tex2D (Film, uv2);

   for (float i = 0.25; i < 2.0; i += 0.25) {
      c += tex2D (Film, uv2 + float2 (0.0, i / _OutputHeight));
      c += tex2D (Film, uv2 - float2 (0.0, i / _OutputHeight));
      c += tex2D (Film, uv2 + float2 (i / _OutputWidth, 0.0));
      c += tex2D (Film, uv2 - float2 (i / _OutputWidth, 0.0));
   }

   float4 fragColor = (c / 29.0) * vignette (uv2 - 0.5, 2.0);

   return IsOutOfBounds (uv1) ? kTransparentBlack : float4 (fragColor.rgb, 1.0);
}

