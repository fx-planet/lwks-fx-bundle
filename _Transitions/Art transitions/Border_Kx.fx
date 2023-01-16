// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 An effect transition that generates borders using a difference or delta key then uses
 them to make the image materialise from four directions or blow apart in four directions.
 Each quadrant is independently coloured.

 If the foreground and/or background resolution differ from the sequence resolution it
 will be necessary to adjust the delta key trim.  Normally you won't need to do this.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Border_Kx_2022.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Border transition (keyed) 2022+", "Mix", "Art transitions", "The foreground materialises from four directions or dematerialises to four directions", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Radius, "Thickness", "Borders", kNoFlags, 0.3, 0.0, 1.0);
DeclareFloatParam (Displace, "Displacement", "Borders", kNoFlags, 0.5, 0.0, 1.0);

DeclareColourParam (Colour_1, "Outline 1", "Colours", kNoFlags, 0.6, 0.9, 1.0, 1.0);
DeclareColourParam (Colour_2, "Outline 2", "Colours", kNoFlags, 0.3, 0.6, 1.0, 1.0);
DeclareColourParam (Colour_3, "Outline 3", "Colours", kNoFlags, 0.9, 0.6, 1.0, 1.0);
DeclareColourParam (Colour_4, "Outline 4", "Colours", kNoFlags, 0.6, 0.3, 1.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_Progress);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define NotEqual(XY_1,XY_2) (any ((XY_1 - XY_2) != 0.0))

#define RADIUS_0 (float2 (1.0, _OutputWidth / _OutputHeight) * 0.00125)
#define DIVISOR  61.0

#define LOOP_1   30
#define RADIUS_1 (float2 (1.0, _OutputWidth / _OutputHeight) * 0.018)
#define ANGLE_1  0.1047

#define LOOP_2   24
#define RADIUS_2 (float2 (1.0, _OutputWidth / _OutputHeight) * 0.012)
#define ANGLE_2  0.1309

#define OFFSET   0.5
#define X_OFFSET 0.5625
#define Y_OFFSET 1.7777777778

#define HALF_PI  1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Fgnd = ReadPixel (F, xy1);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 fn_antialias (sampler S, float2 uv)
{
   float2 radius = RADIUS_0;
   float2 xy1, xy2;

   float4 retval = ReadPixel (S, uv);
   float4 input  = retval;

   float amount = saturate (_Progress * 15.0);

   amount = min (amount, saturate ((1.0 - _Progress) * 15.0));

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy1.x, xy1.y);
      xy1 *= radius;
      xy2  = uv - xy1;
      xy1 += uv;
      retval += ReadPixel (S, xy1);
      retval += ReadPixel (S, xy2);
   }

   return lerp (input, retval / DIVISOR, amount);
}

float4 fn_border_1 (sampler S, float2 uv)
{
   float4 retval = kTransparentBlack;

   if (Radius == 0.0) return retval;

   float radScale = cos (Amount * HALF_PI);

   float2 radius = Radius * radScale * RADIUS_1;
   float2 xy1, xy2;

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy1.x, xy1.y);
      xy1 *= radius;
      xy2  = uv - xy1;
      xy1 += uv;
      retval = max (retval, ReadPixel (S, xy1));
      retval = max (retval, ReadPixel (S, xy2));
   }

   return retval;
}

