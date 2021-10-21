// @Maintainer jwrl
// @Released 2020-11-14
// @Author jwrl
// @Created 2021-10-21
// @see https://www.lwks.com/media/kunena/attachments/6375/VisualMatte_640.png

/**
 This just a simple crop and matte effect engineered so that it can be set visually by
 dragging on-screen pins.  There is no bordering or feathering of the edges and the
 background matte is just a plain flat colour.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VisualMatte.fx
//
// Version history:
//
// Rewrite 2021-10-21 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Visual matte";
   string Category    = "DVE";
   string SubCategory = "Simple visual tools";
   string Notes       = "A simple crop tool that can be set up visually over a flat colour background.";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define inRange(XY,MIN,MAX) (all (XY >= MIN) && all (XY <= MAX))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float4 Colour
<
   string Group = "Background";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.15, 0.12, 0.75, 1.0 };

float CropLeft
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = 0.01;
   float MaxVal = 0.99;
> = 0.01;

float CropTop
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = 0.01;
   float MaxVal = 0.99;
> = 0.99;

float CropRight
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = 0.01;
   float MaxVal = 0.99;
> = 0.99;

float CropBottom
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = 0.01;
   float MaxVal = 0.99;
> = 0.01;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR
{
   return Overflow (uv) ? Colour : tex2D (s_RawInp, uv);
}

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   float2 xy1 = saturate (float2 (CropLeft - 0.01, 0.99 - CropTop) * 1.02041);
   float2 xy2 = saturate (float2 (CropRight - 0.01, 0.99 - CropBottom) * 1.02041);

   if (inRange (uv, xy1, xy2)) return tex2D (s_Input, uv);

   return Colour;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique VisualMatte
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main)
}

