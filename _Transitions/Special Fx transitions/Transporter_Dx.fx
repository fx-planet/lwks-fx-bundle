// @Maintainer jwrl
// @Released 2023-01-29
// @Author jwrl
// @Created 2023-01-29

/**
 This is a difference (delta) key driving a Star Trek-like transporter transition.  It's
 definitely not intended to be a copy of any of the Star Trek versions of the effect.

 It is set up to be used in the same way as a dissolve and the delta key is only ever used
 to control the area that the sparkles occupy.  For it to work properly both the incoming
 and outgoing shots must be static and in exact register.

 During the first part of the transition's progress the sparkles build, then hold for the
 middle section.  They then decay to zero.  Under that, after the first 30% of the
 transition the foreground starts a linear fade in, reaching full value at 70% of the
 transition progress.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.  Unlike LW transitions there is no mask, because
 I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Transporter_Dx.fx
//
// Version history:
//
// Built 2023-01-29 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Transporter mix", "Mix", "Special Effects", "A Star Trek-like transporter fade in or out", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Transition, "Transition", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (starSize, "Centre size", "Star settings", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (starLength, "Arm length", "Star settings", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (starStrength, "Density", "Star settings", kNoFlags, 0.25, 0.0, 1.0);

DeclareColourParam (starColour, "Colour", "Star settings", kNoFlags, 0.9, 0.75, 0.0, 1.0);

DeclareIntParam (KeySetup, "Set up key", "Key settings", 0, "Transition fade in|Transition fade out|Show foreground over black|Show key over black");

DeclareFloatParam (KeyClip, "Key threshold", "Key settings", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (KeyGain, "Key gain", "Key settings", kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (CropLeft, "Top left", "Key crop", "SpecifiesPointX", 0.0, 0.0, 1.0);
DeclareFloatParam (CropTop, "Top left", "Key crop", "SpecifiesPointY", 1.0, 0.0, 1.0);
DeclareFloatParam (CropRight, "Bottom right", "Key crop", "SpecifiesPointX", 1.0, 0.0, 1.0);
DeclareFloatParam (CropBottom, "Bottom right", "Key crop", "SpecifiesPointY", 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI       3.1415926536

#define S_SCALE  0.000868
#define FADER    0.9333333333
#define FADE_DEC 0.0666666667

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

//-----------------------------------------------------------------------------------------//
// These first two shaders simply isolate the foreground and background nodes from the
// resolution.  After this process they can be accessed using TEXCOORD3 coordinates.
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgnd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgnd)
{ return ReadPixel (Bg, uv2); }

//-----------------------------------------------------------------------------------------//
// This starts with a crop shader which masks the foreground so that anomalies with the
// inessential area of the frame can be ignored.  It then compares the foreground to the
// background and generates a difference key.  That then gates a random noise generator
// which creates the required noise for the sparkles that the effect needs for the final
// effect.
//-----------------------------------------------------------------------------------------//

DeclarePass (Sparkles)
{
   // First calculate the image cropping.  If the uv address falls outside the
   // crop area, black with no alpha is returned.

   float left = max (0.0, CropLeft);
   float top = max (0.0, 1.0 - CropTop);
   float right = min (1.0, CropRight);
   float bottom = min (1.0, 1.0 - CropBottom);
   float Amount = KeySetup == 1 ? Transition : 1.0 - Transition;

   Amount = saturate (Amount);

   if ((uv3.x < left) || (uv3.x > right) || (uv3.y < top) || (uv3.y > bottom)) return kTransparentBlack;

   // Now we generate the key by calculating the difference between foreground and
   // background.  We get the differences of R, G and B independently and use the
   // maximum value so obtained to get the cleanest key possible.  It doesn't have
   // to be fantastic, because it will only be used to gate the sparkle noise.

   float3 Fgd = tex2D (Fgnd, uv3).rgb;
   float3 Bgd = tex2D (Bgnd, uv3).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   float4 retval = smoothstep (KeyClip, KeyClip + KeyGain, kDiff).xxxx;

   // Produce the noise required for the stars.

   float scale = (1.0 - starSize) * 800.0;
   float seed = Amount;
   float Y = saturate ((round (uv3.y * scale) / scale) + 0.000123);

   scale *= _OutputAspectRatio;

   float X = saturate ((round (uv3.x * scale) / scale) + 0.00013);
   float rndval = frac (sin ((X * 13.9898) + (Y * 79.233) + seed) * 43758.5453);

   rndval = sin (X) + cos (Y) + rndval * 1000.0;

   // Now gate the noise for the stars, slicing the noise at variable values to
   // control the star density.

   float amt = frac (fmod (rndval, 17.0) * fmod (rndval, 94.0));
   float alpha = abs (cos (Amount * PI));

   amt = smoothstep (0.975 - (starStrength * 0.375), 1.0, amt);
   retval.z *= (amt <= alpha) ? 0.0 : amt;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Blend the foreground with the background, and using the key from ps_keygen, apply the
// sparkle transition as we go.
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Transporter)
{
   float fader = FADER;

   float2 key = tex2D (Sparkles, uv3).zy;
   float2 xy1 = float2 (starLength * S_SCALE, 0.0);
   float2 xy2 = xy1.yx * _OutputAspectRatio;
   float2 xy3 = xy1;
   float2 xy4 = xy2;

   // Create four-pointed stars from the keyed noise.  Doing it this way ensures that the
   // points of the stars fall will overlap the image and won't be cut off.

   for (int i = 0; i <= 15; i++) {
      key.x += tex2D (Sparkles, uv3 + xy1).z * fader;
      key.x += tex2D (Sparkles, uv3 - xy1).z * fader;
      key.x += tex2D (Sparkles, uv3 + xy2).z * fader;
      key.x += tex2D (Sparkles, uv3 - xy2).z * fader;

      xy1 += xy3;
      xy2 += xy4;
      fader -= FADE_DEC;
   }

   // Recover the foreground, and if required, use it to generate the key setup display.

   float4 Fgd = tex2D (Fgnd, uv3);

   if (KeySetup > 1) {
      float mix = saturate (2.0 - (key.y * Fgd.a * 2.0));

      if (KeySetup == 2) return lerp (Fgd, kTransparentBlack, mix);

      return lerp (1.0.xxxx, kTransparentBlack, mix);
   }

   // Create a non-linear transition starting at 0.3 and ending at 0.7.  Using
   // the cosine function gives us a smooth start and end to the transition.

   float Amount = KeySetup == 1 ? Transition : 1.0 - Transition;

   Amount = (cos (smoothstep (0.3, 0.7, saturate (Amount)) * PI) * 0.5) + 0.5;

   float4 retval = lerp (tex2D (Bgnd, uv3), Fgd, Amount);

   // Key the star colour over the transition.  The stars already vary in
   // density as the transition progresses so no further action is needed.

   return lerp (retval, starColour, saturate (key.x));
}

