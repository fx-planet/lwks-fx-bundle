// @Maintainer jwrl
// @Released 2020-09-27
// @Author jwrl
// @Created 2016-01-22
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Blocks_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/BlockDissolve.mp4

/**
 This effect starts off by building blocks from the outgoing image for the first third of
 the effect, then dissolves to the new image for the next third, then loses the blocks
 over the remainder of the effect.

 It's based on the Lightworks mosaic and mix effects, but some settings have been changed.
 It is compatible with both compiler versions used to compile Lightworks effects.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Blocks_Dx.fx
//
// Version history:
//
// Update 2020-09-27 jwrl.
// Revised header block.
//
// Modified 2020-07-31 jwrl.
// Corrected potential divide by zero bug.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
// Changed "Fgd" input to "Fg" and "Bgd" input to "Bg".
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Update August 10 2017 by jwrl - renamed from block_mix.fx for consistency across the
// dissolve range.
//
// Update August 4 2017 by jwrl.
// All samplers fully defined to avoid differences in their default states between Windows
// and Linux/Mac compilers.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Block dissolve";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Builds the outgoing image into larger and larger blocks as it fades";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture BlockInput : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{ 
   Texture   = <Fg>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blocks = sampler_state
{
   Texture = <BlockInput>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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

float blockSize
<
   string Description = "Block size";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.10;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
//  Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mix (float2 uv : TEXCOORD1) : COLOR
{
   float4 FgdPix = tex2D (s_Foreground, uv);
   float4 BgdPix = tex2D (s_Background, uv);

   float  level = saturate ((Amount * 3.0) - 1.0);

   return lerp (FgdPix, BgdPix, level);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   if (blockSize <= 0.0) return tex2D (s_Blocks, uv);

   float amt   = max (0.0, (abs (((Amount + 0.00001) * 2.5) - 1.25) - 0.25));
   float Xsize = max (1e-10, blockSize * cos (amt * HALF_PI));
   float Ysize = Xsize * _OutputAspectRatio;

   float2 xy;

   xy.x = (floor ((uv.x - 0.5) / Xsize) * Xsize) + 0.5;
   xy.y = (floor ((uv.y - 0.5) / Ysize) * Ysize) + 0.5;

   return tex2D (s_Blocks, xy);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dx_Blocks
{
   pass P_1
   < string Script = "RenderColorTarget0 = BlockInput;"; >
   { PixelShader = compile PROFILE ps_mix (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
