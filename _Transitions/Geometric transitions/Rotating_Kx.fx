// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Rotate_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Rotate.mp4

/**
 This rotates a blended foreground such as a title or image key out or in.  It's a
 combination of the functionality of two previous effects, Rotate_Ax and Rotate_Adx.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rotating_Kx.fx
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
   string Description = "Rotating trans (keyed)";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Rotates a title, image key or other blended foreground in or out";
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

int Ttype
<
   string Description = "Transition position";
   string Enum = "At start if delta key folded,At start of clip,At end of clip";
> = 1;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

int SetTechnique
<
   string Description = "Transition type";
   string Enum = "Rotate Right,Rotate Down,Rotate Left,Rotate Up";
> = 0;

float KeyGain
<
   string Description = "Key trim";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Bgnd, Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = GetPixel (s_Background, uv2);
      }
      else Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_rotate_right (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd;

   float2 xy, bgd;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
         : float2 ((uv3.x - 1.0) / (1.0 - Amount) - (Amount * 0.2) + 1.0, ((uv3.y - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv3.y) * uv3.x * sin (Amount * HALF_PI));
      Bgnd = GetPixel (s_Background, uv2);
      bgd = uv2;
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv3.y)
         : float2 ((uv3.x / Amount) - ((1.0 - Amount) * 0.2), ((uv3.y - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv3.y) * uv3.x * cos (Amount * HALF_PI));

      if (Ttype == 0) {
         Bgnd = GetPixel (s_Foreground, uv1);
         bgd = uv1;
      }
      else {
         Bgnd = GetPixel (s_Background, uv2);
         bgd = uv2;
      }
   }

   float4 Fgnd = (CropEdges && Overflow (bgd)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_rotate_down (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd;

   float2 xy, bgd;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
         : float2 (((uv3.x - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv3.x) * uv3.y * sin (Amount * HALF_PI), (uv3.y - 1.0) / (1.0 - Amount) - (Amount * 0.2) + 1.0);
      Bgnd = GetPixel (s_Background, uv2);
      bgd = uv2;
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv3.y)
         : float2 (((uv3.x - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv3.x) * uv3.y * cos (Amount * HALF_PI), (uv3.y / Amount) - ((1.0 - Amount) * 0.2));

      if (Ttype == 0) {
         Bgnd = GetPixel (s_Foreground, uv1);
         bgd = uv1;
      }
      else {
         Bgnd = GetPixel (s_Background, uv2);
         bgd = uv2;
      }
   }

   float4 Fgnd = (CropEdges && Overflow (bgd)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_rotate_left (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd;

   float2 xy, bgd;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
         : float2 (uv3.x / (1.0 - Amount) + (Amount * 0.2), ((uv3.y - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv3.y) * (1.0 - uv3.x) * sin (Amount * HALF_PI));
      Bgnd = GetPixel (s_Background, uv2);
      bgd = uv2;
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv3.y)
         : float2 ((uv3.x - 1.0) / Amount + 1.0 + ((1.0 - Amount) * 0.2), ((uv3.y - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv3.y) * (1.0 - uv3.x) * cos (Amount * HALF_PI));

      if (Ttype == 0) {
         Bgnd = GetPixel (s_Foreground, uv1);
         bgd = uv1;
      }
      else {
         Bgnd = GetPixel (s_Background, uv2);
         bgd = uv2;
      }
   }

   float4 Fgnd = (CropEdges && Overflow (bgd)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_rotate_up (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd;

   float2 xy, bgd;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
         : float2 (((uv3.x - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv3.x) * (1.0 - uv3.y) * sin (Amount * HALF_PI), uv3.y / (1.0 - Amount) + (Amount * 0.2));
      Bgnd = GetPixel (s_Background, uv2);
      bgd = uv2;
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv3.y)
         : float2 (((uv3.x - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv3.x) * (1.0 - uv3.y) * cos (Amount * HALF_PI), (uv3.y - 1.0) / Amount + 1.0 + ((1.0 - Amount) * 0.2));

      if (Ttype == 0) {
         Bgnd = GetPixel (s_Foreground, uv1);
         bgd = uv1;
      }
      else {
         Bgnd = GetPixel (s_Background, uv2);
         bgd = uv2;
      }
   }

   float4 Fgnd = (CropEdges && Overflow (bgd)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Rotating_Kx_right
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_rotate_right)
}

technique Rotating_Kx_down
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_rotate_down)
}

technique Rotating_Kx_left
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_rotate_left)
}

technique Rotating_Kx_up
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_rotate_up)
}

