// @Maintainer jwrl
// @Released 2023-05-16
// @Author khaver
// @Author toninoni
// @Created 2018-06-12

/**
 This effect is an accurate lens flare simulation.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LensFlare.fx
//-----------------------------------------------------------------------------------------//
//
// Original Shadertoy author:
// toninoni (2014-02-05) https://www.shadertoy.com/view/ldSXWK
//
// LensFlare.fx for Lightworks was adapted by user khaver 12 June 2018 from original
// code by the above author taken from the Shadertoy website:
// https://www.shadertoy.com/view/ldSXWK
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Lens Flare", "Stylize", "Filters", "Basic lens flare", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (CENTERX, "Center", kNoGroup, "SpecifiesPointX", 0.15, 0.0, 1.0);
DeclareFloatParam (CENTERY, "Center", kNoGroup, "SpecifiesPointY", 0.75, 0.0, 1.0);

DeclareFloatParam (AMOUNT, "Intensity", kNoGroup, kNoFlags, 2.0, 0.0, 10.0);
DeclareFloatParam (COMPLEXITY, "Lens Adjustment", kNoGroup, kNoFlags, 1.0, 0.0, 10.0);
DeclareFloatParam (DISTANCE, "Flare Distance", kNoGroup, kNoFlags, 1.0, 0.0, 10.0);
DeclareFloatParam (ZOOM, "Flare Size", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (SCATTER, "Light Scatter", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam (AFFECT, "Use Image", "Image Content", false);

DeclareFloatParam (THRESH, "Threshold", "Image Content", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (_Progress);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float vary (sampler S)
{
   float pixX = 1.0 / _OutputWidth;
   float pixY = 1.0 / _OutputHeight;

   float2 iMouse = float2 (CENTERX, 1.0 - CENTERY);

   float4 col = tex2D (S, iMouse);

   col += tex2D (S, iMouse - float2 (pixX, pixY));
   col += tex2D (S, float2 (iMouse.x, iMouse.y - pixY));
   col += tex2D (S, iMouse + float2 (pixX, -pixY));

   col += tex2D (S, float2 (iMouse.x - pixX, iMouse.y));
   col += tex2D (S, float2 (iMouse.x + pixX, iMouse.y));

   col += tex2D (S, iMouse - float2 (pixX, -pixY));
   col += tex2D (S, float2 (iMouse.x, iMouse.y + pixY));
   col += tex2D (S, iMouse + float2 (pixX, pixY));

   col /= 9.0;

   return dot (col.rgb, float3(0.33333, 0.33334, 0.33333));
}

float3 lensflare (sampler S, float2 uv, float2 pos)
{
   float v = vary (S);

   if (v < THRESH) v = 0.0;

   if (!AFFECT) v = 1.0;

   pos *= DISTANCE;

   float intensity = AMOUNT;
   float scatter = (1.0 - SCATTER) * 0.85;

   float2 uvd = uv * (length (uv) * COMPLEXITY);

   float f1 = max (0.01 - pow (length (uv + 1.2 * pos), 1.9 * ZOOM * v), 0.0) * 7.0;
   float f2 = max (1.0 / (1.0 + 32.0 * pow (length (uvd + 0.8 * pos), 2.0 * ZOOM * v)), 0.0) * 0.1;
   float f22 = max (1.0 / (1.0 + 32.0 * pow (length (uvd + 0.85 * pos), 2.0 * ZOOM * v)), 0.0) * 0.08;
   float f23 = max (1.0 / (1.0 + 32.0 * pow (length (uvd + 0.9 * pos), 2.0 * ZOOM * v)), 0.0) * 0.06;

   float2 uvx = lerp (uv, uvd, -0.5);

   float f4 = max (0.01 - pow (length (uvx + 0.4 * pos), 2.4 * ZOOM * v), 0.0) * 6.0;
   float f42 = max (0.01 - pow (length (uvx + 0.45 * pos), 2.4 * ZOOM * v), 0.0) * 5.0;
   float f43 = max (0.01 - pow (length (uvx + 0.5 * pos), 2.4 * ZOOM * v), 0.0) * 3.0;

   uvx = lerp (uv, uvd, -0.4);

   float f5 = max (0.01 - pow (length (uvx + 0.2 * pos), 5.5 * ZOOM * v), 0.0) * 2.0;
   float f52 = max (0.01 - pow (length (uvx + 0.4 * pos), 5.5 * ZOOM * v), 0.0) * 2.0;
   float f53 = max (0.01 - pow (length (uvx + 0.6 * pos), 5.5 * ZOOM * v), 0.0) * 2.0;

   uvx = lerp (uv, uvd, -0.5);

   float f6 = max (0.01 - pow (length (uvx - 0.3 * pos), 1.6 * ZOOM * v), 0.0) * 6.0;
   float f62 = max (0.01 - pow (length (uvx - 0.325 * pos), 1.6 * ZOOM * v), 0.0) * 3.0;
   float f63 = max (0.01 - pow (length (uvx - 0.35 * pos), 1.6 * ZOOM * v), 0.0) * 5.0;

   float3 c = 0.0.xxx;

   c.r += f2 + f4 + f5 + f6;
   c.g += f22 + f42 + f52 + f62;
   c.b += f23 + f43 + f53 + f63;

   return ((c * 1.3) - (length (uvd) * scatter).xxx) * intensity;
}

float3 cc (float3 color, float factor, float factor2)
{
   float w = color.r + color.g + color.b;

   return lerp (color, w.xxx * factor, w * factor2);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (LensFlare2)
{
   float2 uv = uv2 - 0.5.xx;
   float2 mouse = float2 (CENTERX - 0.5, (1.0 - CENTERY) - 0.5);

   float4 orig = tex2D (Inp, uv2);

   uv.x *= _OutputAspectRatio;
   mouse.x *= _OutputAspectRatio;

   float3 color = float3 (1.5, 1.2, 1.2) * lensflare (Inp, uv, mouse);

   color = saturate (cc (color, 0.5, 0.1));
   color = lerp (kTransparentBlack, color, orig.a);

   return float4 (saturate (orig.rgb + color), orig.a);
}

