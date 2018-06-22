// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Optical_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Optical.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Optical.fx
//
// An alpha transition that simulates the burn effect of the classic film optical.
//
// Alpha levels are boosted to support Lightworks titles, which is the default setting.
//
// This is a revision of an earlier effect, Adx_Optical.fx, which also had the ability
// to wipe between two titles.  That added needless complexity, when the same result
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha optical transition";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Simulates the burn effect of the classic film optical title";
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

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Fade in,Fade out";
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI 1.5707963268

#define EMPTY   0.0.xxxx
#define WHITE   1.0.xxxx

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

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float alpha = Fgnd.a;

   alpha *= sin (Amount * HALF_PI) * 1.5;
   Fgnd   = lerp (Bgnd, Fgnd, Fgnd.a);
   Bgnd   = max (EMPTY, Bgnd - alpha.xxxx);

   return lerp (Bgnd, Fgnd, Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float alpha  = Fgnd.a;
   float amount = 1.0 - Amount;

   alpha *= sin (amount * HALF_PI) * 1.5;
   Fgnd   = lerp (Bgnd, Fgnd, Fgnd.a);
   Bgnd   = max (EMPTY, Bgnd - alpha.xxxx);

   return lerp (Bgnd, Fgnd, amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique fade_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique fade_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_out (); }
}

