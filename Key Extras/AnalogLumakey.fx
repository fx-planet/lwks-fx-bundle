// @Maintainer jwrl
// @Released 2021-10-06
// @Author jwrl
// @Created 2021-10-06
// @see https://www.lwks.com/media/kunena/attachments/6375/AnalogLumakey_640.png

/**
 This keyer is similar to the Lightworks lumakey effect, but behaves more like an analogue
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
//
// Version history:
//
// Rewrite 2021-10-06 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Analogue lumakey";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "A digital keyer which behaves in a similar way to an analogue keyer";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define R_LUMA    0.2989
#define G_LUMA    0.5866
#define B_LUMA    0.1145

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   bool BgBlack = KeyMode > 1;
   bool FgAlpha = abs (KeyMode - 2) == 1;

   float4 Fgd = GetPixel (s_Foreground, uv1);
   float4 Bgd = (BgBlack || Overflow (uv2)) ? BLACK : tex2D (s_Background, uv2);

   float luma  = dot (Fgd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   float edge  = max (0.00001, Softness);
   float clip  = (KeyClip * 1.0002) - (edge * 0.5) - 0.0001;
   float alpha = saturate ((luma - clip) / edge);

   if (InvertKey) alpha = 1.0 - alpha;

   if (FgAlpha) alpha = min (Fgd.a, alpha);

   return lerp (Bgd, Fgd, alpha * Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique AnalogLumakey { pass P_1 ExecuteShader (ps_main) }

