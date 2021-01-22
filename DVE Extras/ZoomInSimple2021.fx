// @Released 2021-01-21
// @Author schrauber
// @Created 2021-01-21
// @see https://www.lwks.com/media/kunena/attachments/6375/ZoomIinSimple2021_640.png


/**
Designed for simple zooming in.
Not recommended for stronger negative scaling because the effect comes without minimizing scaling filter.
No background input.
Features:
- Supports the resolution in the effect chain from LWKS version 2021.
- Three scaling modes:
   - "Standard" (similar with the standard LWKS DVD effects)
   - Two "zoom center" modes, which also keep edge positions in focus during dynamic zooming.
     In this mode, you should fine-tune the position with the maximum zoom used to ensure the best centering when zooming in.
- Two backgrounds can be selected: opaque black and transparency.
  In the transparent mode, the frame edge interpolation is only applied to the alpha value
  in order to avoid double interpolation when other effects replace this transparency.
  Therefore, this mode should only be used if you really need transparency.
- "Expand" input
  This input, to which nothing needs to be connected, ensures that the full sequence aspect ratio can be used when zooming in.
  You can even use it to increase the resolution in the effect pipeline far above the original resolution and above the sequence resolution
  by connecting pattern texture with higher resolution width to this input (not with the Image effect, because that uses the sequence resolution).
  Note that higher resolutions load GPU and V-RAM. This feature is more useful with some minimization effects.
*/


//-----------------------------------------------------------------------------------------//
// Lightworks user effect ZoomInSimple2021.fx
//
// Version history:
//
// Created on 2021-01-21 to replace the old "ZoomOutIn.fx" effect,
// for better support of the original resolutions in the LWKS 2021 effect pipeline.
//-----------------------------------------------------------------------------------------//



int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Zoom in, simple, 2021";  
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "Designed for simple zooming in (not recommended for negative zoom values).";
   bool CanSize       = true;
> = 0;





//--------------------------------------------------------------//
// Inputs und Samplers
//--------------------------------------------------------------//

texture In;
sampler s_In = sampler_state
{
   Texture = <In>;
   #ifdef _LENGTH  // Versions check Lightworks >= 14.5 . For current Lightworks versions ClampToEdge is used for low GPU load, but for versions prior to Ligtworks 14.5 Mirror is used for compatibility.
      AddressU  = ClampToEdge;
      AddressV  = ClampToEdge;
   #else
      AddressU  = Mirror;
      AddressV  = Mirror;
   #endif
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};



texture Expand;  // Not used in code, but still does something (LWKS 2021.1):
                 // - The mere presence of the input forces at least a sequence resolution at the shader output.
                 // - If aspect ratio is different, the mere presence of this input forces the 
                 //   shader output texture dimensions to be expanded to the sequence aspect ratio. 
                 // - The user can also increase the dimensions of this texture beyond the sequence dimensions if needed,
                 //   if the width of the texture at this input is greater than the sequence width.

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//


float ScaleExp2
<
   string Description = "Zoom";
   string Flags = "DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 2.0;
> = 0.0;


int PosMethod
<
   string Group = "Positioning";
   string Description = "Method";
   string Enum = "Standard,"
       "Zoom centre (inactive if original scaling),"
       "Zoom centre;    Offset: +200% zoom";
> = 0;

float Point1x
<
   string Group = "Positioning";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Point1y
<
   string Group = "Positioning";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;


int SetTechnique
<
   string Description = "Mode";
   string Enum =  "Background: Opaque black,"
                  "Background: Transparent";
> = 0;



//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//


// Auto-synced parameters  Description see: https://github.com/FxSchrauber/Code_for_developing_Lightworks_effects/blob/master/Basics/Variables_etc/Auto_synced/README.md
float _OutputWidth;
float _OutputHeight;
float _InXScale = 1.0;   // 1.0, if this variable is not automatically synchronized before version 2021.
float _InYScale = 1.0;   // " 
float _InWidth  = 0.1;   // 0.1 is used as version check. From version 2021 the value is replaced automatically. If the value 0.1 remains unchanged, then it must be replaced in the shader code.
float _InHeight = 0.1;   // "





//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//


float4 fn_tex2D_p1 (sampler s,           // Pass 1 - Sampler function with alpha channel interpolation of edges (use only for the first pass)
                  float2 xy,            // Sampler Coordinates
                  float2 inDimensions,  // Dimensions of the texture in pixels at the input of the sampler used .
                  float scale)          // Linear scaling value of the shader (0 = 0% scaling , 1 = 100% unchanged scaling, etc.) 

{
   float2 inter = 1.0.xx / inDimensions;                              // Dimensions of the interpolation areas (Dimensions of an input text)
   inter /= max (1.0e-9.xx, scale.xx);                                // Adjust input interpolation dimensions to scale so that the interpolation width remains constant relative to the output pixel dimension.
   inter = min (0.5.xx, inter);                                       // Limitation of the scaling-dependent interpolation softness in order to avoid unexpected behavior with extremely small scalings.
   float2 distEdge   = 0.5.xx - abs(xy - 0.5.xx);                     // Distance from the edges of the source frame (negative values are outside)
   distEdge += inter;                                                 // Shift edges outward to avoid seeing interpolated lines at output frame edges when full screen.
   inter = min( 1.0.xx, distEdge * (1.0.xx / max (1e-9.xx, inter) )); // Reverses the direction of action, and scales with the distance of the sampler position from the source frame edge.
   float4 retval = tex2D (s, xy);                                     // Take a texture sample
   retval.a *= saturate( min (inter.x, inter.y));                     // Alpha edge softness 
   return retval;
}