float4 fn_border_2 (sampler S1, sampler S2, float2 uv)
{
   float4 retval = ReadPixel (S2, uv);

   if (Radius == 0.0) return retval;

   float radScale = cos (Amount * HALF_PI);
   float alpha = saturate (ReadPixel (S1, uv).a * 2.0);

   float2 radius = Radius * radScale * RADIUS_2;
   float2 xy1, xy2;

   for (int i = 0; i < LOOP_2; i++) {
      sincos ((i * ANGLE_2), xy1.x, xy1.y);
      xy1 *= radius;
      xy2  = uv - xy1;
      xy1 += uv;
      retval = max (retval, ReadPixel (S2, xy1));
      retval = max (retval, ReadPixel (S2, xy2));
   }

   return lerp (retval, kTransparentBlack, alpha);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Border_F

DeclarePass (Key_F)
{
   float4 Fgnd = ReadPixel (Fg, uv1);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (Bg, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

DeclarePass (Super_F)
{ return fn_antialias (Key_F, uv3); }

DeclarePass (Border_1_F)
{ return fn_border_1 (Super_F, uv3); }

DeclarePass (Border_2_F)
{ return fn_border_2 (Super_F, Border_1_F, uv3); }

DeclareEntryPoint (BorderFolded)
{
   float Offset = (1.0 - Amount) * Displace * OFFSET;
   float Outline = 0.0, Opacity = 1.0;

   float2 xy1 = Offset.xx;
   float2 xy2 = float2 (xy1.x * X_OFFSET, (-xy1.y) * Y_OFFSET);
   float2 xy3 = uv3 - xy1;
   float2 xy4 = uv3 + xy1;

   xy1  = uv3 - xy2;
   xy2 += uv3;

   float4 border = ReadPixel (Super_F, xy1);
   float4 retval = kTransparentBlack;

   if (NotEqual (xy1, xy2)) {
      retval = ReadPixel (Super_F, xy2); border = lerp (border, retval, retval.a);
      retval = ReadPixel (Super_F, xy3); border = lerp (border, retval, retval.a);
      retval = ReadPixel (Super_F, xy4); border = lerp (border, retval, retval.a);

      retval = Colour_1 * ReadPixel (Border_2_F, xy1).a;
      retval = lerp (retval, Colour_2, ReadPixel (Border_2_F, xy2).a);
      retval = lerp (retval, Colour_3, ReadPixel (Border_2_F, xy3).a);
      retval = lerp (retval, Colour_4, ReadPixel (Border_2_F, xy4).a);

      sincos ((Amount * HALF_PI), Outline, Opacity);
      Opacity = 1.0 - sin (Opacity * HALF_PI);
   }

   if (CropEdges && IsOutOfBounds (uv1)) {
      border = kTransparentBlack;
      retval = kTransparentBlack;
   }

   float4 Bgnd = lerp (ReadPixel (Fg, uv1), border, border.a * Opacity);

   return lerp (Bgnd, retval, retval.a * Outline);
}


// technique Border_I

DeclarePass (Key_I)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Super_I)
{ return fn_antialias (Key_I, uv3); }

DeclarePass (Border_1_I)
{ return fn_border_1 (Super_I, uv3); }

DeclarePass (Border_2_I)
{ return fn_border_2 (Super_I, Border_1_I, uv3); }

DeclareEntryPoint (BorderInput)
{
   float Offset = (1.0 - Amount) * Displace * OFFSET;
   float Outline = 0.0, Opacity = 1.0;

   float2 xy1 = Offset.xx;
   float2 xy2 = float2 (xy1.x * X_OFFSET, (-xy1.y) * Y_OFFSET);
   float2 xy3 = uv3 - xy1;
   float2 xy4 = uv3 + xy1;

   xy1  = uv3 - xy2;
   xy2 += uv3;

   float4 border = ReadPixel (Super_I, xy1);
   float4 retval = kTransparentBlack;

   if (NotEqual (xy1, xy2)) {
      retval = ReadPixel (Super_I, xy2); border = lerp (border, retval, retval.a);
      retval = ReadPixel (Super_I, xy3); border = lerp (border, retval, retval.a);
      retval = ReadPixel (Super_I, xy4); border = lerp (border, retval, retval.a);

      retval = Colour_1 * ReadPixel (Border_2_I, xy1).a;
      retval = lerp (retval, Colour_2, ReadPixel (Border_2_I, xy2).a);
      retval = lerp (retval, Colour_3, ReadPixel (Border_2_I, xy3).a);
      retval = lerp (retval, Colour_4, ReadPixel (Border_2_I, xy4).a);

      sincos ((Amount * HALF_PI), Outline, Opacity);
      Opacity = 1.0 - sin (Opacity * HALF_PI);
   }

   if (CropEdges && IsOutOfBounds (uv2)) {
      border = kTransparentBlack;
      retval = kTransparentBlack;
   }

   float4 Bgnd = lerp (ReadPixel (Bg, uv2), border, border.a * Opacity);

   return lerp (Bgnd, retval, retval.a * Outline);
}


// technique Border_O

DeclarePass (Key_O)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Super_O)
{ return fn_antialias (Key_O, uv3); }

DeclarePass (Border_1_O)
{
   float4 retval = kTransparentBlack;

   if (Radius == 0.0) return retval;

   float radScale = sin (Amount * HALF_PI);

   float2 radius = Radius * radScale * RADIUS_1;
   float2 xy1, xy2;

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy1.x, xy1.y);
      xy1 *= radius;
      xy2  = uv3 - xy1;
      xy1 += uv3;
      retval = max (retval, ReadPixel (Super_O, xy1));
      retval = max (retval, ReadPixel (Super_O, xy2));
   }

   return retval;
}

