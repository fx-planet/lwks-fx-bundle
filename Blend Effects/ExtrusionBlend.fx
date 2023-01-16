// @Maintainer jwrl
// @Released 2023-01-05
// @Author jwrl
// @Created 2023-01-05

/**
 "Extrusion blend", as the name suggests, extrudes a foreground image either linearly
 or radially towards a centre point.  The extruded section can be shaded by the
 foreground image, colour shaded, or flat colour filled.  The edge shading can be
 inverted if desired. It is also possible to export the alpha channel for use in
 downstream effects.

 Masking is applied to the foreground before the extrusion process.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ExtrusionBlend.fx
//
// Version history:
//
// Built 2023-01-05 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Extrusion blend", "Mix", "Blend Effects", "Extrudes a foreground image either linearly or radially towards a centre point", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Mode, "Edge type", kNoGroup, 0, "Radial|Radial shaded|Radial coloured|Linear|Linear shaded|Linear coloured");

DeclareFloatParam (Opacity, "Master opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (zoomAmount, "Length", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Xcentre, "Effect centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre, "Effect centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareColourParam (Colour, "Edge colour", "Colour setup", kNoFlags, 1.0, 0.3804, 1.0, 1.0));

DeclareBoolParam (invShade, "Invert shading", kNoGroup, true);
DeclareBoolParam (expAlpha, "Export alpha channel", kNoGroup, false);

DeclareIntParam (Source, "Source selection", "Disconnect title and image key inputs", 1, "Crawl/Roll/Title/Image key|Video/External image|Extracted foreground");

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_OutputWidth);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SAMPLE   80
#define HALFWAY  40
#define SAMPLES  81

#define DELTANG  25
#define ALIASFIX 50
#define ANGLE    0.125664

#define B_SCALE  0.0075
#define L_SCALE  0.05
#define R_SCALE  0.00125

#define DEFAULT  0
#define COLOUR   1
#define MONO     2

#define LIN_OFFS 0.667333

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 Eradial (sampler K, float2 uv, int mode)
{
   float4 retval = tex2D (K, uv);

   if (zoomAmount == 0.0) return retval;

   float scale, depth = zoomAmount * R_SCALE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1 = uv;
   float2 xy2 = depth * (uv - zoomCentre);

   retval.rgb = 1.0.xxx - retval.rgb;

   for (int i = 0; i <= SAMPLE; i++) {
      xy1 = uv + (xy2 * i);
      retval += tex2D (K, xy1);
   }

   retval.a = saturate (retval.a);

   if (mode == COLOUR) return float4 (Colour.rgb, retval.a);

   retval.rgb = ((retval.rgb / SAMPLES) * 0.75) + 0.125;

   if (((mode == DEFAULT) && !invShade) || ((mode != DEFAULT) && invShade))
      return retval;

   return float4 (1.0.xxx - retval.rgb, retval.a);
}

float4 Elinear (sampler K, float2 uv, int mode)
{
   float4 retval = tex2D (K, uv);

   float2 offset, xy = uv;

   offset.x = (0.498 - Xcentre) * LIN_OFFS;
   offset.y = (Ycentre - 0.505) * LIN_OFFS;

   if ((max (abs (offset.x), abs (offset.y)) == 0.0) || (zoomAmount == 0.0)) return retval;

   float depth = zoomAmount * L_SCALE;

   retval.rgb = 1.0.xxx - retval.rgb;
   offset *= 1.0 / sqrt ((offset.x * offset.x) + (offset.y * offset.y));
   offset *= depth * B_SCALE;

   for (int i = 0; i < SAMPLES; i++) {
      retval += tex2D (K, xy);
      xy += offset;
      }

   retval.a = saturate (retval.a);

   if (mode == COLOUR) return float4 (Colour.rgb, retval.a);

   retval.rgb = ((retval.rgb / SAMPLES) * 0.75) + 0.125;

   if (((mode == DEFAULT) && !invShade) || ((mode != DEFAULT) && invShade))
      return retval;

   return float4 (1.0.xxx - retval.rgb, retval.a);
}

float4 Eshaded (sampler B, sampler C, float2 uv)
{
   float4 blurImg = tex2D (B, uv);
   float4 colrImg = tex2D (C, uv);

   float alpha   = blurImg.a;
   float minColr = min (colrImg.r, min (colrImg.g, colrImg.b));
   float maxColr = max (colrImg.r, max (colrImg.g, colrImg.b));
   float delta   = maxColr - minColr;

   float3 hsv = 0.0.xxx;

   if (maxColr != 0.0) {
      hsv.y = 1.0 - (minColr / maxColr);
      hsv.x = (colrImg.r == maxColr) ? (colrImg.g - colrImg.b) / delta :
              (colrImg.g == maxColr) ? 2.0 + (colrImg.b - colrImg.r) / delta
                                     : 4.0 + (colrImg.r - colrImg.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
   }

   hsv.z = max (blurImg.r, max (blurImg.g, blurImg.b));

   if (hsv.y == 0.0) return float4 (hsv.zzz, alpha);

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float beta = hsv.x - (float) i;

   float4 retval = hsv.zzzz;

   retval.w *= (1.0 - hsv.y * (1.0 - beta));
   retval.y *= (1.0 - hsv.y);
   retval.z *= (1.0 - hsv.y * beta);

   if (i == 0) return float4 (retval.xwy, alpha);
   if (i == 1) return float4 (retval.zxy, alpha);
   if (i == 2) return float4 (retval.yxw, alpha);
   if (i == 3) return float4 (retval.yzx, alpha);
   if (i == 4) return float4 (retval.wyx, alpha);

   return float4 (retval.xyz, alpha);
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

   return lerp (0.0.xxxx, Fgd, tex2D (Mask, uv1));
}

DeclarePass (blurPre)
{
   return (Mode == 1) ? Eradial (KeyFg, uv3, MONO) :
          (Mode == 4) ? Elinear (KeyFg, uv3, MONO) : kTransparentBlack;
}

DeclarePass (colourPre)
{
   return (Mode == 1) ? Eradial (KeyFg, uv3, COLOUR) :
          (Mode == 4) ? Elinear (KeyFg, uv3, COLOUR) : kTransparentBlack;
}

DeclarePass (blurProc)
{
   if (Mode == 0) return Eradial (KeyFg, uv3, DEFAULT);
   if (Mode == 1) return Eshaded (blurPre, colourPre, uv3);
   if (Mode == 2) return Eradial (KeyFg, uv3, COLOUR);
   if (Mode == 3) return Elinear (KeyFg, uv3, DEFAULT);
   if (Mode == 4) return Eshaded (blurPre, colourPre, uv3);

   return Elinear (KeyFg, uv1, COLOUR);
}

DeclareEntryPoint (ExtrusionBlend)
{
   float4 Fgnd   = tex2D (KeyFg, uv3);
   float4 retval = kTransparentBlack;

   float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 offset, scale;

   float angle = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      retval += tex2D (blurProc, uv3 + offset);
      retval += tex2D (blurProc, uv3 - offset);
      angle += ANGLE;
   }

   retval  /= ALIASFIX;
   retval   = lerp (kTransparentBlack, retval, retval.a);
   retval   = lerp (retval, Fgnd, Fgnd.a);
   retval.a = max (Fgnd.a, retval.a * Strength);

   if (expAlpha) return retval;

   float4 Bgnd = ReadPixel (Bg, uv2);

   retval = lerp (Bgnd, retval, retval.a);

   return lerp (Bgnd, retval, Opacity);
}

