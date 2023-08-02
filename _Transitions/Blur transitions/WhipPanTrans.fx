// @Maintainer jwrl
// @Released 2023-08-02
// @Author jwrl
// @Created 2020-07-19

/**
 This effect performs a whip pan style transition to bring an image onto or off the
 screen.  Unlike the blur dissolve effect, this effect also pans the foreground.  It
 is limited to producing vertical and horizontal whips only.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhipPanTrans.fx
//
// Version history:
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-08 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-07 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Whip pan transition", "Mix", "Blur transitions", "Uses a directional blur to simulate a whip pan between sources", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Mode, "Whip direction", kNoGroup, 0, "Left to right|Right to left|Top to bottom|Bottom to top");
DeclareFloatParam (Spread, "Spread", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Offset, "Start point", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI 1.5707963268

float2 _ang [4] = { { -1.5, 0.0 }, { 1.5, 0.0 }, { 0.0, -1.5 }, { 0.0, 1.5 } };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// This function is necessary because we can't set addressing modes

float4 MirrorPixel (sampler S, float2 xy)
{
   float2 xy1 = 1.0.xx - abs (2.0 * (frac (xy / 2.0) - 0.5.xx));

   return ReadPixel (S, xy1);
}

float4 fn_transition (sampler vid, float2 uv, float amt)
{
   float2 offs = _ang [Mode] * amt;
   float2 blur = offs * Spread;
   float2 xy = uv + blur;

   offs = abs (offs) * Offset;

   if (Mode < 2) offs = -offs;

   float4 retval = MirrorPixel (vid, uv);

   if (Spread > 0.0) {
      blur *= 0.01;

      for (int i = 0; i < 60; i++) {
         xy += blur;
         retval += MirrorPixel (vid, (xy + offs));
      }
    
      retval /= 61;
   }
    
   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   if (!Blended) return float4 ((ReadPixel (Fg, uv1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (Bg, uv2);
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      Fgnd = ReadPixel (Fg, uv1);
      Bgnd = ReadPixel (Bg, uv2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

DeclarePass (Bgd)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

DeclareEntryPoint (WhipPanTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   float amount = saturate (Amount);   // Just in case someone types in silly numbers

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         amount = SwapDir ? cos ((amount + 2.0) * HALF_PI) : sin (amount * HALF_PI);
/*
         if (SwapDir) amount -= 1.0;
*/
         float2 offs = _ang [Mode] * amount / 2.0;
         float2 blur = offs * Spread;
         float2 xy = uv3 + blur;

         offs = abs (offs) * Offset;

         if (Mode < 2) offs = -offs;

         retval = ReadPixel (Fgd, uv3);

         if (Spread > 0.0) {
            blur *= 0.01;

            for (int i = 0; i < 60; i++) {
               xy += blur;
               retval += ReadPixel (Fgd, (xy + offs));
            }
    
            retval /= 61;
         }

         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      maskBg = Fgnd;
      amount *= 2.0;

      Fgnd = fn_transition (Fgd, uv3, amount);
      Bgnd = fn_transition (Bgd, uv3, amount - 2.0);

      retval = lerp (Fgnd, Bgnd, 0.5 - (cos (amount * HALF_PI) / 2.0));
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

