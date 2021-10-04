// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Stretch_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Stretch.mp4

/**
 This effect stretches the blended foreground horizontally or vertically to transition in
 or out.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Stretch_Fx.fx
//
// This effect is a combination of two previous effects, Stretch_Ax and Stretch_Adx.
//
// Version history:
//
// Rewrite 2021-07-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Stretch transition (keyed)";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Stretches the foreground horizontally or vertically to reveal or remove it";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY)  (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow (XY) ? EMPTY : tex2D (SHADER, XY))

#define CENTRE  0.5.xx

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Super, s_Super);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Source
<
   string Description = "Source";
   string Enum = "Extracted foreground (delta key),Crawl/Roll/Title/Image key,Video/External image";
> = 0;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "H start (delta folded),V start (delta folded),At start (horizontal),At end (horizontal),At start (vertical),At end (vertical)";
> = 2;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

float Stretch
<
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

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

float4 ps_horiz_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y = lerp (xy.y, distort, stretch);

   float4 Fgnd = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Super, xy + CENTRE);

   return lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a * Amount);
}

float4 ps_vert_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);

   float4 Fgnd = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Super, xy + CENTRE);

   return lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a * Amount);
}

float4 ps_horiz_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y = lerp (xy.y, distort, stretch);

   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy + CENTRE);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * Amount);
}

float4 ps_horiz_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * Amount;
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y  = lerp (xy.y, distort, stretch);

   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy + CENTRE);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * (1.0 - Amount));
}

float4 ps_vert_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);

   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy + CENTRE);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * Amount);
}

float4 ps_vert_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * Amount;
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x  = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);

   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy + CENTRE);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Hstretch_Fx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 ExecuteShader (ps_horiz_F)
}

technique Vstretch_Fx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 ExecuteShader (ps_vert_F)
}

technique Hstretch_Fx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_horiz_I)
}

technique Hstretch_Fx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_horiz_O)
}

technique Vstretch_Fx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_vert_I)
}

technique Vstretch_Fx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_vert_O)
}

