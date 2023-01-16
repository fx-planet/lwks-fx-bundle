// @Maintainer jwrl
// @Released 2023-01-06
// @Author khaver
// @Released 2015-12-08

/**
 This effect is a 3 pass 13 tap circular kernel blur.  The blur can be varied using the
 alpha channel or luma value of the source video or another video track.  It uses a depth
 map for the blur mask for faux depth of field, and is refocusable.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FocalBlur.fx
//
// Version history:
//
// Update 2023-01-06 jwrl.
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Focal blur", "Stylize", "Blurs and Sharpens", "This effect uses a depth map to create a faux depth of field", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (V1, V2);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (swap, "Swap Inputs", kNoGroup, false);

DeclareFloatParam (blurry, "De-Focus", kNoGroup, kNoFlags, 0.0, 0.0, 100.0);

DeclareBoolParam (big, "x10", kNoGroup, false);

DeclareIntParam (alpha, "Mask Type", "Mask", 0, "None|Source Alpha,Source Luma|Mask Alpha|Mask Luma");

DeclareIntParam (focust, "Focus Type", "Focus", 0, "None|Linear|Point");

DeclareFloatParam (linfocus, "Distance", "Focus", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (DoF, "DoF", "Focus", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (FocusX, "Point", "Focus", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (FocusY, "Point", "Focus", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareBoolParam (show, "Show", "Mask Adjustment", false);
DeclareBoolParam (invert, "Invert", "Mask Adjustment", false);

DeclareIntParam (SetTechnique, "Blur", "Mask Adjustment", 0, "No|Yes");

DeclareFloatParam (mblur, "Blur Strength", "Mask Adjustment", kNoFlags, 0.0, 0.0, 100.0);
DeclareFloatParam (adjust, "Brightness", "Mask Adjustment", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (contrast, "Contrast", "Mask Adjustment", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (thresh, "Threshold", "Mask Adjustment", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUMA float3(0.3, 0.59, 0.11)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler S, float2 xy)
{
   float2 uv = 1.0.xx - abs (abs (xy) - 1.0.xx);

   return tex2D (S, uv);
}

float4 GrowablePoissonDisc13FilterRGBA (sampler tSource, float2 texCoord, float discRadius, int run)
{
   float angle = run * 0.1745329252;      // 10 degrees expressed in radians.

   float2 radius = discRadius / (float2 (_OutputWidth, _OutputHeight) * 4.667);
   float2 circle, coord;

   float4 cOut = tex2D (tSource, texCoord);

   for (int tap = 0; tap < 12; tap++) {
      sincos (angle, circle.y, circle.x);
      coord  = saturate (texCoord + (circle * radius));
      cOut  += mirror2D (tSource, coord);
      angle += 0.5235987756;              // Originally 30 degrees - see above comment
   }

   cOut /= 13.0;

   return cOut;
}

float4 Masking (sampler F, sampler B, float2 uv)
{
   float DOF = (1.0 - DoF) * 2.0;
   float focusl = 1.0 - linfocus;
   float cont = (contrast + 1.0);

   if (cont > 1.0) cont = pow (cont,5.0);

   float4 orig, aff, opoint, mpoint;

   if (swap) {
      orig = tex2D (B, uv);
      aff = tex2D (F, uv);
      opoint = mirror2D (B, float2 (FocusX, 1.0 - FocusY));
      mpoint = mirror2D (F, float2 (FocusX, 1.0 - FocusY));
   }
   else {
      orig = tex2D (F, uv);
      aff = tex2D (B, uv);
      opoint = mirror2D (F, float2 (FocusX, 1.0 - FocusY));
      mpoint = mirror2D (B, float2 (FocusX, 1.0 - FocusY));
   }

   float themask;

   if (alpha == 0) themask = 0.0;
   else if (alpha == 1) {
      if (focust == 0) themask - orig.a;
      else if (focust == 1) themask = 1.0 - abs (orig.a - focusl);
      else themask = 1.0 - abs (orig.a - opoint.a);
   }
   else if (alpha == 2) {
      if (focust == 0) themask = (orig.r + orig.g + orig.b) / 3.0;
      else if (focust == 1) themask = 1.0 - abs (dot (orig.rgb, LUMA) - focusl);
      else themask = 1.0 - abs (dot (orig.rgb, LUMA) - dot (opoint.rgb, LUMA));
   }
   else if (alpha == 3) {
      if (focust == 0) themask = aff.a;
      else if (focust == 1) themask = 1.0 - abs (aff.a - focusl);
      else themask = 1.0 - abs (aff.a - mpoint.a);
   }
   else {
      if (focust == 0) themask = (aff.r + aff.g + aff.b) / 3.0;
      else if (focust == 1) themask = 1.0 - abs (((aff.r + aff.g + aff.b) / 3.0) - focusl);
      else themask = 1.0 - abs ((aff.r - mpoint.r + aff.g - mpoint.g + aff.b - mpoint.b) / 3.0);
   }

   themask = pow (themask, DOF);
   themask = saturate (((themask - 0.5) * max (cont, 0.0)) + adjust + 0.5);

   if ((thresh > 0.0) && (themask < thresh)) themask = 0.0;

   if ((thresh < 0.0) && (themask > 1.0 + thresh)) themask = 1.0;

   if (invert) themask = 1.0 - themask;

   return themask.xxxx;
}

float4 Combine (sampler m1, sampler s1, sampler F, sampler B, float2 uv)
{
   float4 source = swap ? ReadPixel (F, uv) : ReadPixel (B, uv);
   float4 retval = show         ? ReadPixel (m1, uv)
                 : blurry > 0.0 ? ReadPixel (s1, uv)
                 : swap         ? ReadPixel (B, uv) : ReadPixel (F, uv);

   return lerp (source, retval, tex2D (Mask, uv));
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique FocalBlur_N

// These two passes map the video #1 and video #2 clips to TEXCOORD3, so that
// variations in clip geometry and rotation are handled without too much effort.

DeclarePass (Vid1_N)
{ return ReadPixel (V1, uv1); }

DeclarePass (Vid2_N)
{ return ReadPixel (V2, uv2); }

DeclarePass (MaskN)
{ return Masking (Vid1_N, Vid2_N, uv3); }

DeclarePass (No_1)
{
   float blur = big ? blurry * 10.0 : blurry;

   blur *= 1.0 - tex2D (MaskN, uv3).a;

   return swap ? GrowablePoissonDisc13FilterRGBA (Vid2_N, uv3, blur, 0)
               : GrowablePoissonDisc13FilterRGBA (Vid1_N, uv3, blur, 0);
}

DeclarePass (No_2)
{
   float blur = big ? blurry * 10.0 : blurry;

   blur *= 1.0 - tex2D (MaskN, uv1).a;

   return GrowablePoissonDisc13FilterRGBA (No_1, uv3, blur, 1);
}

DeclarePass (No)
{
   float blur = big ? blurry * 10.0 : blurry;

   blur *= 1.0 - tex2D (MaskN, uv1).a;

   return GrowablePoissonDisc13FilterRGBA (No_2, uv3, blur, 2);
}

DeclareEntryPoint (FocalBlur_N)
{ return Combine (MaskN, No, Vid1_N, Vid2_N, uv3); }


// technique FocalBlur_Y

DeclarePass (Vid1_Y)
{ return ReadPixel (V1, uv1); }

DeclarePass (Vid2_Y)
{ return ReadPixel (V2, uv2); }

DeclarePass (Masked)
{ return Masking (Vid1_Y, Vid2_Y, uv3); }

DeclarePass (Yes_1)
{ return GrowablePoissonDisc13FilterRGBA (Masked, uv3, mblur, 0); }

DeclarePass (Yes_2)
{ return GrowablePoissonDisc13FilterRGBA (Yes_1, uv3, mblur, 1); }

DeclarePass (MaskY)
{ return GrowablePoissonDisc13FilterRGBA (Yes_2, uv3, mblur, 2); }

DeclarePass (Yes_3)
{
   float blur = big ? blurry * 10.0 : blurry;

   blur *= 1.0 - tex2D (MaskY, uv3).a;

   return swap ? GrowablePoissonDisc13FilterRGBA (Vid2_Y, uv3, blur, 0)
               : GrowablePoissonDisc13FilterRGBA (Vid1_Y, uv3, blur, 0);
}

DeclarePass (Yes_4)
{
   float blur = big ? blurry * 10.0 : blurry;

   blur *= 1.0 - tex2D (MaskY, uv3).a;

   return GrowablePoissonDisc13FilterRGBA (Yes_3, uv3, blur, 1);
}

DeclarePass (Yes)
{
   float blur = big ? blurry * 10.0 : blurry;

   blur *= 1.0 - tex2D (MaskY, uv1).a;

   return GrowablePoissonDisc13FilterRGBA (Yes_4, uv3, blur, 2);
}

DeclareEntryPoint (FocalBlur_Y)
{ return Combine (MaskY, Yes, Vid1_Y, Vid2_Y, uv3); }

