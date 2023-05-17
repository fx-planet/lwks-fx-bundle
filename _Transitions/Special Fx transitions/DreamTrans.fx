// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2018-11-10

/**
 This effect starts off by rippling the outgoing image for the first third of the effect,
 then dissolves to the new image for the next third, then loses the ripple over the
 remainder of the effect.  It simulates Hollywood's classic dream effect.  The default
 settings give exactly that result.

 It's based on khaver's water effect, but some parameters have been changed to better
 mimic the original film effect.  Two directional blurs have also been added, one very
 much weaker than the other.  Their comparative strengths depend on the predominant
 direction of the wave effect.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DreamTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Dream sequence", "Mix", "Special Fx transitions", "Ripples the images as it dissolves between them", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (WaveType, "Wave type", kNoGroup, 0, "Waves|Ripples");

DeclareFloatParam (Frequency, "Frequency", kNoGroup, "SpecifiesPointX", 0.2, 0.0, 1.0);
DeclareFloatParam (Speed, "Speed", kNoGroup, kNoFlags, 25.0, 0.0, 125.0);
DeclareFloatParam (BlurAmt, "Blur", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (StrengthX, "Strength", kNoGroup, "SpecifiesPointX", 0.0, 0.0, 1.0);
DeclareFloatParam (StrengthY, "Strength", kNoGroup, "SpecifiesPointY", 0.2, 0.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Crawl/Roll/Title/Image key|Video/External image");

DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);

DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SAMPLE  30
#define SAMPLES 60
#define OFFSET  0.0005

#define CENTRE  (0.5).xx

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// This function is necessary because we can't set addressing modes

float4 MirrorPixel (sampler S, float2 xy)
{
   float2 xy1 = 1.0.xx - abs (2.0 * (frac (xy / 2.0) - 0.5.xx));

   return ReadPixel (S, xy1);
}

float2 fn_wave (float2 uv, float2 waves, float levels)
{
   float waveRate = _Progress * Speed * 25.0;

   float2 xy = (uv - CENTRE) * waves;
   float2 strength  = float2 (StrengthX, StrengthY) * levels / 10.0;
   float2 retXY = (WaveType == 0) ? float2 (sin (waveRate + xy.y), cos (waveRate + xy.x))
                                  : float2 (sin (waveRate + xy.x), cos (waveRate + xy.y));

   return uv + (retXY * strength);
}

float4 fn_dissolve (sampler S, float2 uv)
{
   float waves = float (Frequency * 200.0);

   float2 xy = fn_wave (uv, waves.xx, cos (Amount * HALF_PI));

   return MirrorPixel (S, xy) * Amount;
}

float4 fn_blur (sampler B, float2 uv)
{
   float4 Inp = tex2D (B, uv);
   float4 retval = kTransparentBlack;

   float blur = (StrengthY > StrengthX) ? WaveType == 0 ? BlurAmt : (BlurAmt / 2.0)
                                        : WaveType == 0 ? (BlurAmt / 2.0) : BlurAmt;
   if (blur <= 0.0) return Inp;

   float2 offset = float2 (blur, 0.0) * OFFSET;
   float2 blurriness = 0.0.xx;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (B, uv + blurriness);
      retval += tex2D (B, uv - blurriness);
      blurriness += offset;
   }
    
   retval = retval / SAMPLES;
    
   return lerp (Inp, retval, 1.0 - Amount);
}

float4 fn_blur_sub (sampler S, float2 xy, float2 offs)
{
   float Samples = 60.0;
   float Mix = min (1.0, abs (2.5 - abs ((Amount * 5.0) - 2.5)));

   float4 result  = 0.0.xxxx;
   float4 blurInp = tex2D (S, xy);

   for (int i = 0; i < Samples; i++) {
      result += tex2D (S, xy - offs * i);
      }
    
   result /= Samples;

   return lerp (blurInp, result, Mix);
}

float2 fn_XYwave (float2 xy1, float2 xy2, float amt)
{
   float waveRate = _Progress * Speed / 2.0;

   float2 xy = (xy1 * xy2) + waveRate.xx;
   float2 strength = float2 (StrengthX, StrengthY) * amt;

   return WaveType == 0 ? xy1 + (float2 (sin (xy.y), cos (xy.x)) * strength)
                        : xy1 + (float2 (sin (xy.x), cos (xy.y)) * strength.yx);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   float4 Bgnd, Fgnd = ReadPixel (Fg, uv1);

   if (Blended) {
      if ((Source == 0) && SwapDir) {
         Bgnd = Fgnd;
         Fgnd = ReadPixel (Bg, uv2);
      }
      else Bgnd = ReadPixel (Bg, uv2);

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

DeclarePass (Bgd)
{
   float4 retval;

   if (Blended && SwapDir && (Source == 0)) { retval = ReadPixel (Fg, uv1); }
   else retval = ReadPixel (Bg, uv2);

   if (!Blended) retval.a = 1.0;

   return retval;
}

DeclarePass (BlurX)
{
   float4 retval;

   float2 waves, xy;

   if (Blended) {
      if (SwapDir) { retval = fn_dissolve (Fgd, uv3); }
      else {
         waves = float (Frequency * 200.0).xx;
         xy = fn_wave (uv3, waves, sin (Amount * HALF_PI));
         retval = MirrorPixel (Fgd, xy) * (1.0 - Amount);
      }
   }
   else {
      float wAmount = min (1.0, abs (1.5 - abs ((Amount * 3.0) - 1.5))) / 10.0;

      float mixAmount = saturate ((Amount * 2.0) - 0.5);

      waves = Frequency.xx * 20.0;
      xy = fn_XYwave (uv3, waves, wAmount);

      float4 fgProc = MirrorPixel (Fgd, xy);
      float4 bgProc = MirrorPixel (Bgd, xy);

      retval = lerp (fgProc, bgProc, mixAmount);
   }

   return retval;
}

DeclarePass (BlurY)
{
   float4 retval;

   float blur;

   if (Blended) {
      if (SwapDir) { retval = fn_blur (BlurX, uv3); }
      else {
         float4 Inp = tex2D (BlurX, uv3);

         retval = kTransparentBlack;
         blur = (StrengthY > StrengthX) ? WaveType ? BlurAmt : (BlurAmt / 2)
                                        : WaveType ? (BlurAmt / 2) : BlurAmt;
         if (blur <= 0.0) { retval = Inp; }
         else {
            float2 offset = float2 (blur, 0.0) * OFFSET;
            float2 blurriness = 0.0.xx;

            for (int i = 0; i < SAMPLE; i++) {
               retval += tex2D (BlurX, uv3 + blurriness);
               retval += tex2D (BlurX, uv3 - blurriness);
               blurriness += offset;
            }

            retval = retval / SAMPLES;
            retval = lerp (Inp, retval, Amount);
         }
      }
   }
   else {
      if (StrengthX > StrengthY) { blur = WaveType == 0 ? BlurAmt : (BlurAmt / 2.0); }
      else blur = WaveType == 0 ? (BlurAmt / 2.0) : BlurAmt;

      float2 offset = float2 (blur, 0.0) * 0.0005;

      retval = (blur > 0.0) ? fn_blur_sub (BlurX, uv3, offset) : tex2D (BlurX, uv3);
   }

   return retval;
}

DeclareEntryPoint (Dream_Dx)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   float blur = (StrengthY > StrengthX) ? WaveType == 0 ? (BlurAmt / 2.0) : (BlurAmt * 2.0)
                                        : WaveType == 0 ? (BlurAmt * 2.0) : (BlurAmt / 2.0);

   float2 offset = float2 (0.0, blur) * OFFSET;

   if (Blended) {
      maskBg = Bgnd;

      float2 blurriness = 0.0.xx;

      for (int i = 0; i < SAMPLE; i++) {
         retval += tex2D (BlurY, uv3 + blurriness);
         retval += tex2D (BlurY, uv3 - blurriness);
         blurriness += offset;
      }

      retval /= SAMPLES;

      Fgnd = SwapDir ? lerp (tex2D (BlurY, uv3), retval, 1.0 - Amount)
                     : lerp (tex2D (BlurY, uv3), retval, Amount);

      retval = lerp (Bgnd, Fgnd, Fgnd.a);
   }
   else {
      maskBg = Fgnd;

      retval = (blur > 0.0) ? fn_blur_sub (BlurY, uv3, offset) : tex2D (BlurY, uv3);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

