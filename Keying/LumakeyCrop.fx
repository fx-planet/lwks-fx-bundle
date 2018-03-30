//--------------------------------------------------------------//
// Lightworks user effect LumakeyCrop.fx
// Created by LW user jwrl 26 November 2017
//
// This keyer uses an algorithm derived from the Editshare
// lumakey effect, but this implementation is entirely my
// own.  A crop function has also been added to it to give
// this often-needed function without the need to add an
// external effect.
//
// The key section of the effect has two means of creating
// an alpha channel for the foreground image.  The alpha
// channel produced by the keyer can either replace the
// existing foreground alpha channel or can be gated with
// it.  It can then optionally be used to key the foreground
// over the background or passed on to external blends and
// other effects.  In this latter mode any background image
// will be suppressed.
//
// The most obvious difference with the keyer is in the way
// that the parameters are labelled.  "Tolerance" is now
// called "Key clip", "Edge Softness" is "Key Softness" and
// "Invert" has become "Invert key".  These are the industry
// standard names used for these functions, so this change
// makes the effect more consistent with existing tools.
//
// Key softness, instead of being calculated entirely from
// within the keyed area is now produced symmetrically around
// the key boundaries.  This behaviour change is also for
// consistency reasons.  It's more consistent with the way
// that a traditional analog luminance keyer works.
//
// Additionally, when key clip is exceeded by the image
// luminance the Lightworks keyer passes the luminance value
// unchanged, which is incorrect.  This keyer outputs full
// white to the alpha channel when that occurs instead, i.e.,
// the alpha channel is turned fully on.  Again, this is
// consistent with the way that an analog keyer works.
//
// Finally, regardless of whether the key is inverted or not,
// the clip setting always works from black at 0% to white
// at 100%.  In the Lightworks effect the equivalent setting,
// tolerance, changes sense when the key is inverted.  This
// is unexpected to say the least and for that reason is not
// used here.
//
// The crop section can be set up by dragging the upper left
// and lower right corners of the crop on the edit viewer, or
// in the normal way by dragging the sliders.  The crop is a
// simple hard edged one.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lumakey with crop";
   string Category    = "Key";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgdSampler = sampler_state {
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state {
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.0;

int KeyMode
<
   string Group = "Key settings";
   string Description = "Mode";
   string Enum = "Lumakey,Lumakey and Fg alpha,Lumakey (no background),Lumakey and Fg alpha (no Bg)";
> = 0;

float KeyClip
<
   string Group = "Key settings";
   string Description = "Clip";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Softness
<
   string Group = "Key settings";
   string Description = "Softness";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

bool InvertKey
<
   string Group = "Key settings";
   string Description = "Invert key";
> = false;

float Crop_L
<
   string Group = "Crop settings";
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.0;

float Crop_T
<
   string Group = "Crop settings";
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.0;

float Crop_R
<
   string Group = "Crop settings";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.0;

float Crop_B
<
   string Group = "Crop settings";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define R_LUMA    0.2989
#define G_LUMA    0.5866
#define B_LUMA    0.1145

#define KEEP_BGD  0
#define ADD_ALPHA 1

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   int BgMode = (int)floor (KeyMode * 0.5);
   int FgMode = KeyMode - (BgMode * 2);

   float4 Bgd = (BgMode == KEEP_BGD) ? tex2D (BgdSampler, uv) : 0.0.xxxx;

   float y = 1.0 - uv.y;

   if ((uv.x < Crop_L) || (uv.x > Crop_R) || (y > Crop_T) || (y < Crop_B)) return Bgd;

   float4 Fgd = tex2D (FgdSampler, uv);

   float luma  = dot (Fgd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   float edge  = max (0.00001, Softness);
   float clip  = (KeyClip * 1.0002) - (edge * 0.5) - 0.0001;
   float alpha = saturate ((luma - clip) / edge);

   if (InvertKey) alpha = 1.0 - alpha;

   if (FgMode == ADD_ALPHA) alpha = min (Fgd.a, alpha);

   return lerp (Bgd, Fgd, alpha * Amount);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique EnhancedLumaKey
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}

