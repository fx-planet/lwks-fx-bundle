// @Maintainer jwrl
// @Released 2019-07-30
// @Author jwrl
// @Created 2019-07-30
// @see https://www.lwks.com/media/kunena/attachments/6375/AnalogLumakey_640.png

/**
 This keyer is similar to the Editshare lumakey effect, but behaves more like an analogue
 luminance keyer.  In this version "Tolerance" is called "Clip" and "Invert" has become
 "Invert key".  These are the industry standard names used for these functions in analogue
 keyers.

 When the key clip is exceeded by the image luminance the Lightworks keyer passes the luma
 value unchanged, which an analogue keyer will not.  This keyer turns the alpha channel fully
 on instead, which is consistent with the way that an analogue keyer works.

 Regardless of whether the key is inverted or not, the clip setting works from black at 0% to
 white at 100%.  Key softness, instead of being calculated entirely from within the keyed area
 is produced symmetrically around the key's edges.  Both of these are more consistent with the
 way that analogue keyers behave.

 The keyer's alpha channel can either replace the foreground's existing alpha channel or can
 be gated with it.  It can then optionally be used to key the foreground over the background
 or passed on to other effects.  In that mode the background is blanked.  This functionality
 was never provided in the analogue world so there is no equivalent to match it to.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AnalogLumakey.fx
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Analogue lumakey";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "A digital keyer which behaves in a similar way to an analogue keyer";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture   = <Fg>; };
sampler s_Background = sampler_state { Texture   = <Bg>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int KeyMode
<
   string Group = "Key settings";
   string Description = "Mode";
   string Enum = "Luminance key,Lumakey plus existing alpha,Lumakey (no background),Lumakey plus alpha (no background)";
> = 0;

float KeyClip
<
   string Group = "Key settings";
   string Description = "Clip";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Softness
<
   string Group = "Key settings";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

bool InvertKey
<
   string Group = "Key settings";
   string Description = "Invert key";
> = false;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define R_LUMA    0.2989
#define G_LUMA    0.5866
#define B_LUMA    0.1145

#define KEEP_BGD  0
#define ADD_ALPHA 1

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   int BgMode = (int)floor (KeyMode * 0.5);
   int FgMode = KeyMode - (BgMode * 2);

   float4 Fgd = tex2D (s_Foreground, uv);
   float4 Bgd = (BgMode == KEEP_BGD) ? tex2D (s_Background, uv) : 0.0.xxxx;

   float luma  = dot (Fgd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   float edge  = max (0.00001, Softness);
   float clip  = (KeyClip * 1.0002) - (edge * 0.5) - 0.0001;
   float alpha = saturate ((luma - clip) / edge);

   if (InvertKey) alpha = 1.0 - alpha;

   if (FgMode == ADD_ALPHA) alpha = min (Fgd.a, alpha);

   return lerp (Bgd, Fgd, alpha * Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique AnalogLumakey
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}

