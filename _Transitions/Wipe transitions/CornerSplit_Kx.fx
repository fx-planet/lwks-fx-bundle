// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Corners_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Corners.mp4

/**
 This is a four-way split which moves the foreground out to the corners of the frame or moves
 it in from the corners of the frame to reveal the whole the image.  A quick way of applying a
 transition to a title without messing around too much with routing.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CornerSplit_Fx.fx
//
// This effect is a combination of two previous effects, CornerSplit_Ax and CornerSplit_Adx.
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
   string Description = "Corner split (keyed)";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Splits the foreground four ways out to or in from the corners of the frame";
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

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Super, s_Super);
DefineTarget (Horiz, s_Horizontal);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Progress";
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
   string Enum = "At start if delta key folded,At start of clip,At end of clip";
> = 1;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

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

float4 ps_horiz_I (float2 uv : TEXCOORD3) : COLOR
{
   float negAmt = Amount * 0.5;
   float posAmt = 0.5 - negAmt;

   float2 xy1 = float2 (uv.x - posAmt, uv.y);
   float2 xy2 = float2 (uv.x + posAmt, uv.y);

   posAmt += 0.5;

   return (uv.x > posAmt) ? GetPixel (s_Super, xy1)
        : (uv.x < negAmt) ? GetPixel (s_Super, xy2) : EMPTY;
}

float4 ps_horiz_O (float2 uv : TEXCOORD3) : COLOR
{
   float posAmt = Amount * 0.5;
   float negAmt = 0.5 - posAmt;

   float2 xy1 = float2 (uv.x - posAmt, uv.y);
   float2 xy2 = float2 (uv.x + posAmt, uv.y);

   posAmt += 0.5;

   return (uv.x > posAmt) ? GetPixel (s_Super, xy1)
        : (uv.x < negAmt) ? GetPixel (s_Super, xy2) : EMPTY;
}

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float negAmt = Amount * 0.5;
   float posAmt = 0.5 - negAmt;

   float2 xy1 = float2 (uv3.x, uv3.y - posAmt);
   float2 xy2 = float2 (uv3.x, uv3.y + posAmt);

   posAmt += 0.5;

   float4 Fgnd = (uv3.y > posAmt) ? GetPixel (s_Horizontal, xy1)
               : (uv3.y < negAmt) ? GetPixel (s_Horizontal, xy2) : EMPTY;

   if (CropEdges && Overflow (uv1)) Fgnd = EMPTY;

   return lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a);
}

float4 ps_main_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float negAmt = Amount * 0.5;
   float posAmt = 0.5 - negAmt;

   float2 xy1 = float2 (uv3.x, uv3.y - posAmt);
   float2 xy2 = float2 (uv3.x, uv3.y + posAmt);

   posAmt += 0.5;

   float4 Fgnd = (uv3.y > posAmt) ? GetPixel (s_Horizontal, xy1)
               : (uv3.y < negAmt) ? GetPixel (s_Horizontal, xy2) : EMPTY;

   if (CropEdges && Overflow (uv2)) Fgnd = EMPTY;

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

float4 ps_main_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float posAmt = Amount * 0.5;
   float negAmt = 0.5 - posAmt;

   float2 xy1 = float2 (uv3.x, uv3.y - posAmt);
   float2 xy2 = float2 (uv3.x, uv3.y + posAmt);

   posAmt += 0.5;

   float4 Fgnd = (uv3.y > posAmt) ? GetPixel (s_Horizontal, xy1)
               : (uv3.y < negAmt) ? GetPixel (s_Horizontal, xy2) : EMPTY;

   if (CropEdges && Overflow (uv2)) Fgnd = EMPTY;

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique CornerSplit_Kx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 < string Script = "RenderColorTarget0 = Horiz;"; > ExecuteShader (ps_horiz_I)
   pass P_3 ExecuteShader (ps_main_F)
}

technique CornerSplit_Kx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Horiz;"; > ExecuteShader (ps_horiz_I)
   pass P_3 ExecuteShader (ps_main_I)
}

technique CornerSplit_Kx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Horiz;"; > ExecuteShader (ps_horiz_O)
   pass P_3 ExecuteShader (ps_main_O)
}

