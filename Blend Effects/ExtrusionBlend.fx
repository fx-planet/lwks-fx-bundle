// @Maintainer jwrl
// @Released 2020-07-11
// @Author jwrl
// @Created 2016-04-02
// @see https://www.lwks.com/media/kunena/attachments/6375/ExtrusionMatte_640.png

/**
 "Extrusion blend", as the name suggests, extrudes a foreground image either linearly or
 radially towards a centre point.  The extruded section can be shaded by the foreground
 image, colour shaded, or flat colour filled.  The edge shading can be inverted if desired.
 It is also possible to export the alpha channel for use in downstream effects.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ExtrusionBlend.fx
//
// Version history:
//
// Update 11 July 2020 jwrl.
// Added a delta key to separate blended effects from the background.
// THIS MAY (BUT SHOULDN'T) BREAK BACKWARD COMPATIBILITY!!!
//
// Update 23 December 2018 jwrl.
// Converted to version 14.5 and up.
// Modified Windows version to compile as ps_3_0.
// Formatted the descriptive block so that it can automatically be read.
//
// Update 25 November 2018 jwrl.
// Changed name to "Extrusion blend".
// Changed category to "Mix".
// Changed subcategory to "Blend Effects".
// Added alpha boost for Lightworks titles.
//
// Modified 30 August 2018 jwrl.
// Added notes to header.
//
// Modified 5 April 2018
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Bug fix 26 March 2018
// Corrected a hue problem with the extrusion generation.
//
// Bug fix 26 July 2017
// Because Windows and Linux-OS/X have differing defaults for undefined samplers
// they have now been explicitly declared.
//
// Bug fix 26 February 2017
// This corrects for a bug in the way that Lightworks handles interlaced media.  It
// returns only half the actual frame height when interlaced media is stationary.
//
// LW 14+ version 11 January 2017
// Subcategory "Edge Effects" added.
//
// Modified 6 May 2016.
// Extrusion anti-ailasing added.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Extrusion blend";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Extrudes a foreground image either linearly or radially towards a centre point";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture blurPre  : RenderColorTarget;
texture colorPre : RenderColorTarget;
texture blurProc : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blur = sampler_state
{
   Texture   = <blurPre>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Colour = sampler_state
{
   Texture   = <colorPre>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Processed = sampler_state
{
   Texture   = <blurProc>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Edge type";
   string Enum = "Radial,Radial shaded,Radial coloured,Linear,Linear shaded,Linear coloured";
> = 0;

float Opacity
<
   string Description = "Master opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amount
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float zoomAmount
<
   string Description = "Length";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float4 colour
<
   string Group = "Colour setup";
   string Description = "Edge colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.3804, 1.0, 0.0 };

bool invShade
<
   string Description = "Invert shading";
> = false;

bool expAlpha
<
   string Description = "Export alpha channel";
> = false;

int Source
<
   string Description = "Source selection (disconnect input to text effects first)";
   string Enum = "Crawl / roll / titles,Video / external image,Extracted foreground";
> = 1;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SAMPLE   80
#define HALFWAY  40              // SAMPLE / 2
#define SAMPLES  81              // SAMPLE + 1.0

#define DELTANG  25
#define ALIASFIX 50              // DELTANG * 2
#define ANGLE    0.125664

#define B_SCALE  0.0075
#define L_SCALE  0.05
#define R_SCALE  0.00125

#define DEFAULT  0
#define COLOUR   1
#define MONO     2

#define LIN_OFFS 0.667333

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   float4 Fgd = tex2D (s_Sampler, uv);

   if (Source == 0) {
      Fgd.a    = pow (Fgd.a, 0.5);
      Fgd.rgb /= Fgd.a;
   }
   else if (Source == 2) {
      if (Fgd.a == 0.0) return 0.0.xxxx;

      float4 Bgd = tex2D (s_Background, uv);

      float kDiff = distance (Fgd.g, Bgd.g);

      kDiff = max (kDiff, distance (Fgd.r, Bgd.r));
      kDiff = max (kDiff, distance (Fgd.b, Bgd.b));

      Fgd.a = smoothstep (0.0, 0.25, kDiff);
      Fgd.rgb *= Fgd.a;
   }

   return Fgd;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_radial (float2 uv : TEXCOORD1, uniform int mode) : COLOR
{
   float4 retval = fn_tex2D (s_Foreground, uv);

   if (zoomAmount == 0.0) return retval;

   float scale, depth = zoomAmount * R_SCALE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1 = uv;
   float2 xy2 = depth * (uv - zoomCentre);

   retval.rgb = 1.0.xxx - retval.rgb;

   for (int i = 0; i <= SAMPLE; i++) {
      retval += fn_tex2D (s_Foreground, xy1);
      xy1 += xy2;
   }

   retval.a = saturate (retval.a);

   if (mode == COLOUR) return float4 (colour.rgb, retval.a);

   retval.rgb = ((retval.rgb / SAMPLES) * 0.75) + 0.125;

   if (((mode == DEFAULT) && !invShade) || ((mode != DEFAULT) && invShade))
      return retval;

   return float4 (1.0.xxx - retval.rgb, retval.a);
}

float4 ps_linear (float2 uv : TEXCOORD1, uniform int mode) : COLOR
{
   float4 retval = fn_tex2D (s_Foreground, uv);

   float2 offset, xy = uv;

   offset.x = (0.498 - Xcentre) * LIN_OFFS;
   offset.y = (Ycentre - 0.505) * LIN_OFFS;

   if ((max (abs (offset.x), abs (offset.y)) == 0.0) || (zoomAmount == 0.0)) return retval;

   float depth = zoomAmount * L_SCALE;

   retval.rgb = 1.0.xxx - retval.rgb;
   offset *= 1.0 / sqrt ((offset.x * offset.x) + (offset.y * offset.y));
   offset *= depth * B_SCALE;

   for (int i = 0; i < SAMPLES; i++) {
      retval += fn_tex2D (s_Foreground, xy);
      xy += offset;
      }

   retval.a = saturate (retval.a);

   if (mode == COLOUR) return float4 (colour.rgb, retval.a);

   retval.rgb = ((retval.rgb / SAMPLES) * 0.75) + 0.125;

   if (((mode == DEFAULT) && !invShade) || ((mode != DEFAULT) && invShade))
      return retval;

   return float4 (1.0.xxx - retval.rgb, retval.a);
}

float4 ps_shaded (float2 uv : TEXCOORD1) : COLOR
{
   float4 blurImg = tex2D (s_Blur, uv);
   float4 colrImg = tex2D (s_Colour, uv);

   float alpha   = blurImg.a;
   float minColr = min (colrImg.r, min (colrImg.g, colrImg.b));
   float maxColr = max (colrImg.r, max (colrImg.g, colrImg.b));
   float delta   = maxColr - minColr;

   float3 hsv = 0.0.xxx;

   if (maxColr != 0.0) {
      hsv.y = 1.0 - (minColr / maxColr);
      hsv.x = (colrImg.r == maxColr) ? (colrImg.g - colrImg.b) / delta :
              (colrImg.g == maxColr) ? 2.0 + (colrImg.b - colrImg.r) / delta
                                     : 4.0 + (colrImg.r - colrImg.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
   }

   hsv.z = max (blurImg.r, max (blurImg.g, blurImg.b));

   if (hsv.y == 0.0) return float4 (hsv.zzz, alpha);

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float beta = hsv.x - (float) i;

   float4 retval = hsv.zzzz;

   retval.w *= (1.0 - hsv.y * (1.0 - beta));
   retval.y *= (1.0 - hsv.y);
   retval.z *= (1.0 - hsv.y * beta);

   if (i == 0) return float4 (retval.xwy, alpha);
   if (i == 1) return float4 (retval.zxy, alpha);
   if (i == 2) return float4 (retval.yxw, alpha);
   if (i == 3) return float4 (retval.yzx, alpha);
   if (i == 4) return float4 (retval.wyx, alpha);

   return float4 (retval.xyz, alpha);
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 fgImage = fn_tex2D (s_Foreground, xy1);
   float4 retval  = 0.0.xxxx;

   float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 offset, scale;

   float angle = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      retval += tex2D (s_Processed, xy1 + offset);
      retval += tex2D (s_Processed, xy1 - offset);
      angle += ANGLE;
   }

   retval  /= ALIASFIX;
   retval   = lerp (0.0.xxxx, retval, retval.a);
   retval   = lerp (retval, fgImage, fgImage.a);
   retval.a = max (fgImage.a, retval.a * Amount);

   if (expAlpha) return retval;

   float4 bgImage = tex2D (s_Background, xy2);

   retval = lerp (bgImage, retval, retval.a);

   return lerp (bgImage, float4 (retval.rgb, bgImage.a), Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Radial
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_radial (DEFAULT); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique RadialShaded
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurPre;"; >
   { PixelShader = compile PROFILE ps_radial (MONO); }

   pass P_2
   < string Script = "RenderColorTarget0 = colorPre;"; >
   { PixelShader = compile PROFILE ps_radial (COLOUR); }

   pass P_3
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_shaded (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique RadialColour
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_radial (COLOUR); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique Linear
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_linear (DEFAULT); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique LinearShaded
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurPre;"; >
   { PixelShader = compile PROFILE ps_linear (MONO); }

   pass P_2
   < string Script = "RenderColorTarget0 = colorPre;"; >
   { PixelShader = compile PROFILE ps_linear (COLOUR); }

   pass P_3
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_shaded (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique LinearColour
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_linear (COLOUR); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
