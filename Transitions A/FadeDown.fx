// @Maintainer jwrl
// @Released 2018-12-31
// @Author jwrl
// @Created 2018-12-31
// @see https://www.lwks.com/media/kunena/attachments/6375/FadeUpDown_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_FadeOutIn.mp4

/**
This simple effect fades any video to which it's applied down to black.  It isn't a
standard dissolve, since it requires one input only.  It must be applied in the same
way as a title effect, i.e., by marking the region that the fade out is to occupy.

There is companion effect called FadeUp.fx which does the opposite.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FadeDown.fx
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fade down";
   string Category    = "Mix";
   string SubCategory = "Fades and non mixes";
   string Notes       = "Fades video out to black";
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

#define BLACK   float2(0.0,1.0).xxxy

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   return lerp (tex2D (s_Outgoing, uv), BLACK, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FadeDown
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}

