// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2016-05-14
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Warp_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/WarpDissolve.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_Warp.fx
//
// Dissolve that warps.  Nothing more to say really.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Update August 10 2017 by jwrl.
// Renamed from WarpDiss.fx for consistency across the dissolve range.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Warp dissolve";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Image : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Wrap;
   AddressV  = Wrap;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Wrap;
   AddressV  = Wrap;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler ImgSample = sampler_state
{
   Texture   = <Image>;
   AddressU  = Wrap;
   AddressV  = Wrap;
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI 3.141593

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_dissolve (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (FgSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);

   return lerp (Fgd, Bgd, Amount);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float  Amt = sin (Amount * PI);
   float2 xy = uv;
   float4 Img = tex2D (ImgSample, xy);

   xy.x += (Img.r - Img.b) * Amt;
   xy.y -= Img.g * Amt;

   if (xy.x > 1.0) xy.x -= 1.0;

   if (xy.x < 0.0) xy.x += 1.0;

   if (xy.y < 0.0) xy.y += 1.0;

   return tex2D (ImgSample, xy);

}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WarpDiss
{
   pass P_1
   < string Script = "RenderColorTarget0 = Image;"; >
   { PixelShader = compile PROFILE ps_dissolve (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
