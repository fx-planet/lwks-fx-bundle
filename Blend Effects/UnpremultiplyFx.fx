// @Maintainer jwrl
// @Released 2018-12-23
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
// Modified 25 November 2018 jwrl.
// Added creation date.
// Changed category to "Mix".
// Changed subcategory to "Blend Effects".
// Added "Notes" section to header.
// Changed "FG" node to "Inp" for consistency.
//
// Update 23 December 2018 jwrl.
// Converted to version 14.5 and up.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Unpremultiply";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Removes the hard outline you can get with some blend effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture = <Inp>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 main (float2 uv : TEXCOORD1) : COLOR 
{
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

   {
      PixelShader = compile PROFILE main();
   }

}
