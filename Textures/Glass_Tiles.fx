// @Maintainer jwrl
// @Released 2021-10-29
// @Author khaver
// @Created 2011-06-10
// @see https://www.lwks.com/media/kunena/attachments/6375/GlassTiles_2018.png
// @see https://www.youtube.com/watch?v=O55QTV0gjmQ

/**
 Breaks the image into glass tiles.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Glass_Tiles.fx
//
// Version history:
//
// Update 2021-10-29 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Glass Tiles";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "Breaks the image into glass tiles";
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

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Input and shader
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Tiles
<
   string Description = "Tiles";
   float MinVal       = 0.0f;
   float MaxVal       = 200.0;
> = 15.0; // Default value

float BevelWidth
<
   string Description = "Bevel Width";
   float MinVal       = 0.0f;
   float MaxVal       = 200.0;
> = 15.0; // Default value

float Offset
<
   string Description = "Offset";
   float MinVal       = 0.0f;
   float MaxVal       = 200.0;
> = 0.0; // Default value

float4 GroutColor
<
   string Description = "Grout Color";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 0.0, 0.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 GtilesPS (float2 uv : TEXCOORD2) : COLOR
{
   float2 newUV1 = uv + tan ((Tiles * 2.5) * (uv - 0.5) + Offset) * (BevelWidth / _OutputWidth);

   return Overflow (newUV1) ? float4 (GroutColor.rgb, 1.0) : tex2D (s_Input, newUV1);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (GtilesPS)
}

