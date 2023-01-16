// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This transition splits a blended foreground image into strips which then move off
 either horizontally or vertically to reveal the incoming image.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Slice_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Slice transition (keyed)", "Mix", "Wipe transitions", "Splits the foreground into strips which move on or off horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (Ttype, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareIntParam (SetTechnique, "Strip direction", kNoGroup, 1, "Right to left|Left to right|Top to bottom|Bottom to top");
DeclareIntParam (Mode, "Strip type", kNoGroup, 0, "Mode A|Mode B");

DeclareFloatParam (StripNumber, "Strip number", kNoGroup, kNoFlags, 20.0, 10.0, 50.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd, Fgnd = ReadPixel (F, xy1);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = ReadPixel (B, xy2);
      }
      else Bgnd = ReadPixel (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Slice left

DeclarePass (Super_L)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Slice_Left)
{
   float4 Bgnd;

   float2 bgd, xy = uv3;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 2) {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
   }
   else {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
   }

   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = ReadPixel (Bg, uv2);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_L, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}


// technique Slice right

DeclarePass (Super_R)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Slice_Right)
{
   float4 Bgnd;

   float2 bgd, xy = uv3;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 2) {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
      Bgnd = ReadPixel (Bg, uv2);
   }
   else {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
      Bgnd = (Ttype == 0) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);
   }

   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = ReadPixel (Bg, uv2);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_R, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}


// technique Slice top

DeclarePass (Super_T)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Slice_Top)
{
   float4 Bgnd;

   float2 bgd, xy = uv3;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 2) {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      Bgnd = ReadPixel (Bg, uv2);
   }
   else {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      Bgnd = (Ttype == 0) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);
   }

   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = ReadPixel (Bg, uv2);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_T, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}


// technique Slice bottom

DeclarePass (Super_B)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Slice_Bottom)
{
   float4 Bgnd;

   float2 bgd, xy = uv3;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 2) {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      Bgnd = ReadPixel (Bg, uv2);
   }
   else {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      Bgnd = (Ttype == 0) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);
   }

   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = ReadPixel (Bg, uv2);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_B, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

