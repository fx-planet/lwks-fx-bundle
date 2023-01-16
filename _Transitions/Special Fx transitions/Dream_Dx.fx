// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

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
// Lightworks user effect Dream_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Dream sequence", "Mix", "Special Fx transitions", "Ripples the images as it dissolves between them", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Speed, "Speed", kNoGroup, kNoFlags, 25.0, 0.0, 125.0);
DeclareFloatParam (BlurAmt, "Blur", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (Wavy, "Wavy", kNoGroup, true);

DeclareFloatParam (WavesX, "Frequency", kNoGroup, "SpecifiesPointX", 0.0, 0.0, 1.0);
DeclareFloatParam (WavesY, "Frequency", kNoGroup, "SpecifiesPointY", 1.0, 0.0, 1.0);

DeclareFloatParam (StrengthX, "Strength", kNoGroup, "SpecifiesPointX", 0.0, 0.0, 1.0);
DeclareFloatParam (StrengthY, "Strength", kNoGroup, "SpecifiesPointY", 0.2, 0.0, 1.0);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_XYwave (float2 xy1, float2 xy2, float amt)
{
   float waveRate = _Progress * Speed / 2.0;

   float2 xy = (xy1 * xy2) + waveRate.xx;
   float2 strength = float2 (StrengthX, StrengthY) * amt;

   return Wavy ? xy1 + (float2 (sin (xy.y), cos (xy.x)) * strength.yx)
               : xy1 + (float2 (sin (xy.x), cos (xy.y)) * strength);
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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclarePass (BlurX)
{
   float wAmount = min (1.0, abs (1.5 - abs ((Amount * 3.0) - 1.5))) / 10.0;

   float mixAmount = saturate ((Amount * 2.0) - 0.5);

   float2 waves = float2 (WavesX, WavesY) * 20.0;
   float2 xy = fn_XYwave (uv3, waves, wAmount);

   float4 fgProc = tex2D (Fgd, xy);
   float4 bgProc = tex2D (Bgd, xy);

   return lerp (fgProc, bgProc, mixAmount);
}

DeclarePass (BlurY)
{
   float blur;

   if (StrengthX > StrengthY) { blur = Wavy ? BlurAmt : (BlurAmt / 2.0); }
   else blur = Wavy ? (BlurAmt / 2.0) : BlurAmt;

   float2 offset = float2 (blur, 0.0) * 0.0005;

   return (blur > 0.0) ? fn_blur_sub (BlurX, uv3, offset) : tex2D (BlurX, uv3);
}

DeclareEntryPoint (Dream_Dx)
{
   float blur;

   if (StrengthX > StrengthY) { blur = Wavy ? (BlurAmt / 2) : (BlurAmt * 2.0); }
      else blur = Wavy ? (BlurAmt * 2) : (BlurAmt / 2);

   float2 offset = float2 (0.0, blur) * 0.0005;

   return (blur > 0.0) ? fn_blur_sub (BlurY, uv3, offset) : tex2D (BlurY, uv3);
}

