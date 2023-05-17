// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2023-03-04

/**
 This transition splits the outgoing image into strips which then move off either
 horizontally or vertically to reveal the incoming image.  This updated version adds
 the ability to choose whether to wipe the outgoing image out or the incoming image in.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SliceTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Sliced transition", "Mix", "Wipe transitions", "Separates and splits the image into strips which move on or off horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Strip direction", kNoGroup, 1, "Right to left|Left to right|Top to bottom|Bottom to top");
DeclareIntParam (Mode, "Strip type", kNoGroup, 0, "Mode A|Mode B");

DeclareFloatParam (StripNumber, "Strip number", kNoGroup, kNoFlags, 10.0, 5.0, 20.0);

DeclareBoolParam (Direction, "Invert direction", kNoGroup, false);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Crawl/Roll/Title/Image key|Video/External image");

DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);

DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd, Fgnd = ReadPixel (F, xy1);

   if (Blended) {
      if ((Source == 0) && SwapDir) {
         Bgnd = Fgnd;
         Fgnd = ReadPixel (B, xy2);
      }
      else Bgnd = ReadPixel (B, xy2);

      if (Source == 0) {
         Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
         Fgnd.rgb *= Fgnd.a;
      }
      else if (Source == 1) {
         Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
         Fgnd.rgb /= Fgnd.a;
      }

      if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;
   }
   else Fgnd.a = 1.0;

   return Fgnd;
}

float4 fn_initBg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 retval;

   if (Blended && SwapDir && (Source == 0)) { retval = ReadPixel (F, xy1); }
   else retval = ReadPixel (B, xy2);

   if (!Blended) retval.a = 1.0;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Slice right to left

DeclarePass (Fg_R)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_R)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (SliceRight)
{
   float4 Fgnd = tex2D (Fg_R, uv3);
   float4 Bgnd = tex2D (Bg_R, uv3);
   float4 maskBg, retval;

   float2 xy = uv3;

   float strips = max (2.0, round (StripNumber));
   float amount_0, amount_1, amount_2;

   if (Blended) {
      if (SwapDir || Direction) {
         amount_1 = pow (1.0 - Amount, 3.0);
         amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

         xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                             : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
      }
      else {
         amount_1 = pow (Amount, 3.0);
         amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

         xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                             : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
      }

      Fgnd = ReadPixel (Fg_R, xy);
      retval = lerp (Bgnd, Fgnd, Fgnd.a);
      maskBg = Bgnd;
   }
   else {
      maskBg = Fgnd;

      amount_0 = Direction ? 1.0 - Amount : Amount;
      amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
      amount_2 = pow (amount_0, 3.0);

      xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_1) + amount_2
                          : (ceil ((1.0 - xy.y) * strips) * amount_1) + amount_2;

      if (Direction) { retval = (IsOutOfBounds (xy)) ? Fgnd : tex2D (Bg_R, xy); }
      else retval = (IsOutOfBounds (xy)) ? Bgnd : tex2D (Fg_R, xy);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique Slice left to right

DeclarePass (Fg_L)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_L)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (SliceLeft)
{
   float4 Fgnd = tex2D (Fg_L, uv3);
   float4 Bgnd = tex2D (Bg_L, uv3);
   float4 maskBg, retval;

   float2 xy = uv3;

   float strips = max (2.0, round (StripNumber));
   float amount_0, amount_1, amount_2;

   if (Blended) {
      if (SwapDir || Direction) {
         amount_1 = pow (1.0 - Amount, 3.0);
         amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

         xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                             : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
      }
      else {
         amount_1 = pow (Amount, 3.0);
         amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

         xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                             : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
      }

      Fgnd = ReadPixel (Fg_L, xy);
      retval = lerp (Bgnd, Fgnd, Fgnd.a);
      maskBg = Bgnd;
   }
   else {
      maskBg = Fgnd;

      amount_0 = Direction ? 1.0 - Amount : Amount;
      amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
      amount_2 = pow (amount_0, 3.0);

      xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_1) + amount_2
                          : (ceil ((1.0 - xy.y) * strips) * amount_1) + amount_2;

      if (Direction) { retval = (IsOutOfBounds (xy)) ? Fgnd : tex2D (Bg_L, xy); }
      else retval = (IsOutOfBounds (xy)) ? Bgnd : tex2D (Fg_L, xy);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique Slice top to bottom

DeclarePass (Fg_T)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_T)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (SliceTop)
{
   float4 Fgnd = tex2D (Fg_T, uv3);
   float4 Bgnd = tex2D (Bg_T, uv3);
   float4 maskBg, retval;

   float2 xy = uv3;

   float strips = max (2.0, round (StripNumber));
   float amount_0, amount_1, amount_2;

   if (Blended) {
      if (SwapDir || Direction) {
         amount_1 = pow (1.0 - Amount, 3.0);
         amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

         xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                             : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      }
      else {
         amount_1 = pow (Amount, 3.0);
         amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

         xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                             : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      }

      Fgnd = ReadPixel (Fg_T, xy);
      retval = lerp (Bgnd, Fgnd, Fgnd.a);
      maskBg = Bgnd;
   }
   else {
      maskBg = Fgnd;

      amount_0 = Direction ? 1.0 - Amount : Amount;
      amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
      amount_2 = pow (amount_0, 3.0);

      xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_1) + amount_2
                          : (ceil ((1.0 - xy.x) * strips) * amount_1) + amount_2;

      if (Direction) { retval = (IsOutOfBounds (xy)) ? Fgnd : tex2D (Bg_T, xy); }
      else retval = (IsOutOfBounds (xy)) ? Bgnd : tex2D (Fg_T, xy);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique Slice bottom to top

DeclarePass (Fg_B)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_B)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (SliceBottom)
{
   float4 Fgnd = tex2D (Fg_B, uv3);
   float4 Bgnd = tex2D (Bg_B, uv3);
   float4 maskBg, retval;

   float2 xy = uv3;

   float strips = max (2.0, round (StripNumber));
   float amount_0, amount_1, amount_2;

   if (Blended) {
      if (SwapDir || Direction) {
         amount_1 = pow (1.0 - Amount, 3.0);
         amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

         xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                             : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      }
      else {
         amount_1 = pow (Amount, 3.0);
         amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

         xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                             : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      }

      Fgnd = ReadPixel (Fg_B, xy);
      retval = lerp (Bgnd, Fgnd, Fgnd.a);
      maskBg = Bgnd;
   }
   else {
      maskBg = Fgnd;

      amount_0 = Direction ? 1.0 - Amount : Amount;
      amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
      amount_2 = pow (amount_0, 3.0);

      xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_1) + amount_2
                          : (ceil ((1.0 - xy.x) * strips) * amount_1) + amount_2;

      if (Direction) { retval = (IsOutOfBounds (xy)) ? Fgnd : tex2D (Bg_B, xy); }
      else retval = (IsOutOfBounds (xy)) ? Bgnd : tex2D (Fg_B, xy);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

