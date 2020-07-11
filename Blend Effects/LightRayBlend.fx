// @Maintainer jwrl
// @Released 2020-07-11
// @Author jwrl
// @Created 2016-03-04
// @see https://www.lwks.com/media/kunena/attachments/6375/LightRayKeys_640.png

/**
 This effect adds directional blurs to a key or any image with an alpha channel.  The
 default is to apply a radial blur away from the effect centre.  That centre can be put
 up to one frame height and/or frame width outside the frame.  Optionally it can  also
 produce a blur that points to the centre, or a linear directional blur.

 The angle of the linear (directional) blur is set by dragging the effect centre away
 from the frame centre.  The angle of displacement is all that's used in this mode, and
 the amount of that displacement is ignored.  It can help in setting up, because moving
 the effect centre further away from the frame centre in linear mode will enhance the
 angular precision.

 If there is no alpha channel available this can be used to apply an overall blur to
 an image.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LightRayBlend.fx
//
// Version history:
//
// Update 11 July 2020 jwrl.
// Added a delta key to separate blended effects from the background.
// THIS MAY (BUT SHOULDN'T) BREAK BACKWARDS COMPATIBILITY!!!
//
// Update 23 December 2018 jwrl.
// Converted to version 14.5 and up.
// Modified Windows version to compile as ps_3_0.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified 25 November 2018 jwrl.
// Renamed effect from "Light ray keys" to "Light ray blend".
// Changed category from "Key" to "Mix".
// Changed subcategory from "Edge Effects" to "Blend Effects".
// Added alpha boost for Lightworks titles.
//
// Modified 30 August 2018 jwrl.
// Added notes to header.
//
// Modified 5 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// LW 14+ version 11 January 2018
// Subcategory "Edge Effects" added.
//
// Modified 5 December 2017
// Corrected an addressing mode bug which could have effected the way that transitions
// behaved with this effect on Linux and OS-X.
//
// Bug fix 26 July 2017
// Because Windows and Linux-OS/X have differing defaults for undefined samplers they
// have now been explicitly declared.
//
// Modified May 7 2016
// Extended the foreground blend mdoes to include add and subtract, and changed the ray
// blend modes to be add, screen, darken and subtract.  "Add" effectively replaces the
// original "lighten" mode.  Also added the ability to independently fade out the
// foreground image and improved the linear fall-off.
//
// Modified April 3 2016
// Added the ability to set the foreground blend to solid, screen, darken, or none, and
// to make the rays darken or lighter the background.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Light ray blend";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Adds directional blurs to a key or any image with an alpha channel";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture blurProc : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

sampler s_Processed  = sampler_state
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
   string Description = "Blur type";
   string Enum = "Radial from centre,Radial to centre,Linear directional";
> = 0;

int recoverFg
<
   string Description = "Foreground blend";
   string Enum = "Add,Screen,Darken,Subtract,Solid,None";
> = 4;

int rayType
<
   string Description = "Rays";
   string Enum = "Add,Screen,Darken,Subtract";
> = 0;

float zoomAmount
<
   string Description = "Length";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Opacity
<
   string Description = "Master opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Fgd_amt
<
   string Group = "Opacity";
   string Description = "Foreground";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amount
<
   string Group = "Opacity";
   string Description = "Rays";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

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

int Source
<
   string Description = "Source selection (disconnect input to text effects first)";
   string Enum = "Crawl / roll / titles,Video / external image,Extracted foreground";
> = 1;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define R_VAL    0.2989
#define G_VAL    0.5866
#define B_VAL    0.1145

#define SAMPLE   80.0

#define SAMPLES  SAMPLE + 1.0

#define B_SCALE  0.0075

#define L_SCALE  0.00375
#define LIN_OFFS 1.001
#define LUMAOFFS 0.015
#define L_SAMPLE 20.0

#define ADD      0
#define SCREEN   1
#define DARKEN   2
#define SUBTRACT 3
#define SOLID    4

float _OutputAspectRatio;

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

float4 ps_out (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval;

   float scale;

   if (zoomAmount == 0.0) { retval = fn_tex2D (s_Foreground, xy); }
   else {
      float z_Amount = zoomAmount / 2;

      float2 zoomCentre = float2 ((Xcentre * 3) - 1.0, 2.0 - (Ycentre * 3));
      float2 uv = xy - zoomCentre;

      retval = 0.0.xxxx;

      for (int i = SAMPLE; i >= 0.0; i--) {
         scale = 1.0 - z_Amount * (i / SAMPLE);

         retval += fn_tex2D (s_Foreground, uv * scale + zoomCentre);
      }

      retval /= SAMPLES;
   }

   return retval;
}

float4 ps_in (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval;

   float scale;

   if (zoomAmount == 0.0) { retval = fn_tex2D (s_Foreground, xy); }
   else {
      float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
      float2 uv = xy - zoomCentre;

      retval = 0.0.xxxx;

      for (int i = 0; i <= SAMPLE; i++) {
         scale = 1.0 + zoomAmount * (i / SAMPLE);

         retval += fn_tex2D (s_Foreground, uv * scale + zoomCentre);
      }

      retval /= SAMPLES;
   }

   return retval;
}

float4 ps_linear (float2 xy : TEXCOORD1) : COLOR
{
   float2 offset;
   float4 retval;

   offset.x = 0.5 - saturate (Xcentre * LIN_OFFS);
   offset.y = saturate (Ycentre * LIN_OFFS) - 0.5;

   if ((max (abs (offset.x), abs (offset.y)) == 0.0) || (zoomAmount == 0.0)) {
      retval = fn_tex2D (s_Foreground, xy);
   }
   else {
      offset *= 1.0 / sqrt ((offset.x * offset.x) + (offset.y * offset.y));
      offset *= zoomAmount * L_SCALE;
      retval  = 0.0.xxxx;

      float2 uv = xy;

      float luminosity = 1.0;

      for (int i = 0; i < SAMPLES; i++) {
         retval += fn_tex2D (s_Foreground, uv) * luminosity;
         uv += offset;
         luminosity -= LUMAOFFS;
         }

      retval /= ((1.5 - zoomAmount) * L_SAMPLE);
   }

   return retval;
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 fgImage = fn_tex2D (s_Foreground, xy);
   float4 bgImage = tex2D (s_Background, xy);
   float4 blurred = tex2D (s_Processed, xy);

   float inv_luma = 1.0 - dot (blurred.rgb, float3 (R_VAL, G_VAL, B_VAL));

   float4 retval = (rayType == ADD)    ? saturate (bgImage + blurred)
                 : (rayType == SCREEN) ? 1.0 - ((1.0 - blurred) * (1.0 - bgImage))
                 : (rayType == DARKEN) ? bgImage * inv_luma
                                       : saturate (bgImage - blurred);  // Fall through to SUBTRACT

   inv_luma = 1.0 - dot (fgImage.rgb, float3 (R_VAL, G_VAL, B_VAL));

   float4 FxImage = (recoverFg == ADD)      ? saturate (fgImage + bgImage)
                  : (recoverFg == SCREEN)   ? 1.0 - ((1.0 - fgImage) * (1.0 - bgImage))
                  : (recoverFg == DARKEN)   ? bgImage * inv_luma
                  : (recoverFg == SUBTRACT) ? saturate (bgImage - fgImage)
                  : (recoverFg == SOLID)    ? fgImage
                                            : bgImage;                  // Fall through to none

   FxImage = lerp (retval, FxImage, Fgd_amt);
   retval = lerp (bgImage, retval, Amount * blurred.a);
   retval  = lerp (retval, FxImage, fgImage.a);
   retval  = lerp (bgImage, retval, Opacity);

   return float4 (retval.rgb, bgImage.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FromCentre
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_out (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique ToCentre
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_in (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique Linear
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurProc;"; >
   { PixelShader = compile PROFILE ps_linear (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
