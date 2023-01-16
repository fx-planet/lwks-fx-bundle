// @Maintainer jwrl
// @Released 2023-01-05
// @Author jwrl
// @Created 2023-01-05

/**
 Blend tools is an effect that is designed to help if the alpha channel may not be quite
 as required or to generate alpha from absolute black.  The alpha channel may be inverted,
 gamma, gain, contrast and brightness can be adjusted, and the alpha channel may also be
 feathered.  Feathering only works within the existing alpha boundaries and is based on
 the algorithm used in the "Super blur" effect.

 As well as the alpha adjustments the video may be unpremultiplied, and transparency and
 opacity may be adjusted.  Those last two behave in different ways: "Transparency" adjusts
 the key channel background transparency, and "Opacity" is a standard key opacity control.
 The unpremultiply settings when used with the key from black modes will only be applied
 after level adjustment regardless of the actual point selected.  It's impossible to do it
 before because there is no alpha channel available at that stage.

 The effect has been placed in the "Mix" category because it's felt to be closer to the
 blend effect supplied with Lightworks than it is to any of the key effects.  That said,
 it is possible to export just the foreground with the processed alpha.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BlendTools.fx
//
// Version history:
//
// Built 2023-01-05 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Blend tools", "Mix", "Blend Effects", "Provides a wide range of blend and key adjustments including generation of alpha from black", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (KeyMode, "Key mode", kNoGroup, 0, "Standard key|Inverted key|Key from black|Inverted black key");

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Premultiply, "Unpremultiply", "Alpha fine tuning", 0, "None|Before level adjustment|After level adjustment|After feathering");

DeclareFloatParam (Transparency, "Transparency", "Alpha fine tuning", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Gamma, "Alpha gamma", "Alpha fine tuning", kNoFlags, 1.0, 0.1, 4.0);
DeclareFloatParam (Contrast, "Alpha contrast", "Alpha fine tuning", kNoFlags, 0.1, 0.0, 5.0);
DeclareFloatParam (Brightness, "Alpha brightness", "Alpha fine tuning", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Gain, "Alpha gain", "Alpha fine tuning", kNoFlags, 1.0, 0.0, 4.0);
DeclareFloatParam (Feather, "Alpha feather", "Alpha fine tuning", kNoFlags, 0.0, 0.0, 1.0);

DeclareIntParam (OutputMode, "Output mode", kNoGroup, 0, "Blend foreground over background|Export foreground with alpha|Show alpha channel");

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LOOP   12
#define DIVIDE 49

#define RADIUS 0.00125
#define ANGLE  0.2617993878

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Key)
{
   int unpremul = Premultiply;

   float4 Fgd = ReadPixel (Fg, uv1);
   float4 K = ((pow (Fgd, 1.0 / Gamma) * Gain) + (Brightness - 0.5).xxxx) * Contrast;

   K += 0.5.xxxx;

   if (KeyMode > 1) { K.a = saturate ((K.r + K.g + K.b) * 2.0); }
   else if (unpremul == 1) { Fgd.rgb /= Fgd.a; }

   Fgd.a = ((KeyMode == 0) || (KeyMode == 2)) ? K.a : 1.0 - K.a;
   Fgd.a = saturate (lerp (1.0, Fgd.a, Amount));

   if (unpremul == 2) Fgd.rgb /= Fgd.a;

   return Fgd;
}

DeclareEntryPoint (BlendTools)
{
   float4 Bgd = ReadPixel (Bg, uv2);
   float4 Fgd = tex2D (Key, uv3);

   float alpha = Fgd.a;

   if (Feather > 0.0) {
      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Feather * RADIUS;

      float angle = 0.0;

      for (int i = 0; i < LOOP; i++) {
         sincos (angle, xy.x, xy.y);
         xy *= radius;
         alpha += tex2D (Key, uv3 + xy).a;
         alpha += tex2D (Key, uv3 - xy).a;
         xy += xy;
         alpha += tex2D (Key, uv3 + xy).a;
         alpha += tex2D (Key, uv3 - xy).a;
         angle += ANGLE;
      }

      alpha *= (1.0 + Feather) / DIVIDE;
      alpha -= Feather;

      alpha = min (saturate (alpha), Fgd.a);
   }

   if (Premultiply == 3) Fgd.rgb /= alpha;

   Fgd.a = saturate ((alpha + 1.0 - Transparency) * Opacity);

   if (OutputMode == 0) {
      Fgd = lerp (Bgd, Fgd, Fgd.a);
      Fgd.a = max (Bgd.a, Fgd.a);
   }
   else if (OutputMode == 2) Fgd = float4 (Fgd.a.xxx, 1.0);

   return lerp (Bgd, Fgd, tex2D (Mask, uv3));
}

