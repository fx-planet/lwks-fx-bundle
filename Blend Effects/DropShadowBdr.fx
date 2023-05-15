// @Maintainer jwrl
// @Released 2023-05-15
// @Author jwrl
// @Created 2018-10-21

/**
 "Drop shadow and border" is a drop shadow and border generator.  It provides drop shadow
 softness and independent colour settings for border and shadow.  Two border generation
 modes and full border anti-aliassing are provided.  The border centering can be offset
 to make the border assymetrical (thanks Igor for the suggestion).  The foreground can be
 faded out, leaving just the border and drop shadow visible.

 The effect can also output the foreground, border and/or drop shadow alone, with the
 appropriate alpha channel.  When doing so any background input to the effect will not
 be displayed.  This allows it to be used with downstream blending effects.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks effect DropShadowBdr.fx
//
// Version history:
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//
// Conversion 2023-01-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Drop shadow and border", "Mix", "Blend Effects", "Drop shadow and border generator for text graphics", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Foreground, "Foreground", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (BorderMode, "Border mode", "Border", 0, "Fully sampled|Full no anti-alias|Square edged|Square no anti-alias");
DeclareBoolParam (Lock, "Lock height to width", "Border", true);

DeclareFloatParam (Bopacity, "Opacity", "Border", kNoFlags, 1.00, 0.0, 1.0);
DeclareFloatParam (Width, "Width", "Border", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Height, "Height", "Border", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (CentreX, "Border centre", "Border", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Border centre", "Border", "SpecifiesPointY", 0.5, 0.0, 1.0);
DeclareColourParam (Bcolour, "Colour", "Border", kNoFlags, 0.4784, 0.3961, 1.0, 1.0);

DeclareFloatParam (Sopacity, "Opacity", "Shadow", kNoFlags, 0.50, 0.0, 1.0);
DeclareFloatParam (Sfeather, "Feather", "Shadow", kNoFlags, 0.3333, 0.0, 1.0);
DeclareFloatParam (OffsetX, "Offset", "Shadow", "SpecifiesPointX", 0.20, -1.0, 1.0);
DeclareFloatParam (OffsetY, "Offset", "Shadow", "SpecifiesPointY", -0.20, -1.0, 1.0);
DeclareColourParam (Scolour, "Colour", "Shadow", kNoFlags, 0.0, 0.0, 0.0, 1.0);

DeclareIntParam (OutputMode, "Output mode", kNoGroup, 0, "Normal (no alpha)|Foreground with alpha");

DeclareIntParam (Source, "Source selection", "Disconnect title and image key inputs", 1, "Crawl/Roll/Title/Image key|Video/External image|Extracted foreground");

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define F_SCALE    2
#define B_SCALE    10
#define S_SCALE    1.75
#define OFFS_SCALE 0.04

float _sin_0 [] = { 0.0, 0.2225, 0.4339, 0.6235, 0.7818, 0.9010, 0.9749 };
float _cos_0 [] = { 0.9749, 0.9010, 0.7818, 0.6235, 0.4339, 0.2225, 0.0 };

float _sin_1 [] = { 0.1305, 0.3827, 0.6088, 0.7934, 0.9239, 0.9914 };
float _cos_1 [] = { 0.9914, 0.9239, 0.7934, 0.6088, 0.3827, 0.1305 };

float _pascal [] = { 0.00000006, 0.00000143, 0.00001645, 0.00012064, 0.00063336,
                     0.00253344, 0.00802255, 0.02062941, 0.04383749, 0.07793331,
                     0.11689997, 0.14878178, 0.16118026 };

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclarePass (KeyFg)
{
   float4 Fgnd = tex2D (Fgd, uv3);

   if ((Fgnd.a == 0.0) || IsOutOfBounds (uv1)) return kTransparentBlack;

   if (Source == 0) {
      Fgnd.a    = pow (Fgnd.a, 0.5);
      Fgnd.rgb /= Fgnd.a;
   }
   else if (Source == 2) {
      float4 Bgnd = ReadPixel (Bgd, uv3);

      float kDiff = distance (Fgnd.g, Bgnd.g);

      kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
      kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));

      Fgnd.a = smoothstep (0.0, 0.25, kDiff);
      Fgnd.rgb *= Fgnd.a;
   }

   return Fgnd;
}

DeclarePass (RawBorder)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   if (Bopacity == 0.0) return ReadPixel (KeyFg, uv3);

   float edgeX = B_SCALE / _OutputWidth;
   float edgeY = 0.0;

   if (BorderMode < 2) { edgeY = edgeX * _OutputAspectRatio; }
   else edgeX *= S_SCALE;

   float2 offset;
   float2 xy = uv3 + float2 (edgeX * (0.5 - CentreX), edgeY * (CentreY - 0.5)) * 2.0;

   float4 retval = ReadPixel (KeyFg, xy);

   edgeX *= Width;
   edgeY *= Lock ? Width : Height;

   for (int i = 0; i < 7; i++) {
      offset.x = edgeX * _sin_0 [i];
      offset.y = edgeY * _cos_0 [i];

      retval += tex2D (KeyFg, xy + offset);
      retval += tex2D (KeyFg, xy - offset);

      offset.y = -offset.y;

      retval += tex2D (KeyFg, xy + offset);
      retval += tex2D (KeyFg, xy - offset);
   }

   return saturate (retval);
}

DeclarePass (Alias)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   if (Bopacity == 0.0) return tex2D (KeyFg, uv3);

   float edgeX = B_SCALE / _OutputWidth;
   float edgeY = edgeX * _OutputAspectRatio;

   if (BorderMode >= 2) {
      edgeX = 0.0;
      edgeY *= S_SCALE;
   }

   float2 offset;
   float2 xy = uv3 + float2 (edgeX * (0.5 - CentreX), edgeY * (CentreY - 0.5)) * 2.0;

   float4 retval = tex2D (RawBorder, xy);

   edgeX *= Width;
   edgeY *= Lock ? Width : Height;

   for (int i = 0; i < 6; i++) {
      offset.x = edgeX * _sin_1 [i];
      offset.y = edgeY * _cos_1 [i];

      retval += tex2D (RawBorder, xy + offset);
      retval += tex2D (RawBorder, xy - offset);

      offset.y = -offset.y;

      retval += tex2D (RawBorder, xy + offset);
      retval += tex2D (RawBorder, xy - offset);
   }

   return saturate (retval);
}

DeclarePass (Border)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 retval = tex2D (Alias, uv3);
   float4 Fgnd = tex2D (KeyFg, uv3);

   float PixelWidth  = 1.0 / _OutputWidth;
   float PixelHeight = 1.0 / _OutputHeight;

   if (Bopacity > 0.0) {

      if ((BorderMode == 0) || (BorderMode == 2)) {
         float2 offset = max (PixelHeight * _OutputAspectRatio, PixelWidth).xx / (_OutputWidth * 2.0);

         retval += tex2D (Alias, uv3 + offset);
         retval += tex2D (Alias, uv3 - offset);

         offset.x = -offset.x;

         retval += tex2D (Alias, uv3 + offset);
         retval += tex2D (Alias, uv3 - offset);
         retval /= 5.0;
      }

      float alpha = max (Fgnd.a, retval.a * Bopacity);

      retval = lerp (Bcolour, Fgnd, Fgnd.a);
      retval.a = alpha;
   }

   retval.a = saturate (retval.a - (Fgnd.a * (1.0 - Foreground)));

   return retval;
}

DeclarePass (Shadow)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float2 xy = uv3 - float2 (OffsetX / _OutputAspectRatio, -OffsetY) * OFFS_SCALE;

   float4 retval = tex2D (Border, xy);

   if ((Sopacity != 0.0) && (Sfeather != 0.0)) {
      float2 offset = float2 (Sfeather * F_SCALE / _OutputWidth, 0.0);
      float2 xy1 = xy + offset;

      retval *= _pascal [12];
      retval += tex2D (Border, xy1) * _pascal [11]; xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [10]; xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [9];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [8];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [7];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [6];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [5];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [4];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [3];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [2];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [1];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [0];
      xy1 = xy - offset;
      retval += tex2D (Border, xy1) * _pascal [11]; xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [10]; xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [9];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [8];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [7];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [6];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [5];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [4];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [3];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [2];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [1];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [0];
   }

   return retval;
}

DeclareEntryPoint (DropShadowBdr)
{
   float4 retval = tex2D (Shadow, uv3);
   float4 Bgnd = ReadPixel (Bgd, uv3);

   if (IsOutOfBounds (uv1)) return Bgnd;

   if ((Sopacity != 0.0) && (Sfeather != 0.0)) {
      float2 offset = float2 (0.0, Sfeather * F_SCALE * _OutputAspectRatio / _OutputWidth);
      float2 xy1 = uv3 + offset;

      retval *= _pascal [12];
      retval += tex2D (Shadow, xy1) * _pascal [11]; xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [10]; xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [9];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [8];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [7];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [6];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [5];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [4];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [3];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [2];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [1];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [0];
      xy1 = uv3 - offset;
      retval += tex2D (Shadow, xy1) * _pascal [11]; xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [10]; xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [9];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [8];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [7];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [6];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [5];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [4];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [3];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [2];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [1];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [0];
   }

   float alpha = retval.a * Sopacity;

   retval = tex2D (Border, uv3);
   alpha  = max (alpha, retval.a);
   retval = lerp (Scolour, retval, retval.a);
   retval.a = alpha * Opacity;

   if (OutputMode) return lerp (0.0.xxxx, retval, tex2D (Mask, uv3));

   float4 comp = float4 (lerp (Bgnd, retval, retval.a).rgb, max (Bgnd.a, retval.a));

   return lerp (Bgnd, comp, tex2D (Mask, uv3).x);
}

