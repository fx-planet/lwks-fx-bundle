// @Maintainer jwrl
// @Released 2020-11-15
// @Author jwrl
// @Created 2016-04-22
// @see https://www.lwks.com/media/kunena/attachments/6375/Texturizer_640.png

/**
 This effect is designed to modulate the input with a texture from an external piece
 of art.  The texture may be coloured but only the luminance value will be used.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Texturiser.fx
//
// Version history:
//
// Update 2020-11-15 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 29 September 2018 jwrl.
// Added notes to header.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Texturiser";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "Generates bump mapped textures on an image using external texture artwork";
   bool CanSize       = true;
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Art;
texture Inp;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Artwork = sampler_state
{
   Texture   = <Art>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Description = "Overlay";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Size
<
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Depth
<
   string Description = "Depth";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//--------------------------------------------------------------//
// Definitions and constants
//--------------------------------------------------------------//

#define AMT         0.2            // Amount scale factor

#define DPTH        1.5            // Depth scale factor

#define SIZE        0.75           // Size scale factor

#define REDUCTION   0.9            // Foreground reduction for texture add
#define OFFSET      0.0025         // Texture offset factor

#define RED_LUMA    0.3
#define GREEN_LUMA  0.59
#define BLUE_LUMA   0.11

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float amt = Amount * AMT;
   float2 uv = xy - 0.5.xx;

   uv *= 1.0 - (Size * SIZE);
   uv += 0.5.xx;

   float4 Img = tex2D (s_Artwork, uv);

   float luma = dot (Img.rgb, float3(RED_LUMA, GREEN_LUMA, BLUE_LUMA)) * (Depth * DPTH);

   float4 Fgd = (tex2D (s_Input, xy + (luma * OFFSET).xx) * REDUCTION);

   Fgd = saturate (Fgd + (Img * amt));
   Fgd = lerp (Fgd, Img, amt);

   float alpha = tex2D (s_Input, xy).a;

   return float4 (Fgd.rgb, alpha);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Texturiser
{
   pass P_1
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
