// @Maintainer jwrl
// @Released 2018-06-07
// @Author jwrl
// @Created 2018-06-07
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Abstraction3_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Abstraction3.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_Abstraction3.fx
//
// This is the second effect based on my earlier effect Abstraction #1.  It uses the
// same pattern but applies the second half symmetrically into and out of the effect.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Abstraction #3";
   string Category    = "Mix";
   string SubCategory = "Wipes";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

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

float CentreX
<
   string Description = "Mid position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CentreY
<
   string Description = "Mid position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define XY_SCALE 0.25

#define PROGRESS 0.35
#define P_OFFSET 0.3125
#define P_SCALE  4

#define LOOP     50

#define TWO_PI   6.2831853072
#define HALF_PI  1.5707963268

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float amount   = (Amount < 0.5) ? 1.0 - Amount : Amount;
   float progress = pow ((amount * PROGRESS) + P_OFFSET, P_SCALE);
   float ctime, stime;

   float2 xy1 = lerp (0.5.xx, float2 (CentreX, 1.0 - CentreY), saturate (amount * 2.0));
   float2 xy2 = abs (uv1 - xy1) * XY_SCALE;

   float4 Fgnd = tex2D (s_Foreground, uv1);
   float4 Bgnd = tex2D (s_Background, uv2);

   sincos (progress, stime, ctime);
   xy1 = 0.4.xx;

   for (int i = 0; i < LOOP; ++i) {
      xy2  = abs (xy2 - xy1);
      xy2  = xy2 * ctime - xy2.yx * stime;
      xy1 *= 0.95;
   }

   if (Amount < 0.25) Bgnd = lerp (Fgnd, Bgnd, sin (min (TWO_PI - amount * TWO_PI, HALF_PI)));
   else if (Amount > 0.75) Fgnd = lerp (Bgnd, Fgnd, sin (min (TWO_PI - amount * TWO_PI, HALF_PI)));

   progress = abs ((frac (length (xy2) * LOOP) - 0.5) * 2.0 + 0.5);

   return lerp (Bgnd, Fgnd, progress);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dx_Abstract_1_1
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

