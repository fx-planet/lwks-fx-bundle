// @Maintainer jwrl
// @Released 2018-09-05
// @Author jwrl
// @Created 2018-09-01
// @see https://www.lwks.com/media/kunena/attachments/6375/Plasma_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Plasma.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Plasma.fx
//
// This effect generates soft plasma-like cloud patterns.  Hue, level, saturation, rate
// of change of pattern are all adjustable, and the pattern is also adjustable.  It will
// not run under Windows 14.0 or earlier and will instead deliberately produce an error
// message when compiled.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Plasma";
   string Category    = "Mattes";
   string SubCategory = "Patterns";
   string Notes       = "Generates soft plasma clouds";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = Clamp;
   AddressV  = Clamp;
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
> = 1.0;

float Rate
<
   string Description = "Rate";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Style
<
   string Description = "Pattern style";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Scale
<
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Gain
<
   string Description = "Pattern gain";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Level
<
   string Description = "Level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.6666666667;

float Hue
<
   string Description = "Hue";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Saturation
<
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define R_LUMA  0.2989
#define G_LUMA  0.5866
#define B_LUMA  0.1145

#define TWO_PI  6.2831853072
#define HALF_PI 1.5707963268

float _Progress;

#ifdef _LENGTHFRAMES

float _LengthFrames;

#endif

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float rate = _LengthFrames * _Progress / (1.0 + (Rate * 38.0));

   float2 xy1, xy2, xy3, xy4 = (uv - 0.5.xx) * HALF_PI;

   sincos (xy4, xy3, xy2.yx);

   xy1  = lerp (xy3, xy2, (1.0 + Style) * 0.5) * (5.5 - (Scale * 5.0));
   xy1 += sin (xy1 * HALF_PI + rate.xx).yx;
   xy4  = xy1 * HALF_PI;

   sincos (xy1.x, xy3.x, xy3.y);
   sincos (xy4.x, xy2.x, xy2.y);
   sincos (xy1.y, xy1.x, xy1.y);
   sincos (xy4.y, xy4.x, xy4.y);

   float3 ptrn = (dot (xy2, xy4.xx) + dot (xy1, xy3.yy)).xxx;

   ptrn.y = dot (xy1, xy2.xx) + dot (xy3, xy4.xx);
   ptrn.z = dot (xy2, xy3.yy) + dot (xy1, xy4.yy);
   ptrn  += float3 (Hue, 0.5, 1.0 - Hue) * TWO_PI;

   float4 retval = float4 (sin (ptrn) * ((Gain * 0.5) + 0.05), 1.0);

   retval.rgb = saturate (retval.rgb + Level.xxx);

   float luma = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));

   retval.rgb = lerp (luma.xxx, retval.rgb, Saturation * 2.0);

   return lerp (tex2D (s_Input, uv), retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Plasma
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

