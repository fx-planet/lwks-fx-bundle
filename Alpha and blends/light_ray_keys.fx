// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect light_ray_keys.fx
//
// Created by LW user jwrl 4 March 2016.
// @Author jwrl
// @CreationDate "4 March 2016"
//  LW 14+ version by jwrl 11 January 2017
//  Subcategory "Edge Effects" added.
//
// This effect adds directional blurs to a key or any image
// with an alpha channel.  The default is to apply a radial
// blur away from the effect centre.  That centre can be put
// up to one frame height and/or frame width outside the frame.
// Optionally it can produce a blur that points to the centre,
// or a linear directional blur.
//
// The angle of the linear (directional) blur is set by dragging
// the effect centre away from the frame centre.  The angle of
// displacement is all that's used in this mode, and the amount
// of that displacement is ignored.  It can help in setting up,
// because moving the effect centre further away from the frame
// centre in linear mode will enhance the angular precision.
//
// If there is no alpha channel available this can be used to
// apply an overall blur to an image.
//
// April 3 2016: added the ability to set the foreground blend
// to solid, screen, darken, or none, and to make the rays darken
// or lighter the background.
//
// May 7 2016: extended the foreground blend mdoes to include
// add and subtract, and changed the ray blend modes to be add,
// screen, darken and subtract.  "Add" effectively replaces the
// original "lighten" mode.
//
// Also added the ability to independently fade out the
// foreground image and improved the linear fall-off.
//
// Bug fix 26 July 2017 by jwrl:
// Because Windows and Linux-OS/X have differing defaults for
// undefined samplers they have now been explicitly declared.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Light ray keys";
   string Category    = "Key";
   string SubCategory = "Edge Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture blurProc : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef OSX
#define Clamp ClampToEdge
#endif

sampler FgSampler = sampler_state {
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state {
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler ProcSampler  = sampler_state {
   Texture   = <blurProc>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Common
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int SetTechnique
<
   string Description = "Blur type";
   string Enum = "Radial from centre,Radial to centre,Linear directional";
> = 0;

int recoverFg
<
   string Description = "Foreground blend";
   string Enum = "Add,Screen,Darken,Subtract,Solid,None";
> = SOLID;

int rayType
<
   string Description = "Rays";
   string Enum = "Add,Screen,Darken,Subtract";
> = ADD;

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

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_out (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval;

   float scale;

   if (zoomAmount == 0.0) { retval = tex2D (FgSampler, xy); }
   else {
      float z_Amount = zoomAmount / 2;

      float2 zoomCentre = float2 ((Xcentre * 3) - 1.0, 2.0 - (Ycentre * 3));
      float2 uv = xy - zoomCentre;

      retval = 0.0.xxxx;

      for (int i = SAMPLE; i >= 0.0; i--) {
         scale = 1.0 - z_Amount * (i / SAMPLE);

         retval += tex2D (FgSampler, uv * scale + zoomCentre);
      }

      retval /= SAMPLES;
   }

   return retval;
}

float4 ps_in (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval;

   float scale;

   if (zoomAmount == 0.0) { retval = tex2D (FgSampler, xy); }
   else {
      float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
      float2 uv = xy - zoomCentre;

      retval = 0.0.xxxx;

      for (int i = 0; i <= SAMPLE; i++) {
         scale = 1.0 + zoomAmount * (i / SAMPLE);

         retval += tex2D (FgSampler, uv * scale + zoomCentre);
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
      retval = tex2D (FgSampler, xy);
   }
   else {
      offset *= 1.0 / sqrt ((offset.x * offset.x) + (offset.y * offset.y));
      offset *= zoomAmount * L_SCALE;
      retval  = 0.0.xxxx;

      float2 uv = xy;

      float luminosity = 1.0;

      for (int i = 0; i < SAMPLES; i++) {
         retval += tex2D (FgSampler, uv) * luminosity;
         uv += offset;
         luminosity -= LUMAOFFS;
         }

      retval /= ((1.5 - zoomAmount) * L_SAMPLE);
   }

   return retval;
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 fgImage = tex2D (FgSampler, xy);
   float4 bgImage = tex2D (BgSampler, xy);
   float4 blurred = tex2D (ProcSampler, xy);

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

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique FromCentre
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = blurProc;";
   >
   {
      PixelShader = compile PROFILE ps_out ();
   }

   pass pass_two
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

technique ToCentre
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = blurProc;";
   >
   {
      PixelShader = compile PROFILE ps_in ();
   }

   pass pass_two
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

technique Linear
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = blurProc;";
   >
   {
      PixelShader = compile PROFILE ps_linear ();
   }

   pass pass_two
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

