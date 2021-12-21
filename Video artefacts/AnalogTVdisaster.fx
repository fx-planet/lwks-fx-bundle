// @Maintainer jwrl
// @Released 2021-12-21
// @Author jwrl
// @Created 2021-12-21
// @see https://forum.lwks.com/attachments/analogtvdisaster_480-png.40092/

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
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AnalogTVdisaster.fx
//
// Version history:
//
// Created 2021-12-21 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Analog TV disaster";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Simulates just about anything that could go wrong with analog TV";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define SetTargetMode(TGT, SMP, MODE) \
                                      \
 texture TGT : RenderColorTarget;     \
                                      \
 sampler SMP = sampler_state          \
 {                                    \
   Texture   = <TGT>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define PI    3.1415926536
#define SCALE 0.01
#define MODLN 0.25

#define BLANK 0.075
#define BLANKING { BLANK, BLANK, BLANK, 1.0 }

#define IOGAM 0.75
#define IOCOL float3(0.225, 0.238, 0.537)

float _ref[6] = { 12.0, 10.0, 12.0, 10.0, 8.0, 16.0 };

float _Length;
float _LengthFrames;

float _Progress;

float _OutputWidth;
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

SetTargetMode (Video, s_Video, Wrap);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int TVmode
<
   string Description = "TV standard";
   string Enum = "PAL,NTSC,625 line mono,525 line mono,409 line mono,819 line mono";
> = 0;

float Horizontal
<
   string Group = "Horizontal";
   string Description = "Skew";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Offset
<
   string Group = "Horizontal";
   string Description = "Offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Hhold
<
   string Group = "Horizontal";
   string Description = "H. hold";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Vertical
<
   string Group = "Vertical";
   string Description = "Roll";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Vhold
<
   string Group = "Vertical";
   string Description = "V. hold";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ScanLines
<
   string Description = "Scan lines";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float VideoNoise
<
   string Description = "Video noise";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Visibility
<
   string Group = "Glitches / ghosts";
   string Description = "Visibility";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float GlitchRate
<
   string Group = "Glitches / ghosts";
   string Description = "Rate / ghosting";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float EdgeJitter
<
   string Group = "Glitches / ghosts";
   string Description = "Edge jitter";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_noise (float2 uv, float seed)
{
   float sd_1 = dot (uv, float2 (12.9898,78.233));

   sd_1 += frac (sin (sd_1 + seed) * (43758.5453));

   return frac (sin (sd_1) * (43758.5453));
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
// Shaders
//-----------------------------------------------------------------------------------------//

// This sets up vertical and horizontal sync intervals by scaling the video down slightly
// and adding greyscale levels outside it to emulate sync pulses and colour burst signals.
// It also adds scanlines.

float4 ps_init (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = float2 (uv.x * 1.2, uv.y * 1.1111);

   float lines = _ref [TVmode] * 50.0;
   float blend = 0.002;
   float mix, c_bst = 0.015;

   float4 b[6] = { { 0.2, 0.2, 0.2, 1.0 }, { 0.28, 0.2, 0.0, 1.0 },
                     BLANKING, BLANKING, BLANKING, BLANKING };
   float4 burst = b [TVmode];
   float4 retval;

   if (any (xy > 1.0)) retval = float2 (BLANK, 1.0).xxxy;
   else {
      retval = tex2D (s_Input, xy);
      if (TVmode > 1) retval.rgb = pow (dot (retval.rgb, IOCOL), IOGAM).xxx;
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

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
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
      offset.x = lerp (-0.05, 0.05, GlitchRate);
   }

   float2 xy1 = float2 (uv.x / 1.2, uv.y / 1.1111);
   float2 xy2 = fn_modulate (uv.y, rate);
   float2 xy3 = float2 (round ((uv.x - 0.5) / Xval) * Xval, round ((uv.y - 0.5) / Yval) * Yval);

   float modulation = 1.0 - (abs (xy1.x) * MODLN);
   float seed_1 = _Progress;
   float seed_2 = seed_1 + 1.0;
   float seed_3 = seed_2 + 1.0;
   float vertcl = Vertical + (Vhold * _Length * _Progress);
   float horztl = Hhold + Horizontal;
   float skew_1 = Hhold * _Length * _Progress * 7.0;

   horztl = horztl < 0.0 ? -frac (abs (horztl)) : frac (horztl);

   xy2.x *= xy2.y;
   xy2 = float2 (dot (xy2, jitter.xx) * SCALE, 0.0);

   xy1.x += skew_1 - Offset + (horztl * round (xy1.y * multiplier)) / divisor;
   xy1.y += vertcl < 0.0 ? -frac (abs (vertcl)) : frac (vertcl);

   float4 retval = tex2D (s_Video, xy1);
   float4 Vnoise = float4 (fn_noise (xy3, seed_1), fn_noise (xy3, seed_2),
                           fn_noise (xy3, seed_3), retval.a);

   retval.r = lerp (retval.r, tex2D (s_Video, xy1 + xy2 + offset).r, amount);
   retval.b = lerp (retval.b, tex2D (s_Video, xy1 - xy2).b, amount);
   retval   = lerp (retval, Vnoise, saturate (VideoNoise) * 0.3);

   if (TVmode > 1) retval.rgb = lerp (retval.g, saturate (retval.b - retval.r * 0.5), Visibility).xxx;

   return retval;
}

//-----------------------------------------------------------------------------------------//
//  Techniques
//-----------------------------------------------------------------------------------------//

technique AnalogTVdisaster
{
   pass P_1 < string Script = "RenderColorTarget0 = Video;"; > ExecuteShader (ps_init)
   pass P_2 ExecuteShader (ps_main)
}

