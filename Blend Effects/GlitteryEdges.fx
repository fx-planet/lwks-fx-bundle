// @Maintainer jwrl
// @Released 2020-12-28
// @Author jwrl
// @Created 2020-12-28
// @see https://www.lwks.com/media/kunena/attachments/6375/GlitterEdge_640.png

/**
 This effect generates a border from a title or graphic with an alpha channel.  It then adds
 noise generated four pointed stars to that border to create a sparkle/glitter effect to the
 edges of the title or graphic.  Star colour, density, length and rotation are adjustable.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GlitteryEdges.fx
//
// The star point component is similar to khaver's Glint.fx, but modified to create four
// star points in one loop, to have no blur component, no choice of number of points, and
// to compile and run under the default Lightworks shader profile.  A different means of
// setting and calculating rotation is also used.  Apart from that it's identical.
//
// Version history:
//
// Rewrite 2020-12-28 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Glittery edges";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Sparkly edges, best over darker backgrounds";
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

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DELTANG     25
#define ANGLE       0.1256637061

#define A_SCALE     0.005
#define B_SCALE     0.0005

#define STAR_LENGTH 0.025

float _Length;

float _Progress;
float _OutputAspectRatio;

#define EMPTY    (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Border, s_Border);
DefineTarget (Sparkle, s_Sparkle);

DefineTarget (Sample_1, s_Sample_1);
DefineTarget (Sample_2, s_Sample_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Master opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Opacity
<
   string Description = "Fgd opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float EdgeOpacity
<
   string Group = "Edges";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float EdgeWidth
<
   string Group = "Edges";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Threshold
<
   string Group = "Stars";
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Strength
<
   string Group = "Stars";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float StarLen
<
   string Group = "Stars";
   string Description = "Length";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 0.025;
> = 0.0125;

float Rotation
<
   string Group = "Stars";
   string Description = "Rotation";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 45.0;

float Rate
<
   string Group = "Stars";
   string Description = "Speed";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float StartPoint
<
   string Group = "Stars";
   string Description = "Noise seed";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float4 Colour
<
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 1.0, 0.8, 0.0, -1.0 };

int Source
<
   string Description = "Source selection (disconnect title and image key inputs)";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image,Extracted foreground";
> = 1;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   return (max (xy.x, xy.y) > 0.5) ? EMPTY : tex2D (s, uv);
}

float4 fn_key2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   if (max (xy.x, xy.y) > 0.5) return EMPTY;

   float4 Fgd = tex2D (s, uv);

   if (Fgd.a == 0.0) return EMPTY;

   if (Source == 0) {
      Fgd.a    = pow (Fgd.a, 0.5);
      Fgd.rgb /= Fgd.a;
   }
   else if (Source == 2) {
      float4 Bgd = fn_tex2D (s_Background, uv);

      float kDiff = distance (Fgd.g, Bgd.g);

      kDiff = max (kDiff, distance (Fgd.r, Bgd.r));
      kDiff = max (kDiff, distance (Fgd.b, Bgd.b));

      Fgd.a = smoothstep (0.0, 0.25, kDiff);
      Fgd.rgb *= Fgd.a;
   }

   return Fgd;
}

float3 fn_noise (float2 uv)
{
   float2 xy = saturate (float2 (uv.x + 0.00013, uv.y + 0.00123));

   float noise  = (_Progress * _Length * (0.01 + Rate) * 0.005) + StartPoint;
   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + noise) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + rndval * 1000;
   noise  = saturate (frac (fmod (rndval, 17) * fmod (rndval, 94)) * 15 - 12.0);

   return saturate ((Colour * noise) + Colour * 0.05).rgb;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_border_1 (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * (EdgeWidth + 0.1) * A_SCALE;
   float2 offset, scale;

   float angle  = 0.0;
   float border = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      border += fn_key2D (s_Foreground, uv + offset).a;
      border += fn_key2D (s_Foreground, uv - offset).a;
      angle += ANGLE;
   }

   border = (border / DELTANG) - 1.0;
   border = (border > 0.95) ? 0.0 : 1.0;
   border = min (border, fn_key2D (s_Foreground, uv).a);

   return border.xxxx;
}

float4 ps_border_2 (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * B_SCALE;
   float2 offset, scale;

   float border = 0.0;
   float angle  = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      border += fn_tex2D (s_Sample_2, uv + offset).a;
      border += fn_tex2D (s_Sample_2, uv - offset).a;
      angle += ANGLE;
   }

   border = saturate (border / DELTANG);

   float3 retval = lerp (0.0.xxx, fn_noise (uv), border);

   return float4 (retval, border);
}

float4 ps_threshold (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = fn_tex2D (s_Border, uv);

   return ((retval.r + retval.g + retval.b) / 3.0 < Threshold) ? 0.0.xxxx : retval;
}

float4 ps_stretch_1 (float2 uv : TEXCOORD1) : COLOR
{
   float3 delt, ret = 0.0.xxx;

   float2 xy1, xy2, xy3 = 0.0.xx, xy4 = 0.0.xx;

   sincos (radians (Rotation), xy1.y, xy1.x);
   sincos (radians (Rotation + 90), xy2.y, xy2.x);

   xy1 *= StarLen * STAR_LENGTH;
   xy2 *= StarLen * STAR_LENGTH;

   xy1.y *= _OutputAspectRatio;
   xy2.y *= _OutputAspectRatio;

   for (int i = 0; i < 20; i++) {
      delt = fn_tex2D (s_Sample_1, uv + xy3).rgb;
      delt = max (delt, fn_tex2D (s_Sample_1, uv - xy3).rgb);
      delt = max (delt, fn_tex2D (s_Sample_1, uv + xy4).rgb);
      delt = max (delt, fn_tex2D (s_Sample_1, uv - xy4).rgb);
      delt *= 1.0 - (i / 40.0);
      ret += delt;
      xy3 += xy1;
      xy4 += xy2;
   }

   return float4 (ret, 1.0);
}

float4 ps_stretch_2 (float2 uv : TEXCOORD1) : COLOR
{
   float3 delt, ret = 0.0.xxx;

   float2 xy1, xy2, xy3, xy4;

   sincos (radians (Rotation), xy1.y, xy1.x);
   sincos (radians (Rotation + 90), xy2.y, xy2.x);

   xy3 = xy1 * StarLen;
   xy4 = xy2 * StarLen;

   xy3.y *= _OutputAspectRatio;
   xy4.y *= _OutputAspectRatio;

   xy1 = xy3 * 0.05;
   xy2 = xy4 * 0.05;

   for (int i = 0; i < 20; i++) {
      delt = fn_tex2D (s_Sample_1, uv + xy3).rgb;
      delt = max (delt, fn_tex2D (s_Sample_1, uv - xy3).rgb);
      delt = max (delt, fn_tex2D (s_Sample_1, uv + xy4).rgb);
      delt = max (delt, fn_tex2D (s_Sample_1, uv - xy4).rgb);
      delt *= 0.5 - (i / 40.0);
      ret += delt;
      xy3 += xy1;
      xy4 += xy2;
   }

   ret = (ret + fn_tex2D (s_Sample_2, uv).rgb) / 3.6;

   return float4 (ret, 1.0);
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = fn_key2D (s_Foreground, xy1);
   float4 Bgd = fn_tex2D (s_Background, xy2);

   float4 glint  = fn_tex2D (s_Sparkle, xy1);
   float4 retval = lerp (Bgd, Fgd, Fgd.a * Opacity);
   float4 border = fn_tex2D (s_Border, xy1);

   border.rgb = Colour.rgb * 0.95;

   retval = lerp (retval, border, border.a * EdgeOpacity);
   glint  = saturate (retval + glint - (glint * retval));
   retval = lerp (retval, glint, Strength);

   return lerp (Bgd, retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique GlitteryEdges
{
   pass P_1
   < string Script = "RenderColorTarget0 = Sample_2;"; >
   { PixelShader = compile PROFILE ps_border_1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Border;"; >
   { PixelShader = compile PROFILE ps_border_2 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Sample_1;"; >
   { PixelShader = compile PROFILE ps_threshold (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Sample_2;"; >
   { PixelShader = compile PROFILE ps_stretch_1 (); }

   pass P_5
   < string Script = "RenderColorTarget0 = Sparkle;"; >
   { PixelShader = compile PROFILE ps_stretch_2 (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}
