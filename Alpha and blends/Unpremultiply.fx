// @Maintainer jwrl
// @Released 2018-04-05
// @Author baopao
// @Created 2015-11-30
// @see https://www.lwks.com/media/kunena/attachments/6375/Unpremultiply_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Unpremultiply.fx
//
// Removes the hard outline you can get with premultiplied mattes.
//
// LW 14+ version 11 January 2017
// Category changed from "Mixes" to "Key", subcategory "User Effects" added.
//
// Bug fix 26 July 2017
// Because Windows and Linux-OS/X have differing defaults for undefined samplers they
// have now been explicitly declared.
//
// Modified 5 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 4 December 2018 jwrl.
// Added creation date.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Unpremultiply";
   string Category    = "Key";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture FG;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FGSampler = sampler_state
{
   Texture = <FG>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 main (float2 uv : TEXCOORD1) : COLOR 
{
    float4 color = tex2D (FGSampler, uv);

    color.rgb /= color.a;
    
    return color;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SimpleTechnique
{
pass MainPass

   {
      PixelShader = compile PROFILE main();
   }

}
