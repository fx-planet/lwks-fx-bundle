// @Maintainer jwrl
// @Released 2023-05-15
// @Author khaver
// @Created 2018-05-05
// @OriginalAuthor Alexander Alekseev 2014


/**
 Seascape produces a very realistic ocean simulation.  Wave height, choppiness and frequency
 are all adjustable.  The height above the waves and the speed through them can also be set
 up, as can the rocking of the POV.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SeaScape.fx
//
//-----------------------------------------------------------------------------------------//
// "Seascape" by Alexander Alekseev aka TDM - 2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Contact: tdmaav@gmail.com
//-----------------------------------------------------------------------------------------//
// Sea_Scape.fx for Lightworks was adapted by user khaver 5 May 2018 for use with Lightworks
// version 14.5 and higher from original code by the above licensee taken from the Shadertoy
// website (https://www.shadertoy.com/view/Ms2SD1).
//
// This adaptation retains the same Creative Commons license shown above.
// It cannot be used for commercial purposes.
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-11 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Sea Scape", "Matte", "Special Effects", "Seascape produces a very realistic ocean simulation", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Direction, "Direction", kNoGroup, kNoFlags, 0.0, -2.0, 2.0);

DeclareFloatParam (ShipHeight, "Height", "Ship", kNoFlags, 3.5, 0.0, 10.0);
DeclareFloatParam (ShipSpeed, "Speed", "Ship", kNoFlags, 10.0, 0.0, 50.0);

DeclareBoolParam (Reverse, "Reverse", kNoGroup, false);

DeclareFloatParam (RockingAmount, "Amount", "Rocking", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (RockingSpeed, "Speed", "Rocking", kNoFlags, 1.0, 0.0, 10.0);

DeclareFloatParam (WaveHeight, "Height", "Waves", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (WaveSpeed, "Speed", "Waves", kNoFlags, 0.8, 0.0, 3.0);
DeclareFloatParam (WaveFrequency, "Frequency", "Waves", kNoFlags, 0.16, 0.0, 5.0);
DeclareFloatParam (WaveChoppiness, "Choppiness", "Waves", kNoFlags, 4.0, 0.0, 10.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_Progress);

DeclareFloatParam (_LengthFrames);
DeclareFloatParam (_Length);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float3 Water = float3 (0.8, 0.9,  0.6);  // Water Color
float3 Base  = float3 (0.1, 0.19, 0.22); // Base Color

int _NUM_STEPS = 8;
static int ITER_GEOMETRY = 3;
static int ITER_FRAGMENT = 5;

float2x2 octave_m = float2x2 (1.6, 1.2, -1.2, 1.6);

#define EPSILON_NRM (0.1 / _OutputWidth)
#define CTIME       (_Length * _Progress * -1.0)
#define SEA_TIME    (1.0 + CTIME * WaveSpeed)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// math

float3x3 fromEuler (float3 ang)
{
   float2 a1, a2, a3;

   float3x3 m;

   sincos (ang.x, a1.x, a1.y);
   sincos (ang.y, a2.x, a2.y);
   sincos (ang.z, a3.x, a3.y);

   m [0] = float3 (a1.y * a3.y + a1.x * a2.x * a3.x, a1.y * a2.x * a3.x + a3.y * a1.x, -a2.y * a3.x);
   m [1] = float3 (-a2.y * a1.x, a1.y * a2.y, a2.x);
   m [2] = float3 (a3.y * a1.x * a2.x + a1.y * a3.x, a1.x * a3.x - a1.y * a3.y * a2.x, a2.y * a3.y);

   return m;
}

float hash (float2 p)
{
   float h = dot (p, float2 (127.1, 311.7));

   return frac (sin (h) * 43758.5453123);
}

float noise (float2 p)
{
   float2 i = floor (p);
   float2 f = frac (p);
   float2 u = f * f * (3.0 - 2.0 * f);

   return 2.0 * lerp (lerp (hash (i + 0.0.xx), hash (i + float2 (1.0, 0.0)), u.x),
                      lerp (hash (i + float2 (0.0,1.0)), hash (i + 1.0.xx), u.x), u.y) - 1.0;
}

// lighting

float diffuse (float3 n, float3 l, float p)
{
   return pow (dot (n, l) * 0.4 + 0.6, p);
}

float specular(float3 n,float3 l,float3 e,float s)
{
   float nrm = (s + 8.0) / (3.1415 * 8.0);

   return pow (max (dot (reflect (e, n), l), 0.0), s) * nrm;
}

// sky

float3 getSkyColor (float3 e)
{
   float e_y = 1.0 - max (e.y, 0.0);

   return float3 (pow (e_y, 2.0), e_y, 0.6 + (e_y * 0.4));
}

// sea

float sea_octave (float2 uv, float choppy)
{
   float2 xy = uv + noise (uv);
   float2 wv = 1.0 - abs (sin (xy));
   float2 swv = abs (cos (xy));

   wv = lerp (wv, swv, wv);

   return pow (1.0 - pow (wv.x * wv.y, 0.65), choppy);
}

float map (float3 p)
{
   float freq = WaveFrequency;
   float amp = WaveHeight;
   float choppy = WaveChoppiness;
   float d, h = 0.0;

   float2 uv = p.xz;

   uv.x *= 0.75;

   for (int i = 0; i < ITER_GEOMETRY; i++) {
      d  = sea_octave ((uv + SEA_TIME) * freq, choppy);
      d += sea_octave ((uv - SEA_TIME) * freq, choppy);
      h += d * amp;
      uv = mul (uv, octave_m);
      freq *= 1.9;
      amp *= 0.22;
      choppy = lerp (choppy, 1.0, 0.2);
   }

   return p.y - h;
}

float map_detailed (float3 p)
{
   float freq = WaveFrequency;
   float amp = WaveHeight;
   float choppy = WaveChoppiness;
   float d, h = 0.0;

   float2 uv = p.xz;

   uv.x *= 0.75;

   for (int i = 0; i < ITER_FRAGMENT; i++) {
      d  = sea_octave ((uv + SEA_TIME) * freq, choppy);
      d += sea_octave ((uv - SEA_TIME) * freq,choppy);
      h += d * amp;
      uv = mul (uv,octave_m);
      freq *= 1.9;
      amp *= 0.22;
      choppy = lerp (choppy, 1.0, 0.2);
   }

   return p.y - h;
}

float3 getSeaColor (float3 p, float3 n, float3 l, float3 eye, float3 dist)
{
   float fresnel = saturate (1.0 - dot (n, -eye));

   fresnel = pow (fresnel, 3.0) * 0.65;

   float3 reflected = getSkyColor (reflect (eye,n));
   float3 refracted = Base + diffuse (n, l, 80.0) * Water * 0.12;
   float3 color = lerp (refracted, reflected, fresnel);

   float atten = max (1.0 - dot (dist, dist) * 0.001, 0.0);
   float spec = specular (n, l, eye, 60.0);

   color += Water * (p.y - WaveHeight) * 0.18 * atten;

   return color + spec.xxx;
}

// tracing

float3 getNormal (float3 p, float eps)
{
   float3 n;

   n.y = map_detailed (p);
   n.x = map_detailed (float3 (p.x + eps, p.y, p.z)) - n.y;
   n.z = map_detailed (float3 (p.x, p.y, p.z + eps)) - n.y;
   n.y = eps;

   return normalize (n);
}

float heightMapTracing (float3 ori, float3 dir, out float3 p)
{
   float tm = 0.0;
   float tx = 1000.0;
   float hx = map (ori + dir * tx);

   if (hx > 0.0) return tx;

   float hm = map(ori + dir * tm);
   float tmid = 0.0;

   for (int i = 0; i < 8; i++) {
      tmid = lerp (tm, tx, hm / (hm - hx));
      p = ori + dir * tmid;
      float hmid = map (p);
      if (hmid < 0.0) {
         tx = tmid;
         hx = hmid;
      }
      else {
         tm = tmid;
         hm = hmid;
      }
   }

   return tmid;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (SeaScape)
{
   float iTime = Reverse ? -CTIME : CTIME;
   float time  = iTime * 0.3;
   float rtime = time * RockingSpeed;

   float2 xy = (float2 (uv0.x, 1.0 - uv0.y) * 2.0) - 1.0.xx;

   uv0.x *= _OutputWidth / _OutputHeight;

   // ray

   float3 ang = float3 (sin (rtime * 3.0) * 0.1, sin (rtime) * 0.2 + 0.3, rtime);
   float3 ori = float3 (0.0, ShipHeight, time * ShipSpeed);
   float3 dir = normalize (float3 (xy, - 2.0));

   dir.z += length (xy) * 0.00005;
   ang.xy *= RockingAmount;
   ang.z *= Direction;
   dir = mul (normalize (dir), fromEuler (ang));

   // tracing

   float3 p;

   heightMapTracing (ori, dir, p);

   float3 dist = p - ori;
   float3 n = getNormal (p, dot (dist, dist) * EPSILON_NRM);
   float3 light = normalize (float3 (0.0, 1.0, 0.8));

   // color

   float3 color = lerp (getSkyColor (dir), getSeaColor (p,n, light, dir, dist),
                        pow (smoothstep (0.0, -0.05, dir.y), 0.3));
   // post

   return float4 (pow (color, 0.75), 1.0);
}

