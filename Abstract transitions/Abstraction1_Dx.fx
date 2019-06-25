// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-06-07
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Abstraction1_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Abstraction1.mp4

/**
Abstraction #1 uses a pattern that developed from my attempt to create a series of
radiating or collapsing circles to transition between two sources.  Initially I
rather unexpectedly produced a simple X wipe and while plugging in different values
to try and track down the error, stumbled across this.  I liked it so I kept it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Abstraction1_Dx.fx
//
// I have absolutely no idea how this works.  I tried to set up borders and broke the
// effect in the process, so I quit while I was ahead.  I'm still trying to get the
// radiating circles happening, but it will have to be in another effect.
//
// Modified 23 December 2018 jwrl.
// Added "Notes" section to _LwksEffectInfo.
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Abstraction #1";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "An abstract geometric transition between two sources";
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

int SetTechnique
<
   string Description = "Wipe direction";
   string Enum = "Forward,Reverse";
> = 0;

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
#define P_OFFSET 0.3125         // 5/16
#define P_SCALE  4

#define LOOP     50

#define TWO_PI   6.2831853072
#define HALF_PI  1.5707963268

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_forward (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float2 xy1 = lerp (0.5.xx, float2 (CentreX, 1.0 - CentreY), saturate (Amount * 2.0));
   float2 xy2 = abs (uv1 - xy1) * XY_SCALE;

   float progress = pow ((Amount * PROGRESS) + P_OFFSET, P_SCALE);
   float ctime, stime;

   sincos (progress, stime, ctime);
   xy1 = 0.4.xx;

   for (int i = 0; i < LOOP; ++i) {
      xy2  = abs (xy2 - xy1);
      xy2  = xy2 * ctime - xy2.yx * stime;
      xy1 *= 0.95;
   }

   float4 Fgnd = tex2D (s_Foreground, uv1);
   float4 Bgnd = tex2D (s_Background, uv2);

   if (Amount < 0.25) Bgnd = lerp (Fgnd, Bgnd, sin (min (Amount * TWO_PI, HALF_PI)));
   else if (Amount > 0.75) Fgnd = lerp (Bgnd, Fgnd, sin (min (TWO_PI - Amount * TWO_PI, HALF_PI)));

   progress = abs ((frac (length (xy2) * LOOP) - 0.5) * 2.0 + 0.5);

   return lerp (Fgnd, Bgnd, progress);
}

float4 ps_reverse (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float2 xy1 = lerp (0.5.xx, float2 (CentreX, 1.0 - CentreY), saturate ((1.0 - Amount) * 2.0));
   float2 xy2 = abs (uv1 - xy1) * XY_SCALE;

   float progress = pow (((1.0 - Amount) * PROGRESS) + P_OFFSET, P_SCALE);
   float ctime, stime;

   sincos (progress, stime, ctime);
   xy1 = 0.4.xx;

   for (int i = 0; i < LOOP; ++i) {
      xy2  = abs (xy2 - xy1);
      xy2  = xy2 * ctime - xy2.yx * stime;
      xy1 *= 0.95;
   }

   float4 Fgnd = tex2D (s_Foreground, uv1);
   float4 Bgnd = tex2D (s_Background, uv2);

   if (Amount < 0.25) Bgnd = lerp (Fgnd, Bgnd, sin (min (Amount * TWO_PI, HALF_PI)));
   else if (Amount > 0.75) Fgnd = lerp (Bgnd, Fgnd, sin (min (TWO_PI - Amount * TWO_PI, HALF_PI)));

   progress = abs ((frac (length (xy2) * LOOP) - 0.5) * 2.0 + 0.5);

   return lerp (Bgnd, Fgnd, progress);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dx_Abstraction1_1
{
   pass P_1
   { PixelShader = compile PROFILE ps_forward (); }
}

technique Dx_Abstraction1_2
{
   pass P_1
   { PixelShader = compile PROFILE ps_reverse (); }
}

