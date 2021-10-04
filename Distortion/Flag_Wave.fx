// @Maintainer jwrl
// @Released 2021-08-30
// @Author jwrl
// @Created 2021-08-30
// @see https://www.lwks.com/media/kunena/attachments/6375/FlagWave_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Flag_Wave.mp4

/**
 This effect simulates a flag waving.  It incorporates a 3D DVE to allow the flag to be
 scaled, rotated and positioned.

 Note that the depth setting interacts with the scaling.  This is a side effect of the
 way that the waveform tracks the DVE settings.  An accident originally, it was found
 to be useful since it shows the effect works.  For that reason it has been retained,
 but it can easily be trimmed out by adjusting the image scaling if necessary.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Flag_Wave.fx
//
// Version history:
//
// Rewrite 2021-08-30 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Flag wave";
   string Category    = "Stylize";
   string SubCategory = "Distortion";
   string Notes       = "Simulates a waving flag.";
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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputAspectRatio;

float _Progress;
float _LengthFrames;

#define SCALE_F  9.999805263
#define SCALE_P  3.3219

#define LIMIT_Z 0.0000000001

#define PI      3.1415926536

#define OFFS_1  1.4827586207     // 43/29
#define OFFS_2  1.3529411765     // 23/17
#define OFFS_3  1.9473684211     // 37/19
#define OFFS_4  1.5714285714     // 11/7

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);
DefineTarget (Waveforms, s_Waveforms);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int Orientation
<
   string Description = "Orientation";
   string Enum = "Right edge flutter,Left edge flutter";
> = 0;

float Ripples
<
   string Group = "Flag settings";
   string Description = "Ripples";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Speed
<
   string Group = "Flag settings";
   string Description = "Speed";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Depth
<
   string Group = "Flag settings";
   string Description = "Depth";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Shading
<
   string Group = "Flag settings";
   string Description = "Shading";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PivotX
<
   string Description = "Pivot point";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PivotY
<
   string Description = "Pivot point";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float RotateX
<
   string Description = "Rotation";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.035;

float RotateY
<
   string Description = "Rotation";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.035;

float RotateZ
<
   string Description = "Rotation";
   string Flags = "SpecifiesPointZ";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.025;

float Scale
<
   string Group = "Scale";
   string Description = "Master";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.06;

float ScaleX
<
   string Group = "Scale";
   string Description = "X";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ScaleY
<
   string Group = "Scale";
   string Description = "Y";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float PositionX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float PositionY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.035;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These two preamble passes ensure that rotated video is handled correctly.

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_waves (float2 uv : TEXCOORD0) : COLOR
{
   float2 xy1, xy2, xy3;

   float x1 = Orientation == 0 ? uv.x : 1.0 - uv.x;
   float baseFreq = (Ripples + 0.5) * x1 * 19.0;
   float baseTime = floor ((_LengthFrames * _Progress) + 0.5) * max (Speed, 0.01);
   float x2, freq = baseFreq - baseTime;

   sincos (freq, xy1.x, xy1.y);
   sincos (freq * OFFS_1, xy2.x, xy2.y);
   sincos (freq * OFFS_2, xy3.x, xy3.y);

   xy1 = (xy1 + xy2 + xy3) / 6.0;

   baseFreq = (Ripples + 0.5) * uv.y * 13.0;
   freq = baseFreq - baseTime;

   x2  = sin (freq) + sin (freq * OFFS_3) + sin (freq * OFFS_4);
   x2 /= 20.0;

   xy1.x += x2;
   xy1.x /= _OutputAspectRatio;

   xy1 *= x1;
   xy1 += 0.5.xx;

   return xy1.xyxy;
}

float4 ps_main (float2 uv3 : TEXCOORD3) : COLOR
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
   xy2 = (Overflow (xy1) ? 0.0.xx : tex2D (s_Waveforms, xy1).xx - 0.5.xx) * scale;
   xy = xy1 + xy2 - 0.5.xx;
   xy *= scale + 1.0;
   xy.y *= 1.0 + xy2.y;
   xy += 0.5.xx;

   float4 Fgnd = GetPixel (s_Foreground, xy);

   Fgnd.rgb = saturate (pow (Fgnd.rgb + xy2.xxx, 1.0 - (xy2.x * Shading * 15.0)));

   return lerp (GetPixel (s_Background, uv3), Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Flag_Wave
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)

   pass P_1 < string Script = "RenderColorTarget0 = Waveforms;"; > ExecuteShader (ps_waves)
   pass P_2 ExecuteShader (ps_main)
}

