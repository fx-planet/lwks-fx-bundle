// @Maintainer jwrl
// @Released 2021-10-19
// @Author jwrl
// @Created 2021-10-19
// @see https://www.lwks.com/media/kunena/attachments/6375/Mirrors_640.png

/**
 Mirrors creates mirrored halves of the frame for title sequences.  The mirroring can be
 vertical or horizontal, and the mirror point/wipe centre can be moved to vary the effect.
 The image can also be scaled and positioned to control the area mirrored.

 Any black areas visible outside the active picture area are transparent, and can be
 blended with other effects to add complexity.

 There is a more complex version of this effect available, which adds the ability to rotate
 and flip the image. It's called Rosehaven.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Mirrors.fx
//
// Version history:
//
// Updated 2021-10-19 jwrl.
// Added CanSize switch for LW 2021 support.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Mirrors";
   string Category    = "DVE";
   string SubCategory = "Simple tools";
   string Notes       = "Creates mirrored top/bottom or left/right images.";
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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY  0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

DefineTarget (Img, s_Image);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Group = "Mirror settings";
   string Description = "Orientation";
   string Enum = "Horizontal,Vertical";
> = 1;

float Centre
<
   string Group = "Mirror settings";
   string Description = "Axis position";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

float Scale
<
   string Group = "Input image";
   string Description = "Scale";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.25;
   float MaxVal = 4.0;
> = 1.0;

float PosX
<
   string Group = "Input image";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosY
<
   string Group = "Input image";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_scale (float2 uv : TEXCOORD1) : COLOR
{
   return GetPixel (s_Input, (uv - float2 (PosX, 1.0 - PosY)) / max (0.25, Scale) + 0.5.xx);
}

float4 ps_main_H (float2 uv : TEXCOORD2) : COLOR
{
   return GetPixel (s_Image, abs (uv - float2 (Centre, 0.0)));
}

float4 ps_main_V (float2 uv : TEXCOORD2) : COLOR
{
   return GetPixel (s_Image, abs (uv - float2 (0.0, Centre)));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Mirrors_H
{
   pass P_1 < string Script = "RenderColorTarget0 = Img;"; > ExecuteShader (ps_scale)
   pass P_2 ExecuteShader (ps_main_H)
}

technique Mirrors_V
{
   pass P_1 < string Script = "RenderColorTarget0 = Img;"; > ExecuteShader (ps_scale)
   pass P_2 ExecuteShader (ps_main_V)
}

