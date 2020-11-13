// @Maintainer jwrl
// @Released 2020-11-13
// @Author schrauber
// @Created 2020-06-07
// @see: https://www.lwks.com/media/kunena/attachments/6375/QuadDynamic_640.png

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
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadScreenZ.fx
//
// Version history:
//
// Update 2020-11-13 jwrl.
// Added Cansize switch for LW 2021 support.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Quad split screen, dynamic zoom";  
   string Category    = "DVE";
   string SubCategory = "Multiscreen Effects";
   string Notes       = "Revised version of 7 June 2020";
   bool CanSize       = true;
> = 0;



//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//



int ZoomInput
<
   string Group = "Zoom";
   string Description = "Select thumbnail to highlighted zoom";
   string Enum = "Top Left,"
                 "Top Right,"
                 "Bottom Left,"
                 "Bottom Right";
> = 0;

float Zoom
<
   string Group = "Zoom";
   string Description = "Highlighted";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;



float BaseSkale
<
   string Group = "Zoom";
   string Description = "Base Scale";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.492;




float4 Bg
<
   string Group = "Colours (`A` slider colors soft edges in a transparent setup)";
   string Description = "Background";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 0.0, 0.0 };

int AlphaOut
<
   string Group = "Colours (`A` slider colors soft edges in a transparent setup)";
   string Description = " ";
   string Enum = "Output completely opaque colours. Ignores alpha slider,"
                 "Transparency. Add Bg & soft edges in downstream effect";
> = 0;


int SetTechnique
<
   string Group = "Softness (if `Highlighted` at 100%, then partly inactive)";
   string Description = " ";
   string Enum = "Fast mode; frame edge softness only,"
                 "Softness of frame edges and alpha edges,"
                 "Quality mode: Antialiasing & Soft frame edges,"
                 "Quality mode: Antialiasing & Soft edges (frame & alpha)";
> = 0;


float Soft
<
   string Group = "Softness (if `Highlighted` at 100%, then partly inactive)";
   string Description = "Edge softness";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0; 
   float MaxVal = 0.3;
> = 0.0;

bool AllEdges
<
   string Group = "Softness (if `Highlighted` at 100%, then partly inactive)";
   string Description = "Frame edge softness setting affects all edges";
> = false;

bool RoundedEdges
<
   string Group = "Softness (if `Highlighted` at 100%, then partly inactive)";
   string Description = "Frame edge softness setting creates rounded corners";
> = false;



bool ActiveIn0
<
   string Group = "Selected inputs for use if connected";
   string Description = "`a` Top Left";
> = true;

bool ActiveIn1
<
   string Group = "Selected inputs for use if connected";
   string Description = "`b` Top Right";
> = true;

bool ActiveIn2
<
   string Group = "Selected inputs for use if connected";
   string Description = "`c` Bottom Left";
> = true;

bool ActiveIn3
<
   string Group = "Selected inputs for use if connected";
   string Description = "`d` Bottom Right";
> = true;



//-----------------------------------------------------------------------------------------//
// Common definitions, declarations, macros
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

float _OutputWidth;
float _OutputHeight;

#define EMPTY         0.0.xxxx
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
// Inputs and Samplers
//-----------------------------------------------------------------------------------------//

// Macros as short form of the sampler definitions:

#define MIRROR \
   AddressU  = Mirror;\
   AddressV  = Mirror;\
   MinFilter = Linear;\
   MagFilter = Linear;\
   MipFilter = Linear;

#ifdef _LENGTH                 
// Versions check Lightworks > 14.0
   // For current Lightworks versions ClampToEdge is used for low GPU load, but for versions prior to Ligtworks 14.5 Mirror is used for compatibility.
   #define CLAMP_OR_MIRROR \
      AddressU  = ClampToEdge;\
      AddressV  = ClampToEdge;\
      MinFilter = Linear;\
      MagFilter = Linear;\
      MipFilter = Linear;
#else
   #define CLAMP_OR_MIRROR \
      AddressU  = Mirror;\
      AddressV  = Mirror;\
      MinFilter = Linear;\
      MagFilter = Linear;\
      MipFilter = Linear;
#endif


// ...... Input a, and the render pre-bur textures assigned to this input......

texture a;
sampler s_Fg0 = sampler_state       { Texture = <a>; CLAMP_OR_MIRROR };

