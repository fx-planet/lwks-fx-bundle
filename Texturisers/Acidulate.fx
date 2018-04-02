// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Acidulate.fx
//
// Created by LW user jwrl 14 May 2016
// @Author: jwrl
// @CreationDate: "14 May 2016"
//
// I was going to call this LSD, but this name will do.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Cross platform compatibility check 3 August 2017 jwrl.
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Acidulate";
   string Category    = "Stylize";
   string SubCategory = "Textures";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture Image : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique LSD
{
   pass P_1
   < string Script = "RenderColorTarget0 = Image;"; >
   { PixelShader = compile PROFILE ps_main (FgSampler, 0); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (ImgSample, 1); }
}

