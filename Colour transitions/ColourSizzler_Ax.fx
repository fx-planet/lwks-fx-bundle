// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-06-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Sizzler_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Sizzler.mp4

/**
This effect dissolves a title in or out through a complex colour translation while
performing what is essentially a non-additive mix.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourSizzler_Ax.fx
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Colour sizzler (alpha)";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Transitions a title in or out using a complex colour translation";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Super = sampler_state { Texture = <Sup>; };
sampler s_Video = sampler_state { Texture = <Vid>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "If using a Lightworks text effect disconnect its input and set this first";
   string Enum = "Crawl/Roll/Titles,Video/External image";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Ttype
<
   string Description = "Transition";
   string Enum = "Fade in,Fade out";
> = 0;

float Saturation
<
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float HueCycle
<
   string Description = "Cycle rate";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SQRT_3  1.7320508076
#define TWO_PI  6.2831853072

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   float4 retval = tex2D (Vsample, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float amount = Ttype == 0 ? 1.0 - Amount : Amount;

   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 Svid = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 Temp = max (Svid * min (1.0, 2.0 * (1.0 - amount)), Bgnd * min (1.0, 2.0 * amount));

   Svid = max (Svid, Bgnd);

   float Luma  = 0.1 + (0.5 * Svid.x);
   float Satn  = Svid.y * Saturation;
   float Hue   = frac (Svid.z + (amount * HueCycle));
   float HueX3 = 3.0 * Hue;

   Hue = SQRT_3 * tan ((Hue - ((floor (HueX3) + 0.5) / 3.0)) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   Svid.rgb = (HueX3 < 1.0) ? float3 (Green, Blue, Red)
            : (HueX3 < 2.0) ? float3 (Red, Green, Blue)
                            : float3 (Blue, Red, Green);

   float mixval = abs (2.0 * (0.5 - amount));

   mixval *= mixval;
   Temp    = lerp (Svid, Temp, mixval);
   Fgnd.a  = Fgnd.a > 0.0 ? lerp (1.0, Fgnd.a, amount) : 0.0;

   return lerp (Bgnd, Temp, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_ColourSizzler
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
