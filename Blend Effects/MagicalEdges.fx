// @Maintainer jwrl
// @Released 2021-08-11
// @Author jwrl
// @Author Robert Schütze
// @Created 2021-08-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Magic_Edges_640.png

/**
 This effect generates a border from a title or graphic with an alpha channel.  It then adds
 fractal generated four pointed stars to that border to create a sparkle/glitter effect to
 the edges of the title or graphic.  The fractal speed, scaling and offset is adjustable as
 well as star colour, density, length and rotation.

 As part of the resolution independence support, it's also now possible to optionally
 crop the foreground to the boundaries of the background.  This is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MagicalEdges.fx
//
// The fractal generation component was created by Robert Schütze in GLSL sandbox
// (http://glslsandbox.com/e#29611.0).  It has been somewhat modified to better suit the
// needs of its use in this context.
//
// The star point component is similar to khaver's Glint.fx, but modified to create four
// star points in one loop, to have no blur component, and have no choice of number of
// points.  A different means of setting and calculating rotation is also used.  Apart
// from that it's identical.
//
// Version history:
//
// Rewrite 2021-08-11 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Magical edges";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Fractal edges with star-shaped radiating blurs";
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

#define PI_2        6.28318530718

#define R_VAL       0.2989
#define G_VAL       0.5866
#define B_VAL       0.1145

#define SCL_RATE    224

#define LOOP        60

#define DELTANG     25
#define ANGLE       0.1256637061

#define A_SCALE     0.005
#define B_SCALE     0.0005

#define STAR_LENGTH 0.00025

float _Progress;
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

DefineTarget (Fractals, s_Fractals);
DefineTarget (Border, s_Border);

DefineTarget (Sample_1, s_Sample_1);
DefineTarget (Sample_2, s_Sample_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float EdgeWidth
<
   string Description = "Edge width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Rate
<
   string Description = "Speed";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float StartPoint
<
   string Description = "Start point";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Threshold
<
   string Group = "Stars";
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Brightness
<
   string Group = "Stars";
   string Description = "Brightness";
   float MinVal = 1.0;
   float MaxVal = 10.0;
> = 1.0;

float StarLen
<
   string Group = "Stars";
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 20.0;
> = 5.0;

float Rotation
<
   string Group = "Stars";
   string Description = "Rotation";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 45.0;

float Strength
<
   string Group = "Stars";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Size
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointZ";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float ColourMix
<
   string Description = "Colour modulation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float4 Colour
<
   string Description = "Modulation value";
   bool SupportsAlpha = false;
> = { 0.69, 0.26, 1.0, 1.0 };

bool ShowFractal
<
   string Description = "Show pattern";
> = false;

int Source
<
   string Group = "Disconnect title and image key inputs";
   string Description = "Source selection";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image,Extracted foreground";
> = 1;

bool CropToBgd
<
   string Description = "Crop to background";
> = true;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_initFg (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_RawFg, uv1);

   if (Fgd.a == 0.0) return EMPTY;

   if (Source == 0) {
      Fgd.a    = pow (Fgd.a, 0.5);
      Fgd.rgb /= Fgd.a;
   }
   else if (Source == 2) {
      float4 Bgd = GetPixel (s_Background, uv3);

      float kDiff = distance (Fgd.g, Bgd.g);

      kDiff = max (kDiff, distance (Fgd.r, Bgd.r));
      kDiff = max (kDiff, distance (Fgd.b, Bgd.b));

      Fgd.a = smoothstep (0.0, 0.25, kDiff);
      Fgd.rgb *= Fgd.a;
   }

   return Fgd;
}

float4 ps_fractals (float2 uv : TEXCOORD) : COLOR
{
   float progress = ((_Progress + StartPoint) * PI_2) / sqrt (SCL_RATE + 1.0 - (SCL_RATE * Rate));

   float2 seed = float2 (cos (progress) * 0.3, sin (progress) * 0.5) + 0.5;
   float2 xy = uv - float2 (Xcentre, 1.0 - Ycentre);

   float3 retval = float3 (xy / (Size + 0.01), seed.x);

   float4 fg = GetPixel (s_Foreground, uv);

   for (int i = 0; i < LOOP; i++) {
      retval.rbg = float3 (1.2, 0.999, 0.9) * (abs ((abs (retval) / dot (retval, retval) - float3 (1.0, 1.0, seed.y * 0.4))));
   }

   retval = saturate (retval);

   float luma = (retval.r * R_VAL) + (retval.g * G_VAL) + (retval.b * B_VAL);
   float Yscl = (Colour.r * R_VAL) + (Colour.g * G_VAL) + (Colour.b * B_VAL);

   Yscl = saturate (Yscl - 0.5);
   Yscl = 1 / (Yscl + 0.5);

   float4 buffer = Colour * luma  * Yscl;

   return float4 (lerp (retval, buffer.rgb, ColourMix), fg.a);
}

float4 ps_border_1 (float2 uv : TEXCOORD3) : COLOR
{
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * (EdgeWidth + 0.1) * A_SCALE;
   float2 offset, scale;

   float angle  = 0.0;
   float border = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      border += GetPixel (s_Foreground, uv + offset).a;
      border += GetPixel (s_Foreground, uv - offset).a;
      angle += ANGLE;
   }

   border = (border / DELTANG) - 1.0;
   border = (border > 0.95) ? 0.0 : 1.0;
   border = min (border, GetPixel (s_Foreground, uv).a);

   return border.xxxx;
}

float4 ps_border_2 (float2 uv : TEXCOORD3) : COLOR
{
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * B_SCALE;
   float2 offset, scale;

   float border = 0.0;
   float angle  = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      border += GetPixel (s_Sample_1, uv + offset).a;
      border += GetPixel (s_Sample_1, uv - offset).a;
      angle += ANGLE;
   }

   border = saturate (border / DELTANG);

   float3 retval = lerp (0.0.xxx, GetPixel (s_Fractals, uv).rgb, border);

   return float4 (retval, border);
}

float4 ps_threshold (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = GetPixel (s_Border, uv);

   return ((retval.r + retval.g + retval.b) / 3.0 > 1.0 - Threshold) ? retval : 0.0.xxxx;
}

float4 ps_stretch_1 (float2 uv : TEXCOORD3) : COLOR
{
   float3 delt, ret = 0.0.xxx;

   float2 xy1, xy2, xy3 = 0.0.xx, xy4 = 0.0.xx;

   sincos (radians (Rotation), xy1.y, xy1.x);
   sincos (radians (Rotation + 90), xy2.y, xy2.x);

   xy1 *= StarLen * STAR_LENGTH;
   xy2 *= StarLen * STAR_LENGTH;

   xy1.y *= _OutputAspectRatio;
   xy2.y *= _OutputAspectRatio;

   for (int i = 0; i < 18; i++) {
      delt = GetPixel (s_Sample_2, uv + xy3).rgb;
      delt = max (delt, GetPixel (s_Sample_2, uv - xy3).rgb);
      delt = max (delt, GetPixel (s_Sample_2, uv + xy4).rgb);
      delt = max (delt, GetPixel (s_Sample_2, uv - xy4).rgb);
      delt *= 1.0 - (i / 36.0);
      ret += delt;
      xy3 += xy1;
      xy4 += xy2;
   }

   return float4 (ret, 1.0);
}

float4 ps_stretch_2 (float2 uv : TEXCOORD3) : COLOR
{
   float3 delt, ret = 0.0.xxx;

   float2 xy1, xy2, xy3, xy4;

   sincos (radians (Rotation), xy1.y, xy1.x);
   sincos (radians (Rotation + 90), xy2.y, xy2.x);

   xy1 *= StarLen * STAR_LENGTH;
   xy2 *= StarLen * STAR_LENGTH;

   xy1.y *= _OutputAspectRatio;
   xy2.y *= _OutputAspectRatio;

   xy3 = xy1 * 18.0;
   xy4 = xy2 * 18.0;

   for (int i = 0; i < 18; i++) {
      delt = GetPixel (s_Sample_2, uv + xy3).rgb;
      delt = max (delt, GetPixel (s_Sample_2, uv - xy3).rgb);
      delt = max (delt, GetPixel (s_Sample_2, uv + xy4).rgb);
      delt = max (delt, GetPixel (s_Sample_2, uv - xy4).rgb);
      delt *= 0.5 - (i / 36.0);
      ret += delt;
      xy3 += xy1;
      xy4 += xy2;
   }

   ret = (ret + GetPixel (s_Sample_1, uv).rgb) / 3.6;

   return float4 (ret, 1.0);
}

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Foreground, uv3);
   float4 Bgd = GetPixel (s_Background, uv3);
   float4 retval = lerp (Bgd, Fgd, Fgd.a * Amount);

   float4 border = GetPixel (s_Border, uv3);

   if (ShowFractal) return lerp (GetPixel (s_Fractals, uv3), border, (border.a + 1.0) / 2);

   retval = lerp (retval, border, Brightness * border.a);

   float4 glint = GetPixel (s_Sample_2, uv3);
   float4 comb  = retval + (glint * (1.0 - retval));

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (retval, comb, Strength);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique MagicalEdges
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = Fractals;"; > ExecuteShader (ps_fractals)
   pass P_2 < string Script = "RenderColorTarget0 = Sample_1;"; > ExecuteShader (ps_border_1)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_2)
   pass P_4 < string Script = "RenderColorTarget0 = Sample_2;"; > ExecuteShader (ps_threshold)
   pass P_5 < string Script = "RenderColorTarget0 = Sample_1;"; > ExecuteShader (ps_stretch_1)
   pass P_6 < string Script = "RenderColorTarget0 = Sample_2;"; > ExecuteShader (ps_stretch_2)
   pass P_7 ExecuteShader (ps_main)
}

