// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 Bounces a key, title or blended image up to a preset size at the mid point then lets it
 fall back.  The transition can be linear or follow a preset smooth curve.  It operates
 on both alpha and delta keys.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Bounce_Fx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Bounce transition (keyed)", "Mix", "DVE transitions", "Bounces the foreground up to a preset size then falls back", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Mid, "Midpoint", kNoGroup, "DisplayAsPercentage", 0.5, 0.1, 0.9);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (Ttype, "Transition position", kNoGroup, 1, "At start if delta key folded|At start of effect|At end of effect");
DeclareIntParam (Curve, "Transition curve", kNoGroup, 0, "Linear|Curve 1|Curve 2");

DeclareFloatParam (CentreX, "Centre point", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Centre point", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareIntParam (ZeroMode, "Mode", "Zero settings", 0, "Operate|Set up size");

DeclareFloatParam (ZeroScale, "Size", "Zero settings", "DisplayAsPercentage", 0.0, 0.0, 4.0);

DeclareIntParam (MidMode, "Mode", "Midpoint settings", 0, "Operate|Set up size");

DeclareFloatParam (MidScale, "Size", "Midpoint settings", "DisplayAsPercentage", 1.5, 0.0, 4.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.141592654
#define HALF_PI 1.570796327

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super)
{
   float4 Bgnd, Fgnd = tex2D (Fgd, uv3);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = tex2D (Bgd, uv3);
      }
      else Bgnd = tex2D (Bgd, uv3);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

DeclareEntryPoint (Bounce)
{
   float scale;

   if (ZeroMode) {
      scale = ZeroScale;
   }
   else if (MidMode) {
      scale = MidScale;
   }
   else {
      float amt_1 = smoothstep (0.0, Mid, Amount) + smoothstep (Mid, 1.0, Amount);
      float amt_2;

      // The above ranges the progress of the transition from 0.0 to 2.0, with 1.0
      // at the preset midpoint.  We now apply some simple trig curves if needed.

      if (Curve == 1) {
         amt_2 = (cos (amt_1 * PI) + 3.0) * 0.5;      // Swings between 2.0 > 1.0 > 2.0
         amt_1 = amt_1 > 1.0 ? amt_2 : 2.0 - amt_2;   // Swings between 0.0 > 1.0 > 2.0
      }
      else if (Curve == 2) {
         amt_2 = sin (amt_1 * HALF_PI);               // Swings between 0.0 > 1.0 > 0.0
         amt_1 = amt_1 < 1.0 ? amt_2 : 2.0 - amt_2;   // Swings between 0.0 > 1.0 > 2.0
      }

      // We now set up amt_1 to ramp from zero to 100% at the preset midpoint of the
      // transition and amt_2 to ramp from zero to 100% after that.

      amt_2 = max (amt_1 - 1.0, 0.0);
      amt_1 = min (amt_1, 1.0);

      // The next block of code sets s_1 to ZeroScale if we're transitioning in or 100%
      // if transitioning out.  The variable s_2 is set to 100% if we're transitioning
      // in or ZeroScale if transitioning out.

      float s_1, s_2;

      if (Ttype == 2) {
         s_1 = 1.0;
         s_2 = ZeroScale;
      }
      else {
         s_1 = ZeroScale;
         s_2 = 1.0;
      }

      // Finally the transition ramps the scale from the start to the midpoint scale
      // value then ramps it from the midpoint value to the end scale.

      scale = lerp (lerp (s_1, MidScale, amt_1), s_2, amt_2);
   }

   // We now perform a simple scaling of the coordinates around the screen centre,
   // recover our foreground and background components, combine them and quit.

   float2 xy1 = float2 (CentreX, 1.0 - CentreY);
   float2 xy2 = (uv3 - xy1) / scale;

   float4 Fgnd = tex2D (Super, xy1 + xy2);
   float4 Bgnd = Ttype == 0 ? tex2D (Fgd, uv3) : tex2D (Bgd, uv3);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

