// @Maintainer jwrl
// @Released 2020-12-28
// @Author baopao
// @Created 2015-11-30
// @see https://www.lwks.com/media/kunena/attachments/6375/Unpremultiply_640.png

/**
 Unpremultiply does just that.  It removes the hard outline you can get with premultiplied
 mattes.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect UnpremultiplyFx.fx
//
// Version history:
//
// Rewrite 2020-12-28 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Unpremultiply";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Removes the hard outline you can get with some blend effects";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define EMPTY   0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 main (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = abs (uv - 0.5.xx);

   if (max (xy.x, xy.y) > 0.5) return EMPTY;

   float4 color = tex2D (s_Input, uv);

   color.rgb /= color.a;

   return color;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SimpleTechnique
{
   pass MainPass
   { PixelShader = compile PROFILE main (); }
}
