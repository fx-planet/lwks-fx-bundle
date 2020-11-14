// @Maintainer jwrl
// @Released 2020-11-14
// @Author jwrl
// @Created 2019-07-27
// @see https://www.lwks.com/media/kunena/attachments/6375/TitleFix_640.png

/**
 This effect enhances the blending of a title, roll or crawl when used with external blending
 or DVE effects.  Because it has been developed empirically with no knowledge of how Lightworks
 does it internally, it only claims to be subjectively close to the Lightworks effect.

 To use it, disconnect the title input, apply this effect to the title then apply the blend or
 DVE effect that you need.  You will get a result very similar to that obtained with a standard
 title effect.

 It also has the ability to smooth and antialias text produced by any Lightworks text effect.
 This can be particularly useful when moving or zooming on a title.  A suggested start point
 setting of 10% is completely subjective, and will almost certainly vary depending on text
 size and style.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TitleFix.fx
//
// Version history:
//
// Updated 2020-11-14 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 2020-07-02 jwrl:
// Changed the gaussian blur default to zero to bypass the gaussian blur.
//
// Modified 2020-03-07 jwrl:
// Added a gaussian blur to smooth and antialias text edges.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Title blend fix";
   string Category    = "Key";
   string SubCategory = "Simple tools";
   string Notes       = "Enhances Lightworks titles when they are used with DVEs and other effects";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Input;

sampler s_Input = sampler_state
{
   Texture   = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Smoothing
<
   string Description = "Smooth edges";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define STRENGTH  0.00125

float _OutputAspectRatio;

float _gaussian[] = { 0.2255859375, 0.193359375, 0.120849609375,
                      0.0537109375, 0.01611328125, 0.0029296875, 0.000244140625 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   if (Smoothing > 0.0) {
      float2 xy1 = float2 (1.0, _OutputAspectRatio) * Smoothing * STRENGTH;
      float2 xy2 = uv + xy1;

      retval *= _gaussian [0];
      retval += tex2D (s_Input, xy2) * _gaussian [1];
      xy2 += xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [2];
      xy2 += xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [3];
      xy2 += xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [4];
      xy2 += xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [5];
      xy2 += xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [6];

      xy2 = uv - xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [1];
      xy2 -= xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [2];
      xy2 -= xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [3];
      xy2 -= xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [4];
      xy2 -= xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [5];
      xy2 -= xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [6];
   }

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
