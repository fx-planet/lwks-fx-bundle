// @Maintainer jwrl
// @Released 2021-08-31
// @Author juhartik
// @AuthorEmail "juha@linearteam.org"
// @Created 2011-04-29
// @see https://www.lwks.com/media/kunena/attachments/6375/jh_stylize_vignette_640.png

/**
 A lens vignette effect created by Juha Hartikainen
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Vignette.fx
//
// Version history:
//
// Update 2021-08-31 jwrl:
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Vignette";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "A lens vignette effect created by Juha Hartikainen";
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

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Radius
<
   string Description = "Radius";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.67;                                 // Originally 1.0 - jwrl

float Amount
<
   string Description = "Amount";
   float MinVal       = -1.0;
   float MaxVal       = 1.0;
> = 1.0;                                  // Originally 0.0 - jwrl

float Hardness
<
   string Description = "Hardness";       // Originally "Softness" - jwrl
   float MinVal       = 0.5;
   float MaxVal       = 4.0;
> = 2.0;

// New parameter - jwrl

float4 Colour
<
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.69, 0.78, 0.82, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 VignettePS (float2 uv : TEXCOORD2) : COLOR
{
   float2 xy = abs (uv - 0.5.xx);

   float4 c = (max (xy.x, xy.y) > 0.5) ? EMPTY : tex2D (s_Input, uv);

   float v = length (uv - 0.5.xx) / Radius;

   // Four new lines replace the original [c.rgb += (pow (v, Softness) * Amount).xxx] to
   // support the vignette colour.  Negative values of Amount still invert colour - jwrl.

   float a = c.a;

   v = saturate (pow (v, Hardness) * abs (Amount));
   c = (Amount >= 0.0) ? lerp (c, Colour, v) : lerp (c, 1.0.xxxx - Colour, v);
   c.a = a;

   return c;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Vignette
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (VignettePS)
}

