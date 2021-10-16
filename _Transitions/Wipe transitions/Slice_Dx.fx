// @Maintainer jwrl
// @Released 2021-07-27
// @Author jwrl
// @Created 2021-07-27
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Slice_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Slice.mp4

/**
 This transition splits the outgoing image into strips which then move off either
 horizontally or vertically to reveal the incoming image.  This updated version adds
 the ability to choose whether to wipe the outgoing image out or the incoming image in.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Slice_Dx.fx
//
// Version history:
//
// Rewrite 2021-07-27 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Slice transition";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Separates and splits the image into strips which move on or off horizontally or vertically";
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
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

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

int Mode
<
   string Description = "Strip type";
   string Enum = "Mode A,Mode B";
> = 0;

int SetTechnique
<
   string Description = "Strip direction";
   string Enum = "Right to left,Left to right,Top to bottom,Bottom to top";
> = 1;

bool Direction
<
   string Description = "Invert direction";
> = false;

float StripNumber
<
   string Description = "Strip number";
   float MinVal = 5.0;
   float MaxVal = 20.0;
> = 10.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These two shaders are used to convert the sampler texture coordinates to sequence
// texture coordinates.  This ensures that the wipe calculations aren't affected by
// varying input sizes.

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_right (float2 uv : TEXCOORD3) : COLOR
{
   float strips   = max (2.0, round (StripNumber));
   float amount_0 = Direction ? 1.0 - Amount : Amount;
   float amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
   float amount_2 = pow (amount_0, 3.0);

   float2 xy = uv;

   xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_1) + amount_2
                       : (ceil ((1.0 - xy.y) * strips) * amount_1) + amount_2;

   if (Direction)
      return (Overflow (xy)) ? tex2D (s_Foreground, uv) : tex2D (s_Background, xy);

   return (Overflow (xy)) ? tex2D (s_Background, uv) : tex2D (s_Foreground, xy);
}

float4 ps_left (float2 uv : TEXCOORD3) : COLOR
{
   float strips   = max (2.0, round (StripNumber));
   float amount_0 = Direction ? 1.0 - Amount : Amount;
   float amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
   float amount_2 = pow (amount_0, 3.0);

   float2 xy = uv;

   xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_1) + amount_2
                       : (ceil ((1.0 - xy.y) * strips) * amount_1) + amount_2;

   if (Direction)
      return (Overflow (xy)) ? tex2D (s_Foreground, uv) : tex2D (s_Background, xy);

   return (Overflow (xy)) ? tex2D (s_Background, uv) : tex2D (s_Foreground, xy);
}

float4 ps_top (float2 uv : TEXCOORD3) : COLOR
{
   float strips   = max (2.0, round (StripNumber));
   float amount_0 = Direction ? 1.0 - Amount : Amount;
   float amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
   float amount_2 = pow (amount_0, 3.0);

   float2 xy = uv;

   xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_1) + amount_2
                       : (ceil ((1.0 - xy.x) * strips) * amount_1) + amount_2;

   if (Direction)
      return (Overflow (xy)) ? tex2D (s_Foreground, uv) : tex2D (s_Background, xy);

   return (Overflow (xy)) ? tex2D (s_Background, uv) : tex2D (s_Foreground, xy);
}

float4 ps_bottom (float2 uv : TEXCOORD3) : COLOR
{
   float strips   = max (2.0, round (StripNumber));
   float amount_0 = Direction ? 1.0 - Amount : Amount;
   float amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
   float amount_2 = pow (amount_0, 3.0);

   float2 xy = uv;

   xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_1) + amount_2
                       : (ceil ((1.0 - xy.x) * strips) * amount_1) + amount_2;

   if (Direction)
      return (Overflow (xy)) ? tex2D (s_Foreground, uv) : tex2D (s_Background, xy);

   return (Overflow (xy)) ? tex2D (s_Background, uv) : tex2D (s_Foreground, xy);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Slice_Dx_Left
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_right)
}

technique Slice_Dx_Right
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_left)
}

technique Slice_Dx_Top
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_top)
}

technique Slice_Dx_Bottom
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_bottom)
}

