// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect FormatFixer.fx
//
// Created by LW user jwrl 9 May 2017.
// @Author jwrl
// @Created "9 May 2017"
//
// This effect is designed to be a very straightforward
// portrait to landscape rotator/180 degree rotator.  This it
// does very effectively over a mixture of backgrounds.  With
// all background mix settings set to zero a transparent
// black surround is produced, and the resulting image may be
// blended with other effects.
//
// The foreground image can be rotated through plus or minus
// 90 degrees, or given a full 180 degree rotation to invert
// the image.  As it is rotated it's also corrected for size
// so that no part of the image is lost.  The image can be
// independently scaled from one quarter size to four times
// it's actual size.  The width can be trimmed from half size
// to twice size to allow adjustment of the aspect ratio.
//
// A single symmetrical crop tool is provided to crop the
// left-right and top-bottom edges of the foreground.  This
// is also provided with a coloured border and feathering.
// The vertical crop defaults to 110% of screen height to
// ensure that no colour bleed or feathering will be visible
// unless it's absolutely required.  The crop width tracks
// the rotation and scaling of the foreground automatically.
//
// The three mix faders have a bottom up priority.  That is,
// the colour fader has highest priority and overrides all
// others.  The foreground fader has higher priority than
// the background fader and overrides it.  The background
// fader simply fades from black to 100% level.
//
// Bug fix by LW user jwrl 13 July 2017 - this effect didn't
// work as expected on Linux/Mac platforms.  It now does.
//
// Version 14.5 update 24 March 2018 by jwrl.
//
// Legality checking has been added to correct for a bug
// in XY sampler addressing on Linux and OS-X platforms.
// This effect should now function correctly when used with
// all current and previous Lightworks versions.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Format fixer";
   string Category    = "DVE";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fgd;
texture Bgd;

