// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2018-09-27

/**
 This is a modified version of "Colour gradient transition" but is very much simpler
 to use.  Apply it as you would a dissolve, adjust the duration of the dissolve that
 you want to be colour and set the colour to whatever you want.  You can also mix the
 colour with a black and white mixture of the outgoing and incoming video.

 The effect defaults to a 50% mix of a blue colour with the black and white mixture of
 the video inputs.  That mix in turn defaults to a duration of 10% of the transition.
 Setting the colour mix to a negative value fades the colour out.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-05-05 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Colour transition", "Mix", "Colour transitions", "Dissolves to a user defined colour then from that to the incoming image", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (cDuration, "Duration", "Colour setup", kNoFlags, 0.1, 0.0, 1.0);

DeclareColourParam (Colour, "Colour", "Colour setup", kNoFlags, 0.016, 0.306, 0.608, 1.0);

DeclareFloatParam (cMix, "Colour mix", "Colour setup", kNoFlags, 0.5, -1.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Crawl/Roll/Title/Image key|Video/External image");

DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);

DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_setFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Fgnd = ReadPixel (F, xy1);

   if (Blended) {
      float4 Bgnd = ReadPixel (B, xy2);

      if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
      else {
         if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

         Fgnd.rgb = SwapDir ? Bgnd.rgb : lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a);
      }
      Fgnd.a = pow (Fgnd.a, 0.1);
   }
   else Fgnd.a = 1.0;

   return Fgnd;
}

float4 fn_setBg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd = ReadPixel (B, xy2);

   if (Blended && SwapDir) {

      if (Source > 0) {
         float4 Fgnd = ReadPixel (F, xy1);

         if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

         Bgnd = lerp (Bgnd, Fgnd, Fgnd.a);
      }
   }

   return Bgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return fn_setFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bgd)
{ return fn_setBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (ColourTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg = Blended && !SwapDir ? Bgnd : Fgnd;
   float4 retval = Bgnd;

   if (Fgnd.a > 0.0) {
      float mix_bgd = min (1.0, (1.0 - Amount) * 2.0);
      float mix_fgd = min (1.0, Amount * 2.0);

      if (cDuration < 1.0) {
         float duration = 1.0 - cDuration;

         mix_bgd = min (1.0, mix_bgd / duration);
         mix_fgd = min (1.0, mix_fgd / duration);
      }
      else {
         mix_bgd = 1.0;
         mix_fgd = 1.0;
      }

      float4 Csub;

      float cAmt;

      if (cMix < 0.0) {
         cAmt = saturate (-cMix);
         retval = lerp (Bgnd, Fgnd, 0.5);
      }
      else {
         cAmt = saturate (cMix);
         Csub = Fgnd + Bgnd;
         Csub.a = max (Fgnd.a, Bgnd.a);
         retval = float4 (dot (Csub.rgb, float3 (0.299, 0.587, 0.114)).xxx, Csub.a);
      }

      Csub   = saturate (lerp (Colour, retval, cAmt));

      retval = lerp (Bgnd, lerp (Fgnd, Csub, mix_fgd), mix_bgd);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

