// @Maintainer jwrl
// @Released 2023-01-31
// @Author jwrl
// @Created 2023-01-31

/**
 This effect ripples the outgoing or incoming blended foreground as it dissolves.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dreams_Fx.fx
//
// Version history:
//
// Built 2023-01-31 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Dream sequence (keyed)", "Mix", "Special Fx transitions", "Ripples the outgoing or incoming blended foreground as it dissolves", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key folded|At start if non-delta unfolded|Standard transitions");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareIntParam (WaveType, "Wave type", kNoGroup, 0, "Waves|Ripples");

DeclareFloatParam (Frequency, "Frequency", "Pattern", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (Speed, "Speed", "Pattern", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (BlurAmt, "Blur", "Pattern", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (StrengthX, "Strength", "Pattern", "SpecifiesPointX", 0.0, 0.0, 1.0);
DeclareFloatParam (StrengthY, "Strength", "Pattern", "SpecifiesPointY", 0.2, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

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

float2 fn_wave (float2 uv, float2 waves, float levels)
{
   float waveRate = _Progress * Speed * 25.0;

   float2 xy = (uv - CENTRE) * waves;
   float2 strength  = float2 (StrengthX, StrengthY) * levels / 10.0;
   float2 retXY = (WaveType == 0) ? float2 (sin (waveRate + xy.y), cos (waveRate + xy.x))
                                  : float2 (sin (waveRate + xy.x), cos (waveRate + xy.y));

   return uv + (retXY * strength);
}

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

float4 fn_dissolve (sampler S, float2 uv)
{
   float waves = float (Frequency * 200.0);

   float2 xy = fn_wave (uv, waves.xx, cos (Amount * HALF_PI));

   return tex2D (S, xy) * Amount;
}

float4 fn_blur (sampler B, float2 uv)
{
   float4 Inp = tex2D (B, uv);
   float4 retval = kTransparentBlack;

   float blur = (StrengthY > StrengthX) ? WaveType ? BlurAmt : (BlurAmt / 2.0)
                                        : WaveType ? (BlurAmt / 2.0) : BlurAmt;
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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// technique Dreams_Kx_F

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

DeclarePass (BlurX_F)
{ return fn_dissolve (Super_F, uv3); }

DeclarePass (BlurY_F)
{ return fn_blur (BlurX_F, uv3); }

DeclareEntryPoint (Dreams_F)
{
   float4 Fgnd   = tex2D (BlurY_F, uv3);
   float4 retval = kTransparentBlack;

   float blur = (StrengthY > StrengthX) ? WaveType ? (BlurAmt / 2.0) : (BlurAmt * 2.0)
                                         : WaveType ? (BlurAmt * 2.0) : (BlurAmt / 2.0);
   if (blur > 0.0) {
      float2 offset = float2 (0.0, blur) * OFFSET;
      float2 blurriness = 0.0.xx;

      for (int i = 0; i < SAMPLE; i++) {
         retval += tex2D (BlurY_F, uv3 + blurriness);
         retval += tex2D (BlurY_F, uv3 - blurriness);
         blurriness += offset;
      }

      retval /= SAMPLES;

      Fgnd = lerp (Fgnd, retval, 1.0 - Amount);
   }

   if (CropEdges && IsOutOfBounds (uv1)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_F, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Dreams_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclarePass (BlurX_I)
{ return fn_dissolve (Super_I, uv3); }

DeclarePass (BlurY_I)
{ return fn_blur (BlurX_I, uv3); }

DeclareEntryPoint (Dreams_I)
{
   float4 Fgnd   = tex2D (BlurY_I, uv3);
   float4 retval = kTransparentBlack;

   float blur = (StrengthY > StrengthX) ? WaveType ? (BlurAmt / 2.0) : (BlurAmt * 2.0)
                                         : WaveType ? (BlurAmt * 2.0) : (BlurAmt / 2.0);
   if (blur > 0.0) {
      float2 offset = float2 (0.0, blur) * OFFSET;
      float2 blurriness = 0.0.xx;

      for (int i = 0; i < SAMPLE; i++) {
         retval += tex2D (BlurY_I, uv3 + blurriness);
         retval += tex2D (BlurY_I, uv3 - blurriness);
         blurriness += offset;
      }

      retval /= SAMPLES;

      Fgnd = lerp (Fgnd, retval, 1.0 - Amount);
   }

   if (CropEdges && IsOutOfBounds (uv2)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_I, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Dreams_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclarePass (BlurX_O)
{
   float waves = float (Frequency * 200.0);

   float2 xy = fn_wave (uv3, waves.xx, sin (Amount * HALF_PI));

   return tex2D (Super_O, xy) * (1.0 - Amount);
}

DeclarePass (BlurY_O)
{
   float4 Inp = tex2D (BlurX_O, uv3);
   float4 retval = kTransparentBlack;

   float blur = (StrengthY > StrengthX) ? WaveType ? BlurAmt : (BlurAmt / 2)
                                         : WaveType ? (BlurAmt / 2) : BlurAmt;
   if (blur <= 0.0) return Inp;

   float2 offset = float2 (blur, 0.0) * OFFSET;
   float2 blurriness = 0.0.xx;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (BlurX_O, uv3 + blurriness);
      retval += tex2D (BlurX_O, uv3 - blurriness);
      blurriness += offset;
   }
    
   retval = retval / SAMPLES;
    
   return lerp (Inp, retval, Amount);
}

DeclareEntryPoint (Dreams_O)
{
   float4 Fgnd   = tex2D (BlurY_O, uv3);
   float4 retval = kTransparentBlack;

   float blur = (StrengthY > StrengthX) ? WaveType ? (BlurAmt / 2.0) : (BlurAmt * 2.0)
                                         : WaveType ? (BlurAmt * 2.0) : (BlurAmt / 2.0);
   if (blur > 0.0) {
      float2 offset = float2 (0.0, blur) * OFFSET;
      float2 blurriness = 0.0.xx;

      for (int i = 0; i < SAMPLE; i++) {
         retval += tex2D (BlurY_O, uv3 + blurriness);
         retval += tex2D (BlurY_O, uv3 - blurriness);
         blurriness += offset;
      }

      retval /= SAMPLES;

      Fgnd = lerp (Fgnd, retval, Amount);
   }

   if (CropEdges && IsOutOfBounds (uv2)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_O, uv3), Fgnd, Fgnd.a);
}

