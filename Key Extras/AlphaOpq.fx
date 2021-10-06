// @Maintainer jwrl
// @Released 2021-10-06
// @Author jwrl
// @Created 2021-10-06
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaOpq_640.png

/**
 This simple effect turns the alpha channel of a clip fully on, making it opaque.  There
 are two modes available - the first simply turns the alpha on, the second adds a flat
 background colour where previously the clip was transparent.  The default colour used
 is black, and the image can be unpremultiplied in this mode if desired.

 A means of boosting alpha before processing to support clips such as Lightworks titles
 has also been included.  This only functions when the background is being replaced.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AlphaOpq.fx
//
// Version history:
//
// Rewrite 2021-10-06 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha opaque";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "Makes a transparent image or title completely opaque";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Opacity mode";
   string Enum = "Make opaque,Blend with colour";
> = 0;

int KeyMode
<
   string Description = "Type of alpha channel";
   string Enum = "Standard,Premultiplied,Lightworks title effects";
> = 0;

float4 Colour
<
   string Description = "Background colour";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.0, 0.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_0 (float2 uv : TEXCOORD1) : COLOR
{
   return float4 (GetPixel (s_Input, uv).rgb, 1.0);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = GetPixel (s_Input, uv);

   if (KeyMode == 2) Fgd.a = pow (Fgd.a, 0.5);
   if (KeyMode > 0) Fgd.rgb /= Fgd.a;

   return float4 (lerp (Colour.rgb, Fgd.rgb, Fgd.a), 1.0);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique AlphaOpq_0 { pass P_1 ExecuteShader (ps_main_0) }

technique AlphaOpq_1 { pass P_1 ExecuteShader (ps_main_1) }

