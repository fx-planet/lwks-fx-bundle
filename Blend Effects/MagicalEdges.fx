// @Maintainer jwrl
// @Released 2023-01-23
// @Author jwrl
// @Author Robert Schütze
// @Created 2023-01-23

/**
 This effect generates a border from a title or graphic with an alpha channel.  It then adds
 fractal generated four pointed stars to that border to create a sparkle/glitter effect to
 the edges of the title or graphic.  The fractal speed, scaling and offset is adjustable as
 well as star colour, density, length and rotation.

 Masking is applied to the foreground before the main effect creation.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MagicalEdges.fx
//
// Version history:
//
// Built 2023-01-23 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Magical edges", "Mix", "Blend Effects", "Fractal edges with star-shaped radiating blurs", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (EdgeWidth, "Edge width", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Rate, "Speed", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (StartPoint, "Start point", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (Threshold, "Threshold", "Stars", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Brightness, "Brightness", "Stars", kNoFlags, 1.0, 1.0, 10.0);
DeclareFloatParam (StarLen, "Length", "Stars", kNoFlags, 5.0, 0.0, 20.0);
DeclareFloatParam (Rotation, "Rotation", "Stars", kNoFlags, 45.0, 0.0, 180.0);
DeclareFloatParam (Strength, "Strength", "Stars", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Xcentre, "Effect centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre, "Effect centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);
DeclareFloatParam (Size, "Effect centre", kNoGroup, "SpecifiesPointZ", 0.0, 0.0, 1.0);

DeclareFloatParam (ColourMix, "Colour modulation", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareColourParam (Colour, "Modulation value", kNoGroup, kNoFlags, 0.69, 0.26, 1.0, 1.0);

DeclareBoolParam (ShowFractal, "Show pattern", kNoGroup, false);

DeclareIntParam (Source, "Source selection", "Disconnect title and image key inputs", 1, "Crawl/Roll/Title/Image key|Video/External image|Extracted foreground");

DeclareFloatParam (_Progress);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI_2  6.28318530718

#define R_VAL 0.2989
#define G_VAL 0.5866
#define B_VAL 0.1145

#define SCL_RATE 224

#define LOOP 60

#define DELTANG 25
#define ANGLE   0.1256637061

#define A_SCALE 0.005
#define B_SCALE 0.0005

#define STAR_LENGTH 0.00025

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

DeclarePass (Fractals)
{
   float progress = ((_Progress + StartPoint) * PI_2) / sqrt (SCL_RATE + 1.0 - (SCL_RATE * Rate));

   float2 seed = float2 (cos (progress) * 0.3, sin (progress) * 0.5) + 0.5;
   float2 xy = uv3 - float2 (Xcentre, 1.0 - Ycentre);

   float3 retval = float3 (xy / (Size + 0.01), seed.x);

   float4 fg = tex2D (KeyFg, uv3);

   for (int i = 0; i < LOOP; i++) {
      retval.rbg = float3 (1.2, 0.999, 0.9) * (abs ((abs (retval) / dot (retval, retval) - float3 (1.0, 1.0, seed.y * 0.4))));
   }

   retval = saturate (retval);

   float luma = (retval.r * R_VAL) + (retval.g * G_VAL) + (retval.b * B_VAL);
   float Yscl = (Colour.r * R_VAL) + (Colour.g * G_VAL) + (Colour.b * B_VAL);

   Yscl = saturate (Yscl - 0.5);
   Yscl = 1 / (Yscl + 0.5);

   float4 buffer = Colour * luma  * Yscl;

   return float4 (lerp (retval, buffer.rgb, ColourMix), fg.a);
}

DeclarePass (Sample_1)
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
      border += tex2D (Sample_1, uv3 + offset).a;
      border += tex2D (Sample_1, uv3 - offset).a;
      angle += ANGLE;
   }

   border = saturate (border / DELTANG);

   float3 retval = lerp (0.0.xxx, ReadPixel (Fractals, uv3).rgb, border);

   return float4 (retval, border);
}

DeclarePass (Sample_2)
{
   float4 retval = tex2D (Border, uv3);

   return ((retval.r + retval.g + retval.b) / 3.0 > 1.0 - Threshold) ? retval : 0.0.xxxx;
}

DeclarePass (Sample_3)
{
   float3 delt, ret = 0.0.xxx;

   float2 xy1, xy2, xy3 = 0.0.xx, xy4 = 0.0.xx;

   sincos (radians (Rotation), xy1.y, xy1.x);
   sincos (radians (Rotation + 90), xy2.y, xy2.x);

   xy1 *= StarLen * STAR_LENGTH;
   xy2 *= StarLen * STAR_LENGTH;

   xy1.y *= _OutputAspectRatio;
   xy2.y *= _OutputAspectRatio;

   for (int i = 0; i < 18; i++) {
      delt = tex2D (Sample_2, uv1 + xy3).rgb;
      delt = max (delt, tex2D (Sample_2, uv1 - xy3).rgb);
      delt = max (delt, tex2D (Sample_2, uv1 + xy4).rgb);
      delt = max (delt, tex2D (Sample_2, uv1 - xy4).rgb);
      delt *= 1.0 - (i / 36.0);
      ret += delt;
      xy3 += xy1;
      xy4 += xy2;
   }

   return float4 (ret, 1.0);
}

DeclarePass (Sample_4)
{
   float3 delt, ret = 0.0.xxx;

   float2 xy1, xy2, xy3, xy4;

   sincos (radians (Rotation), xy1.y, xy1.x);
   sincos (radians (Rotation + 90), xy2.y, xy2.x);

   xy1 *= StarLen * STAR_LENGTH;
   xy2 *= StarLen * STAR_LENGTH;

   xy1.y *= _OutputAspectRatio;
   xy2.y *= _OutputAspectRatio;

   xy3 = xy1 * 18.0;
   xy4 = xy2 * 18.0;

   for (int i = 0; i < 18; i++) {
      delt = tex2D (Sample_2, uv3 + xy3).rgb;
      delt = max (delt, tex2D (Sample_2, uv3 - xy3).rgb);
      delt = max (delt, tex2D (Sample_2, uv3 + xy4).rgb);
      delt = max (delt, tex2D (Sample_2, uv3 - xy4).rgb);
      delt *= 0.5 - (i / 36.0);
      ret += delt;
      xy3 += xy1;
      xy4 += xy2;
   }

   ret = (ret + tex2D (Sample_3, uv3).rgb) / 3.6;

   return float4 (ret, 1.0);
}

DeclareEntryPoint (MagicalEdges)
{
   float4 Bgd = ReadPixel (Bg, uv2);

   if (IsOutOfBounds (uv1)) return Bgd;

   float4 Fgd = ReadPixel (KeyFg, uv3);
   float4 retval = lerp (Bgd, Fgd, Fgd.a * Amount);

   float4 border = ReadPixel (Border, uv3);

   if (ShowFractal) return lerp (ReadPixel (Fractals, uv3), border, (border.a + 1.0) / 2);

   retval = lerp (retval, border, Brightness * border.a);

   float4 glint = tex2D (Sample_4, uv3);
   float4 comb  = retval + (glint * (1.0 - retval));

   retval = lerp (retval, comb, Strength);

   return lerp (Bgd, retval, tex2D (Mask, uv1).x);
}