//--------------------------------------------------------------
// Shader
//--------------------------------------------------------------


float4 ps_main (float2 uv1 : TEXCOORD1, uniform bool modeAlpha) : COLOR
{ 
   float2 inDimensions = float2 (_InWidth, _InHeight);                       // Dimensions of the texture at the "In" input.
   if (_InWidth == 0.1) inDimensions = float2 (_OutputWidth, _OutputHeight); // Version check. Use of variables compatible with versions before 2021.

   // ... Position vectors ...
   float2 point1 = float2 (Point1x - 0.5, 0.5 - Point1y);  // Zoom cernter (0 corresponds to the frame center)
      // Pass 1 adjustment:
      point1.x /= _InXScale;                // Adjustment of the position to different aspect ratios of the input in relation to the output effect.
      point1.y /= _InYScale;                // "
   float2 point1b = point1 + 0.5.xx;        // Zoom cernter (0.5 corresponds to the frame center)

  
   //  ... Scale ...
   float offset = (PosMethod == 2) ? 2.0 : 0.0; // 200% zoom offset
   float scale = exp2(ScaleExp2 + offset);      // The dimensions of the output image are adjusted proportionally to the scale variable ( 0 = 0% dimensions, 1 = imput dimensions etc.).
                                                // The function `exp2(ScaleExp)` causes an exponential slider characteristic (details see code description below the Technique).

   //  ... Zoom control value ...
   float zoom = (1.0 + (-1.0 / max (1.0e-9, scale )));    // Zoom control value. Details see code description (below the Technique)
   float2 zoomVector = zoom.xx * (point1b - uv1);         // Zoom direction vector. Details see code description (below the Technique)


   //  ... Scaling & Position ...
   float2 posOut;                                                       // Sample position 
   if (PosMethod == 0) posOut = (uv1 + point1 *-1.0.xx) + zoomVector;   // Scaling & Position; Position setting point in sync with the same pixel
   if (PosMethod >= 1) posOut = uv1 + zoomVector;                       // Scaling & Position; Zoom centre (Inactive if original scaling).


   // Sampler, Border
   float4 retval = fn_tex2D_p1 (s_In, posOut, inDimensions, scale);   // Sampler function with alpha softness
   if (modeAlpha == 1) {
      retval.rgb = retval.rgb * retval.aaa;            // RGB softness from alpha softness
      retval.a = 1.0;                                  // Remove all transparency, including alpha softness.
   }else{
      if (retval.a == 0.0) retval.rgb = 0.0.xxx;       // Disables reflection at alpha 0                             
   }
   return retval; 
} 








//--------------------------------------------------------------
// Technique
//--------------------------------------------------------------



technique tech_BlackBackground
{
   pass P_01  { PixelShader = compile PROFILE ps_main ( 1 ); }
}


technique tech_TransparentBackground
{
   pass P_01  { PixelShader = compile PROFILE ps_main ( 0 ); }
}




// ******************************************************************

// ****** END of the effect, following only descriptions ************

// ******************************************************************







//--------------------------------------------------------------
// Code descriptions
//--------------------------------------------------------------

/* ---------------------------------------

   `float zoom = (1.0 + (-1.0 / max (1.0e-9, scale )));` 
     // Provides zoom control values whose intentional non-linearity compensates for the unintentional non-linearity in the later zoom code.

     // Maximum output value range of "zoom":
        // zoom -1e9 (nearly negative infinite) ; Designed to generate scaling 0%
        // zoom  nearly 1 ; Designed to generate scaling nearly  infinite

     // Characteristic of this formula:
        // scale 0   rescaled to zoom -1e9 (nearly negative infinite) ; Designed to generate a 0% scaling
        // scale 0.5 rescaled to zoom -1   ; Designed to generate a 50% scaling
        // scale 1   rescaled to zoom  0   ; Designed to generate a 100% scaling
        // scale 2   rescaled to zoom  0.5 ; Designed to generate a 200% scaling
        // scale 10  rescaled to zoom  0.9 ; Designed to generate a 1000% scaling

   `float2 zoomVector = zoom * (point1b - uv1);`                // Zoom direction vector. 
      // Non-linear scaling, which can be linearized by the previously shown compensation code of the variable zoom. 
      // The Code `(point1b - uv1)` is the direction vector between the corrected adjusted point1, and the respective calculated texel / pixel.


*/

/* -------------------------------------------------------------------

   `exp2(ScaleExp)` 
   Do the same as `pow (2.0, ScaleExp)`.
   Causes an exponential slider characteristic 

   // Setting characteristic of the exponential zoom slider
   //         The dimensions will be doubled or halved in setting steps of 100%:
   //           0% No change
   //          100% Double dimensions
   //          200% Dimensions * 4

*/
