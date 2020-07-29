// @Maintainer jwrl
// @Released 2020-07-29
// @Author jwrl
// @Created 2015-10-12
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Blurs_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/BlurDissolve.mp4

/**
 This effect performs a transition between two sources.  During the process it also applies
 a directional blur, the angle and strength of which can be independently set for both the
 incoming and outgoing vision sources.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BlurDissolve_Dx.fx
//
// Version history:
//
// Modified 2020-07-29 jwrl.
// Reformatted the effect header.
//
// Modified 23 December 2018 jwrl.
// Fixed bug which caused spread to do very little.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Update August 10 2017 by jwrl.
// Renamed from BlurDissolve.fx for consistency across the dissolve range.
//
// Update August 4 2017 by jwrl.
// All samplers fully defined to avoid differences in their default states between
// Windows and Linux/Mac compilers.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//
// Modified May 6 2016 by jwrl.
// Changed the blur engine and offset the incoming blur by 180 degrees so that the
// incoming and outgoing blurs are perceived to match direction.  A setting to tie both
// incoming and outgoing blurs together has also been added.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Blur dissolve";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Uses a directional blur to transition between two sources";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture FgBlur : RenderColorTarget;
texture BgBlur : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state
{ 
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FbSampler = sampler_state
{ 
   Texture   = <FgBlur>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BbSampler = sampler_state
{ 
   Texture   = <BgBlur>;
   AddressU  = Mirror;
   AddressV  = Mirror;
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

float Spread
<
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float o_Angle
<
   string Group = "Outgoing blur";
   string Description = "Angle";
   float MinVal = -180.00;
   float MaxVal = 180.0;
> = 0.0;

float o_Strength
<
   string Group = "Outgoing blur";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int SetTechnique
<
   string Group = "Incoming blur";
   string Description = "Settings";
   string Enum = "Use outgoing settings,Use settings below";
> = 0;

float i_Angle
<
   string Group = "Incoming blur";
   string Description = "Angle";
   float MinVal = -180.00;
   float MaxVal = 180.0;
> = 0.0;

float i_Strength
<
   string Group = "Incoming blur";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SAMPLES   60

#define SAMPSCALE 61

#define STRENGTH  0.01

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_blur (float2 uv : TEXCOORD1, uniform sampler bSamp, uniform float bStrn, uniform float bAng, uniform int bOffs) : COLOR
{
   if ((Spread <= 0.0) || (bStrn <= 0.0)) return tex2D (bSamp, uv);

   float2 blurOffset, xy = uv;
   float4 retval = 0.0;

   sincos (radians (bAng + (bOffs * 180)), blurOffset.y, blurOffset.x);
   blurOffset *= (Spread * bStrn * abs (bOffs - Amount) * STRENGTH);

   for (int i = 0; i < SAMPLES; i++) {
      retval += tex2D (bSamp, xy);
      xy += blurOffset;
      }
    
   retval /= SAMPSCALE;

   return saturate (retval);
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 outBlur = tex2D (FbSampler, xy);
   float4 in_Blur = tex2D (BbSampler, xy);

   float Mix = saturate (((Amount - 0.5) * ((Spread * 3.0) + 1.5)) + 0.5);

   return lerp (outBlur, in_Blur, Mix);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique BlurDissolve_Dx_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = FgBlur;"; >
   { PixelShader = compile PROFILE ps_blur (FgSampler, o_Strength, o_Angle, 0); }

   pass P_2
   < string Script = "RenderColorTarget0 = BgBlur;"; >
   { PixelShader = compile PROFILE ps_blur (BgSampler, o_Strength, o_Angle, 1); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique BlurDissolve_Dx_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = FgBlur;"; >
   { PixelShader = compile PROFILE ps_blur (FgSampler, o_Strength, o_Angle, 0); }

   pass P_2
   < string Script = "RenderColorTarget0 = BgBlur;"; >
   { PixelShader = compile PROFILE ps_blur (BgSampler, i_Strength, i_Angle, 1); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}