DeclarePass (Border_2_O)
{
   float4 retval = ReadPixel (Border_1_O, uv3);

   if (Radius == 0.0) return retval;

   float radScale = sin (Amount * HALF_PI);
   float alpha = saturate (tex2D (Super_O, uv3).a * 2.0);

   float2 radius = Radius * radScale * RADIUS_2;
   float2 xy1, xy2;

   for (int i = 0; i < LOOP_2; i++) {
      sincos ((i * ANGLE_2), xy1.x, xy1.y);
      xy1 *= radius;
      xy2  = uv3 - xy1;
      xy1 += uv3;
      retval = max (retval, ReadPixel (Border_1_O, xy1));
      retval = max (retval, ReadPixel (Border_1_O, xy2));
   }

   return lerp (retval, kTransparentBlack, alpha);
}

DeclareEntryPoint (BorderOutput)
{
   float Offset = Amount * Displace * OFFSET;
   float Outline = 0.0, Opacity = 1.0;

   float2 xy1 = float2 (-Offset, Offset);
   float2 xy2 = float2 (xy1.x * X_OFFSET, (-xy1.y) * Y_OFFSET);
   float2 xy3 = uv3 - xy1;
   float2 xy4 = uv3 + xy1;

   xy1  = uv3 - xy2;
   xy2 += uv3;

   float4 border = ReadPixel (Super_O, xy1);
   float4 retval = kTransparentBlack;

   if (NotEqual (xy1, xy2)) {
      retval = ReadPixel (Super_O, xy2); border = lerp (border, retval, retval.a);
      retval = ReadPixel (Super_O, xy3); border = lerp (border, retval, retval.a);
      retval = ReadPixel (Super_O, xy4); border = lerp (border, retval, retval.a);

      retval = Colour_1 * ReadPixel (Border_2_O, xy1).a;
      retval = lerp (retval, Colour_2, ReadPixel (Border_2_O, xy2).a);
      retval = lerp (retval, Colour_3, ReadPixel (Border_2_O, xy3).a);
      retval = lerp (retval, Colour_4, ReadPixel (Border_2_O, xy4).a);

      sincos ((Amount * HALF_PI), Opacity, Outline);
      Opacity = 1.0 - sin (Opacity * HALF_PI);
   }

   if (CropEdges && IsOutOfBounds (uv2)) {
      border = kTransparentBlack;
      retval = kTransparentBlack;
   }

   float4 Bgnd = lerp (ReadPixel (Bg, uv2), border, border.a * Opacity);

   return lerp (Bgnd, retval, retval.a * Outline);
}

