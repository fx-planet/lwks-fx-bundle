// @Maintainer jwrl
// @Released 2023-05-15
// @Author jwrl
// @Created 2016-05-10

/**
 This effect generates a border from a title or graphic with an alpha channel.  It then
 adds noise generated four pointed stars to that border to create a sparkle/glitter
 effect to the edges of the title or graphic.  Star colour, density, length and rotation
 are adjustable.

 The star point component is similar to khaver's Glint.fx, but modified to create four
 star points in one loop, to have no blur component, no choice of number of points, and
 to compile and run under the default Lightworks shader profile.  A different means of
 setting and calculating rotation is also used.

 Masking is applied to the foreground before the edge generation.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GlitteryEdges.fx
//
// Version history:
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//
// Conversion 2023-01-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Glittery edges", "Mix", "Blend Effects", "Sparkly edges, best over darker backgrounds", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Master opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Opacity, "Fgd opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (EdgeOpacity, "Opacity", "Edges", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (EdgeWidth, "Width", "Edges", kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (Threshold, "Threshold", "Stars", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Strength, "Strength", "Stars", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (StarLen, "Length", "Stars", "DisplayAsPercentage", 0.0125, 0.0, 0.025);
DeclareFloatParam (Rotation, "Rotation", "Stars", kNoFlags, 45.0, 0.0, 180.0);
DeclareFloatParam (Rate, "Speed", "Stars", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (StartPoint, "Noise seed", "Stars", kNoFlags, 0.0, 0.0, 1.0);

DeclareColourParam (Colour, "Colour", kNoGroup, kNoFlags, 1.0, 0.8, 0.0, 1.0);

DeclareIntParam (Source, "Source selection", "Disconnect title and image key inputs", 1, "Crawl/Roll/Title/Image key|Video/External image|Extracted foreground");

DeclareFloatParam (_Length);
DeclareFloatParam (_Progress);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DELTANG 25
#define ANGLE   0.1256637061

#define A_SCALE 0.005
#define B_SCALE 0.0005

#define STAR_LENGTH 0.025

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 fn_noise (float2 uv)
{
   float2 xy = saturate (float2 (uv.x + 0.00013, uv.y + 0.00123));

   float noise  = (_Progress * _Length * (0.01 + Rate) * 0.005) + StartPoint;
   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + noise) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + rndval * 1000;
   noise  = saturate (frac (fmod (rndval, 17) * fmod (rndval, 94)) * 15 - 12.0);

   return saturate ((Colour * noise) + Colour * 0.05).rgb;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (KeyFg)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Fgd = tex2D (Fg, uv1);

   if (Source == 0) {
      Fgd.a    = pow (Fgd.a, 0.5);
      Fgd.rgb /= Fgd.a;
   }
   else if (Source == 2) {
      float4 Bgd = ReadPixel (Bg, uv2);

      float kDiff = distance (Fgd.g, Bgd.g);

      kDiff = max (kDiff, distance (Fgd.r, Bgd.r));
      kDiff = max (kDiff, distance (Fgd.b, Bgd.b));

      Fgd.a = smoothstep (0.0, 0.25, kDiff);
      Fgd.rgb *= Fgd.a;
   }

   return Fgd;
}

DeclarePass (Sample_0)
{
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * (EdgeWidth + 0.1) * A_SCALE;
   float2 offset, scale;

   float angle  = 0.0;
   float border = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      border += tex2D (KeyFg, uv3 + offset).a;
      border += tex2D (KeyFg, uv3 - offset).a;
      angle += ANGLE;
   }

   border = (border / DELTANG) - 1.0;
   border = (border > 0.95) ? 0.0 : 1.0;
   border = min (border, tex2D (KeyFg, uv3).a);

   return border.xxxx;
}

DeclarePass (Border)
{
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * B_SCALE;
   float2 offset, scale;

   float border = 0.0;
   float angle  = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      border += tex2D (Sample_0, uv3 + offset).a;
      border += tex2D (Sample_0, uv3 - offset).a;
      angle += ANGLE;
   }

   border = saturate (border / DELTANG);

   float3 retval = lerp (0.0.xxx, fn_noise (uv3), border);

   return float4 (retval, border);
}

DeclarePass (Sample_1)
{
   float4 retval = tex2D (Border, uv3);

   return ((retval.r + retval.g + retval.b) / 3.0 < Threshold) ? kTransparentBlack : retval;
}

DeclarePass (Sample_2)
{
   float3 delt, ret = 0.0.xxx;

   float2 xy1, xy2, xy3 = 0.0.xx, xy4 = 0.0.xx;

   sincos (radians (Rotation), xy1.y, xy1.x);
   sincos (radians (Rotation + 90), xy2.y, xy2.x);

   xy1 *= StarLen * STAR_LENGTH;
   xy2 *= StarLen * STAR_LENGTH;

   xy1.y *= _OutputAspectRatio;
   xy2.y *= _OutputAspectRatio;

   for (int i = 0; i < 20; i++) {
      delt = ReadPixel (Sample_1, uv3 + xy3).rgb;
      delt = max (delt, tex2D (Sample_1, uv3 - xy3).rgb);
      delt = max (delt, tex2D (Sample_1, uv3 + xy4).rgb);
      delt = max (delt, tex2D (Sample_1, uv3 - xy4).rgb);
      delt *= 1.0 - (i / 40.0);
      ret += delt;
      xy3 += xy1;
      xy4 += xy2;
   }

   return float4 (ret, 1.0);
}

DeclarePass (Sparkle)
{
   float3 delt, ret = 0.0.xxx;

   float2 xy1, xy2, xy3, xy4;

   sincos (radians (Rotation), xy1.y, xy1.x);
   sincos (radians (Rotation + 90), xy2.y, xy2.x);

   xy3 = xy1 * StarLen;
   xy4 = xy2 * StarLen;

   xy3.y *= _OutputAspectRatio;
   xy4.y *= _OutputAspectRatio;

   xy1 = xy3 * 0.05;
   xy2 = xy4 * 0.05;

   for (int i = 0; i < 20; i++) {
      delt = tex2D (Sample_1, uv3 + xy3).rgb;
      delt = max (delt, tex2D (Sample_1, uv3 - xy3).rgb);
      delt = max (delt, tex2D (Sample_1, uv3 + xy4).rgb);
      delt = max (delt, tex2D (Sample_1, uv3 - xy4).rgb);
      delt *= 0.5 - (i / 40.0);
      ret += delt;
      xy3 += xy1;
      xy4 += xy2;
   }

   ret = (ret + tex2D (Sample_2, uv3).rgb) / 3.6;

   return float4 (ret, 1.0);
}

DeclareEntryPoint (GlitteryEdges)
{
   float4 Fgd = tex2D (KeyFg, uv3);
   float4 Bgd = ReadPixel (Bg, uv2);

   float4 glint  = tex2D (Sparkle, uv3);
   float4 retval = lerp (Bgd, Fgd, Fgd.a * Opacity);
   float4 border = tex2D (Border, uv3);

   border.rgb = Colour.rgb * 0.95;

   retval = lerp (retval, border, border.a * EdgeOpacity);
   glint  = saturate (retval + glint - (glint * retval));
   retval = lerp (retval, glint, Strength);

   retval = lerp (Bgd, retval, Amount);

   return lerp (Bgd, retval, tex2D (Mask, uv1).x);
}
