// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2018-06-13
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Twister_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Twister.mp4

/**
This is a dissolve/wipe that uses sine & cos distortions to perform a rippling twist to
establish or remove an alpha image.  The range of possible effect variations obtainable
with differing combinations of settings is almost inifinite.  Alpha levels can be boosted
to support Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Twister_Ax.fx
//
// This is a revision of an earlier effect, Adx_Twister.fx, which also had the ability
// to wipe between two titles.  That added needless complexity, when the same result can
// be obtained by overlaying two effects.
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
   string Description = "The twister (alpha)";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Performs a rippling twist to establish or remove a title";
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
   Texture   = <Sup>;
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
   string Enum = "Twist in,Twist out";
> = 0;

int TransProfile
<
   string Description = "Transition profile";
   string Enum = "Left > right profile A,Left > right profile B,Right > left profile A,Right > left profile B"; 
> = 1;

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
   string Description = "Ripple amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.6;

float Spread
<
   string Group = "Ripples";
   string Description = "Ripple width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

float Twists
<
   string Group = "Twists";
   string Description = "Twist amount";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

bool Show_Axis
<
   string Group = "Twists";
   string Description = "Show twist axis";
> = false;

float Axis
<
   string Group = "Twists";
   string Description = "Set axis";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputHeight;

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

#define EMPTY (0.0).xxxx

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
   int Mode = (int) fmod ((float)TransProfile, 2.0);                 // If TransProfile is odd it's mode B

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;              // Calculate softness range of the effect
   float maxVis = (Mode == TransProfile) ? uv.x : 1.0 - uv.x;        // If mode and profile match it's left > right

   maxVis = Amount * (1.0 + range) - maxVis;                         // Set up the maximum visibility

   float amount = saturate (maxVis / range);                         // Calculate the visibility
   float T_Axis = uv.y - Axis;                                       // Calculate the normalised twist axis

   float ripples = max (0.0, RIPPLES * (range - maxVis));            // Correct the ripples of the final effect
   float spread  = ripples * Spread * SCALE;                         // Correct the spread
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;          // Calculate the modulation factor
   float offset  = sin (modultn) * spread;                           // Calculate the vertical offset from the modulation and spread
   float twists  = cos (modultn * Twists * 4.0);                     // Calculate the twists using cos () instead of sin ()

   float2 xy = float2 (uv.x, Axis + (T_Axis / twists) - offset);     // Foreground X is uv.x, foreground Y is modulated uv.y

   xy.y += offset * float (Mode * 2);                                // If the transition profile is positive correct Y

   float4 Fgd = fn_tex2D (s_Super, xy);                              // This version of the foreground has the modulation applied
   float4 Bgd = lerp (tex2D (s_Video, uv), Fgd, Fgd.a * amount);     // Produce the final composite blend

   if (Show_Axis) {                                                  // Get out if we don't want to see the axis

      // To help with line-up this section produces a two-pixel wide line from the twist axis.  That is added to the output, and the
      // result is folded if it exceeds peak white.  This ensures that the line will be visible regardless of the video content.

      float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

      Fgd.rgb = Bgd.rgb + AxisLine.xxx;
      Bgd.rgb = min (1.0.xxx, Fgd.rgb) - max (0.0.xxx, Fgd.rgb - 1.0.xxx);
   }

   return Bgd;
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   int Mode = (int) fmod ((float)TransProfile, 2.0);

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (Mode == TransProfile) ? 1.0 - uv.x : uv.x;        // Here the sense of the x position is opposite to above

   maxVis = (1.0 - Amount) * (1.0 + range) - maxVis;                 // The sense of the Amount parameter also has to change

   float amount = saturate (maxVis / range);
   float T_Axis = uv.y - Axis;

   float ripples = max (0.0, RIPPLES * (range - maxVis));
   float spread  = ripples * Spread * SCALE;
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;
   float offset  = sin (modultn) * spread;
   float twists  = cos (modultn * Twists * 4.0);

   float2 xy = float2 (uv.x, Axis + (T_Axis / twists) - offset);

   xy.y += offset * float (Mode * 2);

   float4 Fgd = fn_tex2D (s_Super, xy);
   float4 Bgd = lerp (tex2D (s_Video, uv), Fgd, Fgd.a * amount);

   if (Show_Axis) {
      float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

      Fgd.rgb = Bgd.rgb + AxisLine.xxx;
      Bgd.rgb = min (1.0.xxx, Fgd.rgb) - max (0.0.xxx, Fgd.rgb - 1.0.xxx);
   }

   return Bgd;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Twister_Ax_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Twister_Ax_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_out (); }
}

