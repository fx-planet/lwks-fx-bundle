// @Maintainer jwrl
// @Released 2023-02-02
// @Author jwrl
// @Created 2023-02-02

/**
 This is a dissolve/wipe that uses sine & cosine distortions to perform a rippling twist to
 establish or remove the blended foreground.  The range of effect variations possible with
 different combinations of settings is almost inifinite.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Twister_Kx.fx
//
// Version history:
//
// Built 2023-02-02 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("The twister (keyed)", "Mix", "Special Fx transitions", "Performs a rippling twist to establish or remove the blended foreground image", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta|Standard transitions");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareIntParam (TransProfile, "Transition profile", kNoGroup, 1, "Left > right profile A|Left > right profile B|Right > left profile A|Right > left profile B");

DeclareFloatParam (Width, "Softness", "Ripples", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Ripples, "Ripple amount", "Ripples", kNoFlags, 0.6, 0.0, 1.0);
DeclareFloatParam (Spread, "Ripple width", "Ripples", kNoFlags, 0.15, 0.0, 1.0);

DeclareFloatParam (Twists, "Twist amount", "Twists", kNoFlags, 0.25, 0.0, 1.0);

DeclareBoolParam (Show_Axis, "Show twist axis", "Twists", false);

DeclareFloatParam (Axis, "Set axis", "Twists", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

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

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Twister_Kx_F

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

DeclareEntryPoint (Twister_F)
{
   int Mode = (int) fmod ((float)TransProfile, 2.0);

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (Mode == TransProfile) ? uv3.x : 1.0 - uv3.x;

   maxVis = Amount * (1.0 + range) - maxVis;

   float amount = saturate (maxVis / range);
   float T_Axis = uv3.y - Axis;

   float ripples = max (0.0, RIPPLES * (range - maxVis));
   float spread  = ripples * Spread * SCALE;
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;
   float offset  = sin (modultn) * spread;
   float twists  = cos (modultn * Twists * 4.0);

   float2 xy = float2 (uv3.x, Axis + (T_Axis / twists) - offset);

   xy.y += offset * float (Mode * 2);

   float4 Fgd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : ReadPixel (Super_F, xy);
   float4 Bgd = lerp (tex2D (Bg_F, uv3), Fgd, Fgd.a * amount);

   if (Show_Axis) {
      float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

      Fgd.rgb = Bgd.rgb + AxisLine.xxx;
      Bgd.rgb = min (1.0.xxx, Fgd.rgb) - max (0.0.xxx, Fgd.rgb - 1.0.xxx);
   }

   return Bgd;
}

//-----------------------------------------------------------------------------------------//

// technique Twister_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclareEntryPoint (Twister_I)
{
   int Mode = (int) fmod ((float)TransProfile, 2.0);

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (Mode == TransProfile) ? uv3.x : 1.0 - uv3.x;

   maxVis = Amount * (1.0 + range) - maxVis;

   float amount = saturate (maxVis / range);
   float T_Axis = uv3.y - Axis;

   float ripples = max (0.0, RIPPLES * (range - maxVis));
   float spread  = ripples * Spread * SCALE;
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;
   float offset  = sin (modultn) * spread;
   float twists  = cos (modultn * Twists * 4.0);

   float2 xy = float2 (uv3.x, Axis + (T_Axis / twists) - offset);

   xy.y += offset * float (Mode * 2);

   float4 Fgd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_I, xy);
   float4 Bgd = lerp (tex2D (Bg_I, uv3), Fgd, Fgd.a * amount);

   if (Show_Axis) {
      float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

      Fgd.rgb = Bgd.rgb + AxisLine.xxx;
      Bgd.rgb = min (1.0.xxx, Fgd.rgb) - max (0.0.xxx, Fgd.rgb - 1.0.xxx);
   }

   return Bgd;
}

//-----------------------------------------------------------------------------------------//

// technique Twister_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclareEntryPoint (Twister_O)
{
   int Mode = (int) fmod ((float)TransProfile, 2.0);

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (Mode == TransProfile) ? 1.0 - uv3.x : uv3.x;

   maxVis = (1.0 - Amount) * (1.0 + range) - maxVis;

   float amount = saturate (maxVis / range);
   float T_Axis = uv3.y - Axis;

   float ripples = max (0.0, RIPPLES * (range - maxVis));
   float spread  = ripples * Spread * SCALE;
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;
   float offset  = sin (modultn) * spread;
   float twists  = cos (modultn * Twists * 4.0);

   float2 xy = float2 (uv3.x, Axis + (T_Axis / twists) - offset);

   xy.y += offset * float (Mode * 2);

   float4 Fgd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_O, xy);
   float4 Bgd = lerp (tex2D (Bg_O, uv3), Fgd, Fgd.a * amount);

   if (Show_Axis) {
      float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

      Fgd.rgb = Bgd.rgb + AxisLine.xxx;
      Bgd.rgb = min (1.0.xxx, Fgd.rgb) - max (0.0.xxx, Fgd.rgb - 1.0.xxx);
   }

   return Bgd;
}

