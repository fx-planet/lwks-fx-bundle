// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This transition splits a blended foreground image into strips which then move off
 either horizontally or vertically to reveal the incoming image.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Slice_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
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
DeclareIntParam (Ttype, "Transition position", kNoGroup, 2, "At start if delta key folded|At start if non-delta unfolded|Standard transitions");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareIntParam (SetTechnique, "Strip direction", kNoGroup, 1, "Right to left|Left to right|Top to bottom|Bottom to top");
DeclareIntParam (Mode, "Strip type", kNoGroup, 0, "Mode A|Mode B");

DeclareFloatParam (StripNumber, "Strip number", kNoGroup, kNoFlags, 20.0, 10.0, 50.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, sampler B, float2 xy)
{
   float4 Bgnd, Fgnd = tex2D (F, xy);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = tex2D (B, xy);
      }
      else Bgnd = tex2D (B, xy);

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

DeclarePass (Fg_L)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_L)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_L)
{ return fn_keygen (Fg_L, Bg_L, uv3); }

DeclareEntryPoint (Slice_Left)
{
   float2 bg, xy = uv3;

   float strips = max (2.0, round (StripNumber));

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

   float4 Bgnd;

   if (Ttype == 0) {
      bg = uv1;
      Bgnd = tex2D (Fg_L, uv3);
   }
   else {
      bg = uv2;
      Bgnd = tex2D (Bg_L, uv3);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bg)) ? kTransparentBlack : tex2D (Super_L, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Slice right

DeclarePass (Fg_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_R)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_R)
{ return fn_keygen (Fg_R, Bg_R, uv3); }

DeclareEntryPoint (Slice_Right)
{
   float2 bg, xy = uv3;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 2) {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
   }
   else {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
   }

   float4 Bgnd;

   if (Ttype == 0) {
      bg = uv1;
      Bgnd = tex2D (Fg_R, uv3);
   }
   else {
      bg = uv2;
      Bgnd = tex2D (Bg_R, uv3);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bg)) ? kTransparentBlack : tex2D (Super_R, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Slice top

DeclarePass (Fg_T)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_T)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_T)
{ return fn_keygen (Fg_T, Bg_T, uv3); }

DeclareEntryPoint (Slice_Top)
{
   float2 bg, xy = uv3;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 2) {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
   }
   else {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
   }

   float4 Bgnd;

   if (Ttype == 0) {
      bg = uv1;
      Bgnd = tex2D (Fg_T, uv3);
   }
   else {
      bg = uv2;
      Bgnd = tex2D (Bg_T, uv3);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bg)) ? kTransparentBlack : tex2D (Super_T, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Slice bottom

DeclarePass (Fg_B)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_B)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_B)
{ return fn_keygen (Fg_B, Bg_B, uv3); }

DeclareEntryPoint (Slice_Bottom)
{
   float2 bg, xy = uv3;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 2) {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
   }
   else {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
   }

   float4 Bgnd;

   if (Ttype == 0) {
      bg = uv1;
      Bgnd = tex2D (Fg_B, uv3);
   }
   else {
      bg = uv2;
      Bgnd = tex2D (Bg_B, uv3);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bg)) ? kTransparentBlack : tex2D (Super_B, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

