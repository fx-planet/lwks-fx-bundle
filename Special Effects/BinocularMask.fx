// @Maintainer jwrl
// @Released 2021-10-22
// @Author jwrl
// @Created 2021-10-22
// @see https://www.lwks.com/media/kunena/attachments/6375/BinocularMask_640.png

/**
 This effect creates the classic binocular mask shape.  It can be adjusted from a simple
 circular or telescope-style effect, to separated circular masks.  The edge softness can
 be adjusted, and colour fringing can be applied to the edges as well.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BinocularMask.fx
//
// Version history:
//
// Rewrite 2021-10-22 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Binocular mask";
   string Category    = "DVE";
   string SubCategory = "Special Effects";
   string Notes       = "Creates the classic binocular effect";
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

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy
#define WHITE   1.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define FEATHER 0.05
#define CIRCLE  0.25
#define RADIUS  1.6666666667

#define CENTRE  0.5.xx

#define SIZE    3.25

#define PI      3.1415926536
#define HALF_PI 1.5707963268

float _OutputAspectRatio; 

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);
DefineTarget (Msk, s_Mask);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Size
<
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Offset
<
   string Description = "L / R offset";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Softness
<
   string Description = "Edge softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Fringing
<
   string Description = "Edge fringing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return BdrPixel (s_RawInp, uv); }

float4 ps_circle (float2 uv : TEXCOORD0) : COLOR
{
   float2 range = float2 (0.5 - uv.x - (Offset * 0.2), 0.5 - uv.y);

   float soft   = max (0.02, Softness) * FEATHER;
   float edge   = CIRCLE - soft;
   float radius = length (float2 (range.x, range.y / _OutputAspectRatio)) * RADIUS;

   soft += soft;

   return lerp (WHITE, EMPTY, saturate ((radius - edge) / soft));
}

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   float2 xy1 = (uv - CENTRE) / (Size * SIZE);
   float2 xy2 = float2 (0.5 - uv.x, uv.y - 0.5) / (Size * SIZE);

   xy1 += CENTRE;
   xy2 += CENTRE;

   float Mgrn = 1.0 - GetPixel (s_Mask, xy1).x;
   float Mred = 1.0 - GetPixel (s_Mask, xy2).x;
   float Mask = 1.0 - (Mgrn * Mred);

   Mask = lerp (1.0 - min (Mgrn, Mred), Mask, saturate (Offset * 4.0));

   Mgrn = (1.0 + sin ((Mask - 0.5) * PI)) * 0.5;
   Mred = lerp (Mask, Mgrn, Fringing);
   Mgrn = 1.0 - cos (Mgrn * HALF_PI);

   float4 retval = GetPixel (s_Input, uv);

   retval.r  *= Mred;
   retval.g  *= lerp (Mask, Mgrn, Fringing);
   retval.ba *= Mask;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique BinocularMask
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Msk;"; > ExecuteShader (ps_circle)
   pass P_3 ExecuteShader (ps_main)
}

