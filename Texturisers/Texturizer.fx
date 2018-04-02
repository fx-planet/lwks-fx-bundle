//--------------------------------------------------------------//
// Lightworks effect Texturizer.fx
//
// Created by Lightworks user jwrl 22 April 2016.
// @Author: jwrl
// @CreationDate: "22 April 2016"
//
// This effect is designed to modulate the input with a texture
// from an external piece of art.  The texture may be coloured
// but only the luminance value will be used.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Texturizer";
   string Category    = "Stylize";
   string SubCategory = "Textures";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Artwk;

texture Input;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgdSampler = sampler_state
{
   Texture = <Input>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler ArtSampler = sampler_state
{
   Texture = <Artwk>;
   AddressU = Mirror;
   AddressV = Mirror;
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

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float amt = Amount * AMT;
   float2 uv = xy - 0.5.xx;

   uv *= 1.0 - (Size * SIZE);
   uv += 0.5.xx;

   float4 Img = tex2D (ArtSampler, uv);

   float luma = dot (Img.rgb, float3(RED_LUMA, GREEN_LUMA, BLUE_LUMA)) * (Depth * DPTH);

   float4 Fgd = (tex2D (FgdSampler, xy + (luma * OFFSET).xx) * REDUCTION);

   Fgd = saturate (Fgd + (Img * amt));
   Fgd = lerp (Fgd, Img, amt);

   float alpha = tex2D (FgdSampler, xy).a;

   return float4 (Fgd.rgb, alpha);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique texturizer
{
   pass main
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
