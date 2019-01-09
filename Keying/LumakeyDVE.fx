// @Maintainer jwrl
// @Released 2018-09-29
// @Author jwrl
// @Created 2018-03-20
// @see https://www.lwks.com/media/kunena/attachments/6375/LumakeyDVE_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect LumakeyDVE.fx
//
// This keyer uses an algorithm derived from the Editshare lumakey effect, but this
// implementation is entirely my own.  A crop function and a simple DVE has also been
// added to provide these often-needed functions without the need to add external
// effects.
//
// The most obvious difference with the keyer is in the way that the parameters are
// labelled.  "Tolerance" is now called "Key clip", "Edge Softness" is "Key Softness"
// and "Invert" has become "Invert key".  These are the industry standard names used
// for these functions, so this change makes the effect more consistent with existing
// tools.
//
// Regardless of whether the key is inverted or not, the clip setting always works
// from black at 0% to white at 100%.  In the Lightworks effect the equivalent setting,
// tolerance, changes sense when the key is inverted.  This is unexpected to say the
// least and for that reason has been discarded.
//
// Key softness is produced symmetrically around the key boundaries.  This behaviour
// is more consistent with the way that a traditional analog luminance keyer works.
// When the key clip level is exceeded by the luminance full white is output to the
// alpha channel, unlike the Lightworks keyer which passes the luminance value
// unchanged.  That is completely incorrect and not at all consistent with the way
// that a keyer should work.
//
// The DVE is a simple 2D DVE, but zooming is achieved by Z-axis adjustment.  This is
// treated as an offset from zero, and has limted range only.  Negative values give
// size reduction which strictly speaking is incorrect, but feels more natural -
// smaller numbers equal smaller images.
//
// The crop section can be set up by dragging the upper left and lower right corners
// of the crop on the edit viewer, or in the normal way by dragging the sliders.  The
// crop is a simple hard edged one, and operates before the DVE.
//
// The alpha channel produced can either replace any existing foreground alpha channel
// or can be gated with it.  It can then be used to key the foreground over the
// background or passed on to other effects.  In this latter mode any background image
// will be suppressed.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 22 April 2018 jwrl.
// Merged DVE operation with main shader, reducing the number of passes required by one
// and the samplers required by one also.
// No longer explicitly define addressing/filtering of Fg and Bg.  Defaults are OK here.
// Changed the exit implementation - logically the same, cosmetically different.
// Range limited the crop settings.  It's no longer possible to exceed frame boundaries.
// Restored comments to the code to assist anyone trying to work out what on earth I did.
//
// IMPORTANT ATTRIBUTION INFORMATION:
// The code in this effect is original work by Lightworks user jwrl, and developed for
// use in the Lightworks non-linear editor.  Should this effect be ported to another
// edit platform or used in part or in whole in an effect in any other non-linear
// editor this attribution in its entirety must be included.  Negotiations to modify or
// suspend this requirement can be undertaken by contacting jwrl at www.lwks.com, where
// the original effect and the software on which it was designed to run may also be found.
//
// Modified 29 September 2018 jwrl.
// Added notes to header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lumakey with DVE";
   string Category    = "Key";
   string SubCategory = "Custom";
   string Notes       = "A keyer which respects any existing foreground alpha and can pass the generated alpha to external effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture InpCrop  : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Cropped = sampler_state
{
   Texture   = <InpCrop>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define R_LUMA    0.2989
#define G_LUMA    0.5866
#define B_LUMA    0.1145

#define EMPTY     (0.0).xxxx

#define KEEP_BGD  0
#define ADD_ALPHA 1

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   // Range limit X and Y crop values and invert the Y values so that more positive
   // Y settings move the crop line up the screen rather than down as they do in Cg.

   float left  = max (0.0, CropLeft);
   float right = min (1.0, CropRight);
   float top   = max (0.0, 1.0 - CropTop);
   float botm  = min (1.0, 1.0 - CropBottom);

   return (uv.x >= left) && (uv.y >= top) && (uv.x <= right) && (uv.y <= botm)
          ? tex2D (s_Foreground, uv) : EMPTY;
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   // Extract the background and foreground modes from KeyMode

   int BgMode = (int)floor (KeyMode * 0.5);

   bool addAlpha = (KeyMode - (BgMode * 2)) == ADD_ALPHA;

   // Set up range limited DVE scaling.  Values of zero or below will be ignored if
   // input manually.  The minimum value will be limited to 0.0001.

   float scale = pow (max ((CentreZ + 2.0) * 0.5, 0.0001), 4.0);

   // Set up pixel addressing for the Fgd parameter to produce the DVE effect

   float2 xy3 = ((xy1 - 0.5.xx) / scale) + float2 (-CentreX, CentreY) + 0.5.xx;

   // Recover background and foreground, limiting the foreground to legal addresses.  This
   // is done to ensure that the differences in cross platform edge clamping are bypassed.

   float4 Bgd = (BgMode == KEEP_BGD) ? tex2D (s_Background, xy2) : EMPTY;
   float4 Fgd = (xy3.x >= 0.0) && (xy3.x <= 1.0) && (xy3.y >= 0.0) && (xy3.y <= 1.0)
              ? tex2D (s_Cropped, xy3) : EMPTY;

   // Set up the key clip and softness from the Fgd luminance

   float luma  = dot (Fgd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   float edge  = max (0.00001, Softness);
   float clip  = (KeyClip * 1.0002) - (edge * 0.5) - 0.0001;
   float alpha = saturate ((luma - clip) / edge);

   // Invert the alpha if needed and optionally gate it with Fgd.a then quit

   if (InvertKey) alpha = 1.0 - alpha;

   if (addAlpha) alpha = min (Fgd.a, alpha);

   return (ShowAlpha) ? float4 (alpha.xxx, 1.0) : lerp (Bgd, Fgd, alpha * Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LumakeyDVE
{
   pass P_1
   < string Script = "RenderColorTarget0 = InpCrop;"; >
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
