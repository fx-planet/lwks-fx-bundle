// @Maintainer jwrl
// @Released 2023-01-25
// @Author jwrl
// @Created 2023-01-25

/**
 To use this effect just add it on top of your existing effect, select the colours
 to affect, then the spread and the amount of edge roughness that you need.  That
 really is all that there is to it.  You can also control the edge jitter, the glitch
 rate and angle and the amount of video modulation that is applied to the image.

 The effect is built around a delta or difference key.  This ensures that the effect
 can be applied over an existing title, image key or key effect and will usually just
 automatically extract the foreground to apply the glitch to.  Should you need to,
 adjustments have been provided but it shouldn't often be necessary to touch them.

 Should the separation of the foreground from the background not be all that you
 would wish even after adjustment, you can use the alpha channel of your foreground.
 If you do that you will need to open the routing panel and manually disconnect any
 input to the foreground.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Glitch.fx
//
// Version history:
//
// Built 2023-01-25 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Glitch", "Stylize", "Special Effects", "Applies a glitch to titles or keys.  Just apply on top of your effect.", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Mode, "Glitch channels", "Glitch settings", 3, "Red - cyan|Green - magenta|Blue - yellow|Full colour");

DeclareFloatParam (GlitchRate, "Glitch rate", "Glitch settings", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Modulation, "Modulation", "Glitch settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Rotation, "Rotation", "Glitch settings", kNoFlags, 0.0, -180.0, 180.0);
DeclareFloatParam (Spread, "Spread", "Glitch settings", kNoFlags, 0.5, -1.0, 1.0);
DeclareFloatParam (EdgeRoughen, "Edge roughen", "Glitch settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (EdgeJitter, "Edge jitter", "Glitch settings", kNoFlags, 0.0, 0.0, 1.0);

DeclareIntParam (ShowKey, "Operating mode", "Key settings", 0, "Delta key|Show delta key|Use foreground alpha");

DeclareFloatParam (KeyClip, "Key clip", "Key settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (KeyGain, "Key gain", "Key settings", kNoFlags, 0.9, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Length);
DeclareFloatParam (_LengthFrames);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#define SCALE 0.01
#define MODLN 0.25
#define EDGE  9.0

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Key)
{
   float4 Fgnd = ReadPixel (Fg, uv1);

   if (Fgnd.a == 0.0) return Fgnd.aaaa;

   if (ShowKey == 2) {
      Fgnd.a = pow (Fgnd.a, 0.5 + (KeyClip * 0.5));
      Fgnd.rgb /= lerp (1.0, Fgnd.a, KeyGain);
   }
   else {
      float3 Bgnd = ReadPixel (Bg, uv2).rgb;

      float cDiff = distance (Bgnd, Fgnd.rgb);
      float alpha = smoothstep (KeyClip, KeyClip - KeyGain + 1.0, cDiff);

      Fgnd.rgb *= alpha;
      Fgnd.a    = pow (alpha, 0.5);
   }

   return Fgnd;
}

DeclarePass (Noise)
{
   float ruff = lerp (1.0, 0.25, saturate (EdgeRoughen)) * _OutputHeight;
   float y    = floor (uv3.y * ruff) / _OutputHeight;
   float edge = _OutputWidth * _OutputAspectRatio;
   float rate = floor (_LengthFrames / _Length);

   edge  = floor ((edge * y) / ((EdgeJitter * EDGE) + 1.0)) / edge;
   rate -= (rate - 1.0) * ((GlitchRate * 0.2) + 0.8);
   rate *= floor ((_LengthFrames * _Progress) / rate) / _LengthFrames;

   float3 seed = frac (float3 (_Length, _LengthFrames, 1.0) * rate * 19.0);

   float n1 = 8192.0 * sin (dot (seed, float3 (17.0, 53.0, 7.0)));
   float n2 = 1024.0 * sin (((n1 / 1024.0) + edge) * 59.0);

   return frac (float2 (abs (n1), n2) * 256.0).xyxy;
}

DeclareEntryPoint (Glitch)
{
   if (ShowKey == 1) return tex2D (Key, uv3);

   float2 xy = tex2D (Noise, uv3).xy;

   xy.x *= xy.y;

   float modulation = 1.0 - abs (dot (xy, 0.5.xx) * Modulation * MODLN);
   float x = dot (xy, Spread.xx) * SCALE;

   sincos (radians (Rotation), xy.y, xy.x);

   xy.y *= _OutputAspectRatio;
   xy *= x;

   if (Mode != 3) xy /= 2.0;

   float4 video = ReadPixel (Bg, uv2);
   float4 ret_1 = tex2D (Key, uv3 + xy) * modulation;
   float4 ret_2 = tex2D (Key, uv3 - xy) * modulation;
   float4 glitch;

   glitch.r = Mode == 0 ? lerp (video.r, ret_2.r, ret_2.a)
                        : lerp (video.r, ret_1.r, ret_1.a);
   glitch.g = Mode == 1 ? lerp (video.g, ret_2.g, ret_2.a)
                        : lerp (video.g, ret_1.g, ret_1.a);
   glitch.b = Mode == 2 ? lerp (video.b, ret_2.b, ret_2.a)
                        : lerp (video.b, ret_1.b, ret_1.a);
   glitch.a = video.a;

   glitch = lerp (video, glitch, Opacity);

   return lerp (video, glitch, tex2D (Mask, uv1).x);
}

