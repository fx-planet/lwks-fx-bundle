// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect 70s_psych.fx
//
// Created by LW user jwrl 11 May 2016
// @Author jwrl
// @CreationDate "11 May 2016"
//
// This is an entirely original effect, but feel free to do
// what you will with it.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  THE BUG WAS NOT IN THE WAY THIS EFFECT
// WAS ORIGINALLY IMPLEMENTED.
//
// It appears that when a height parameter is needed one can
// not reliably use _OutputHeight.  It returns only half the
// actual frame height when interlaced media is playing and
// only when it is playing.  For that reason the output height
// should always be obtained by dividing _OutputWidth by
// _OutputAspectRatio until such time as the bug in the
// Lightworks code can be fixed.  It seems that after contact
// with the developers that is very unlikely to be soon.
//
// Note: This fix has been fully tested, and appears to be a
// reliable solution regardless of the pixel aspect ratio.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "70s Psychedelia";
   string Category    = "Stylize";
   string SubCategory = "Textures";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture Processed : RenderColorTarget;
texture Contours  : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state {
        Texture   = <Input>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler Process_S = sampler_state {
        Texture   = <Processed>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler Contour_S = sampler_state {
        Texture   = <Contours>;
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
   string Description = "Pattern mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Contouring
<
   string Description = "Contour level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Smudge
<
   string Description = "Smudger";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float4 ColourOne
<
   string Group = "Colours";
   string Description = "Colour one";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

float4 ColourTwo
<
   string Group = "Colours";
   string Description = "Colour two";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 0.0, 1.0 };

float4 ColourBase
<
   string Group = "Colours";
   string Description = "Base colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float Hue
<
   string Group = "Colours";
   string Description = "Hue";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

float Saturation
<
   string Group = "Colours";
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Monochrome
<
   string Group = "Colours";
   string Description = "Monochrome";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define DELTANG_1  25
#define ALIASFIX   50
#define ANGLE_1    0.125664

#define DELTANG_2  29
#define BLURFIX    58
#define ANGLE_2    0.108331

#define LUMA_RED   0.3
#define LUMA_GREEN 0.59
#define LUMA_BLUE  0.11

#define EMPTY      0.0.xxxx

float _OutputAspectRatio;
float _OutputWidth;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_gene (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = EMPTY;

   float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 offset, scale;

   float angle = 0.0;

   for (int i = 0; i < DELTANG_1; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;

      retval += tex2D (FgSampler, xy + offset);
      retval += tex2D (FgSampler, xy - offset);

      angle += ANGLE_1;
   }

   retval /= ALIASFIX;

   float amtC = Contouring + 0.025;
   float Col1 = frac ((0.5 + retval.r + retval.b) * 29.0 * amtC);
   float Col2 = frac ((0.5 + retval.g) * 13.0 * amtC);

   float4 rgb = max (ColourBase, max ((ColourOne * Col1), (ColourTwo * Col2)));
   retval     = (rgb + min (ColourBase, min ((ColourOne * Col1), (ColourTwo * Col2)))) / 2.0;
   retval.a   = Col1 * 0.333333 + Col1 * 0.666667;

   return retval;
}

float4 ps_hueSat (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (FgSampler, xy);
   float4 rgb    = tex2D (Process_S, xy);

   float luma  = rgb.a;

   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float4 hsv = float2 (0.0, Cmax).xxyx;

   if (Cmax != 0.0) {
      hsv.y = 1.0 - (Cmin / Cmax);

      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
   }

   if (hsv.y != 0.0) {
      float satVal = Saturation + 1.0;

      if (Saturation > 0.0) hsv.y *= satVal;

      hsv.x += Hue / 360.0;

      if (hsv.x > 1.0) hsv.x -= 1.0;

      if (hsv.x < 0.0) hsv.x += 1.0;

      hsv.x *= 6.0;

      int i = (int) floor (hsv.x);

      hsv.x = frac (hsv.x);

      float p = hsv.z * (1.0 - hsv.y);
      float q = hsv.z * (1.0 - hsv.y * hsv.x);
      float r = hsv.z * (1.0 - hsv.y * (1.0 - hsv.x));

      rgb.rgb = (i == 0) ? float3 (hsv.z, r, p) : (i == 1) ? float3 (q, hsv.z, p)
              : (i == 2) ? float3 (p, hsv.z, r) : (i == 3) ? float3 (p, q, hsv.z)
              : (i == 4) ? float3 (r, p, hsv.z) : float3 (hsv.z, p, q);

      float luma1 = (rgb.r * LUMA_RED) + (rgb.g * LUMA_GREEN) + (rgb.b * LUMA_BLUE);

      rgb = lerp (float2 (luma1, 1.0).xxxy, rgb, saturate (satVal));
   }

   retval.rgb = lerp (rgb.rgb, luma.xxx, Monochrome);

   return retval;
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 Fgnd  = tex2D (FgSampler, xy);
   float4 pattern = EMPTY;

   float blur  = 1.0 + (Smudge * 5.0);
   float angle = 0.0;

   float2 pixsize = float2 (1.0, _OutputAspectRatio) * blur / _OutputWidth;
   float2 offset, scale;

   for (int j = 0; j < DELTANG_2; j++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;

      pattern += tex2D (Contour_S, xy + offset);
      pattern += tex2D (Contour_S, xy - offset);

      angle += ANGLE_2;
   }

   pattern /= BLURFIX;

   return lerp (Fgnd, pattern, Amount);
}

//--------------------------------------------------------------
// Techniques
//--------------------------------------------------------------

technique TopToBottom
{
   pass P_1
   < string Script = "RenderColorTarget0 = Processed;"; >
   { PixelShader = compile PROFILE ps_gene (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Contours;"; >
   { PixelShader = compile PROFILE ps_hueSat (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