texture Input  : RenderColorTarget;
texture Blur_1 : RenderColorTarget;
texture Blur_2 : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgdSampler = sampler_state {
   Texture   = <Fgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state {
   Texture   = <Bgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler InpSampler = sampler_state {
   Texture   = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler b1_Sampler = sampler_state
{
   Texture   = <Blur_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler b2_Sampler = sampler_state
{
    Texture  = <Blur_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int fgRotate
<
   string Group = "Foreground";
   string Description = "Rotation";
   string Enum = "None,90 degrees clockwise,180 degree inversion,90 degrees anticlockwise";
> = 0;

float fgZoom
<
   string Group = "Foreground";
   string Description = "Scale image";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.00;

float fgWidth
<
   string Group = "Foreground";
   string Description = "Adjust width";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.00;

float Crop_X
<
   string Group = "Foreground";
   string Description = "Crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Crop_Y
<
   string Group = "Foreground";
   string Description = "Crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
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
> = { 0.0, 0.125, 0.25, 0.0 };

float Bgd_Mix
<
   string Group = "Background mixes";
   string Description = "External bgd";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Fgd_Mix
<
   string Group = "Background mixes";
   string Description = "Foreground";
   float MinVal = 0.0;
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
> = { 0.0, 0.0, 0.25, 0.0 };

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define DIVISOR  15

#define TURN_CW  1
#define FLIP     1
#define TURN_180 2
#define TURN_CCW 3
#define FLOP     3

#define BRDR_SCALE 0.0666667
#define BRDR_FTHR  0.1

#define EMPTY      (0.0).xxxx

float _OutputAspectRatio;
float _OutputWidth;

#define Output_Height (_OutputWidth/_OutputAspectRatio)

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_foreground (float2 uv : TEXCOORD1) : COLOR
{
   float vScale = 1.0 - fgZoom + (max (0.0, fgZoom) * 0.5);
   float hScale = 1.0 - fgWidth + (max (0.0, fgWidth) * 0.5);

   vScale *= vScale;
   hScale *= vScale;

   float2 xy = (uv - 0.5.xx) * float2 (hScale, vScale);

   if ((fgRotate == TURN_CW) || (fgRotate == TURN_CCW)) {
      xy = xy.yx;
      xy.y = -xy.y * _OutputAspectRatio * _OutputAspectRatio;

      hScale *=  _OutputAspectRatio * _OutputAspectRatio;
   }

   xy = (fgRotate > TURN_CW) ? 0.5 - xy : xy + 0.5;

   float2 Feather = float2 (1.0, _OutputAspectRatio) * max (0.0, BorderFeather) * BRDR_FTHR;
   float2 Border  = float2 (1.0, _OutputAspectRatio) * max (0.0, BorderWidth) * BRDR_SCALE;
   float2 cropval = abs (float2 ((Crop_X - 0.5) / hScale, (0.5 - Crop_Y) / vScale)) - abs (uv - 0.5.xx);
   float2 brdrval = cropval + Border;

   float4 Fgnd = fn_illegal (xy) ? EMPTY : tex2D (FgdSampler, xy);
   float4 retval = lerp (Fgnd, BorderColour, min (1.0, BorderWidth * 50.0));

   brdrval  = max (0.0.xx, brdrval / Feather);
   retval.a = min (1.0, min (brdrval.x, brdrval.y));

   cropval += Feather / 2.0;
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

   if ((bgRotate == FLIP) || (bgRotate == TURN_180)) xy.x = -xy.x;
   if ((bgRotate == FLOP) || (bgRotate == TURN_180)) xy.y = -xy.y;

   bgStretch.x = (bgStretchX < 0.0) ? max (bgStretchX * 0.5, -0.9) : bgStretchX;
   bgStretch.y = (bgStretchY < 0.0) ? max (bgStretchY * 0.5, -0.9) : bgStretchY;

   xy = saturate ((xy / (bgStretch + 1.0)) - (float2 (bgOffsetX, bgOffsetY)) + 0.5);

   float4 Fgnd   = fn_illegal (xy) ? EMPTY : tex2D (FgdSampler, xy);
   float4 Bgnd   = tex2D (BgdSampler, uv) * Bgd_Mix;
   float4 retval = lerp (Bgnd, Fgnd, Fgd_Mix);

   return lerp (retval, bgColour, Colour_Mix);
}

float4 ps_blur_X (float2 uv : TEXCOORD1) : COLOR
{
   float sample_width = 10.0 * bgBlur / _OutputWidth;

   float2 blur_offset = float2 (sample_width, 0.0);
   float2 xy = uv + blur_offset;

   float4 retval = tex2D (b2_Sampler, uv);

   retval += tex2D (b2_Sampler, xy); xy += blur_offset;
   retval += tex2D (b2_Sampler, xy); xy += blur_offset;
   retval += tex2D (b2_Sampler, xy); xy += blur_offset;
   retval += tex2D (b2_Sampler, xy); xy += blur_offset;
   retval += tex2D (b2_Sampler, xy); xy += blur_offset;
   retval += tex2D (b2_Sampler, xy); xy += blur_offset;
   retval += tex2D (b2_Sampler, xy); xy = uv - blur_offset;
   retval += tex2D (b2_Sampler, xy); xy -= blur_offset;
   retval += tex2D (b2_Sampler, xy); xy -= blur_offset;
   retval += tex2D (b2_Sampler, xy); xy -= blur_offset;
   retval += tex2D (b2_Sampler, xy); xy -= blur_offset;
   retval += tex2D (b2_Sampler, xy); xy -= blur_offset;
   retval += tex2D (b2_Sampler, xy); xy -= blur_offset;
   retval += tex2D (b2_Sampler, xy);

   return retval / DIVISOR;
}

float4 ps_blur_Y (float2 uv : TEXCOORD1) : COLOR
{
   float sample_height = 10.0 * bgBlur / Output_Height;

   float2 blur_offset = float2 (0.0, sample_height);
   float2 xy = uv + blur_offset;

   float4 retval = tex2D (b1_Sampler, uv);

   retval += tex2D (b1_Sampler, xy); xy += blur_offset;
   retval += tex2D (b1_Sampler, xy); xy += blur_offset;
   retval += tex2D (b1_Sampler, xy); xy += blur_offset;
   retval += tex2D (b1_Sampler, xy); xy += blur_offset;
   retval += tex2D (b1_Sampler, xy); xy += blur_offset;
   retval += tex2D (b1_Sampler, xy); xy += blur_offset;
   retval += tex2D (b1_Sampler, xy); xy = uv - blur_offset;
   retval += tex2D (b1_Sampler, xy); xy -= blur_offset;
   retval += tex2D (b1_Sampler, xy); xy -= blur_offset;
   retval += tex2D (b1_Sampler, xy); xy -= blur_offset;
   retval += tex2D (b1_Sampler, xy); xy -= blur_offset;
   retval += tex2D (b1_Sampler, xy); xy -= blur_offset;
   retval += tex2D (b1_Sampler, xy); xy -= blur_offset;
   retval += tex2D (b1_Sampler, xy);

   return retval / DIVISOR;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (InpSampler, uv);
   float4 Bgnd = tex2D (b2_Sampler, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique formatFixer
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = Input;";
   >
   {
      PixelShader = compile PROFILE ps_foreground ();
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = Blur_2;";
   >
   {
      PixelShader = compile PROFILE ps_background ();
   }

   pass pass_three
   <
      string Script = "RenderColorTarget0 = Blur_1;";
   >
   {
      PixelShader = compile PROFILE ps_blur_X ();
   }

   pass pass_four
   <
      string Script = "RenderColorTarget0 = Blur_2;";
   >
   {
      PixelShader = compile PROFILE ps_blur_Y ();
   }

   pass pass_five
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

