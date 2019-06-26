// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2018-06-12
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Sine_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Sine.mp4

/**
This is an alpha dissolve/wipe that uses sine distortion to perform a left-right or
right-left transition into or out of the alpha components.  Phase can be offset by
180 degrees.  Alpha levels are boosted to support Lightworks titles, which is the
default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sine_Ax.fx
//
// This is a revision of an earlier effect, Adx_Sine.fx, which also had the ability to
// wipe between two titles.  That added needless complexity, when the same functionality
// can be obtained by overlaying two effects.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Sinusoidal mix (alpha)";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Uses a sine wave distortion to transition into or out of a title";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Video = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture =   <Sup>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
   string Enum = "Wipe in,Wipe out";
> = 0;

int Direction
<
   string Description = "Direction";
   string Enum = "Left to right,Right to left"; 
> = 0;

int Mode
<
   string Group = "Ripples";
   string Description = "Distortion";
   string Enum = "Upwards,Downwards"; 
> = 0;

float Width
<
   string Group = "Ripples";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ripples
<
   string Group = "Ripples";
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Spread
<
   string Group = "Ripples";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

#define EMPTY    (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

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
   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = Amount * (1.0 + range);
   float minVis = maxVis - range;

   float x = (Direction == 0) ? uv.x : 1.0 - uv.x;

   float amount = (x <= minVis) ? 1.0
                : (x >= maxVis) ? 0.0 : (maxVis - x) / range;

   float ripples = max (0.0, RIPPLES * (x - minVis));
   float spread  = ripples * Spread * SCALE;
   float offset  = sin (pow (max (0.0, Ripples), 5.0) * ripples) * spread;

   float2 xy = (Mode == 0) ? float2 (uv.x, uv.y + offset) : float2 (uv.x, uv.y - offset);

   float4 Fgd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a * amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (1.0 - Amount) * (1.0 + range);
   float minVis = maxVis - range;

   float x = (Direction == 0) ? 1.0 - uv.x : uv.x;

   float amount = (x <= minVis) ? 1.0
                : (x >= maxVis) ? 0.0 : (maxVis - x) / range;

   float ripples = max (0.0, RIPPLES * (x - minVis));
   float spread  = ripples * Spread * SCALE;
   float offset  = sin (pow (max (0.0, Ripples), 5.0) * ripples) * spread;

   float2 xy = (Mode == 0) ? float2 (uv.x, uv.y + offset) : float2 (uv.x, uv.y - offset);

   float4 Fgd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a * amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Sine_Ax_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Sine_Ax_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_out (); }
}

