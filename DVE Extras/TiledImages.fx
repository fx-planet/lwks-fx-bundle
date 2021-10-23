// @Maintainer jwrl
// @Released 2021-09-17
// @Author windsturm
// @Created 2012-05-12
// @see https://www.lwks.com/media/kunena/attachments/6375/FxTile_640.png

/**
 This effect tiles an image and rotates those tiles to create abstract backgrounds.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TiledImages.fx
//
//------------------------------- Original author's header --------------------------------//
//
// FxTile.
// Tiling and Rotation effect.
// 
// @param <threshold> The granularity of the tiling parameters
// @param <angle> Rotation parameters of the screen
// @author Windsturm
// @version 1.0
// @see <a href="http://kuramo.ch/webgl/videoeffects/">WebGL Video Effects Demo</a>
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Update 2021-09-17 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 2020-04-12:
// Various compatibility updates.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Tiled images";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "Creates tile patterns from the image, which can be rotated";
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

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

DefineTarget (t0, s0);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float threshold
<
   string Description = "Threshold";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

float angle
<
   string Description = "Angle";
   float MinVal = 0.00;
   float MaxVal = 360.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Pixel Shader
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Input, uv); }

float4 FxRotateTile (float2 uv : TEXCOORD2) : COLOR
{
   float Tcos, Tsin;

   if (threshold >= 1.0) return float2 (0.5, 1.0).xxxy;

   float2 xy = uv - 0.5.xx;

   //rotation

   float2 angXY = float2 (xy.x, xy.y / _OutputAspectRatio);

   sincos (radians (angle), Tsin, Tcos);

   float temp = (angXY.x * Tcos - angXY.y * Tsin) + 0.5;

   angXY.y = ((angXY.x * Tsin + angXY.y * Tcos) * _OutputAspectRatio ) + 0.5;
   angXY.x = temp;

   // tiling

   return tex2D (s0, frac ((angXY - 0.5.xx) / (1.0 - threshold) + 0.5.xx));
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass P_0 < string Script = "RenderColorTarget0 = t0;"; > ExecuteShader (ps_initInp)
   pass SinglePass ExecuteShader (FxRotateTile)
}

