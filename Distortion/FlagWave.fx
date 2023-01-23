// @Maintainer jwrl
// @Released 2023-01-24
// @Author jwrl
// @Created 2023-01-24

/**
 This effect simulates a flag waving.  It incorporates a 3D DVE to allow the flag to be
 scaled, rotated and positioned.

 Note that the depth setting interacts with the scaling.  This is a side effect of the
 way that the waveform tracks the DVE settings.  An accident originally, it was found
 to be useful since it shows the effect works.  For that reason it has been retained,
 but it can easily be trimmed out by adjusting the image scaling if necessary.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlagWave.fx
//
// Version history:
//
// Built 2023-01-24 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Flag wave", "Stylize", "Distortion", "Simulates a waving flag.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Orientation, "Orientation", kNoGroup, 0, "Right edge flutter|Left edge flutter");

DeclareFloatParam (Ripples, "Ripples", "Flag settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Speed, "Speed", "Flag settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Depth, "Depth", "Flag settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Shading, "Shading", "Flag settings", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (PivotX, "Pivot point", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (PivotY, "Pivot point", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (RotateX, "Rotation", kNoGroup, "SpecifiesPointX", -0.035, -1.0, 1.0);
DeclareFloatParam (RotateY, "Rotation", kNoGroup, "SpecifiesPointY", -0.035, -1.0, 1.0);
DeclareFloatParam (RotateZ, "Rotation", kNoGroup, "SpecifiesPointZ", 0.025, -1.0, 1.0);

DeclareFloatParam (Scale, "Master", "Scale", kNoFlags, -0.06, -1.0, 1.0);

DeclareFloatParam (ScaleX, "X", "Scale", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (ScaleY, "Y", "Scale", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (PositionX, "Position", kNoGroup, "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (PositionY, "Position", kNoGroup, "SpecifiesPointY", 0.035, -1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);
DeclareFloatParam (_LengthFrames);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SCALE_F  9.999805263
#define SCALE_P  3.3219

#define LIMIT_Z 0.0000000001

#define PI      3.1415926536

#define OFFS_1  1.4827586207     // 43/29
#define OFFS_2  1.3529411765     // 23/17
#define OFFS_3  1.9473684211     // 37/19
#define OFFS_4  1.5714285714     // 11/7

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// These two preamble passes ensure that rotated video is handled correctly.

DeclarePass (Foreground)
{ return lerp (kTransparentBlack, ReadPixel (Fg, uv1), tex2D (Mask, uv1).x); }

DeclarePass (Background)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Waves)
{
   float2 xy1, xy2, xy3;

   float x1 = Orientation == 0 ? uv0.x : 1.0 - uv0.x;
   float baseFreq = (Ripples + 0.5) * x1 * 19.0;
   float baseTime = floor ((_LengthFrames * _Progress) + 0.5) * max (Speed, 0.01);
   float x2, freq = baseFreq - baseTime;

   sincos (freq, xy1.x, xy1.y);
   sincos (freq * OFFS_1, xy2.x, xy2.y);
   sincos (freq * OFFS_2, xy3.x, xy3.y);

   xy1 = (xy1 + xy2 + xy3) / 6.0;

   baseFreq = (Ripples + 0.5) * uv0.y * 13.0;
   freq = baseFreq - baseTime;

   x2  = sin (freq) + sin (freq * OFFS_3) + sin (freq * OFFS_4);
   x2 /= 20.0;

   xy1.x += x2;
   xy1.x /= _OutputAspectRatio;

   xy1 *= x1;
   xy1 += 0.5.xx;

   return xy1.xyxy;
}

DeclareEntryPoint (FlagWave)
{
   //  This first section is a standard 3D DVE.  This is the bulk of the effect

   float rotation = (RotateX < 0.0 ? RotateX + 0.5 : RotateX - 0.5) * 2.0;
   float scale, rotate;

   sincos (rotation * PI, rotate, scale);
   rotate = abs (rotate);

   float2 pivot = float2 (PivotX, 1.0 - PivotY);
   float2 xy = uv3 - pivot;

   if (scale > 0.0) { xy.y = -xy.y; }

   scale = xy.y / max (abs (scale), LIMIT_Z);

   float2 xy1 = float2 (xy.x * (1.0 - scale), scale);
   float2 xy2 = float2 (xy.x * (1.0 + scale), scale);

   xy = rotation >= 0.0 ? lerp (xy, xy1, rotate) : lerp (xy, xy2, rotate);

   rotation = (RotateY < 0.0 ? RotateY + 0.5 : RotateY - 0.5) * 2.0;
   sincos (rotation * PI, rotate, scale);
   rotate = abs (rotate);

   if (scale > 0.0) { xy.x = -xy.x; }

   scale = xy.x / max (abs (scale), LIMIT_Z);

   xy1 = float2 (scale, xy.y * (1.0 + scale));
   xy2 = float2 (scale, xy.y * (1.0 - scale));
   xy  = rotation >= 0.0 ? lerp (xy, xy1, rotate) : lerp (xy, xy2, rotate);

   rotation = (RotateZ < 0.0 ? RotateZ + 0.5 : RotateZ - 0.5) * 2.0;
   sincos (rotation * PI, rotate, scale);

   xy1 = xy.yx * rotate;

   xy1.x /= _OutputAspectRatio;
   xy1.y *= -_OutputAspectRatio;

   xy1 -= xy * scale;

   float2 scale_XY = (Scale + 1.0.xx) * (float2 (ScaleX, ScaleY) + 1.0.xx) * 0.5;

   scale_XY = max (pow (scale_XY, SCALE_P) * SCALE_F, LIMIT_Z);

   xy1 /= scale_XY;
   xy1 += (float2 (-PositionX, PositionY) / scale_XY) + pivot;

   // From here on is the flag creation.  Note that the waveform generation is
   // recovered first, then used to modify the foreground XY parameters.  This
   // ensures that the flag scaling tracks correctly with the image scaling.

   scale = Depth * 0.1;
   xy2 = (IsOutOfBounds (xy1) ? 0.0.xx : tex2D (Waves, xy1).xx - 0.5.xx) * scale;
   xy = xy1 + xy2 - 0.5.xx;
   xy *= scale + 1.0;
   xy.y *= 1.0 + xy2.y;
   xy += 0.5.xx;

   float4 Fgnd = ReadPixel (Foreground, xy);

   Fgnd.rgb = saturate (pow (Fgnd.rgb + xy2.xxx, 1.0 - (xy2.x * Shading * 15.0)));

   return lerp (ReadPixel (Background, uv3), Fgnd, Fgnd.a * Opacity);
}

