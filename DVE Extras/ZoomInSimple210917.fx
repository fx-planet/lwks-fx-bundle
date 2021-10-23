// @Maintainer jwrl
// @Released 2021-09-17
// @Author schrauber
// @Created 2021-01-21
// @see https://www.lwks.com/media/kunena/attachments/6375/ZoomIinSimple2021_640.png

/**
 Designed for simple zooming in.
 Not recommended for stronger negative scaling because the effect comes without minimizing
 scaling filter.
 No background input.

 Features:
 - Supports the resolution in the effect chain from LWKS version 2021.

 - Three scaling modes:
   - "Standard" (similar with the standard LWKS DVD effects)
   - Two "zoom center" modes, which also keep edge positions in focus during dynamic zooming.
     In this mode, you should fine-tune the position with the maximum zoom used to ensure the
     best centering when zooming in.

 - Two backgrounds can be selected: opaque black and transparency.
     In the transparent mode, the frame edge interpolation is only applied to the alpha value
     in order to avoid double interpolation when other effects replace this transparency.
     Therefore, this mode should only be used if you really need transparency.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ZoomInSimple210917.fx
//
// Version history:
//
// Update 2021-09-17 jwrl.
// Update of the original effect to improve support of LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }
#define ExecuteParam(SHD,PRM) { PixelShader = compile PROFILE SHD (PRM); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputWidth;
float _OutputHeight;

//--------------------------------------------------------------//
// Inputs und Samplers
//--------------------------------------------------------------//

DefineInput (In, s_RawInp);

DefineTarget (FixInp, s_In);

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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main (float2 uv1 : TEXCOORD2, uniform bool modeAlpha) : COLOR
{ 
   float2 inDimensions = float2 (_OutputWidth, _OutputHeight); // Use of variables compatible with versions before 2021.

   // ... Position vectors ...
   float2 point1 = float2 (Point1x - 0.5, 0.5 - Point1y);  // Zoom cernter (0 corresponds to the frame center)
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

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique tech_BlackBackground
{
   pass P_01 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_02 ExecuteParam (ps_main, 1)
}

technique tech_TransparentBackground
{
   pass P_01 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_01 ExecuteParam (ps_main, 0)
}

// ******************************************************************

// ****** END of the effect, following only descriptions ************

// ******************************************************************

//--------------------------------------------------------------
// Code descriptions
//--------------------------------------------------------------

/* ---------------------------------------

   This version has a new preamble shader, ps_initInp, that is designed to initialise the
   effect in a way that ensure that rotated image inputs do not behave oddly.  This means
   that coordinates used in the effect must reference TEXCOORD2 and not as would normally
   be expected, TEXCOORD1 - jwrl.

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
