// @Maintainer jwrl
// @Released 2018-07-29
// @Author jwrl
// @Created 2018-07-27
// @see https://www.lwks.com/media/kunena/attachments/6375/FlagWave_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Flag_Wave.mp4
//-----------------------------------------------------------------------------------------//
//
//   ***********  WARNING: THIS EFFECT REQUIRES LIGHTWORKS 14.5 OR BETTER  ***********
//
//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlagWave.fx
//
// This effect simulates a flag waving.  It incorporates a 3D DVE to allow the flag to
// be scaled, rotated and positioned.
//
// Note that the depth setting interacts with the scaling.  This is a side effect of the
// way the waveform tracks the DVE settings.  An accident originally, it was found to be
// useful since it shows that effect is working.  For that reason it has been retained,
// but it can easily be trimmed out by adjusting the image scaling if necessary.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Flag wave";
   string Category    = "Stylize";
   string SubCategory = "Special Fx";
   string Notes       = "Simulates a waving flag in the foreground image.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Waveforms : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Waveforms = sampler_state
{
   Texture   = <Waveforms>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

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
> = 0.0;

float RotateY
<
   string Description = "Rotation";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float RotateZ
<
   string Description = "Rotation";
   string Flags = "SpecifiesPointZ";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Scale
<
   string Group = "Scale";
   string Description = "Master";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

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
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputWidth;
float _OutputHeight;
float _OutputAspectRatio;

float _Progress;
float _LengthFrames;

#define FRAME   float2(_OutputWidth, _OutputHeight)

#define SCALE_F  9.999805263
#define SCALE_P  3.3219

#define LIMIT_Z 0.0000000001

#define PI      3.1415926536

#define OFFS_1  1.8571428571
#define OFFS_2  1.3076923077

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv, float ret)
{
   float2 xy = abs (uv - 0.5.xx);

   if ((xy.x > 0.5) || (xy.y > 0.5)) return ret.xxxx;

   return tex2D (Vsample, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_waves (float2 uv : TEXCOORD0) : COLOR
{
   float4 retval;

   float baseFreq = (Ripples + 0.5) * uv.x * 6.0 * PI;

   baseFreq -= floor ((_LengthFrames * _Progress) + 0.5) * max (Speed, 0.01);

   sincos (baseFreq, retval.w, retval.x);
   sincos (baseFreq * OFFS_1, retval.y, retval.z);

   retval.wx += retval.yz;

   sincos (baseFreq * OFFS_2, retval.y, retval.z);

   retval.yz += retval.wx;
   retval.wx  = retval.yz * 0.5;
   retval    /= 3.0;

   return ((retval * uv.x) + 1.0.xxxx) * 0.5;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   //  This first section is a standard 3D DVE.  This is the bulk of the effect

   float rotation = (RotateX < 0.0 ? RotateX + 0.5 : RotateX - 0.5) * 2.0;
   float scale, rotate;

   sincos (rotation * PI, rotate, scale);
   rotate = abs (rotate);

   float2 pivot = float2 (PivotX, 1.0 - PivotY);
   float2 xy = uv1 - pivot;

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

   scale = Depth * 0.2;
   xy2 = (fn_tex2D (s_Waveforms, xy1, 0.5).xy - 0.5.xx) * scale;
   scale++;
   xy = xy1 + xy2 - 0.5.xx;
   xy *= scale;
   xy.y *= 1.0 + (xy2.y * 0.5);
   xy += 0.5.xx;

   float4 Fgnd = fn_tex2D (s_Foreground, xy, 0.0);

   Fgnd.rgb = saturate (pow (Fgnd.rgb + xy2.xxx, 1.0 - (xy2.x * Shading * 15.0)));

   return lerp (tex2D (s_Background, uv2), Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique FlagWave
{
   pass P_1
   < string Script = "RenderColorTarget0 = Waveforms;"; > 
   { PixelShader = compile PROFILE ps_waves (); }

   pass P_2 { PixelShader = compile PROFILE ps_main (); }
}

