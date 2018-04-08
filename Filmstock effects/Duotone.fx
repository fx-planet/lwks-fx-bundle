// @Maintainer jwrl
// @Released 2018-04-07
// @Author jwrl
// @Created 2016-04-12
// @see https://www.lwks.com/media/kunena/attachments/6375/Duotone_4.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Duotone_9.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Duotone.fx
//
// This simulates the effect of the old Duotone film colour process.
//
// Modified 14 April 2016 by jwrl.
// This version has changed the axes slightly to better handle foliage and other
// greenery, and has added a saturation control after requests for it.
//
// Update 31 July 2017 jwrl.
// Added an extra profile and two extra parameters.  It's now possible to mix between
// the original profile and a new one that is better for flesh tones.  Additionally,
// a gamma tweak has been added under the guise of a dye curve adjustment.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Duotone";
   string Category    = "Colour";
   string SubCategory = "Preset Looks";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Saturation
<
   string Description = "Saturation";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Profile
<
   string Description = "Colour profile";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 1.0;

float Curve
<
   string Description = "Dye curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define R_LUMA 0.2989
#define G_LUMA 0.5866
#define B_LUMA 0.1145

#define R_ORG  1.4088
#define G_ORG  0.5912

#define G_BGN  1.7472
#define B_BGN  0.2528

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (FgSampler, xy);

   float gamma = (Curve > 0.0) ? 1.0 - Curve * 0.2 : 1.0;
   float luma  = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));

   float4 altret = float2 (luma, retval.a).xxxy;
   float4 desat  = altret;

   float orange = dot (retval.rg, float2 (G_ORG, R_ORG));
   float cyan   = dot (retval.gb, float2 (G_BGN, B_BGN));

   altret.r = orange - luma;
   altret.b = cyan - luma;

   retval.r    = orange / 2.0;
   retval.b    = cyan / 2.0;
   luma        = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   retval.rgb += retval.rgb - luma.xxx;

   retval = saturate (lerp (altret, retval, Profile));
   retval = pow (retval, gamma);

   return lerp (desat, retval, Saturation * 4.0);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique duotone
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
