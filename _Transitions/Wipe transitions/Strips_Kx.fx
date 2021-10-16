// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Strips_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Strips.mp4

/**
 A transition that splits a blended foreground image into strips and compresses it to zero
 height.  The vertical centring can be adjusted so that the collapse is symmetrical or
 asymmetrical.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Strips_Kx.fx
//
// This effect is a combination of two previous effects, Strips_Ax and Strips_Adx.
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
   string Description = "Strips (keyed)";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Splits the foreground into strips and compresses it to zero height";
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

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define HEIGHT   20.0

#define PI       3.1415926536
#define HALF_PI  1.5707963268

float _Progress;

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
   string Enum = "At start if delta key folded,At start of clip,At end of clip";
> = 1;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

float Spacing
<
   string Group = "Strips";
   string Description = "Spacing";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float Spread
<
   string Group = "Strips";
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreX
<
   string Group = "Strips";
   string Description = "Centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreY
<
   string Group = "Strips";
   string Description = "Centre";
   string Flags = "SpecifiesPointY";
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

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount   = 1.0 - Amount;
   float Width    = 10.0 + (Spacing * 40.0);
   float centre_X = 1.0 - (2.0 * centreX);
   float centre_Y = 1.0 - centreY;
   float offset   = sin (Width * uv3.y * PI);
   float Height   = 1.0 + ((1.0 - cos (amount * HALF_PI)) * HEIGHT);

   if (abs (offset) > 0.5) offset = -offset;

   offset = ((floor (offset * 5.2) / 5.0) + centre_X) * amount;

   float2 xy = uv3 + float2 (offset, -centre_Y);

   offset *= 2.0 * Spread;
   xy.y = (xy.y * Height) + offset + centre_Y;

   float4 Fgnd = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount   = 1.0 - Amount;
   float Width    = 10.0 + (Spacing * 40.0);
   float centre_X = 1.0 - (2.0 * centreX);
   float centre_Y = 1.0 - centreY;
   float offset   = sin (Width * uv3.y * PI);
   float Height   = 1.0 + ((1.0 - cos (amount * HALF_PI)) * HEIGHT);

   if (abs (offset) > 0.5) offset = -offset;

   offset = ((floor (offset * 5.2) / 5.0) + centre_X) * amount;

   float2 xy = uv3 + float2 (offset, -centre_Y);

   offset *= 2.0 * Spread;
   xy.y = (xy.y * Height) + offset + centre_Y;

   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount   = 1.0 - Amount;
   float Width    = 10.0 + (Spacing * 40.0);
   float centre_X = 1.0 - (2.0 * centreX);
   float centre_Y = 1.0 - centreY;
   float offset   = sin (Width * uv3.y * PI);
   float Height   = 1.0 + ((1.0 - cos (Amount * HALF_PI)) * HEIGHT);

   if (abs (offset) > 0.5) offset = -offset;

   offset = ((floor (offset * 5.2) / 5.0) + centre_X) * Amount;

   float2 xy = uv3 + float2 (offset, -centre_Y);

   offset *= 2.0 * Spread;
   xy.y = (xy.y * Height) + offset + centre_Y;

   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Strips_Kx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 ExecuteShader (ps_main_F)
}

technique Strips_Kx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_I)
}

technique Strips_Kx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_O)
}

