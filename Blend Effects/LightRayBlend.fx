// @Maintainer jwrl
// @Released 2023-01-23
// @Author jwrl
// @Created 2023-01-23

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
 an image.  Masking is applied to the foreground before the rest of the effect.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LightRayBlend.fx
//
// Version history:
//
// Built 2023-01-23 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Light ray blend", "Mix", "Blend Effects", "Adds directional blurs to a key or any image with an alpha channel", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Blur type", kNoGroup, 0, "Radial from centre|Radial to centre|Linear directional");
DeclareIntParam (recoverFg, "Foreground blend", kNoGroup, 4, "Add|Screen|Darken|Subtract|Solid|None");
DeclareIntParam (rayType, "Rays", kNoGroup, 0, "Add|Screen|Darken|Subtract");

DeclareFloatParam (zoomAmount, "Length", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Opacity, "Master opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Fgd_amt, "Foreground", "Opacity", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Amount, "Rays", "Opacity", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Xcentre, "Effect centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre, "Effect centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareIntParam (Source, "Source selection", "Disconnect title and image key inputs", 1, "Crawl/Roll/Title/Image key|Video/External image|Extracted foreground");

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define R_VAL    0.2989
#define G_VAL    0.5866
#define B_VAL    0.1145

#define SAMPLE   80

#define SAMPLES  81.0

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

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   if (IsOutOfBounds (xy1)) return kTransparentBlack;

   float4 Fgd = tex2D (F, xy1);

   if (Source == 0) {
      Fgd.a    = pow (Fgd.a, 0.5);
      Fgd.rgb /= Fgd.a;
   }
   else if (Source == 2) {
      float4 Bgd = ReadPixel (B, xy2);

      float kDiff = distance (Fgd.g, Bgd.g);

      kDiff = max (kDiff, distance (Fgd.r, Bgd.r));
      kDiff = max (kDiff, distance (Fgd.b, Bgd.b));

      Fgd.a = smoothstep (0.0, 0.25, kDiff);
      Fgd.rgb *= Fgd.a;
   }

   return Fgd;
}

float4 main (sampler F, float2 xy1, sampler B, float2 xy2, float4 blurred)
{
   float4 bgImage = ReadPixel (B, xy2);

   if (IsOutOfBounds (xy1)) return bgImage;

   float inv_luma = 1.0 - dot (blurred.rgb, float3 (R_VAL, G_VAL, B_VAL));

   float4 fgImage = ReadPixel (F, xy1);
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
   retval  = lerp (bgImage, retval, Amount * blurred.a);
   retval  = lerp (retval, FxImage, fgImage.a);
   retval  = lerp (bgImage, retval, Opacity);

   return lerp (bgImage, float4 (retval.rgb, bgImage.a), tex2D (Mask, xy1).x);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (KeyFgOut)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (LightRayBlendFromCentre)
{
   float4 retval;

   float scale;

   if (zoomAmount == 0.0) { retval = ReadPixel (KeyFgOut, uv3); }
   else {
      float z_Amount = zoomAmount / 2;

      float2 zoomCentre = float2 ((Xcentre * 3) - 1.0, 2.0 - (Ycentre * 3));
      float2 xy = uv3 - zoomCentre;

      retval = kTransparentBlack;

      for (int i = SAMPLE; i >= 0; i--) {
         scale = 1.0 - z_Amount * ((float)i / SAMPLE);

         retval += tex2D (KeyFgOut, (xy * scale) + zoomCentre);
      }

      retval /= SAMPLES;
   }

   return main (Fg, uv1, Bg, uv2, retval);
}

DeclarePass (KeyFgIn)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (LightRayBlendToCentre)
{
   float4 retval;

   float scale;

   if (zoomAmount == 0.0) { retval = ReadPixel (KeyFgIn, uv3); }
   else {
      float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
      float2 xy = uv3 - zoomCentre;

      retval = kTransparentBlack;

      for (int i = 0; i <= SAMPLE; i++) {
         scale = 1.0 + zoomAmount * ((float)i / SAMPLE);

         retval += tex2D (KeyFgIn, (xy * scale) + zoomCentre);
      }

      retval /= SAMPLES;
   }

   return main (Fg, uv1, Bg, uv2, retval);
}

DeclarePass (KeyFgLin)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (LightRayBlendLinear)
{
   float2 offset;
   float4 retval;

   offset.x = 0.5 - saturate (Xcentre * LIN_OFFS);
   offset.y = saturate (Ycentre * LIN_OFFS) - 0.5;

   if ((max (abs (offset.x), abs (offset.y)) == 0.0) || (zoomAmount == 0.0)) {
      retval = ReadPixel (KeyFgLin, uv3);
   }
   else {
      offset *= 1.0 / sqrt ((offset.x * offset.x) + (offset.y * offset.y));
      offset *= zoomAmount * L_SCALE;
      retval  = 0.0.xxxx;

      float2 xy = uv3;

      float luminosity = 1.0;

      for (int i = 0; i < SAMPLES; i++) {
         retval += tex2D (KeyFgLin, xy) * luminosity;
         xy += offset;
         luminosity -= LUMAOFFS;
         }

      retval /= ((1.5 - zoomAmount) * L_SAMPLE);
   }

   return main (Fg, uv1, Bg, uv2, retval);
}