texture renderBlur0 : RenderColorTarget;
sampler s_blur0 = sampler_state     { Texture = <renderBlur0>; CLAMP_OR_MIRROR };     // No 'mirror' addressing was used for pre-blanking, because it has no advantage due to the minimization, and 'ClampToEdge' is partly more efficient. 



// ...... Input b, and the render pre-bur textures assigned to this input......

texture b;
sampler s_Fg1 = sampler_state { Texture = <b>; CLAMP_OR_MIRROR };

texture renderBlur1 : RenderColorTarget;
sampler s_blur1 = sampler_state     { Texture = <renderBlur1>; CLAMP_OR_MIRROR };



// ...... Input c, and the render pre-bur textures assigned to this input......

texture c;
sampler s_Fg2 = sampler_state       { Texture  = <c>; CLAMP_OR_MIRROR };

texture renderBlur2 : RenderColorTarget;
sampler s_blur2 = sampler_state      { Texture = <renderBlur2>; CLAMP_OR_MIRROR };



// ...... Input d, and the render pre-bur textures assigned to this input......

texture d;
sampler s_Fg3 = sampler_state       { Texture  = <d>; CLAMP_OR_MIRROR };

texture renderBlur3 : RenderColorTarget;
sampler s_blur3 = sampler_state     { Texture = <renderBlur3>; CLAMP_OR_MIRROR };




// ...... Render texture after mixing the inputs......

texture renderMix : RenderColorTarget;
sampler s_blurA = sampler_state     { Texture = <renderMix>; MIRROR };





//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_fn, float2 xy, float2 soft, bool4 edges)
{
   float2 distEdge = 0.5.xx - abs(xy - 0.5.xx);                    // Distance from edges (negative values are Outside)
   if ((distEdge.x < 0.0 ) || (distEdge.y < 0.0 )) return EMPTY;
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



     
//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_splitScreen (float2 uv_ : TEXCOORD1,
                       float2 uv_1 : TEXCOORD2,
                       float2 uv_2 : TEXCOORD3,
                       float2 uv_3 : TEXCOORD4,
                       uniform sampler sampler0,
                       uniform sampler sampler1,
                       uniform sampler sampler2,
                       uniform sampler sampler3,
                       uniform bool alphaBlur) : COLOR
{ 
   int i; // loop counter

   float2 uv[THUMBNAILS];
   uv[0] = uv_;
   uv[1] = uv_1;
   uv[2] = uv_2;
   uv[3] = uv_3;

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
      vPt[i] = pos[i] - uv[i];   // Direction vector of the set position to the currently calculated texel.
   }


