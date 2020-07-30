// @Maintainer jwrl
// @Released 2020-07-30
// @Author jwrl
// @Created 2019-01-01
// @see https://www.lwks.com/media/kunena/attachments/6375/OpticalFade_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/OpticalFade.mp4

/**
 This simulates the look of the classic film optical fade from black.  It applies a gamma
 shift and a degree of black crush to the transition the way early optical printers did.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect OpticalFadeUp.fx
//
// Version history:
//
// Modified 2020-07-30 jwrl.
// Reformatted the effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Optical fade up";
   string Category    = "Mix";
   string SubCategory = "Fades and non mixes";
   string Notes       = "Simulates the black crush effect of a film optical fade from black";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Incoming = sampler_state { Texture = <Inp>; };

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

#define BLACK (0.0).xxx

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 video = tex2D (s_Incoming, uv);

   float amount = 1.0 - Amount;
   float alpha  = max (video.a, amount);

   float3 retval = pow (video.rgb, 1.0 + (amount * 0.25));

   retval = lerp (retval, BLACK, amount * 0.8);
   retval = saturate (retval - (amount * 0.2).xxx);

   return float4 (retval, alpha);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique OpticalFadeUp
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
