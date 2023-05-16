// @Maintainer jwrl
// @Released 2023-05-16
// @Author schrauber
// @Created 2020-06-07

/**
 This is an advanced dynamic effect with 4 inputs.  It features:
 - Frame Edge Interpolation
 - Antialiasing (optional)
 - Alpha softness (optional)
 - Quad split screen with the possibility to highlight a selected screen by zooming

 The screen to zoom, when selected, will automatically adjust the size of the other three
 screens so that no overlap can occur.  The base scale parameter will changes the distance
 between the screens by scaling them, always keeping them fixed in their corners.

 The background color is adjustable. If you want to use a different background (image,
 background effects or video), you can use the Transparent mode and replace the transparency
 with your background in a downstream effect.  In this mode, edge softness is only applied
 to the alpha (transparency) value, not to the RGB values.  Therefore, the softness of edges
 in this mode is only visible when the transparency is replaced in the subsequent effect
 (e.g. Blend). The reason for not applying softness to the visible colors (RGB) in this mode
 is to avoid double application of edge softness.

 Edge softness can be used to minimise edge jitter when zooming.  When this is left at zero
 the effect automatically calculates a 1 pixel wide edge softness to reduce jitter.  The
 edge softness is fully adjustable.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadScreenZ.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-25 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Quad split screen with zoom", "DVE", "Multiscreen Effects", "An advanced dynamic 4 input effect with zoom", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (a, b, c, d);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (ZoomInput, "Select thumbnail to highlighted zoom", "Zoom", 0, "Top Left|Top Right|Bottom Left|Bottom Right");

DeclareFloatParam (Zoom, "Highlighted", "Zoom", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (BaseScale, "Base Scale", "Zoom", kNoFlags, 0.492, 0.0, 0.5);

DeclareColourParam (Bg, "Background", "Colours (`A` slider colors soft edges in a transparent setup)", kNoFlags, 0.0, 0.0, 0.0, 0.0);

DeclareIntParam (AlphaOut, " ", "Colours (`A` slider colors soft edges in a transparent setup)", 0, "Output completely opaque colours. Ignores alpha slider|Transparency. Add Bg & soft edges in downstream effect)";
DeclareIntParam (SetTechnique, " ", "Softness (if `Highlighted` at 100%, then partly inactive)",0, "Fast mode; frame edge softness only|Softness of frame edges and alpha edges| Quality mode: Antialiasing & Soft frame edges|Quality mode: Antialiasing & Soft edges (frame & alpha)");

DeclareFloatParam (Soft, "Edge softness", "Softness (if `Highlighted` at 100%, then partly inactive)", "DisplayAsPercentage", 0.0, 0.0, 0.3);

DeclareBoolParam (AllEdges, "Frame edge softness setting affects all edges", "Softness (if `Highlighted` at 100%, then partly inactive)", false);
DeclareBoolParam (RoundedEdges, "Frame edge softness setting creates rounded corners", "Softness (if `Highlighted` at 100%, then partly inactive)", false);

DeclareBoolParam (ActiveIn0, "`a` Top Left", "Selected inputs for use if connected", true);
DeclareBoolParam (ActiveIn1, "`b` Top Right", "Selected inputs for use if connected", true);
DeclareBoolParam (ActiveIn2, "`c` Bottom Left", "Selected inputs for use if connected", true);
DeclareBoolParam (ActiveIn3, "`d` Bottom Right", "Selected inputs for use if connected", true);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Common definitions, declarations, macros
//-----------------------------------------------------------------------------------------//

#define THUMBNAILS    4
#define SOFT          (Soft / 4.0)
#define SOFT_ALPHA    (Soft / 10.0) 

// ... Blur definitions &  macros
 #define TEXEL (1.0.xx / float2(_OutputWidth, _OutputHeight))
 #define DIAG_SCALE 0.707107     // Sine/cosine 45 degrees correction for diagonal blur
 // radius change factor of 1.71 between different passes (This factor also optimizes the blur quality with the 9 samples per pass used here):
  #define RADIUS_1    0.5
  #define RADIUS_2    0.2924
  #define RADIUS_3    0.171
  #define RADIUS_4    0.1
 // Similar to the above radius settings with the same factor (1.71), but the values are all minimally shifted to the radii above toto reduce sampler interference during the pre-blur process
#define RADIUS_2b    0.2605
#define RADIUS_3b    0.1523
#define RADIUS_4b    0.0891

// Notes on reserved definitions and macros defined elsewhere:
// #define ZOOM(zoom) This makto is defined in the shader code

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_fill2D (sampler s_fn, float2 xy)
{
   if (xy.x < 0.0 || xy.x > 1.0 || xy.y < 0.0 || xy.y > 1.0) return float2 (0.0,1.0).xxxy;

   return tex2D (s_fn, xy);
}

float4 fn_tex2D (sampler s_fn, float2 xy, float2 soft, bool4 edges)
{ 
   float2 distEdge = 0.5.xx - abs(xy - 0.5.xx);                    // Distance from edges (negative values are Outside)
   if ((distEdge.x < 0.0 ) || (distEdge.y < 0.0 )) return kTransparentBlack;
   float2 alpha = distEdge;
   alpha = min( 1.0.xx, alpha * (1.0.xx / max( 1.0e-9.xx, soft)));
   if (!AllEdges)                          // Deactivating the softness of selected edges
   {
      if (  (!edges.x && (xy.y < 0.5))      // top edge
         || (!edges.z && (xy.y > 0.5))      // bottom edge
         )  alpha.y = 1.0; 
      if (  (!edges.y && (xy.x > 0.5))      // right edge
         || (!edges.w && (xy.x < 0.5))      // left edge
         )  alpha.x = 1.0; 
   }
   float4 retval = tex2D (s_fn, xy);       // Take a texture sample
   retval.a = (RoundedEdges)
      ? retval.a * alpha.x * alpha.y       // Rounded alpha edge softness (Tip: add alpha-bluring can improve the quality.)
      : retval.a * min (alpha.x, alpha.y); // Square alpha edge softness  (Tip: add alpha-bluring can improve the quality.)
   return retval;
}

float4 fn_splitScreen (sampler s_a, sampler s_b, sampler s_c, sampler s_d, float2 uv, bool alphaBlur)
{ 
   int i; // loop counter

   float zoomOffset; // Highlight Zoom Offset. Increase the set "Highlighted" Zoom depending on the edge softness.
                     // The purpose is to achieve 100% zoom already at lower setting values, 
                     // so that the last phase to 100% setting value can be used to remove the edge softness.

  // Zoom positions:
   float2 pos[THUMBNAILS];
   pos[0] = float2 ( 0.0, 0.0);
   pos[1] = float2 ( 1.0, 0.0);
   pos[2] = float2 ( 0.0, 1.0);
   pos[3] = float2 ( 1.0, 1.0);

  // Direction vectors
   float2 vPt[THUMBNAILS];  
   for(i=0; i<THUMBNAILS; i++)
   { 
      vPt[i] = pos[i] - uv;   // Direction vector of the set position to the currently calculated texel.
   }


// Zoom strength & Edge softness:
   float soft1 = max( SOFT, 1.0 / _OutputWidth);               // Edge softness included minimum softness to prevent edge flickering.
   zoomOffset = Zoom * (1.0 + soft1);                          // Highlight Zoom Offset. Details see variable declaration
   float zoomH = min (1.0, Zoom * (1.0 + soft1));              // Stop at 100%.
   float zoomDelta = zoomOffset - zoomH;                       // Controls the reduction of edge softness above the stop value.
   float dimensionH = (zoomH * (1.0 - BaseScale)) + BaseScale; // Dimension of the texture to be highlighted;  Range [BaseScale .. 1]
   float zoomCorrection = dimensionH - BaseScale;              // Range [0 .. 0.5] (Quad split screen)
   float dimensionT[THUMBNAILS];                               // Dimension of the individual thrumbinals, 0 = Dimensions 0 , 0.5 = Dimensions 50%, 1 = Dimensions 100% (full screen)
   float2 soft[THUMBNAILS]; 
   for(i=0; i<THUMBNAILS; i++)
   { 
      dimensionT[i] = (ZoomInput == i )
        ? dimensionH                                        // Range [BaseScale .. 1] (If it is the texture to be highlighted & quad)
        : (BaseScale - zoomCorrection);                     // Range (Quad split screen) [0.5 .. 0] (If it is the other textures that are minimized when "Highlighted" > 0% & quad)
      soft[i] = soft1.xx / max (1.0e-9, dimensionT[i]).xx;  // Widen the softness before scaling to maintain the width after scaling down.
      soft[i] -= zoomDelta.xx;                              // Controls the reduction of edge softness above the stop value.
      soft[i].y *=  _OutputAspectRatio;
      soft[i] =  min (0.5.xx, soft[i]);                     // Prevents edge softness overdrive beyond the center.
   }


   // ------ ZOOM:
   float4 input[THUMBNAILS];
   #define ZOOM(zoom)  (1.0 + (-1.0 / max (1.0e-9, zoom)))         // Macro, the zoom range from [0..1] is rescaled to [-1e-9 .. 0]   ( 0 = Dimensions 100%, -1 = Dimensions 50 %, -2 Dimensions 33.3 %, -1e-9 (approximately negative infinite) = size 0%)
   input[0] = fn_tex2D (s_a, ZOOM(dimensionT[0]).xx * vPt[0] + uv, soft[0], bool4 (false, true, true, false)); // Thumbnail top left.    bool4 defines the deactivation of softness edges. `true` allows softness.   Order: up, right, down, left
   input[1] = fn_tex2D (s_b, ZOOM(dimensionT[1]).xx * vPt[1] + uv, soft[1], bool4 (false, false, true, true)); // Thumbnail top right.
   input[2] = fn_tex2D (s_c, ZOOM(dimensionT[2]).xx * vPt[2] + uv, soft[2], bool4 (true, true, false, false)); // Thumbnail bottom left.
   input[3] = fn_tex2D (s_d, ZOOM(dimensionT[3]).xx * vPt[3] + uv, soft[3], bool4 (true, false, false, true)); // Thumbnail bottom right.

   // ------ Mix:
   input[0] = (ActiveIn0) ?  input[0] : kTransparentBlack;
   input[1] = (ActiveIn1) ?  input[1] : kTransparentBlack;
   input[2] = (ActiveIn2) ?  input[2] : kTransparentBlack;
   input[3] = (ActiveIn3) ?  input[3] : kTransparentBlack;

   float4 mix = max (input[0], input[1]);
          mix = max (mix, input[2]);
          mix = max (mix, input[3]);

   // ------ Mix Bg & Alpha:
   float4 retval = mix;
   if (!alphaBlur)  retval.rgb = lerp (Bg.rgb, mix.rgb, mix.a);        // Add the background color
   if (AlphaOut == 1) retval.rgb = lerp (mix.rgb, retval.rgb, Bg.a);   // Transparent mode: If the alpha slider of the color panels is set to 0, the RGB mix without background color is used.
   if (AlphaOut == 0 && !alphaBlur) retval.a = 1.0;

   return retval;
}

float4 fn_preBlur (sampler blurSampler, float2 uv, float passRadius, int blurInput)
{
  // Zoom strength:

  float dimension = (Zoom * (1.0 - BaseScale)) + BaseScale;  // Range [BaseScale .. 1]
  float zoomCorrection = dimension - BaseScale;              // Range [0 .. 0.5] (Quad split screen)
  float scale = (blurInput == ZoomInput )
     ? dimension                                      // Range [BaseScale .. 1] (If it is the texture to be highlighted & quad)
     : (BaseScale - zoomCorrection);                  // Range (Quad split screen) [0.5 .. 0] (If it is the other textures that are minimized when "Highlighted" > 0% & quad)
   scale = 1.0 / max (scale, 1.0e-5);                 // Range [1 .. 100 000]
   scale -= 1.0;                                      // Range [0 ..  99 999]
   float2 radius = TEXEL * scale.xx * passRadius.xx ; // Example UHD : (1/4096) *  scale * 0.5   results in a radius range of   [0 ... 1220 %] of the horizontal dimension   (0 if full screen, 1220 % at almost infinite minimization)

  // ... Blur ...

   float4 retval = tex2D (blurSampler, uv);

   // vertical blur
   retval += tex2D (blurSampler, float2 (uv.x, uv.y + radius.y));
   retval += tex2D (blurSampler, float2 (uv.x, uv.y - radius.y));

   //horizantal blur
   retval += tex2D (blurSampler, float2 (uv.x + radius.x, uv.y));
   retval += tex2D (blurSampler, float2 (uv.x - radius.x, uv.y));

   // The box blur is now repeated with the coordinates rotated by 45 degrees
   radius *= DIAG_SCALE;
   retval += tex2D (blurSampler, uv + radius);
   retval += tex2D (blurSampler, uv - radius);

   // Inverting the Y vector changes the rotation to -45 degrees from reference
   radius.y = -radius.y;
   retval += tex2D (blurSampler, uv + radius);
   retval += tex2D (blurSampler, uv - radius);

   retval /= 9.0.xxxx;

   return retval;
}

// AlphaBlur1: Prevents the alpha-0 areas from being excessively reduced by blurring.

float4 fn_AlphaBlur1 (sampler Sblur, float2 uv, float passRadius)
{
   float soft = max( SOFT_ALPHA, 1.0 / _OutputWidth);  // Softness included minimum softness to prevent edge flickering.
   float2 radius = float2 (1.0, _OutputAspectRatio)  * soft.xx * passRadius.xx;

  // ... Blur ...
   float sample[9];
   float4 retval = tex2D (Sblur, uv);
   sample[0] = retval.a;

   // vertical blur
   sample[1] = tex2D (Sblur, float2 (uv.x, uv.y + radius.y)).a;
   sample[2] = tex2D (Sblur, float2 (uv.x, uv.y - radius.y)).a;


   //horizantal blur
   sample[3] = tex2D (Sblur, float2 (uv.x + radius.x, uv.y)).a;
   sample[4] = tex2D (Sblur, float2 (uv.x - radius.x, uv.y)).a;

   // The box blur is now repeated with the coordinates rotated by 45 degrees
   radius *= DIAG_SCALE;
   sample[5] = tex2D (Sblur, uv + radius).a;
   sample[6] = tex2D (Sblur, uv - radius).a;

   // Inverting the Y vector changes the rotation to -45 degrees from reference
   radius.y = -radius.y;
   sample[7] = tex2D (Sblur, uv + radius).a;
   sample[8] = tex2D (Sblur, uv - radius).a;

  // Normalize level
   retval.a = (  (sample[0] == 0.0)
              || (sample[1] == 0.0)
              || (sample[2] == 0.0)
              || (sample[3] == 0.0)
              || (sample[4] == 0.0)
              || (sample[5] == 0.0)
              || (sample[6] == 0.0)
              || (sample[7] == 0.0)
              || (sample[8] == 0.0))
              ? 0.0   // Prevents the alpha-0 areas from being excessively reduced by blurring.
              : ( sample[0] + sample[1] + sample[2] + sample[3] + sample[4] + sample[5] + sample[6] + sample[7] + sample[8] ) / 9.0;
  
   return retval;
}

float4 fn_AlphaBlur2 (sampler Sblur, float2 uv, float passRadius, bool lastPass) : COLOR
{
   float soft = max( SOFT_ALPHA, 1.0 / _OutputWidth);  // Softness included minimum softness to prevent edge flickering.
  float2 radius = float2 (1.0, _OutputAspectRatio)  * soft.xx * passRadius.xx;

// ... Blur ...
   float4 sample = tex2D (Sblur, uv);
   float alpha = sample.a;

   // vertical blur
   alpha += tex2D (Sblur, float2 (uv.x, uv.y + radius.y)).a;
   alpha += tex2D (Sblur, float2 (uv.x, uv.y - radius.y)).a;

   //horizantal blur
   alpha += tex2D (Sblur, float2 (uv.x + radius.x, uv.y)).a;
   alpha += tex2D (Sblur, float2 (uv.x - radius.x, uv.y)).a;

   // The box blur is now repeated with the coordinates rotated by 45 degrees
   radius *= DIAG_SCALE;
   alpha += tex2D (Sblur, uv + radius).a;
   alpha += tex2D (Sblur, uv - radius).a;

   // Inverting the Y vector changes the rotation to -45 degrees from reference
   radius.y = -radius.y;
   alpha += tex2D (Sblur, uv + radius).a;
   alpha += tex2D (Sblur, uv - radius).a;

  // Normalize level
   sample.a = alpha / 9.0;

  // The alpha values are applied to the RGB values (if no transparent mode was activated)
   float4 retval = sample;
   if (lastPass) {
      retval.rgb = lerp (Bg.rgb, retval.rgb, retval.a);                      // Add the background color
      if (AlphaOut == 1) retval.rgb = lerp (sample.rgb, retval.rgb, Bg.a);   // Transparent mode: If the alpha slider of the color panels is set to 0, the RGB mix without background color is used.
      if (AlphaOut == 0) retval.a = 1.0;                                     // Opaque mode
   }

   return retval;
}
//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// tech_fast

DeclarePass (a_0)
{ return fn_fill2D (a, uv1); }

DeclarePass (b_0)
{ return fn_fill2D (b, uv2); }

DeclarePass (c_0)
{ return fn_fill2D (c, uv3); }

DeclarePass (d_0)
{ return fn_fill2D (d, uv4); }

DeclareEntryPoint (QuadScreenZfast)
{ return fn_splitScreen (a_0, b_0, c_0, d_0, uv5, false); }


// tech_Alpha

DeclarePass (a_1)
{ return fn_fill2D (a, uv1); }

DeclarePass (b_1)
{ return fn_fill2D (b, uv2); }

DeclarePass (c_1)
{ return fn_fill2D (c, uv3); }

DeclarePass (d_1)
{ return fn_fill2D (d, uv4); }

DeclarePass (TAblur1)  // ... Main shader
{ return fn_splitScreen (a_1, b_1, c_1, d_1, uv5, true); }

DeclarePass (TAblur2)  // ... Alpha blur
{ return fn_AlphaBlur1 (TAblur1, uv5, RADIUS_1); }

DeclarePass (TAblur3)
{ return fn_AlphaBlur2 (TAblur2, uv5, RADIUS_2, false); }

DeclarePass (TAblur4)
{ return fn_AlphaBlur2 (TAblur3, uv5, RADIUS_2b, false); }

DeclarePass (TAblur5)
{ return fn_AlphaBlur2 (TAblur4, uv5, RADIUS_3b, false); }

DeclareEntryPoint (QuadScreenZalpha) //  If necessary, the alpha values are applied to the RGB values
{ return fn_AlphaBlur2 (TAblur5, uv5, RADIUS_4b, true); }


// tech_filter ... Pre-blurring of the input textures (scaling dependent):

DeclarePass (a_2)
{ return fn_fill2D (a, uv1); }

DeclarePass (b_2)
{ return fn_fill2D (b, uv2); }

DeclarePass (c_2)
{ return fn_fill2D (c, uv3); }

DeclarePass (d_2)
{ return fn_fill2D (d, uv4); }

DeclarePass (TFblur1a)
{ return fn_preBlur (a_2, uv5, RADIUS_2, 0); }

DeclarePass (TFblur1)
{ return fn_preBlur (TFblur1a, uv5, RADIUS_1, 0); }

DeclarePass (TFblur2a)
{ return fn_preBlur (b_2, uv5, RADIUS_2, 1); }

DeclarePass (TFblur2)
{ return fn_preBlur (TFblur2a, uv5, RADIUS_1, 1); }

DeclarePass (TFblur3a)
{ return fn_preBlur (c_2, uv5, RADIUS_2, 2); }

DeclarePass (TFblur3)
{ return fn_preBlur (TFblur3a, uv5, RADIUS_1, 2); }

DeclarePass (TFblur4a)
{ return fn_preBlur (d_2, uv5, RADIUS_2, 3); }

DeclarePass (TFblur4)
{ return fn_preBlur (TFblur4a, uv5, RADIUS_1, 3); }

DeclareEntryPoint (QuadScreenZfilter)  // ... Main shader:
{ return fn_splitScreen (TFblur1, TFblur2, TFblur3, TFblur4, uv5, true); }


// tech_filterAlpha ... Pre-blurring of the input textures (scaling dependent):

DeclarePass (a_3)
{ return fn_fill2D (a, uv1); }

DeclarePass (b_3)
{ return fn_fill2D (b, uv2); }

DeclarePass (c_3)
{ return fn_fill2D (c, uv3); }

DeclarePass (d_3)
{ return fn_fill2D (d, uv4); }

DeclarePass (TFAblur1a)
{ return fn_preBlur (a_3, uv5, RADIUS_2, 0); }

DeclarePass (TFAblur1)
{ return fn_preBlur (TFAblur1a, uv5, RADIUS_1, 0); }

DeclarePass (TFAblur2a)
{ return fn_preBlur (b_3, uv5, RADIUS_2, 1); }

DeclarePass (TFAblur2)
{ return fn_preBlur (TFAblur2a, uv5, RADIUS_1, 1); }

DeclarePass (TFAblur3a)
{ return fn_preBlur (c_3, uv5, RADIUS_2, 2); }

DeclarePass (TFAblur3)
{ return fn_preBlur (TFAblur3a, uv5, RADIUS_1, 2); }

DeclarePass (TFAblur4a)
{ return fn_preBlur (d_3, uv5, RADIUS_2, 3); }

DeclarePass (TFAblur4)
{ return fn_preBlur (TFAblur4a, uv3, RADIUS_1, 3); }

DeclarePass (TFAblur5)  // ... Main shader
{ return fn_splitScreen (TFAblur1, TFAblur2, TFAblur3, TFAblur4, uv5, true); }

DeclarePass (TFAblur6)  // ... Alpha blur
{ return fn_AlphaBlur1 (TFAblur5, uv5, RADIUS_1); }

DeclarePass (TFAblur7)
{ return fn_AlphaBlur2 (TFAblur6, uv5, RADIUS_2, false); }

DeclarePass (TFAblur8)
{ return fn_AlphaBlur2 (TFAblur7, uv5, RADIUS_2b, false); }

DeclarePass (TFAblur9)
{ return fn_AlphaBlur2 (TFAblur8, uv5, RADIUS_3b, false); }

DeclareEntryPoint (QuadScreenZfilterAlpha) //  If necessary, the alpha values are applied to the RGB values
{ return fn_AlphaBlur2 (TFAblur9, uv5, RADIUS_4b, true); }