// Zoom strength & Edge softness:
   float soft1 = max( SOFT, 1.0 / _OutputWidth);               // Edge softness included minimum softness to prevent edge flickering.
   zoomOffset = Zoom * (1.0 + soft1);                          // Highlight Zoom Offset. Details see variable declaration
   float zoomH = min (1.0, Zoom * (1.0 + soft1));              // Stop at 100%.
   float zoomDelta = zoomOffset - zoomH;                       // Controls the reduction of edge softness above the stop value.
   float dimensionH = (zoomH * (1.0 - BaseSkale)) + BaseSkale; // Dimension of the texture to be highlighted;  Range [BaseSkale .. 1]
   float zoomCorrection = dimensionH - BaseSkale;              // Range [0 .. 0.5] (Quad split screen)
   float dimensionT[THUMBNAILS];                               // Dimension of the individual thrumbinals, 0 = Dimensions 0 , 0.5 = Dimensions 50%, 1 = Dimensions 100% (full screen)
   float2 soft[THUMBNAILS]; 
   for(i=0; i<THUMBNAILS; i++)
   { 
      dimensionT[i] = (ZoomInput == i )
        ? dimensionH                                        // Range [BaseSkale .. 1] (If it is the texture to be highlighted & quad)
        : (BaseSkale - zoomCorrection);                     // Range (Quad split screen) [0.5 .. 0] (If it is the other textures that are minimized when "Highlighted" > 0% & quad)
      soft[i] = soft1.xx / max (1.0e-9, dimensionT[i]).xx;  // Widen the softness before scaling to maintain the width after scaling down.
      soft[i] -= zoomDelta.xx;                              // Controls the reduction of edge softness above the stop value.
      soft[i].y *=  _OutputAspectRatio;
      soft[i] =  min (0.5.xx, soft[i]);                     // Prevents edge softness overdrive beyond the center.
   }


   // ------ ZOOM:
   float4 input[THUMBNAILS];
   #define ZOOM(zoom)  (1.0 + (-1.0 / max (1.0e-9, zoom)))         // Macro, the zoom range from [0..1] is rescaled to [-1e-9 .. 0]   ( 0 = Dimensions 100%, -1 = Dimensions 50 %, -2 Dimensions 33.3 %, -1e-9 (approximately negative infinite) = size 0%)
   input[0] = fn_tex2D (sampler0, ZOOM(dimensionT[0]).xx * vPt[0] + uv[0], soft[0], bool4 (false, true, true, false)); // Thumbnail top left.    bool4 defines the deactivation of softness edges. `true` allows softness.   Order: up, right, down, left
   input[1] = fn_tex2D (sampler1, ZOOM(dimensionT[1]).xx * vPt[1] + uv[1], soft[1], bool4 (false, false, true, true)); // Thumbnail top right.
   input[2] = fn_tex2D (sampler2, ZOOM(dimensionT[2]).xx * vPt[2] + uv[2], soft[2], bool4 (true, true, false, false)); // Thumbnail bottom left.
   input[3] = fn_tex2D (sampler3, ZOOM(dimensionT[3]).xx * vPt[3] + uv[3], soft[3], bool4 (true, false, false, true)); // Thumbnail bottom right.

   // ------ Mix:
   input[0] = (ActiveIn0) ?  input[0] : EMPTY;
   input[1] = (ActiveIn1) ?  input[1] : EMPTY;
   input[2] = (ActiveIn2) ?  input[2] : EMPTY;
   input[3] = (ActiveIn3) ?  input[3] : EMPTY;

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







