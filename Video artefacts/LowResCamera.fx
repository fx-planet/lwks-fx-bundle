// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2016-02-12

/**
 This effect was designed to simulate the pixellation that you get when a low-resolution
 camera is blown up just that little too much.

 NOTE 1:  Because this effect needs to be able to precisely set mosaic sizes no matter
 what the original clip size or aspect ratio is it has not been possible to make it
 truly resolution independent.  What it does is lock the clip resolution to sequence
 resolution instead.

 NOTE 2:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LowResCamera.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-12 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Low-res camera", "Stylize", "Video artefacts", "Simulates the pixellation that you get when a low-res camera is blown up just that little too much", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Blur position", kNoGroup, 0, "Apply blur before mosaic|Apply blur after mosaic|Apply blur either side of mosaic");

DeclareFloatParam (Pixelation, "Pixelation", kNoGroup, kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (Blurriness, "Blurriness", kNoGroup, kNoFlags, 0.35, 0.0, 1.0);
DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

// Pascal's triangle magic numbers for blur

#define BLUR_0  0.001
#define BLUR_1  0.3125
#define BLUR_2  0.2344
#define BLUR_3  0.09375
#define BLUR_4  0.01563

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_do_mosaic (sampler S, float2 uv)
{
   if (Pixelation > 0.0) {
      float size = Pixelation / 50;

      uv.x = (round ((uv.x - 0.5) / size) * size) + 0.5;
      size *= _OutputAspectRatio;
      uv.y = (round ((uv.y - 0.5) / size) * size) + 0.5;
   }

   return tex2D (S, uv);
}

float4 fn_preblur (sampler S, float2 uv)
{
   float4 retval = tex2D (S, uv);

   if (Blurriness == 0.0) return retval;

   float2 offset_X1 = float2 (Blurriness * BLUR_0, 0.0);
   float2 offset_X2 = offset_X1 + offset_X1;
   float2 offset_X3 = offset_X1 + offset_X2;

   retval *= BLUR_1;
   retval += tex2D (S, uv + offset_X1) * BLUR_2;
   retval += tex2D (S, uv - offset_X1) * BLUR_2;
   retval += tex2D (S, uv + offset_X2) * BLUR_3;
   retval += tex2D (S, uv - offset_X2) * BLUR_3;
   retval += tex2D (S, uv + offset_X3) * BLUR_4;
   retval += tex2D (S, uv - offset_X3) * BLUR_4;

   return retval;
}

float4 fn_fullblur (sampler S, float2 uv)
{
   float4 retval = tex2D (S, uv);

   if (Blurriness == 0.0) return retval;

   float2 offset_Y1 = float2 (0.0, Blurriness * _OutputAspectRatio * BLUR_0);
   float2 offset_Y2 = offset_Y1 + offset_Y1;
   float2 offset_Y3 = offset_Y1 + offset_Y2;

   retval *= BLUR_1;
   retval += tex2D (S, uv + offset_Y1) * BLUR_2;
   retval += tex2D (S, uv - offset_Y1) * BLUR_2;
   retval += tex2D (S, uv + offset_Y2) * BLUR_3;
   retval += tex2D (S, uv - offset_Y2) * BLUR_3;
   retval += tex2D (S, uv + offset_Y3) * BLUR_4;
   retval += tex2D (S, uv - offset_Y3) * BLUR_4;

   return retval;
}

float4 fn_main (sampler S1, sampler S2, float2 uv)
{
   float4 Image = ReadPixel (S1, uv);

   if (Opacity <= 0.0) return Image;

   return lerp (Image, ReadPixel (S2, uv), Opacity);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Apply blur before mosaic

DeclarePass (InpPre)
{ return ReadPixel (Input, uv1); }

DeclarePass (Buffer_1_0)
{ return fn_preblur (InpPre, uv2); }

DeclarePass (Buffer_2_0)
{ return fn_fullblur (Buffer_1_0, uv2); }

DeclarePass (MosaicPre)
{ return fn_do_mosaic (Buffer_2_0, uv2); }

DeclareEntryPoint (PreMosaic)
{ return fn_main (InpPre, MosaicPre, uv2); }

// Apply blur after mosaic

DeclarePass (InpPost)
{ return ReadPixel (Input, uv1); }

DeclarePass (Buffer_1_1)
{ return fn_do_mosaic (InpPost, uv2); }

DeclarePass (Buffer_2_1)
{ return fn_preblur (Buffer_1_1, uv2); }

DeclarePass (MosaicPost)
{ return fn_fullblur (Buffer_2_1, uv2); }

DeclareEntryPoint (PostMosaic)
{ return fn_main (InpPost, MosaicPost, uv2); }

// Apply blur either side of mosaic

DeclarePass (InpFull)
{ return ReadPixel (Input, uv1); }

DeclarePass (Buffer_1_2)
{ return fn_preblur (InpFull, uv2); }

DeclarePass (Buffer_2_2)
{ return fn_fullblur (Buffer_1_2, uv2); }

DeclarePass (Buffer_1)
{ return fn_do_mosaic (Buffer_2_2, uv2); }

DeclarePass (Buffer_2)
{ return fn_preblur (Buffer_1, uv2); }

DeclarePass (MosaicFull)
{ return fn_fullblur (Buffer_2, uv2); }

DeclareEntryPoint (FullMosaic)
{ return fn_main (InpFull, MosaicFull, uv2); }

