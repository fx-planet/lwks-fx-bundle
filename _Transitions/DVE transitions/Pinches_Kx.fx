// @Maintainer jwrl
// @Released 2023-02-02
// @Author jwrl
// @Created 2023-02-02

/**
 This effect pinches the outgoing blended foreground to a user-defined point to reveal
 the background video.  It can also reverse the process to bring in the foreground.
 It's the blended effect version of Pinches_Dx.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Pinches_Fx.fx
//
// Version history:
//
// Built 2023-02-02 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Pinches (keyed)", "Mix", "DVE transitions", "Pinches the foreground to a user-defined point to either hide or reveal it", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Mode, "Transition", kNoGroup, 0, "Linear pinch|Radial pinch|X pinch");
DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta|Standard transitions");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (centreX, "Position", "Pinch centre", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (centreY, "Position", "Pinch centre", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define MID_PT     (0.5).xx
#define HALF_PI    1.5707963268
#define QUARTER_PI 0.7853981634

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler B, float2 xy1, float2 xy2)
{
   float4 Fgnd = ReadPixel (Fg, xy1);

   if (Source == 0) {
      float4 Bgnd = tex2D (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 fn_pinch (sampler S, float2 uv)
{
   float2 xy = uv;

   if (Mode == 2) {
      float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, Amount);

      float progress = sin ((1.0 - Amount) * QUARTER_PI);
      float dist  = (distance (uv, centre) * 32.0) + 1.0;
      float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

      xy = ((uv - centre) * scale) + MID_PT;
   }

   return ReadPixel (S, xy);
}

float4 fn_PinchL1 (sampler P, float2 uv, float2 xy)
{
   float amount = (Amount * 0.5) + 0.5;

   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, amount);
   float2 xy1 = (xy - centre) * (1.0 + pow ((1.0 - sin (amount * HALF_PI)), 4.0) * 128.0);

   xy1 *= pow (abs (xy1 * 2.0), -cos ((amount + 0.01) * HALF_PI));
   xy1 += MID_PT;

   return CropEdges && IsOutOfBounds (uv) ? kTransparentBlack : ReadPixel (P, xy1);
}

float4 fn_PinchR1 (sampler P, float2 uv, float2 xy)
{
   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, Amount);

   float progress = (1.0 - Amount) / 2.14;
   float rfrnc = (distance (xy, centre) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy1 = (xy - centre) * scale;

   xy1 *= scale;
   xy1 += MID_PT;

   return CropEdges && IsOutOfBounds (uv) ? kTransparentBlack : ReadPixel (P, xy1);
}

float4 fn_PinchX1 (sampler P, float2 uv, float2 xy)
{
   float progress = 1.0 - cos (sin ((1.0 - Amount) * QUARTER_PI));
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, Amount);
   float2 xy1 = ((xy - centre) * scale) + MID_PT;

   return CropEdges && IsOutOfBounds (uv) ? kTransparentBlack : ReadPixel (P, xy1);
}

float4 fn_PinchP2 (sampler E, float2 uv, float2 xy)
{
   float amount = Amount * 0.5;

   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), amount);
   float2 xy1 = (xy - centre) * (1.0 + pow ((1.0 - cos (amount * HALF_PI)), 4.0) * 128.0);

   xy1 *= pow (abs (xy1 * 2.0), -sin (amount * HALF_PI));
   xy1 += MID_PT;

   return CropEdges && IsOutOfBounds (uv) ? kTransparentBlack : ReadPixel (E, xy1);
}

float4 fn_PinchR2 (sampler E, float2 uv, float2 xy)
{
   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), Amount);

   float progress = Amount / 2.14;
   float rfrnc = (distance (xy, centre) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy1 = (xy - centre) * scale;

   xy1 *= scale;
   xy1 += MID_PT;

   return CropEdges && IsOutOfBounds (uv) ? kTransparentBlack : ReadPixel (E, xy1);
}

float4 fn_PinchX2 (sampler E, float2 uv, float2 xy)
{
   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), Amount);

   float progress = 1.0 - cos (sin (Amount * QUARTER_PI));
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy1 = ((xy - centre) * scale) + MID_PT;

   return CropEdges && IsOutOfBounds (uv) ? kTransparentBlack : ReadPixel (E, xy1);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Pinches_Fx_F

DeclarePass (Bg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Super_F)
{
   float4 Fgnd = tex2D (Bg_F, uv3);

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

DeclarePass (Pinch_F)
{ return fn_pinch (Super_F, uv3); }

DeclareEntryPoint (Pinches_Fx_F)
{
   float4 Fgnd = Mode == 0 ? fn_PinchL1 (Pinch_F, uv1, uv3)
               : Mode == 1 ? fn_PinchR1 (Pinch_F, uv1, uv3)
                           : fn_PinchX1 (Pinch_F, uv1, uv3);

   return lerp (tex2D (Fg, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Pinches_Fx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclarePass (Pinch_I)
{ return fn_pinch (Super_I, uv3); }

DeclareEntryPoint (Pinches_Fx_I)
{
   float4 Fgnd = Mode == 0 ? fn_PinchL1 (Pinch_I, uv2, uv3)
               : Mode == 1 ? fn_PinchR1 (Pinch_I, uv2, uv3)
                           : fn_PinchX1 (Pinch_I, uv2, uv3);

   return lerp (tex2D (Bg_I, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Pinches_Fx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclarePass (Pinch_O)
{
   float2 xy = uv3;

   if (Mode == 2) {
      float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), Amount);

      float progress = sin (Amount * QUARTER_PI);
      float dist  = (distance (uv3, centre) * 32.0) + 1.0;
      float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

      xy = ((uv3 - centre) * scale) + MID_PT;
   }

   return ReadPixel (Super_O, xy);
}

DeclareEntryPoint (Pinches_Fx_O)
{
   float4 Fgnd = Mode == 0 ? fn_PinchP2 (Pinch_O, uv2, uv3)
               : Mode == 1 ? fn_PinchR2 (Pinch_O, uv2, uv3)
                           : fn_PinchX2 (Pinch_O, uv2, uv3);

   return lerp (tex2D (Bg_O, uv3), Fgnd, Fgnd.a);
}

