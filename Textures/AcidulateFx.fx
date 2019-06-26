// @Maintainer jwrl
// @Released 2018-12-27
// @Author jwrl
// @Created 2016-05-14
// @see https://www.lwks.com/media/kunena/attachments/6375/Acidulate_640.png

/**
I was going to call this LSD, but this name will do.  Original effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AcidulateFx.fx
//
// Version 14 update 18 Feb 2017 jwrl - added subcategory to effect header.
//
// Cross platform compatibility check 3 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 29 September 2018 jwrl.
// Added notes to header.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Acidulate";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "I was going to call this LSD, but this name will do";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Image : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler ImgSample = sampler_state
{
   Texture   = <Image>;
   AddressU  = Clamp;
   AddressV  = Clamp;
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
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1, uniform sampler extSampler, uniform int proc) : COLOR
{
   float4 Img = tex2D (extSampler, uv);

   if (Amount == 0.0) return Img;

   float2 xy = (proc == 0) ? float2 (Img.b - Img.r, Img.g) : float2 (Img.b, Img.g - Img.r - 1.0);

   xy  = abs (uv + frac (xy * Amount));

   if (xy.x > 1.0) xy.x -= 1.0;

   if (xy.y > 1.0) xy.y -= 1.0;

   return tex2D (extSampler, xy);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique AcidulateFx
{
   pass P_1
   < string Script = "RenderColorTarget0 = Image;"; >
   { PixelShader = compile PROFILE ps_main (FgSampler, 0); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (ImgSample, 1); }
}
