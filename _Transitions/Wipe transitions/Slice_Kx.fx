// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Slice_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Slice.mp4

/**
 This transition splits a blended foreground image into strips which then move off
 either horizontally or vertically to reveal the incoming image.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Slice_Kx.fx
//
// This effect is a combination of two previous effects, Slice_Ax and Slice_Adx.
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
   string Description = "Slice transition (keyed)";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Splits the foreground into strips which move on or off horizontally or vertically";
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
   string Description = "Strip direction";
   string Enum = "Right to left,Left to right,Top to bottom,Bottom to top";
> = 1;

int Mode
<
   string Description = "Strip type";
   string Enum = "Mode A,Mode B";
> = 0;

float StripNumber
<
   string Description = "Strip number";
   float MinVal = 10.0;
   float MaxVal = 50.0;
> = 20.0;

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

float4 ps_left (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd;

   float2 bgd, xy = uv3;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 2) {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
   }
   else {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
   }

   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = GetPixel (s_Foreground, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = GetPixel (s_Background, uv2);
   }

   float4 Fgnd = (CropEdges && Overflow (bgd)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_right (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd;

   float2 bgd, xy = uv3;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 2) {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
      Bgnd = GetPixel (s_Background, uv2);
   }
   else {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
      Bgnd = (Ttype == 0) ? GetPixel (s_Foreground, uv1) : GetPixel (s_Background, uv2);
   }

   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = GetPixel (s_Foreground, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = GetPixel (s_Background, uv2);
   }

   float4 Fgnd = (CropEdges && Overflow (bgd)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_top (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd;

   float2 bgd, xy = uv3;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 2) {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      Bgnd = GetPixel (s_Background, uv2);
   }
   else {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      Bgnd = (Ttype == 0) ? GetPixel (s_Foreground, uv1) : GetPixel (s_Background, uv2);
   }

   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = GetPixel (s_Foreground, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = GetPixel (s_Background, uv2);
   }

   float4 Fgnd = (CropEdges && Overflow (bgd)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_bottom  (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd;

   float2 bgd, xy = uv3;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 2) {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      Bgnd = GetPixel (s_Background, uv2);
   }
   else {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      Bgnd = (Ttype == 0) ? GetPixel (s_Foreground, uv1) : GetPixel (s_Background, uv2);
   }

   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = GetPixel (s_Foreground, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = GetPixel (s_Background, uv2);
   }

   float4 Fgnd = (CropEdges && Overflow (bgd)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Slice_Kx_Left
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_left)
}

technique Slice_Kx_Right
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_right)
}

technique Slice_Kx_Top
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_top)
}

technique Slice_Kx_Bottom
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_bottom)
}

