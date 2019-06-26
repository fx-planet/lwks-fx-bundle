// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-09-27
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_ColourFlat_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_ColourFlat.mp4

/**
This is a modified version of my "Dissolve through colour" but is very much simpler to
use.  Apply it as you would a dissolve, adjust the percentage of the dissolve that you
want to be colour and set the colour to what you want.  It defaults to white colour
with a colour duration of 10% of the total effect duration.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlatColour_Dx.fx
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
   string Description = "Dissolve thru flat colour";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Dissolves to a flat user defined colour then from that to the incoming image";
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

float cDuration
<
   string Group = "Colour setup";
   string Description = "Duration";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float4 Colour
<
   string Group = "Colour setup";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 1.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float mix_bgd = min (1.0, (1.0 - Amount) * 2.0);
   float mix_fgd = min (1.0, Amount * 2.0);

   if (cDuration < 1.0) {
      float duration = 1.0 - cDuration;

      mix_bgd = min (1.0, mix_bgd / duration);
      mix_fgd = min (1.0, mix_fgd / duration);
   }
   else {
      mix_bgd = 1.0;
      mix_fgd = 1.0;
   }

   float4 retval = lerp (tex2D (s_Foreground, uv), Colour, mix_fgd);

   return lerp (tex2D (s_Background, uv), retval, mix_bgd);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Dx_FlatColour
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
