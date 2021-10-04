// @Maintainer jwrl
// @Released 2021-08-29
// @Author jwrl
// @Created 2021-08-29
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Borders_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Borders.mp4

/**
 An effect transition that generates borders using a difference or delta key then uses
 them to make the image materialise from four directions or blow apart in four directions.
 Each quadrant is independently coloured.

 If the foreground and/or background resolution differ from the sequence resolution it
 will be necessary to adjust the delta key trim.  Normally you won't need to do this.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Border_Kx.fx
//
// This effect is a rewrite of two earlier effects, Borders_Adx and Borders_Ax.
//
// Version history:
//
// Built 2021-08-29 jwrl.
// Rewrite of the original to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Border transition (keyed)";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "The foreground materialises from four directions or dematerialises to four directions";
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
   AddressU  = Mirror;                \
   AddressV  = Mirror;                \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY)  (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow (XY) ? EMPTY : tex2D (SHADER, XY))

#define NotEqual(XY_1,XY_2)  (distance (XY_1, XY_2) != 0.0)

float _OutputPixelWidth  = 1.0;
float _OutputPixelHeight = 1.0;

float _OutputWidth;
float _OutputHeight;

#define LOOP_1   30
#define RADIUS_1 (float2 (1.0, _OutputWidth / _OutputHeight) * 0.018)
#define ANGLE_1  1.0471975512

#define LOOP_2   24
#define RADIUS_2 (float2 (1.0, _OutputWidth / _OutputHeight) * 0.012)
#define ANGLE_2  0.1309

#define OFFSET   0.5
#define X_OFFSET 0.5625
#define Y_OFFSET 1.7777777778

#define HALF_PI  1.5707963268

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Super, s_Super);
DefineTarget (border_1, s_Border_1);
DefineTarget (border_2, s_Border_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0 = 0.0;
   float KF1 = 1.0;
> = 0.5;

int Source
<
   string Description = "Source";
   string Enum = "Extracted foreground (delta key),Crawl/Roll/Title/Image key,Video/External image";
> = 0;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start if delta key folded,At start of effect,At end of effect";
> = 1;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

float Radius
<
   string Group = "Borders";
   string Description = "Thickness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.3;

float Displace
<
   string Group = "Borders";
   string Description = "Displacement";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 Colour_1
<
   string Group = "Colours";
   string Description = "Outline 1";
   bool SupportsAlpha = false;
> = { 0.6, 0.9, 1.0, -1.0 };

float4 Colour_2
<
   string Group = "Colours";
   string Description = "Outline 2";
   bool SupportsAlpha = false;
> = { 0.3, 0.6, 1.0, -1.0 };

float4 Colour_3
<
   string Group = "Colours";
   string Description = "Outline 3";
   bool SupportsAlpha = false;
> = { 0.9, 0.6, 1.0, -1.0 };

float4 Colour_4
<
   string Group = "Colours";
   string Description = "Outline 4";
   bool SupportsAlpha = false;
> = { 0.6, 0.3, 1.0, -1.0 };

float KeyGain
<
   string Description = "Key trim";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_keygen (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_border_I_1 (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = EMPTY;

   if (Radius != 0.0) {
      float radScale = cos (Amount * HALF_PI);

      float2 radius = float2 (_OutputPixelWidth, _OutputPixelHeight) * Radius * radScale * RADIUS_1;
      float2 xy;

      for (int i = 0; i < LOOP_1; i++) {
         sincos ((i * ANGLE_1), xy.x, xy.y);
         xy *= radius;
         retval = max (retval, GetPixel (s_Super, uv + xy));
         retval = max (retval, GetPixel (s_Super, uv - xy));
      }
   }

   return retval;
}

float4 ps_border_O_1 (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = EMPTY;

   if (Radius == 0.0) return retval;

   float radScale = sin (Amount * HALF_PI);

   float2 radius = float2 (_OutputPixelWidth, _OutputPixelHeight) * Radius * radScale * RADIUS_1;
   float2 xy;

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy.x, xy.y);
      xy *= radius;
      retval = max (retval, GetPixel (s_Super, uv + xy));
      retval = max (retval, GetPixel (s_Super, uv - xy));
   }

   return retval;
}

float4 ps_border_I_2 (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = GetPixel (s_Border_1, uv);

   if (Radius == 0.0) return retval;

   float radScale = cos (Amount * HALF_PI);
   float alpha = saturate (GetPixel (s_Super, uv).a * 2.0);

   float2 radius = float2 (_OutputPixelWidth, _OutputPixelHeight) * Radius * radScale * RADIUS_2;
   float2 xy;

   for (int i = 0; i < LOOP_2; i++) {
      sincos ((i * ANGLE_2), xy.x, xy.y);
      xy *= radius;
      retval = max (retval, GetPixel (s_Border_1, uv + xy));
      retval = max (retval, GetPixel (s_Border_1, uv - xy));
   }

   return lerp (retval, EMPTY, alpha);
}

float4 ps_border_O_2 (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = GetPixel (s_Border_1, uv);

   if (Radius == 0.0) return retval;

   float radScale = sin (Amount * HALF_PI);
   float alpha = saturate (GetPixel (s_Super, uv).a * 2.0);

   float2 radius = float2 (_OutputPixelWidth, _OutputPixelHeight) * Radius * radScale * RADIUS_2;
   float2 xy;

   for (int i = 0; i < LOOP_2; i++) {
      sincos ((i * ANGLE_2), xy.x, xy.y);
      xy *= radius;
      retval = max (retval, GetPixel (s_Border_1, uv + xy));
      retval = max (retval, GetPixel (s_Border_1, uv - xy));
   }

   return lerp (retval, EMPTY, alpha);
}

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float Offset = (1.0 - Amount) * Displace * OFFSET;
   float Outline = 0.0, Opacity = 1.0;

   float2 xy1 = float2 (_OutputPixelWidth, _OutputPixelHeight) * Offset;
   float2 xy2 = float2 (xy1.x * X_OFFSET, (-xy1.y) * Y_OFFSET);
   float2 xy3 = uv3 - xy1;
   float2 xy4 = uv3 + xy1;

   xy1  = uv3 - xy2;
   xy2 += uv3;

   float4 border = GetPixel (s_Super, xy1);
   float4 retval = EMPTY;

   if (NotEqual (xy1, xy2)) {
      retval = GetPixel (s_Super, xy2); border = lerp (border, retval, retval.a);
      retval = GetPixel (s_Super, xy3); border = lerp (border, retval, retval.a);
      retval = GetPixel (s_Super, xy4); border = lerp (border, retval, retval.a);

      retval = Colour_1 * GetPixel (s_Border_2, xy1).a;
      retval = lerp (retval, Colour_2, GetPixel (s_Border_2, xy2).a);
      retval = lerp (retval, Colour_3, GetPixel (s_Border_2, xy3).a);
      retval = lerp (retval, Colour_4, GetPixel (s_Border_2, xy4).a);

      sincos ((Amount * HALF_PI), Outline, Opacity);
      Opacity = 1.0 - sin (Opacity * HALF_PI);
   }

   if (CropEdges && Overflow (uv1)) {
      border = EMPTY;
      retval = EMPTY;
   }

   float4 Bgnd = lerp (GetPixel (s_Foreground, uv1), border, border.a * Opacity);

   return lerp (Bgnd, retval, retval.a * Outline);
}

float4 ps_main_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float Offset = (1.0 - Amount) * Displace * OFFSET;
   float Outline = 0.0, Opacity = 1.0;

   float2 xy1 = float2 (_OutputPixelWidth, _OutputPixelHeight) * Offset;
   float2 xy2 = float2 (xy1.x * X_OFFSET, (-xy1.y) * Y_OFFSET);
   float2 xy3 = uv3 - xy1;
   float2 xy4 = uv3 + xy1;

   xy1  = uv3 - xy2;
   xy2 += uv3;

   float4 border = GetPixel (s_Super, xy1);
   float4 retval = EMPTY;

   if (NotEqual (xy1, xy2)) {
      retval = GetPixel (s_Super, xy2); border = lerp (border, retval, retval.a);
      retval = GetPixel (s_Super, xy3); border = lerp (border, retval, retval.a);
      retval = GetPixel (s_Super, xy4); border = lerp (border, retval, retval.a);

      retval = Colour_1 * GetPixel (s_Border_2, xy1).a;
      retval = lerp (retval, Colour_2, GetPixel (s_Border_2, xy2).a);
      retval = lerp (retval, Colour_3, GetPixel (s_Border_2, xy3).a);
      retval = lerp (retval, Colour_4, GetPixel (s_Border_2, xy4).a);

      sincos ((Amount * HALF_PI), Outline, Opacity);
      Opacity = 1.0 - sin (Opacity * HALF_PI);
   }

   if (CropEdges && Overflow (uv2)) {
      border = EMPTY;
      retval = EMPTY;
   }

   float4 Bgnd = lerp (GetPixel (s_Background, uv2), border, border.a * Opacity);

   return lerp (Bgnd, retval, retval.a * Outline);
}

float4 ps_main_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float Offset = Amount * Displace * OFFSET;
   float Outline = 0.0, Opacity = 1.0;

   float2 xy1 = float2 (-_OutputPixelWidth, _OutputPixelHeight) * Offset;
   float2 xy2 = float2 (xy1.x * X_OFFSET, (-xy1.y) * Y_OFFSET);
   float2 xy3 = uv3 - xy1;
   float2 xy4 = uv3 + xy1;

   xy1  = uv3 - xy2;
   xy2 += uv3;

   float4 border = GetPixel (s_Super, xy1);
   float4 retval = EMPTY;

   if (NotEqual (xy1, xy2)) {
      retval = GetPixel (s_Super, xy2); border = lerp (border, retval, retval.a);
      retval = GetPixel (s_Super, xy3); border = lerp (border, retval, retval.a);
      retval = GetPixel (s_Super, xy4); border = lerp (border, retval, retval.a);

      retval = Colour_1 * GetPixel (s_Border_2, xy1).a;
      retval = lerp (retval, Colour_2, GetPixel (s_Border_2, xy2).a);
      retval = lerp (retval, Colour_3, GetPixel (s_Border_2, xy3).a);
      retval = lerp (retval, Colour_4, GetPixel (s_Border_2, xy4).a);

      sincos ((Amount * HALF_PI), Opacity, Outline);
      Opacity = 1.0 - sin (Opacity * HALF_PI);
   }

   if (CropEdges && Overflow (uv2)) {
      border = EMPTY;
      retval = EMPTY;
   }

   float4 Bgnd = lerp (GetPixel (s_Background, uv2), border, border.a * Opacity);

   return lerp (Bgnd, retval, retval.a * Outline);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Border_Kx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 < string Script = "RenderColorTarget0 = border_1;"; > ExecuteShader (ps_border_I_1)
   pass P_3 < string Script = "RenderColorTarget0 = border_2;"; > ExecuteShader (ps_border_I_2)
   pass P_4 ExecuteShader (ps_main_F)
}

technique Border_Kx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = border_1;"; > ExecuteShader (ps_border_I_1)
   pass P_3 < string Script = "RenderColorTarget0 = border_2;"; > ExecuteShader (ps_border_I_2)
   pass P_4 ExecuteShader (ps_main_I)
}

technique Border_Kx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = border_1;"; > ExecuteShader (ps_border_O_1)
   pass P_3 < string Script = "RenderColorTarget0 = border_2;"; > ExecuteShader (ps_border_O_2)
   pass P_4 ExecuteShader (ps_main_O)
}

