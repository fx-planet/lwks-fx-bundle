// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_SplitSqueeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_SplitSqueeze.mp4

/**
 This is similar to the split squeeze effect, customised to suit its use with blended
 effects.  It moves the separated foreground image halves apart and squeezes them to
 the edges of the screen or expands the halves from the edges.  It can operate either
 vertically or horizontally depending on the user setting.
*/

//-----------------------------------------------------------------------------------------//
// User effect BarndoorSqueeze_Fx.fx
//
// This effect is a combination of two previous effects, BarndoorSqueeze_Ax and
// BarndoorSqueeze_Adx.
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
   string Description = "Barn door squeeze (keyed)";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Splits the foreground and squeezes the halves apart horizontally or vertically";
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
   string Enum = "H start (delta folded),V start (delta folded),At start (horizontal),At end (horizontal),At start (vertical),At end (vertical)";
> = 2;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

float Split
<
   string Description = "Split centre";
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

float4 ps_expand_Hf (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = Amount - 1.0;
   float negAmt = Amount * Split;
   float posAmt = 1.0 - (Amount * (1.0 - Split));

   float4 Fgnd = (uv3.x > posAmt) ? tex2D (s_Super, float2 ((uv3.x + amount) / Amount, uv3.y))
               : (uv3.x < negAmt) ? tex2D (s_Super, float2 (uv3.x / Amount, uv3.y)) : EMPTY;

   if (CropEdges && Overflow (uv1)) Fgnd = EMPTY;

   return lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a);
}

float4 ps_expand_Vf (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = Amount - 1.0;
   float negAmt = Amount * (1.0 - Split);
   float posAmt = 1.0 - (Amount * Split);

   float4 Fgnd = (uv3.y > posAmt) ? tex2D (s_Super, float2 (uv3.x, (uv3.y + amount) / Amount))
               : (uv3.y < negAmt) ? tex2D (s_Super, float2 (uv3.x, uv3.y / Amount)) : EMPTY;

   if (CropEdges && Overflow (uv1)) Fgnd = EMPTY;

   return lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a);
}

float4 ps_squeeze_H (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = 1.0 - Amount;
   float negAmt = amount * Split;
   float posAmt = 1.0 - (amount * (1.0 - Split));

   float4 Fgnd = (uv3.x > posAmt) ? tex2D (s_Super, float2 ((uv3.x - Amount) / amount, uv3.y))
               : (uv3.x < negAmt) ? tex2D (s_Super, float2 (uv3.x / amount, uv3.y)) : EMPTY;

   if (CropEdges && Overflow (uv2)) Fgnd = EMPTY;

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

float4 ps_squeeze_V (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = 1.0 - Amount;
   float negAmt = amount * (1.0 - Split);
   float posAmt = 1.0 - (amount * Split);

   float4 Fgnd = (uv3.y > posAmt) ? tex2D (s_Super, float2 (uv3.x, (uv3.y - Amount) / amount))
               : (uv3.y < negAmt) ? tex2D (s_Super, float2 (uv3.x, uv3.y / amount)) : EMPTY;

   if (CropEdges && Overflow (uv2)) Fgnd = EMPTY;

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

float4 ps_expand_H (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = Amount - 1.0;
   float negAmt = Amount * Split;
   float posAmt = 1.0 - (Amount * (1.0 - Split));

   float4 Fgnd = (uv3.x > posAmt) ? tex2D (s_Super, float2 ((uv3.x + amount) / Amount, uv3.y))
               : (uv3.x < negAmt) ? tex2D (s_Super, float2 (uv3.x / Amount, uv3.y)) : EMPTY;

   if (CropEdges && Overflow (uv2)) Fgnd = EMPTY;

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

float4 ps_expand_V (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = Amount - 1.0;
   float negAmt = Amount * (1.0 - Split);
   float posAmt = 1.0 - (Amount * Split);

   float4 Fgnd = (uv3.y > posAmt) ? tex2D (s_Super, float2 (uv3.x, (uv3.y + amount) / Amount))
               : (uv3.y < negAmt) ? tex2D (s_Super, float2 (uv3.x, uv3.y / Amount)) : EMPTY;

   if (CropEdges && Overflow (uv2)) Fgnd = EMPTY;

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Expand_Hf
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 ExecuteShader (ps_expand_Hf)
}

technique Expand_Vf
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 ExecuteShader (ps_expand_Vf)
}

technique Expand_H
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_expand_H)
}

technique Squeeze_H
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_squeeze_H)
}

technique Expand_V
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_expand_V)
}

technique Squeeze_V
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_squeeze_V)
}

