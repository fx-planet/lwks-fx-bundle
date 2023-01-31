// @Maintainer jwrl
// @Released 2023-01-31
// @Author jwrl
// @Created 2023-01-31

/**
 This effect performs a whip pan style transition to bring a foreground image onto or off
 the screen.  Unlike the blur dissolve effect, this effect also pans the foreground.  It
 is limited to producing vertical and horizontal whips only.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhipPan_Kx.fx
//
// Version history:
//
// Built 2023-01-31 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Whip pan (keyed)", "Mix", "Blur transitions", "Uses a difference key and a directional blur to simulate a whip pan into or out of a title", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key folded|At start if non-delta unfolded|Standard transitions");
DeclareIntParam (Mode, "Whip direction", kNoGroup, 0, "Left to right|Right to left|Top to bottom|Bottom to top");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define L_R       0
#define R_L       1
#define T_B       2
#define B_T       3

#define HALF_PI   1.5707963268

#define SAMPLES   120
#define SAMPSCALE 121.0

#define STRENGTH  0.00125

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

float4 fn_blur (sampler T, float2 uv)
{
   float4 retval = tex2D (T, uv);

   float amount = 1.0 - cos (saturate ((1.0 - Amount) * 2.0) * HALF_PI);

   if ((amount == 0.0) || (Strength <= 0.0)) return retval;

   float2 xy1 = uv;
   float2 xy2 = (Mode < T_B) ? float2 (amount, 0.0)
                             : float2 (0.0, amount * _OutputAspectRatio);

   xy2 *= Strength * STRENGTH;

   for (int i = 0; i < SAMPLES; i++) {
      retval += tex2D (T, xy1);
      xy1 -= xy2;
   }

   return retval / SAMPSCALE;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique WhipPan_Kx_F

DeclarePass (Bg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Title_F)
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

DeclarePass (Blur_F)
{ return fn_blur (Title_F, uv3); }

DeclareEntryPoint (WhipPan_Kx_F)
{
   float amount = (1.0 - sin (Amount * HALF_PI)) * 1.5 * Strength;

   float2 xy = (Mode == L_R) ? uv3 + float2 (amount, 0.0)
             : (Mode == R_L) ? uv3 - float2 (amount, 0.0)
             : (Mode == T_B) ? uv3 + float2 (0.0, amount) : uv3 - float2 (0.0, amount);

   float4 Overlay = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : ReadPixel (Blur_F, xy);

   return lerp (tex2D (Bg_F, uv3), Overlay, Overlay.a);
}

//-----------------------------------------------------------------------------------------//

// technique WhipPan_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Title_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclarePass (Blur_I)
{ return fn_blur (Title_I, uv3); }

DeclareEntryPoint (Blur_Kx_I)
{
   float amount = (1.0 - sin (Amount * HALF_PI)) * 1.5 * Strength;

   float2 xy = (Mode == L_R) ? uv3 + float2 (amount, 0.0)
             : (Mode == R_L) ? uv3 - float2 (amount, 0.0)
             : (Mode == T_B) ? uv3 + float2 (0.0, amount) : uv3 - float2 (0.0, amount);

   float4 Overlay = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Blur_I, xy);

   return lerp (tex2D (Bg_I, uv3), Overlay, Overlay.a);
}

//-----------------------------------------------------------------------------------------//

// technique WhipPan_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Title_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclarePass (Blur_O)
{
   float4 retval = tex2D (Title_O, uv3);

   float amount = 1.0 - cos (saturate (Amount * 2.0) * HALF_PI);

   if ((amount == 0.0) || (Strength <= 0.0)) return retval;

   float2 xy1 = uv3;
   float2 xy2 = (Mode < T_B) ? float2 (amount, 0.0)
                             : float2 (0.0, amount * _OutputAspectRatio);

   xy2 *= Strength * STRENGTH;

   for (int i = 0; i < SAMPLES; i++) {
      retval += tex2D (Title_O, xy1);
      xy1 -= xy2;
   }

   return retval / SAMPSCALE;
}

DeclareEntryPoint (WhipPan_Kx_O)
{
   float amount = (1.0 - cos (Amount * HALF_PI)) * 1.5 * Strength;

   float2 xy = (Mode == L_R) ? uv3 - float2 (amount, 0.0)
             : (Mode == R_L) ? uv3 + float2 (amount, 0.0)
             : (Mode == T_B) ? uv3 - float2 (0.0, amount) : uv3 + float2 (0.0, amount);

   float4 Overlay = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Blur_O, xy);

   return lerp (tex2D (Bg_O, uv3), Overlay, Overlay.a);
}

