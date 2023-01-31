// @Maintainer jwrl
// @Released 2023-01-31
// @Author rakusan
// @Author jwrl
// @Created 2022-06-01

/**
 The effect applies a rotary blur to transition into or out of a foreground effect
 and is based on original shader code by rakusan (http://kuramo.ch/webgl/videoeffects/).
 The direction, aspect ratio, centring and strength of the blur can all be adjusted.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Spin_Kx.fx
//
// Version history:
//
// Updated 2023-01-31 jwrl
// Updated to provide LW 2022 revised cross platform support.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Spin dissolve (keyed)", "Mix", "Blur transitions", "Dissolves the foreground through a blurred spin", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");
DeclareIntParam (CW_CCW, "Rotation direction", kNoGroup, 1, "Anticlockwise|Clockwise");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (blurAmount, "Arc (degrees)", "Spin", kNoFlags, 90.0, 0.0, 180.0);
DeclareFloatParam (aspectRatio, "Aspect ratio 1:x", "Spin", kNoFlags, 1.0, 0.01, 10.0);

DeclareFloatParam (centreX, "Centre", "Spin", "SpecifiesPointX", 0.5, -0.5, 1.5);
DeclareFloatParam (centreY, "Centre", "Spin", "SpecifiesPointY", 0.5, -0.5, 1.5);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI 1.5707963268

#define REDUCE  0.009375

#define CCW     0
#define CW      1

float blur_idx []  = { 0, 20, 40, 60, 80 };
float redux_idx [] = { 1.0, 0.8125, 0.625, 0.4375, 0.25 };

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

float4 fn_spin (sampler T, sampler S, float2 uv, int passNum, int rotate)
{
   float blurLen = (1.0 - sin (Amount * HALF_PI)) * blurAmount;

   float4 retval;

   if (blurLen == 0.0) { retval = tex2D (T, uv); }
   else {
      retval = (0.0).xxxx;

      float2 outputAspect = float2 (1.0, _OutputAspectRatio);
      float2 blurAspect = float2 (1.0, aspectRatio);
      float2 centre = float2 (centreX, 1.0 - centreY );
      float2 xy1, xy2 = (uv - centre) / outputAspect / blurAspect;

      float reduction = redux_idx [passNum];
      float amount = radians (blurLen) / 100.0;

      if (CW_CCW == rotate) amount = -amount;

      float Tcos, Tsin, ang = amount * blur_idx [passNum];

      for (int i = 0; i < 20; i++) {
         sincos (ang, Tsin, Tcos);
         xy1 = centre + float2 ((xy2.x * Tcos - xy2.y * Tsin),
                                (xy2.x * Tsin + xy2.y * Tcos) * outputAspect.y) * blurAspect;
         retval = max (retval, (tex2D (T, xy1) * reduction));
         reduction -= REDUCE;
         ang += amount;
      }

      if (passNum != 0) retval = max (retval, tex2D (S, uv));
   }

   return retval;
}

float4 fn_main ( sampler B, float2 uv, float4 T, float amt)
{
   float4 Title = CropEdges && IsOutOfBounds (uv) ? kTransparentBlack : T;

   return lerp (tex2D (B, uv), Title, Title.a * amt);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

// technique Spin_Kx_F

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

DeclarePass (Super_1_F)
{ return fn_spin (Title_F, Title_F, uv3, 0, CCW); }

DeclarePass (Spin_1_F)
{ return fn_spin (Title_F, Super_1_F, uv3, 1, CCW); }

DeclarePass (Super_2_F)
{ return fn_spin (Title_F, Spin_1_F, uv3, 2, CCW); }

DeclarePass (Spin_2_F)
{ return fn_spin (Title_F, Super_2_F, uv3, 3, CCW); }

DeclareEntryPoint (Spin_Kx_F)
{
   float4 Title = fn_spin (Title_F, Spin_2_F, uv3, 4, CCW);

   return fn_main (Bg_F, uv3, Title, Amount);
}

//-----------------------------------------------------------------------------------------//

// technique Spin_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Title_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclarePass (Super_1_I)
{ return fn_spin (Title_I, Title_I, uv3, 0, CCW); }

DeclarePass (Spin_1_I)
{ return fn_spin (Title_I, Super_1_I, uv3, 1, CCW); }

DeclarePass (Super_2_I)
{ return fn_spin (Title_I, Spin_1_I, uv3, 2, CCW); }

DeclarePass (Spin_2_I)
{ return fn_spin (Title_I, Super_2_I, uv3, 3, CCW); }

DeclareEntryPoint (Spin_Kx_I)
{
   float4 Title = fn_spin (Title_I, Spin_2_I, uv3, 4, CCW);

   return fn_main (Bg_I, uv3, Title, Amount);
}

//-----------------------------------------------------------------------------------------//

// technique Spin_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Title_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclarePass (Super_1_O)
{ return fn_spin (Title_O, Title_O, uv3, 0, CW); }

DeclarePass (Spin_1_O)
{ return fn_spin (Title_O, Super_1_O, uv3, 1, CW); }

DeclarePass (Super_2_O)
{ return fn_spin (Title_O, Spin_1_O, uv3, 2, CW); }

DeclarePass (Spin_2_O)
{ return fn_spin (Title_O, Super_2_O, uv3, 3, CW); }

DeclareEntryPoint (Spin_Kx_O)
{
   float4 Title = fn_spin (Title_O, Spin_2_O, uv3, 4, CW);

   return fn_main (Bg_O, uv3, Title, 1.0 - Amount);
}

