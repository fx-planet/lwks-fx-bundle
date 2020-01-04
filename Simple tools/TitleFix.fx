// @Maintainer jwrl
// @Released 2020-01-04
// @Author jwrl
// @Created 2019-07-27
// @see https://www.lwks.com/media/kunena/attachments/6375/TitleFix_640.png

/**
 This effect enhances the blending of a title, roll or crawl when used with external blending
 or DVE effects.  Because it has been developed empirically with no knowledge of how Editshare
 does it internally, it only claims to be subjectively close to the Lightworks effect.

 To use it, disconnect the title input, apply this effect to the title then apply the blend or
 DVE effect that you need.  You will get a result very similar to that obtained with a standard
 title effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TitleFix.fx
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Title blend fix";
   string Category    = "Key";
   string SubCategory = "Simple tools";
   string Notes       = "Enhances Lightworks titles when they are used with DVEs and other effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Input;

sampler s_Input = sampler_state { Texture = <Input>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

// No parameters needed or provided

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   retval.a = pow (retval.a, 0.5);
   retval.rgb /= retval.a;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique TitleFix
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

