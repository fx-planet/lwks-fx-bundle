//--------------------------------------------------------------//
// Lightworks user effect LumakeyDVE.fx
// Created by LW user jwrl 20 March 2018.
//
// This keyer uses an algorithm derived from the Editshare
// lumakey effect, but this implementation is entirely my
// own.  A crop function and a simple DVE has also been added
// to provide these often-needed functions without the need
// to add external effects.
//
// The most obvious difference with the keyer is in the way
// that the parameters are labelled.  "Tolerance" is now
// called "Key clip", "Edge Softness" is "Key Softness" and
// "Invert" has become "Invert key".  These are the industry
// standard names used for these functions, so this change
// makes the effect more consistent with existing tools.
//
// Regardless of whether the key is inverted or not, the
// clip setting always works from black at 0% to white at
// 100%.  In the Lightworks effect the equivalent setting,
// tolerance, changes sense when the key is inverted.  This
// is unexpected to say the least and for that reason has
// been discarded.
//
// Key softness is produced symmetrically around the key
// boundaries.  This behaviour is more consistent with the
// way that a traditional analog luminance keyer works.
// When the key clip level is exceeded by the luminance
// full white is output to the alpha channel, unlike the
// Lightworks keyer which passes the luminance value
// unchanged.  That is completely incorrect and not at
// all consistent with the way that a keyer should work.
//
// The DVE is a simple 2D DVE, but zooming is achieved by
// Z-axis adjustment.  This is treated as an offset from
// zero, and has limted range only.  Negative values give
// size reduction which strictly speaking is incorrect,
// but feels more natural - smaller numbers equal smaller
// images.
//
// The crop section can be set up by dragging the upper left
// and lower right corners of the crop on the edit viewer, or
// in the normal way by dragging the sliders.  The crop is a
// simple hard edged one, and operates before the DVE.
//
// The alpha channel produced can either replace any existing
// foreground alpha channel or can be gated with it.  It can
// then be used to key the foreground over the background or
// passed on to other effects.  In this latter mode any
// background image will be suppressed.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lumakey with DVE";
   string Category    = "Key";
   string SubCategory = "Custom";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture InpCrop  : RenderColorTarget;
texture InpDVE   : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Cropped = sampler_state
{
   Texture   = <InpCrop>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_DVE = sampler_state
{
   Texture   = <InpDVE>;
   AddressU  = Mirror;
   AddressV  = Mirror;
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
   string Description = "Key clip";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Softness
<
   string Group = "Key settings";
   string Description = "Key softness";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

bool InvertKey
<
   string Group = "Key settings";
   string Description = "Invert key";
> = false;

bool ShowAlpha
<
   string Group = "Key settings";
   string Description = "Display alpha channel";
> = false;

float CentreX
<
   string Description = "DVE position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreY
<
   string Description = "DVE position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreZ
<
   string Description = "DVE position";
   string Flags = "SpecifiesPointZ";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropLeft
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropTop
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CropRight
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CropBottom
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define R_LUMA    0.2989
#define G_LUMA    0.5866
#define B_LUMA    0.1145

#define EMPTY     (0.0).xxxx

#define KEEP_BGD  0
#define ADD_ALPHA 1

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   return (uv.x >= CropLeft) && (uv.y >= 1.0 - CropTop)
       && (uv.x <= CropRight) && (uv.y <= 1.0 - CropBottom)
          ? tex2D (s_Foreground, uv) : EMPTY;
}

float4 ps_dve (float2 uv : TEXCOORD1) : COLOR
{
   float scale = pow (max ((CentreZ + 1.0) * 0.5, 0.0001) + 0.5, 4.0);

   float2 xy = ((uv - 0.5.xx) / scale) + float2 (-CentreX, CentreY) + 0.5.xx;

   return (xy.x >= 0.0) && (xy.x <= 1.0) && (xy.y >= 0.0) && (xy.y <= 1.0)
          ? tex2D (s_Cropped, xy) : EMPTY;
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   int BgMode = (int)floor (KeyMode * 0.5);
   int FgMode = KeyMode - (BgMode * 2);

   float4 Fgd = tex2D (s_DVE, xy1);
   float4 Bgd = (BgMode == KEEP_BGD) ? tex2D (s_Background, xy2) : EMPTY;

   float luma  = dot (Fgd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   float edge  = max (0.00001, Softness);
   float clip  = (KeyClip * 1.0002) - (edge * 0.5) - 0.0001;
   float alpha = saturate ((luma - clip) / edge);

   if (InvertKey) alpha = 1.0 - alpha;

   if (FgMode == ADD_ALPHA) alpha = min (Fgd.a, alpha);

   if (ShowAlpha) return float4 (alpha.xxx, 1.0);

   return lerp (Bgd, Fgd, alpha * Amount);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique LumakeyDVE
{
   pass P_1
   < string Script = "RenderColorTarget0 = InpCrop;"; >
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   < string Script = "RenderColorTarget0 = InpDVE;"; >
   { PixelShader = compile PROFILE ps_dve (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

