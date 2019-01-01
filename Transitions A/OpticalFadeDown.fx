// @Maintainer jwrl
// @Released 2019-01-01
// @Author jwrl
// @Created 2019-01-01
// @see https://www.lwks.com/media/kunena/attachments/6375/OpticalFade_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/OpticalFade.mp4

/**
This simulates the look of the classic film optical fade to black.  It applies a gamma shift
and a degree of black crush to the transition the way early optical printers did.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect OpticalFadeDown.fx
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Optical fade down";
   string Category    = "Mix";
   string SubCategory = "Fades and non mixes";
   string Notes       = "Simulates the black crush effect of a film optical fade to black";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Outgoing = sampler_state { Texture = <Inp>; };

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
   float4 video = tex2D (s_Outgoing, uv);

   float alpha = max (video.a, Amount);

   float3 retval = pow (video.rgb, 1.0 + (Amount * 0.25));

   retval = lerp (retval, BLACK, Amount * 0.8);
   retval = saturate (retval - (Amount * 0.2).xxx);

   return float4 (retval, alpha);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique OpticalFadeDown
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

