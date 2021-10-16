// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Tiles_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Tiles.mp4

/**
 This is a transition that splits the outgoing image into tiles then blows them apart or
 materialises the incoming video from those tiles.  It's the companion to the effect
 "Tiled split (keyed)" (TiledSplit_Kx.fx).
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TiledSplit_Dx.fx
//
// Version history:
//
// Rewrite 2021-07-25 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Tiled split";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Splits the outgoing video into tiles and blows them apart or reverses that process";
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
#define BLACK float2 (0.0,1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define FACTOR 100
#define OFFSET 1.2

float _OutputAspectRatio;
float _Progress;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Overlay, s_Overlay);
DefineTarget (Tiles, s_Tiles);

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

int SetTechnique
<
   string Description = "Transition direction";
   string Enum = "Materialise from tiles,Break apart to tiles";
> = 1;

float Width
<
   string Group = "Tile size";
   string Description = "Width";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float Height
<
   string Group = "Tile size";
   string Description = "Height";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_init_I (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_Background, uv); }
float4 ps_init_O (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_Foreground, uv); }

float4 ps_horiz_I (float2 uv3 : TEXCOORD3) : COLOR
{
   float dsplc  = (OFFSET - Height) * FACTOR / _OutputAspectRatio;
   float offset = floor (uv3.y * dsplc);

   offset = ceil (frac (offset / 2.0)) * 2.0;
   offset = (1.0 - offset) * (1.0 - Amount);

   return GetPixel (s_Overlay, uv3 + float2 (offset, 0.0));
}

float4 ps_horiz_O (float2 uv3 : TEXCOORD3) : COLOR
{
   float dsplc  = (OFFSET - Height) * FACTOR / _OutputAspectRatio;
   float offset = floor (uv3.y * dsplc);

   offset = ceil (frac (offset / 2.0)) * 2.0;
   offset = (offset - 1.0) * Amount;

   return GetPixel (s_Overlay, uv3 + float2 (offset, 0.0));
}

float4 ps_main_I (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float dsplc  = (OFFSET - Width) * FACTOR;
   float offset = floor (uv3.x * dsplc);

   offset = (1.0 - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);

   float4 Fgnd = GetPixel (s_Tiles, uv3 + float2 (0.0, offset / _OutputAspectRatio));

   return lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a);
}

float4 ps_main_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float dsplc  = (OFFSET - Width) * FACTOR;
   float offset = floor (uv3.x * dsplc);

   offset  = ((ceil (frac (offset / 2.0)) * 2.0) - 1.0) * Amount;

   float4 Fgnd = GetPixel (s_Tiles, uv3 + float2 (0.0, offset / _OutputAspectRatio));

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique TiledSplit_Dx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Overlay;"; > ExecuteShader (ps_init_I)
   pass P_2 < string Script = "RenderColorTarget0 = Tiles;"; > ExecuteShader (ps_horiz_I)
   pass P_3 ExecuteShader (ps_main_I)
}

technique TiledSplit_Kx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Overlay;"; > ExecuteShader (ps_init_O)
   pass P_2 < string Script = "RenderColorTarget0 = Tiles;"; > ExecuteShader (ps_horiz_O)
   pass P_3 ExecuteShader (ps_main_O)
}

