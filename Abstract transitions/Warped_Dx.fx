// @Maintainer jwrl
// @Released 2020-07-29
// @Author jwrl
// @Created 2016-05-14
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Warp_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/WarpDissolve.mp4

/**
 This is a dissolve that warps.  The warp is driven by the background image, and so will be
 different each time that it's used.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Warped_Dx.fx
//
// Version history:
//
// Modified 2020-07-29 jwrl.
// Reformatted the effect header.
// Simplified maths.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Update August 10 2017 by jwrl.
// Renamed from WarpDiss.fx for consistency across the dissolve range.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Warped dissolve";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "Warps between two shots";
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

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Image = sampler_state
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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_dissolve (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   return lerp (Fgd, Bgd, Amount);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Img = tex2D (s_Image, uv);

   float2 xy = uv - float2 (Img.b - Img.r, Img.g) * sin (Amount * PI);

   return tex2D (s_Image, xy);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Warped_Dx
{
   pass P_1
   < string Script = "RenderColorTarget0 = Image;"; >
   { PixelShader = compile PROFILE ps_dissolve (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
