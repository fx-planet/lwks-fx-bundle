// @Maintainer jwrl
// @Released 2020-12-28
// @Author jwrl
// @Created 2020-12-28
// @see https://www.lwks.com/media/kunena/attachments/6375/ExtrusionMatte_640.png

/**
 "Extrusion blend", as the name suggests, extrudes a foreground image either linearly or
 radially towards a centre point.  The extruded section can be shaded by the foreground
 image, colour shaded, or flat colour filled.  The edge shading can be inverted if desired.
 It is also possible to export the alpha channel for use in downstream effects.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ExtrusionBlend.fx
//
// Version history:
//
// Rewrite 2020-12-28 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Extrusion blend";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Extrudes a foreground image either linearly or radially towards a centre point";
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

#define SAMPLE   80
#define HALFWAY  40              // SAMPLE / 2
#define SAMPLES  81              // SAMPLE + 1.0

#define DELTANG  25
#define ALIASFIX 50              // DELTANG * 2
#define ANGLE    0.125664

#define B_SCALE  0.0075
#define L_SCALE  0.05
#define R_SCALE  0.00125

#define DEFAULT  0
#define COLOUR   1
#define MONO     2

#define LIN_OFFS 0.667333

float _OutputAspectRatio;
float _OutputWidth;

#define EMPTY    (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (blurPre, s_Blur);
DefineTarget (colorPre, s_Colour);
DefineTarget (blurProc, s_Processed);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Edge type";
   string Enum = "Radial,Radial shaded,Radial coloured,Linear,Linear shaded,Linear coloured";
> = 0;

float Opacity
<
   string Description = "Master opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amount
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float zoomAmount
<
   string Description = "Length";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float4 colour
<
   string Group = "Colour setup";
   string Description = "Edge colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.3804, 1.0, -1.0 };

bool invShade
<
   string Description = "Invert shading";
> = false;

bool expAlpha
<
   string Description = "Export alpha channel";
> = false;

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

      return Fgd;
   }

   if (Source == 1) return Fgd;

   float4 Bgd = fn_tex2D (s_Background, uv);

   float kDiff = distance (Fgd.g, Bgd.g);

   kDiff = max (kDiff, distance (Fgd.r, Bgd.r));
   kDiff = max (kDiff, distance (Fgd.b, Bgd.b));

   Fgd.a = smoothstep (0.0, 0.25, kDiff);
   Fgd.rgb *= Fgd.a;

   return Fgd;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_radial (float2 uv : TEXCOORD1, uniform int mode) : COLOR
{
   float4 retval = fn_key2D (s_Foreground, uv);

   if (zoomAmount == 0.0) return retval;

   float scale, depth = zoomAmount * R_SCALE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1 = uv;
   float2 xy2 = depth * (uv - zoomCentre);

   retval.rgb = 1.0.xxx - retval.rgb;

   for (int i = 0; i <= SAMPLE; i++) {
      retval += fn_key2D (s_Foreground, xy1);
      xy1 += xy2;
   }

   retval.a = saturate (retval.a);

   if (mode == COLOUR) return float4 (colour.rgb, retval.a);

   retval.rgb = ((retval.rgb / SAMPLES) * 0.75) + 0.125;

   if (((mode == DEFAULT) && !invShade) || ((mode != DEFAULT) && invShade))
      return retval;

   return float4 (1.0.xxx - retval.rgb, retval.a);
}

float4 ps_linear (float2 uv : TEXCOORD1, uniform int mode) : COLOR
{
   float4 retval = fn_key2D (s_Foreground, uv);

   float2 offset, xy = uv;

   offset.x = (0.498 - Xcentre) * LIN_OFFS;
   offset.y = (Ycentre - 0.505) * LIN_OFFS;

   if ((max (abs (offset.x), abs (offset.y)) == 0.0) || (zoomAmount == 0.0)) return retval;

   float depth = zoomAmount * L_SCALE;

   retval.rgb = 1.0.xxx - retval.rgb;
   offset *= 1.0 / sqrt ((offset.x * offset.x) + (offset.y * offset.y));
   offset *= depth * B_SCALE;

   for (int i = 0; i < SAMPLES; i++) {
      retval += fn_key2D (s_Foreground, xy);
      xy += offset;
      }

   retval.a = saturate (retval.a);

   if (mode == COLOUR) return float4 (colour.rgb, retval.a);

   retval.rgb = ((retval.rgb / SAMPLES) * 0.75) + 0.125;

   if (((mode == DEFAULT) && !invShade) || ((mode != DEFAULT) && invShade))
      return retval;

   return float4 (1.0.xxx - retval.rgb, retval.a);
}

float4 ps_shaded (float2 uv : TEXCOORD1) : COLOR
{
   float4 blurImg = fn_tex2D (s_Blur, uv);
   float4 colrImg = fn_tex2D (s_Colour, uv);

   float alpha   = blurImg.a;
   float minColr = min (colrImg.r, min (colrImg.g, colrImg.b));
   float maxColr = max (colrImg.r, max (colrImg.g, colrImg.b));
   float delta   = maxColr - minColr;

   float3 hsv = 0.0.xxx;

   if (maxColr != 0.0) {
      hsv.y = 1.0 - (minColr / maxColr);
      hsv.x = (colrImg.r == maxColr) ? (colrImg.g - colrImg.b) / delta :
              (colrImg.g == maxColr) ? 2.0 + (colrImg.b - colrImg.r) / delta
                                     : 4.0 + (colrImg.r - colrImg.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
   }

   hsv.z = max (blurImg.r, max (blurImg.g, blurImg.b));

   if (hsv.y == 0.0) return float4 (hsv.zzz, alpha);

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float beta = hsv.x - (float) i;

   float4 retval = hsv.zzzz;

   retval.w *= (1.0 - hsv.y * (1.0 - beta));
   retval.y *= (1.0 - hsv.y);
   retval.z *= (1.0 - hsv.y * beta);

   if (i == 0) return float4 (retval.xwy, alpha);
   if (i == 1) return float4 (retval.zxy, alpha);
   if (i == 2) return float4 (retval.yxw, alpha);
   if (i == 3) return float4 (retval.yzx, alpha);
   if (i == 4) return float4 (retval.wyx, alpha);

   return float4 (retval.xyz, alpha);
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 fgImage = fn_key2D (s_Foreground, xy1);
   float4 retval  = 0.0.xxxx;

   float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 offset, scale;

   float angle = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      retval += fn_tex2D (s_Processed, xy1 + offset);
      retval += fn_tex2D (s_Processed, xy1 - offset);
      angle += ANGLE;
   }

   retval  /= ALIASFIX;
   retval   = lerp (0.0.xxxx, retval, retval.a);
   retval   = lerp (retval, fgImage, fgImage.a);
   retval.a = max (fgImage.a, retval.a * Amount);

   if (expAlpha) return retval;

   float4 bgImage = fn_tex2D (s_Background, xy2);

   retval = lerp (bgImage, retval, retval.a);

   return lerp (bgImage, float4 (retval.rgb, bgImage.a), Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Radial
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_radial (DEFAULT); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique RadialShaded
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurPre;"; >
   { PixelShader = compile PROFILE ps_radial (MONO); }

   pass P_2
   < string Script = "RenderColorTarget0 = colorPre;"; >
   { PixelShader = compile PROFILE ps_radial (COLOUR); }

   pass P_3
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_shaded (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique RadialColour
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_radial (COLOUR); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique Linear
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_linear (DEFAULT); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique LinearShaded
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurPre;"; >
   { PixelShader = compile PROFILE ps_linear (MONO); }

   pass P_2
   < string Script = "RenderColorTarget0 = colorPre;"; >
   { PixelShader = compile PROFILE ps_linear (COLOUR); }

   pass P_3
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_shaded (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique LinearColour
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_linear (COLOUR); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
