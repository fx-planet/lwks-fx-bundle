// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Squeeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Squeeze.mp4

/**
 This mimics the Lightworks squeeze effect but fades delta keys in or out.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Squeeze_Fx.fx
//
// This effect is a combination of two previous effects, Squeeze_Ax and Squeeze_Adx.
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
   string Description = "Squeeze transition (keyed)";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Mimics the Lightworks squeeze effect with the blended foreground";
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

int SetTechnique
<
   string Description = "Type";
   string Enum = "Squeeze Right,Squeeze Down,Squeeze Left,Squeeze Up";
> = 0;

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

float4 ps_squeeze_right (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd, Fgnd;

   float2 xy;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
                           : float2 ((uv3.x - 1.0) / (1.0 - Amount) + 1.0, uv3.y);
   }
   else xy = (Amount == 0.0) ? float2 (2.0, uv3.y) : float2 (uv3.x / Amount, uv3.y);

   if (Ttype == 0) {
      Bgnd = GetPixel (s_Foreground, uv1);
      Fgnd = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Super, xy);
   }
   else {
      Bgnd = GetPixel (s_Background, uv2);
      Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_squeeze_left (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd, Fgnd;

   float2 xy;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y) : float2 (uv3.x  / (1.0 - Amount), uv3.y);
   }
   else xy = (Amount == 0.0) ? float2 (2.0, uv3.y) : float2 ((uv3.x - 1.0) / Amount + 1.0, uv3.y);

   if (Ttype == 0) {
      Bgnd = GetPixel (s_Foreground, uv1);
      Fgnd = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Super, xy);
   }
   else {
      Bgnd = GetPixel (s_Background, uv2);
      Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_squeeze_down (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd, Fgnd;

   float2 xy;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, (uv3.y - 1.0) / (1.0 - Amount) + 1.0);
   }
   else xy = (Amount == 0.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, uv3.y / Amount);

   if (Ttype == 0) {
      Bgnd = GetPixel (s_Foreground, uv1);
      Fgnd = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Super, xy);
   }
   else {
      Bgnd = GetPixel (s_Background, uv2);
      Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_squeeze_up (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd, Fgnd;

   float2 xy;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, uv3.y  / (1.0 - Amount));
   }
   else xy = (Amount == 0.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, (uv3.y - 1.0) / Amount + 1.0);

   if (Ttype == 0) {
      Bgnd = GetPixel (s_Foreground, uv1);
      Fgnd = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Super, xy);
   }
   else {
      Bgnd = GetPixel (s_Background, uv2);
      Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Squeeze_Fx_right
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_squeeze_right)
}

technique Squeeze_Fx_down
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_squeeze_down)
}

technique Squeeze_Fx_left
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_squeeze_left)
}

technique Squeeze_Fx_up
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_squeeze_up)
}

