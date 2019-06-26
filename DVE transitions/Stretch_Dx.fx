// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2016-05-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Stretch_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/StretchDissolve.mp4

/**
Stretches the image horizontally through the dissolve.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Stretch_Dx.fx
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined float2 variables to allow for the behaviour difference between
// the D3D and Cg compilers.
//
// Update August 10 2017 by jwrl.
// Renamed from StretchDiss.fx for consistency across the dissolve range.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Stretch dissolve";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Stretches the image horizontally through the dissolve";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state {
        Texture   = <Fg>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
        };

sampler s_Background = sampler_state {
        Texture   = <Bg>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
        };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int StretchMode
<
   string Description = "Stretch mode";
   string Enum = "Horizontal,Vertical";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float Stretch
<
   string Description = "Stretch";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.141593

#define HALF_PI 1.570796

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - (0.5).xx;

   float dissAmt = saturate (lerp (Amount, ((1.5 * Amount) - 0.25), Stretch));
   float stretchAmt = lerp (0.0, saturate (sin (Amount * PI)), Stretch);
   float distort;

   if (StretchMode == 0) {
      distort = sin (xy.y * PI);
      distort = sin (distort * HALF_PI);

      xy.y = lerp (xy.y, distort / 2.0, stretchAmt);
      xy.x /= 1.0 + (5.0 * stretchAmt);
   }
   else {
      distort = sin (xy.x * PI);
      distort = sin (distort * HALF_PI);

      xy.x = lerp (xy.x, distort / 2.0, stretchAmt);
      xy.y /= 1.0 + (5.0 * stretchAmt);
   }

   xy += (0.5).xx;

   float4 fgPix = tex2D (s_Foreground, xy);
   float4 bgPix = tex2D (s_Background, xy);

   return lerp (fgPix, bgPix, dissAmt);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dx_Stretch
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
