// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2021-12-21

/**
 This simulates loss of horizontal and/or vertical hold on analog TV sets.  It works
 best on 4x3 or 16x9 landscape media.  PAL, NTSC colour and 625, 525, 409 and 819 line
 monochrome video formats are supported.  In monochrome mode gamma is lifted and the
 colourimetry has been adjusted to more closely approximate the look of image orthicon
 cameras.  No attempt has been made to duplicate the highlight bloom of those cameras.

 Scanlines can be added, and a range of video artefacts are available.  Horizontal and
 vertical lock can be set manually, or can continuously unlock.  Roll speed and horizontal
 skew rate are both adjustable.  Colour glitches are supported, or in monochrome, ghost
 images can be generated.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AnalogTVdisaster.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-26 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Analog TV disaster", "Stylize", "Video artefacts", "Simulates just about anything that could go wrong with analog TV", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (TVmode, "TV standard", kNoGroup, 0, "PAL|NTSC|625 line mono|525 line mono|409 line mono|819 line mono");

DeclareFloatParam (Horizontal, "Skew", "Horizontal", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Offset, "Offset", "Horizontal", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Hhold, "H. hold", "Horizontal", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (Vertical, "Roll", "Vertical", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Vhold, "V. hold", "Vertical", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (ScanLines, "Scan lines", kNoGroup, kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (VideoNoise, "Video noise", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (Visibility, "Visibility", "Glitches / ghosts", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (GlitchRate, "Rate / ghosting", "Glitches / ghosts", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (EdgeJitter, "Edge jitter", "Glitches / ghosts", kNoFlags, 0.5, -1.0, 1.0);

DeclareFloatParam (_Length);
DeclareFloatParam (_LengthFrames);

DeclareFloatParam (_Progress);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define PI    3.1415926536
#define SCALE 0.01
#define MODLN 0.25

#define BLANK 0.075
#define BLANKING { BLANK, BLANK, BLANK, 1.0 }

#define IOGAM 0.75
#define IOCOL float3(0.225, 0.238, 0.537)

float _ref[6] = { 12.0, 10.0, 12.0, 10.0, 8.0, 16.0 };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_noise (float2 uv, float seed)
{
   float sd_1 = dot (uv, float2 (12.9898,78.233));

   sd_1 += frac (sin (sd_1 + seed) * (43758.5453));

   return frac (sin (sd_1) * (43758.5453));
}

float2 fn_xyWrap (float2 uv)
{
   float2 xy;

   xy.x = uv.x < 0.0 ? 1.0 - frac (abs (uv.x)) : frac (uv.x);
   xy.y = uv.y < 0.0 ? 1.0 - frac (abs (uv.y)) : frac (uv.y);

   return xy;
}

float2 fn_modulate (float y, float r)
{
   float edge = _OutputWidth * _OutputAspectRatio;
   float rate = floor (_LengthFrames / _Length);

   edge  = floor (edge * y) / edge;
   rate -= (rate - 1.0) * (r + 0.8);
   rate *= floor ((_LengthFrames * _Progress) / rate) / _LengthFrames;

   float3 seed = frac (float3 (_Length, _LengthFrames, 1.0) * rate * 19.0);

   float n1 = 8192.0 * sin (dot (seed, float3 (17.0, 53.0, 7.0)));
   float n2 = 1024.0 * sin (((n1 / 1024.0) + edge) * 59.0);

   return frac (float2 (abs (n1), n2) * 256.0);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// This sets up vertical and horizontal sync intervals by scaling the video down slightly
// and adding greyscale levels outside it to emulate sync pulses and colour burst signals.
// It also adds scanlines.

DeclarePass (Video)
{
   float2 xy = float2 (uv1.x * 1.2, uv1.y * 1.1111);

   float lines = _ref [TVmode] * 50.0;
   float blend = 0.002;
   float mix, c_bst = 0.015;

   float4 b[6] = { { 0.2, 0.2, 0.2, 1.0 }, { 0.28, 0.2, 0.0, 1.0 },
                     BLANKING, BLANKING, BLANKING, BLANKING };
   float4 burst = b [TVmode];
   float4 retval;

   if (any (xy > 1.0)) retval = float2 (BLANK, 1.0).xxxy;
   else {
      retval = tex2D (Inp, xy);

      if (TVmode > 1) retval.rgb = pow (dot (retval.rgb, IOCOL), IOGAM).xxx;

      retval.rgb *= 0.9125;
      retval.rgb += 0.0875.xxx;
   }

   if ((xy.y <= 1.0) || (xy.y >= 1.045)) {
      mix = smoothstep (1.012, 1.012 + blend, xy.x) * smoothstep (1.099, 1.099 - blend, xy.x);
      retval = lerp (retval, BLACK, mix);
      mix = smoothstep (1.121, 1.121 + c_bst, xy.x) * smoothstep (1.178, 1.178 - c_bst, xy.x);
      retval = lerp (retval, burst, mix);
   }
   else if ((xy.y >= 1.015) && (xy.y <= 1.03)) {
      mix = smoothstep (0.512, 0.512 + blend, xy.x) * smoothstep (0.968, 0.968 - blend, xy.x);
      mix = max (mix, smoothstep (0.468 + blend, 0.468, xy.x));
      mix = max (mix, smoothstep (1.012, 1.012 + blend, xy.x));
      retval = lerp (retval, BLACK, mix);
   }
   else {
      mix = smoothstep (0.512, 0.512 + blend, xy.x) * smoothstep (0.556, 0.556 - blend, xy.x);
      mix = max (mix, smoothstep (1.012, 1.012 + blend, xy.x) * smoothstep (1.056, 1.056 - blend, xy.x));
      retval = lerp (retval, BLACK, mix);
   }

   retval.rgb *= lerp (1.0, (sin (PI * xy.y * lines) + 1.0) * 0.5, ScanLines);
   retval.rgb += retval.rgb * ScanLines * 0.375;

   return saturate (retval);
}

DeclareEntryPoint (AnalogTVdisaster)
{
   float divisor = _ref [TVmode];
   float multiplier = divisor * 25.0;
   float Xval = 0.5 / multiplier;
   float Yval = Xval * _OutputAspectRatio;
   float amount, jitter, rate;

   float2 offset = 0.0.xx;

   if (TVmode < 2) {
      amount = Visibility;
      jitter = EdgeJitter;
      rate = GlitchRate * 0.2;
   }
   else {
      amount = 1.0;
      jitter = EdgeJitter * 0.5;
      rate = 0.2;
      offset.x = lerp (-0.5, 0.5, GlitchRate);
   }

   float2 xy1 = float2 (uv2.x / 1.2, uv2.y / 1.1111);
   float2 xy2 = fn_modulate (uv2.y, rate);
   float2 xy3 = float2 (round ((uv2.x - 0.5) / Xval) * Xval, round ((uv2.y - 0.5) / Yval) * Yval);

   float modulation = 1.0 - (abs (xy1.x) * MODLN);
   float vertcl = Vertical + (Vhold * _Length * _Progress);
   float horztl = Hhold + Horizontal;
   float skew_1 = Hhold * _Length * _Progress * 7.0;

   xy2.x *= xy2.y;
   xy2    = float2 (dot (xy2, jitter.xx) * SCALE, 0.0);
   xy1.x += skew_1 - Offset + (horztl * round (xy1.y * multiplier)) / divisor;
   xy1.y += vertcl;

   float2 xy4 = fn_xyWrap (xy1 - xy2);

   xy2 = fn_xyWrap (xy1 + xy2 + offset);
   xy1 = fn_xyWrap (xy1);

   float4 retval = tex2D (Video, xy1);
   float4 Vnoise = float4 (fn_noise (xy3, _Progress), fn_noise (xy3, _Progress + 1.0),
                           fn_noise (xy3, _Progress + 2.0), retval.a);

   retval.r = lerp (retval.r, tex2D (Video, xy2).r, amount);
   retval.b = lerp (retval.b, tex2D (Video, xy4).b, amount);
   retval   = lerp (retval, Vnoise, saturate (VideoNoise) * 0.3);

   if (TVmode > 1) retval.rgb = lerp (retval.g, saturate (retval.b - retval.r * 0.5), Visibility).xxx;

   return retval;
}

