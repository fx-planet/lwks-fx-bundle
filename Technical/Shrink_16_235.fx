// @Maintainer jwrl
// @Released 2020-09-28
// @Author khaver
// @Created 2011-05-05
// @see https://www.lwks.com/media/kunena/attachments/6375/Shrink16_235_640.png

/**
 This is one of three tools to manage broadcast colour space.  The names are self-explanatory.
 They install into the custom category "User", subcategory "Technical".
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Shrink_16_235.fx
//
// Version history:
//
// Update 2020-09-28 jwrl.
// Revised header block.
//
// Modified by LW user jwrl 6 December 2018.
// Added creation date.
// Changed subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Shrink 0-255 to 16-235";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "Shrinks full gamut RGB signals to broadcast legal video";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and shader
//-----------------------------------------------------------------------------------------//

texture Input;


sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 NullPS(float2 xy : TEXCOORD1) : COLOR
{
    float highc = 235.0f / 255.0f;
    float lowc = 16.0f / 255.0f;
    float scale = 255.0f / 219.0f;

    float4 color = tex2D(FgSampler, xy.xy);

    color = (color / scale) + lowc;

    if (color.r > highc) color.r = highc;
    if (color.g > highc) color.g = highc;
    if (color.b > highc) color.b = highc;
    if (color.a > highc) color.a = highc;
    if (color.r < lowc) color.r = lowc;
    if (color.g < lowc) color.g = lowc;
    if (color.b < lowc) color.b = lowc;
    if (color.a < lowc) color.a = lowc;

	return color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Shrink16_235
{
   pass p0
   {
      PixelShader = compile PROFILE NullPS();
   }
}