float4 ps_preBlur (float2 uv  : TEXCOORD1,
                   float2 uv1 : TEXCOORD2,
                   float2 uv2 : TEXCOORD3,
                   float2 uv3 : TEXCOORD4, 
                   uniform sampler blurSampler,
                   uniform float passRadius,
                   uniform int blurInput) : COLOR
{
   if (blurInput == 1) uv = uv1;
   if (blurInput == 2) uv = uv2;
   if (blurInput == 3) uv = uv3;

  // Zoom strength:

  float dimension = (Zoom * (1.0 - BaseSkale)) + BaseSkale;  // Range [BaseSkale .. 1]
  float zoomCorrection = dimension - BaseSkale;              // Range [0 .. 0.5] (Quad split screen)
  float scale = (blurInput == ZoomInput )
     ? dimension                                      // Range [BaseSkale .. 1] (If it is the texture to be highlighted & quad)
     : (BaseSkale - zoomCorrection);                  // Range (Quad split screen) [0.5 .. 0] (If it is the other textures that are minimized when "Highlighted" > 0% & quad)
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





// ps_AlphaBlur1: Prevents the alpha-0 areas from being excessively reduced by blurring.
float4 ps_AlphaBlur1 (float2 uv  : TEXCOORD0,
                      float2 uv1 : TEXCOORD1,
                      float2 uv2 : TEXCOORD2,
                      float2 uv3 : TEXCOORD3,
                      float2 uv4 : TEXCOORD4,
                      uniform float passRadius ) : COLOR
{
   if (ActiveIn3) uv = uv4;
   if (ActiveIn2) uv = uv3;
   if (ActiveIn1) uv = uv2;
   if (ActiveIn0) uv = uv1 ;

   float soft = max( SOFT_ALPHA, 1.0 / _OutputWidth);  // Softness included minimum softness to prevent edge flickering.
   float2 radius = float2 (1.0, _OutputAspectRatio)  * soft.xx * passRadius.xx;

  // ... Blur ...
   float sample[9];
   float4 retval = tex2D (s_blurA, uv);
   sample[0] = retval.a;

   // vertical blur
   sample[1] = tex2D (s_blurA, float2 (uv.x, uv.y + radius.y)).a;
   sample[2] = tex2D (s_blurA, float2 (uv.x, uv.y - radius.y)).a;


   //horizantal blur
   sample[3] = tex2D (s_blurA, float2 (uv.x + radius.x, uv.y)).a;
   sample[4] = tex2D (s_blurA, float2 (uv.x - radius.x, uv.y)).a;

   // The box blur is now repeated with the coordinates rotated by 45 degrees
   radius *= DIAG_SCALE;
   sample[5] = tex2D (s_blurA, uv + radius).a;
   sample[6] = tex2D (s_blurA, uv - radius).a;

   // Inverting the Y vector changes the rotation to -45 degrees from reference
   radius.y = -radius.y;
   sample[7] = tex2D (s_blurA, uv + radius).a;
   sample[8] = tex2D (s_blurA, uv - radius).a;

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




float4 ps_AlphaBlur2 (float2 uv  : TEXCOORD0,
                      float2 uv1 : TEXCOORD1,
                      float2 uv2 : TEXCOORD2,
                      float2 uv3 : TEXCOORD3,
                      float2 uv4 : TEXCOORD4,
                      uniform float passRadius, 
                      uniform bool lastPass ) : COLOR
{
   if (ActiveIn3) uv = uv4;
   if (ActiveIn2) uv = uv3;
   if (ActiveIn1) uv = uv2;
   if (ActiveIn0) uv = uv1 ;

   float soft = max( SOFT_ALPHA, 1.0 / _OutputWidth);  // Softness included minimum softness to prevent edge flickering.
  float2 radius = float2 (1.0, _OutputAspectRatio)  * soft.xx * passRadius.xx;

// ... Blur ...
   float4 sample = tex2D (s_blurA, uv);
   float alpha = sample.a;

   // vertical blur
   alpha += tex2D (s_blurA, float2 (uv.x, uv.y + radius.y)).a;
   alpha += tex2D (s_blurA, float2 (uv.x, uv.y - radius.y)).a;

   //horizantal blur
   alpha += tex2D (s_blurA, float2 (uv.x + radius.x, uv.y)).a;
   alpha += tex2D (s_blurA, float2 (uv.x - radius.x, uv.y)).a;

   // The box blur is now repeated with the coordinates rotated by 45 degrees
   radius *= DIAG_SCALE;
   alpha += tex2D (s_blurA, uv + radius).a;
   alpha += tex2D (s_blurA, uv - radius).a;

   // Inverting the Y vector changes the rotation to -45 degrees from reference
   radius.y = -radius.y;
   alpha += tex2D (s_blurA, uv + radius).a;
   alpha += tex2D (s_blurA, uv - radius).a;

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
// Technique
//-----------------------------------------------------------------------------------------//


technique tech_fast
{
   pass P_1  { PixelShader = compile PROFILE ps_splitScreen (s_Fg0, s_Fg1, s_Fg2, s_Fg3, false); }
}


technique tech_Alpha
{
  // ... Main shader:
   pass P_1_1  < string Script = "RenderColorTarget0 = renderMix;";   > { PixelShader = compile PROFILE  ps_splitScreen (s_Fg0, s_Fg1, s_Fg2, s_Fg3, true); }

  // ... Alpha blur:
   pass P_2_1  < string Script = "RenderColorTarget0 = renderMix;";   > { PixelShader = compile PROFILE  ps_AlphaBlur1 (RADIUS_1); }
   pass P_2_2  < string Script = "RenderColorTarget0 = renderMix;";   > { PixelShader = compile PROFILE  ps_AlphaBlur2 (RADIUS_2,  false); }
   pass P_2_3  < string Script = "RenderColorTarget0 = renderMix;";   > { PixelShader = compile PROFILE  ps_AlphaBlur2 (RADIUS_2b, false); }
   pass P_2_4  < string Script = "RenderColorTarget0 = renderMix;";   > { PixelShader = compile PROFILE  ps_AlphaBlur2 (RADIUS_3b, false); }
   pass P_2_5  { PixelShader = compile PROFILE  ps_AlphaBlur2 (RADIUS_4b, true); } //  If necessary, the alpha values are applied to the RGB values
}





technique tech_filter
{
  // ... Pre-blurring of the input textures (scaling dependent):
   pass P_0_1  < string Script = "RenderColorTarget0 = renderBlur0;"; > { PixelShader = compile PROFILE  ps_preBlur (s_Fg0,   RADIUS_2,0); }
   pass P_0_2  < string Script = "RenderColorTarget0 = renderBlur0;"; > { PixelShader = compile PROFILE  ps_preBlur (s_blur0, RADIUS_1,0); }
   pass P_1_1  < string Script = "RenderColorTarget0 = renderBlur1;"; > { PixelShader = compile PROFILE  ps_preBlur (s_Fg1,   RADIUS_2,1); }
   pass P_1_2  < string Script = "RenderColorTarget0 = renderBlur1;"; > { PixelShader = compile PROFILE  ps_preBlur (s_blur1, RADIUS_1,1); }
   pass P_2_1  < string Script = "RenderColorTarget0 = renderBlur2;"; > { PixelShader = compile PROFILE  ps_preBlur (s_Fg2,   RADIUS_2,2); }
   pass P_2_2  < string Script = "RenderColorTarget0 = renderBlur2;"; > { PixelShader = compile PROFILE  ps_preBlur (s_blur2, RADIUS_1,2); }
   pass P_3_1  < string Script = "RenderColorTarget0 = renderBlur3;"; > { PixelShader = compile PROFILE  ps_preBlur (s_Fg3,   RADIUS_2,3); }
   pass P_3_2  < string Script = "RenderColorTarget0 = renderBlur3;"; > { PixelShader = compile PROFILE  ps_preBlur (s_blur3, RADIUS_1,3); }

  // ... Main shader:
   pass P_4_1  { PixelShader = compile PROFILE ps_splitScreen (s_blur0, s_blur1, s_blur2, s_blur3, false); }
}




technique tech_filterAlpha
{
  // ... Pre-blurring of the input textures (scaling dependent):
   pass P_0_1  < string Script = "RenderColorTarget0 = renderBlur0;"; > { PixelShader = compile PROFILE  ps_preBlur (s_Fg0,   RADIUS_2,0); }
   pass P_0_2  < string Script = "RenderColorTarget0 = renderBlur0;"; > { PixelShader = compile PROFILE  ps_preBlur (s_blur0, RADIUS_1,0); }
   pass P_1_1  < string Script = "RenderColorTarget0 = renderBlur1;"; > { PixelShader = compile PROFILE  ps_preBlur (s_Fg1,   RADIUS_2,1); }
   pass P_1_2  < string Script = "RenderColorTarget0 = renderBlur1;"; > { PixelShader = compile PROFILE  ps_preBlur (s_blur1, RADIUS_1,1); }
   pass P_2_1  < string Script = "RenderColorTarget0 = renderBlur2;"; > { PixelShader = compile PROFILE  ps_preBlur (s_Fg2,   RADIUS_2,2); }
   pass P_2_2  < string Script = "RenderColorTarget0 = renderBlur2;"; > { PixelShader = compile PROFILE  ps_preBlur (s_blur2, RADIUS_1,2); }
   pass P_3_1  < string Script = "RenderColorTarget0 = renderBlur3;"; > { PixelShader = compile PROFILE  ps_preBlur (s_Fg3,   RADIUS_2,3); }
   pass P_3_2  < string Script = "RenderColorTarget0 = renderBlur3;"; > { PixelShader = compile PROFILE  ps_preBlur (s_blur3, RADIUS_1,3); }

  // ... Main shader:
   pass P_4_1  < string Script = "RenderColorTarget0 = renderMix;";   > { PixelShader = compile PROFILE  ps_splitScreen (s_blur0, s_blur1, s_blur2, s_blur3, true); }

  // ... Alpha blur:
   pass P_5_1  < string Script = "RenderColorTarget0 = renderMix;";   > { PixelShader = compile PROFILE  ps_AlphaBlur1 (RADIUS_1); }
   pass P_5_2  < string Script = "RenderColorTarget0 = renderMix;";   > { PixelShader = compile PROFILE  ps_AlphaBlur2 (RADIUS_2,  false); }
   pass P_5_3  < string Script = "RenderColorTarget0 = renderMix;";   > { PixelShader = compile PROFILE  ps_AlphaBlur2 (RADIUS_2b, false); }
   pass P_5_4  < string Script = "RenderColorTarget0 = renderMix;";   > { PixelShader = compile PROFILE  ps_AlphaBlur2 (RADIUS_3b, false); }
   pass P_5_5  { PixelShader = compile PROFILE  ps_AlphaBlur2 (RADIUS_4b, true); } //  If necessary, the alpha values are applied to the RGB values
}
