// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Split_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Split.mp4

/**
 This is really the classic barn door effect, but since a wipe with that name already exists
 in Lightworks another name had to be found.  This version moves the separated foreground
 halves apart rather than just wipes them off.
*/

//-----------------------------------------------------------------------------------------//
// User effect BarnDoorSplit_Kx.fx
//
// This effect is a combination of two previous effects, BarndoorSplit_Ax and
// BarndoorSplit_Adx.
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
   string Description = "Barn door split (keyed)";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Splits the foreground and separates the halves horizontally or vertically";
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

float4 ps_horiz_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float range = (1.0 - Amount) * max (Split, 1.0 - Split);

   float2 xy2 = float2 (range, 0.0);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Fgd = ((xy1.x < Split) && (xy2.x > Split)) ? EMPTY
              : (uv3.x > Split) ? GetPixel (s_Super, xy1) : GetPixel (s_Super, xy2);

   if (CropEdges && Overflow (uv1)) Fgd = EMPTY;

   return lerp (GetPixel (s_Foreground, uv1), Fgd, Fgd.a);
}

float4 ps_vert_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float split = 1.0 - Split;
   float range = (1.0 - Amount) * max (Split, split);

   float2 xy2 = float2 (0.0, range);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Fgd = ((xy1.y < split) && (xy2.y > split)) ? EMPTY
              : (uv3.y > split) ? GetPixel (s_Super, xy1) : GetPixel (s_Super, xy2);

   if (CropEdges && Overflow (uv1)) Fgd = EMPTY;

   return lerp (GetPixel (s_Foreground, uv1), Fgd, Fgd.a);
}

float4 ps_horiz_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float range = (1.0 - Amount) * max (Split, 1.0 - Split);

   float2 xy2 = float2 (range, 0.0);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Fgd = ((xy1.x < Split) && (xy2.x > Split)) ? EMPTY
              : (uv3.x > Split) ? GetPixel (s_Super, xy1) : GetPixel (s_Super, xy2);

   if (CropEdges && Overflow (uv2)) Fgd = EMPTY;

   return lerp (GetPixel (s_Background, uv2), Fgd, Fgd.a);
}

float4 ps_horiz_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float range = Amount * max (Split, 1.0 - Split);

   float2 xy2 = float2 (range, 0.0);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Fgd = ((xy1.x < Split) && (xy2.x > Split)) ? EMPTY
              : (uv3.x > Split) ? GetPixel (s_Super, xy1) : GetPixel (s_Super, xy2);

   if (CropEdges && Overflow (uv2)) Fgd = EMPTY;

   return lerp (GetPixel (s_Background, uv2), Fgd, Fgd.a);
}

float4 ps_vert_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float split = 1.0 - Split;
   float range = (1.0 - Amount) * max (Split, split);

   float2 xy2 = float2 (0.0, range);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Fgd = ((xy1.y < split) && (xy2.y > split)) ? EMPTY
              : (uv3.y > split) ? GetPixel (s_Super, xy1) : GetPixel (s_Super, xy2);

   if (CropEdges && Overflow (uv2)) Fgd = EMPTY;

   return lerp (GetPixel (s_Background, uv2), Fgd, Fgd.a);
}

float4 ps_vert_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float split = 1.0 - Split;
   float range = Amount * max (Split, split);

   float2 xy2 = float2 (0.0, range);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Fgd = ((xy1.y < split) && (xy2.y > split)) ? EMPTY
              : (uv3.y > split) ? GetPixel (s_Super, xy1) : GetPixel (s_Super, xy2);

   if (CropEdges && Overflow (uv2)) Fgd = EMPTY;

   return lerp (GetPixel (s_Background, uv2), Fgd, Fgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Hsplit_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 ExecuteShader (ps_horiz_F)
}

technique Vsplit_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 ExecuteShader (ps_vert_F)
}

technique Hsplit_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_horiz_I)
}

technique Hsplit_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_horiz_O)
}

technique Vsplit_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_vert_I)
}

technique Vsplit_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_vert_O)
}

