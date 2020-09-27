// @Maintainer jwrl
// @Released 2020-09-27
// @Author jwrl
// @Created 2017-05-09
// @see https://www.lwks.com/media/kunena/attachments/6375/FormatFixer_640.png

/**
 In versions 2020.1 and up Lightworks should automatically correct the image orientation.
 There will always be times when this won't happen, usually because the image doesn't
 have the necessary information stored in the file.  This effect can fix that.  It's
 designed to be a simple portrait to landscape rotator.  It can do this over a range of
 backgrounds.  With all background mix settings set to zero a transparent black surround
 is produced, and the resulting image may be blended with other effects.

 The foreground image can be rotated through plus or minus 90 degrees, or given a full 180
 degree rotation to invert the image.  As it is rotated it's also corrected for size so that
 no part of the image is lost.  The image can be independently scaled from one quarter size
 to four times it's actual size.  The width can be trimmed from half size to twice size to
 allow adjustment of the aspect ratio.

 A single symmetrical crop tool is provided to crop the left-right and top-bottom edges of
 the foreground.  This is also provided with a coloured border and feathering.  The vertical
 crop defaults to 110% of screen height to ensure that no colour bleed or feathering will be
 visible unless it's absolutely required.  The crop width tracks the rotation and scaling of
 the foreground automatically.

 The three mix faders have a bottom up priority.  That is, the colour fader has highest
 priority and overrides all others.  The foreground fader has higher priority than the
 background fader and overrides it.  The background fader simply fades from transparent
 to full.  Both foreground and background mixes can be negative to make the corresponding
 image negative.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FormatFixer.fx
//
// Version history:
//
// Update 2020-09-27 jwrl.
// Amended header block.
//
// Modified 2020-04-24 jwrl.
// Reduced the number of shader passes from 5 to 4.
// Bypassed the box blur if neither foreground nor external backgrounds are used.
// Extended crop range by 10% in X and Y directions to hide edge softness at edge of frame.
// Extended the mix range of foreground and background to -100%.  Negative values make the
// selected image negative.
// Explicitly defined alpha support in border and background colour.  This now means that
// setting the background colour to black produces opaque black.
//
// Modified 2018-12-26 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 2018-12-05 jwrl.
// Changed subcategory.
//
// Modified 6 July 2018 jwrl.
// Added four flipped orientation modes to the foreground settings.
// Prevented the crop function from over-running the centre point of the video.
// Modified the background scaling to be influenced by the crop settings.
// The blur settings are now frame based rather than pixel based.
//
// Modified 23 June 2018 jwrl.
// Updated legality check function.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.  This effect should now function correctly when used with
// all current and previous Lightworks versions.
//
// Bug fix by LW user jwrl 13 July 2017
// Corrected a syntax variation that meant that this effect may not work as expected on
// Linux/Mac platforms.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Format fixer";
   string Category    = "DVE";
   string SubCategory = "Repair tools";
   string Notes       = "Designed to fix landscape/portrait format and image rotation problems";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fgd;
texture Bgd;

texture Input : RenderColorTarget;
texture Fill  : RenderColorTarget;
texture Blur  : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state {
   Texture   = <Fgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state { Texture = <Bgd>; };

sampler s_Input = sampler_state {
   Texture   = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Fill = sampler_state
{
    Texture  = <Fill>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blur = sampler_state
{
   Texture   = <Blur>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int fgRotate
<
   string Group = "Foreground";
   string Description = "Rotation";
   string Enum = "None,90 degrees clockwise,180 degree inversion,90 degrees anticlockwise,Flip,Flip + 90 degrees CW,Flop,Flip + 90 degrees ACW";
> = 0;

float fgZoom
<
   string Group = "Foreground";
   string Description = "Scale image";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float fgWidth
<
   string Group = "Foreground";
   string Description = "Adjust width";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Crop_X
<
   string Group = "Foreground";
   string Description = "Crop";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 1.1;
> = 0.0;

float Crop_Y
<
   string Group = "Foreground";
   string Description = "Crop";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 1.1;
> = 1.1;

float BorderWidth
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float BorderFeather
<
   string Group = "Border";
   string Description = "Feathering";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 BorderColour
<
   string Group = "Border";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.0, 0.125, 0.25, 0.0 };

float Bgd_Mix
<
   string Group = "Background mixes";
   string Description = "External bgd";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Fgd_Mix
<
   string Group = "Background mixes";
   string Description = "Foreground";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 1.0;

float Colour_Mix
<
   string Group = "Background mixes";
   string Description = "Colour";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float bgBlur
<
   string Group = "Background mixes";
   string Description = "Blur";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int bgRotate
<
   string Group = "Background components";
   string Description = "Foreground orientation";
   string Enum = "Unchanged,Flip horizontal,180 degree rotation,Flop vertical";
> = 0;

float bgStretchX
<
   string Group = "Background components";
   string Description = "Fgd X stretch";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float bgStretchY
<
   string Group = "Background components";
   string Description = "Fgd Y stretch";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float bgOffsetX
<
   string Group = "Background components";
   string Description = "Fgd X displace";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float bgOffsetY
<
   string Group = "Background components";
   string Description = "Fgd Y displace";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float4 bgColour
<
   string Group = "Background components";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.25, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define DIVISOR    15

#define NONE       0
#define TURN_CW    1
#define FLIP       1
#define TURN_180   2
#define TURN_CCW   3
#define FLOP       3

#define BLUR_SCALE 0.005

#define BRDR_SCALE 0.0666666667
#define BRDR_FTHR  0.1

#define EMPTY      (0.0).xxxx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0) ? EMPTY
        : tex2D (Vsample, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_foreground (float2 uv : TEXCOORD1) : COLOR
{
   float vScale = 1.0 - fgZoom + (max (0.0, fgZoom) * 0.5);
   float hScale = 1.0 - fgWidth + (max (0.0, fgWidth) * 0.5);
   float rotate = fgRotate;

   vScale *= vScale;
   hScale *= vScale;

   float2 xy1 = uv - 0.5.xx;

   if (fgRotate > TURN_CCW) {
      rotate -= 4;

      if ((rotate == TURN_CW) || (rotate == TURN_CCW)) xy1.y = -xy1.y;
      else xy1.x = -xy1.x;
   }

   float2 xy2 = xy1 * float2 (hScale, vScale);

   if ((rotate == TURN_CW) || (rotate == TURN_CCW)) {
      float scale = _OutputAspectRatio * _OutputAspectRatio;

      xy2 = xy2.yx;
      xy2.y = -xy2.y * scale;

      hScale *= scale;
   }

   xy2 = (rotate > TURN_CW) ? 0.5.xx - xy2 : xy2 + 0.5.xx;

   float2 Feather = float2 (1.0, _OutputAspectRatio) * max (0.0, BorderFeather) * BRDR_FTHR;
   float2 Border  = float2 (1.0, _OutputAspectRatio) * max (0.0, BorderWidth) * BRDR_SCALE;
   float2 cropval = (Feather + (0.5 / float2 (hScale, vScale))) * float2 (1.0 - Crop_X, Crop_Y) - abs (xy1);
   float2 brdrval = max (0.0.xx, (cropval + Border) / Feather);

   float4 Fgnd = fn_tex2D (s_Foreground, xy2);
   float4 retval = lerp (Fgnd, BorderColour, min (1.0, BorderWidth * 50.0));

   retval.a = min (1.0, min (brdrval.x, brdrval.y));
   cropval  = max (0.0.xx, cropval / Feather);

   float alpha = min (1.0, min (cropval.x, cropval.y));

   return lerp (retval, Fgnd, alpha);
}

float4 ps_background (float2 uv : TEXCOORD1) : COLOR
{
   float2 bgStretch, xy;

   if ((fgRotate == TURN_CW) || (fgRotate == TURN_CCW)) {
      xy = float2 (uv.y, 1.0 - uv.x);
   }
   else xy = uv;

   xy = (fgRotate > TURN_CW) ? 0.5.xx - xy : xy - 0.5.xx;

   if (bgRotate != NONE) {
      if (bgRotate != FLOP) xy.x = -xy.x;
      if (bgRotate != FLIP) xy.y = -xy.y;
   }

   bgStretch.x = (bgStretchX < 0.0) ? max (bgStretchX * 0.5, -0.9) : bgStretchX * (1.0 + (Crop_X * 2.5));
   bgStretch.y = (bgStretchY < 0.0) ? max (bgStretchY * 0.5, -0.9) : bgStretchY * (1.0 + (Crop_Y * 2.5));

   xy = saturate ((xy / (bgStretch + 1.0.xx)) - (float2 (bgOffsetX, bgOffsetY)) + 0.5);

   float4 Fgnd = fn_tex2D (s_Foreground, xy);
   float4 Bgnd = tex2D (s_Background, uv);

   if (Fgd_Mix < 0.0) Fgnd.rgb = 1.0.xxx - Fgnd.rgb;
   if (Bgd_Mix < 0.0) Bgnd.rgb = 1.0.xxx - Bgnd.rgb;

   Bgnd *= abs (Bgd_Mix);

   float4 retval = lerp (Bgnd, Fgnd, abs (Fgd_Mix));

   return lerp (retval, bgColour, Colour_Mix);
}

float4 ps_blur_X (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Fill, uv);

   if ((Bgd_Mix != 0.0) || (Fgd_Mix != 0.0)) {

      // We only do the box blur if there is a valid image to blur.
      // It's pointless blurring a plain colour or transparency.

      float2 blur_offset = float2 (bgBlur * BLUR_SCALE, 0.0);
      float2 xy = uv + blur_offset;

      retval += tex2D (s_Fill, xy); xy += blur_offset;
      retval += tex2D (s_Fill, xy); xy += blur_offset;
      retval += tex2D (s_Fill, xy); xy += blur_offset;
      retval += tex2D (s_Fill, xy); xy += blur_offset;
      retval += tex2D (s_Fill, xy); xy += blur_offset;
      retval += tex2D (s_Fill, xy); xy += blur_offset;
      retval += tex2D (s_Fill, xy); xy  = uv - blur_offset;
      retval += tex2D (s_Fill, xy); xy -= blur_offset;
      retval += tex2D (s_Fill, xy); xy -= blur_offset;
      retval += tex2D (s_Fill, xy); xy -= blur_offset;
      retval += tex2D (s_Fill, xy); xy -= blur_offset;
      retval += tex2D (s_Fill, xy); xy -= blur_offset;
      retval += tex2D (s_Fill, xy); xy -= blur_offset;
      retval += tex2D (s_Fill, xy);

      retval /= DIVISOR;
   }

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd   = tex2D (s_Input, uv);
   float4 retval = tex2D (s_Blur, uv);

   if ((Bgd_Mix != 0.0) || (Fgd_Mix != 0.0)) {

      float2 blur_offset = float2 (0.0, bgBlur * _OutputAspectRatio * BLUR_SCALE);
      float2 xy = uv + blur_offset;

      retval += tex2D (s_Blur, xy); xy += blur_offset;
      retval += tex2D (s_Blur, xy); xy += blur_offset;
      retval += tex2D (s_Blur, xy); xy += blur_offset;
      retval += tex2D (s_Blur, xy); xy += blur_offset;
      retval += tex2D (s_Blur, xy); xy += blur_offset;
      retval += tex2D (s_Blur, xy); xy += blur_offset;
      retval += tex2D (s_Blur, xy); xy  = uv - blur_offset;
      retval += tex2D (s_Blur, xy); xy -= blur_offset;
      retval += tex2D (s_Blur, xy); xy -= blur_offset;
      retval += tex2D (s_Blur, xy); xy -= blur_offset;
      retval += tex2D (s_Blur, xy); xy -= blur_offset;
      retval += tex2D (s_Blur, xy); xy -= blur_offset;
      retval += tex2D (s_Blur, xy); xy -= blur_offset;
      retval += tex2D (s_Blur, xy);

      retval /= DIVISOR;
   }

   return lerp (retval, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FormatFixer
{
   pass P_1
   < string Script = "RenderColorTarget0 = Input;"; >
   { PixelShader = compile PROFILE ps_foreground (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Fill;"; >
   { PixelShader = compile PROFILE ps_background (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Blur;"; >
   { PixelShader = compile PROFILE ps_blur_X (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}
