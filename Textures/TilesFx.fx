// @Maintainer jwrl
// @Released 2021-10-29
// @Author khaver
// @Created 2011-04-28
// @see https://www.lwks.com/media/kunena/attachments/6375/Tiles_640.png

/**
 Tiles breaks the image up into adjustable tiles of solid colour.  It's like a mosaic
 effect but has adjustable bevelled edges as well.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TilesFx.fx
//
// Version history:
//
// Update 2021-10-29 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Tiles";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "Breaks the image up into adjustable solid colour tiles with bevelled edges";
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
// Inputs and shaders
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Size
<
   string Description = "Size";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.05; // Default value

float Threshhold
<
   string Description = "Edge Width";
   float MinVal       = 0.0;
   float MaxVal       = 2.0;
> = 0.15; // Default value

float4 EdgeColor
<
   string Description = "Color";
   bool SupportsAlpha = false;
> = { 0.7, 0.7, 0.7, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 tilesPS (float2 xy : TEXCOORD2) : COLOR
{
   if (Size <= 0.0) return tex2D (s_Input, xy);

   float threshholdB = 1.0 - Threshhold;

   float2 Pbase = xy - fmod (xy, Size.xx);
   float2 PCenter = Pbase + (Size / 2.0).xx;
   float2 st = (xy - Pbase) / Size;

   float3 cTop = 0.0.xxx;
   float3 cBottom = 0.0.xxx;
   float3 invOff = 1.0.xxx - EdgeColor.rgb;

   if ((st.x > st.y) && any (st > threshholdB)) { cTop = invOff; }

   if ((st.x > st.y) && any (st < Threshhold)) { cBottom = invOff; }

   float4 tileColor = tex2D (s_Input, PCenter);

   return float4 (max (0.0.xxx, (tileColor.rgb + cBottom - cTop)), tileColor.a);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (tilesPS)
}

