// @Maintainer jwrl
// @Released 2020-10-24
// @Author schrauber
// @Created 2020-10-23
// @see https://www.lwks.com/media/kunena/attachments/6375/Liquify_640.png

/**
 This is an effect that mimics the popular liquify effect in art software.  While those
 perform the distortion by means of warp meshes, this effect instead distorts by means
 of an offset from a frame reference point.  The difference in the end result is slight.

 The edge of the frame can be mirrored, the area outside the frame can be black, or can
 be made transparent for use in other blend or DVE effects.  When in the two latter
 modes the edge of frame can be softened.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect  Liquify.fx
//
// Version history:
//
// Optimised 2020-10-23 by jwrl.
// The visual impact of the effect is unchanged after the optimisation.  This has been
// confirmed by exhaustive comparisons between the optimised version and the original.
// Optimisations are:
// Where possible float2 variables were replaced with float variables
// Maths functions were simplified
// Redundant mathematical operations were removed
// If division could be avoided it has been
// Soft edge function was converted to in-line code
// Instead of separate shaders for mirror and opaque/transparent operations a single
// shader is used
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Liquify";
   string Category    = "Stylize";
   string SubCategory = "Distortion";
   string Notes       = "Distorts the image in a soft liquid manner";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and Samplers
//-----------------------------------------------------------------------------------------//

texture Input;

sampler s_Input = sampler_state
 {
   Texture   = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
 };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Area
<
   string Description = "Distortion Area";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 1.5;
> = 0.5;

float Strength
<
   string Description = "Strength";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Soft
<
   string Description = "Edge softness";
   string Flags = "DisplayAsPercentage";
   float MinVal = -0.01;
   float MaxVal = 0.2;
> = 0.0;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Xdistort
<
   string Description = "Distortion Direction";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float Ydistort
<
   string Description = "Distortion Direction";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.6;

int modeAlpha
<
   string Description = "Background";
   string Enum = "Mirrored foreground,Opaque black,Transparent";
> = 1;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   // This section is a heavily optimised version of the original shader ps_mirror()

   float2 offset = float2 (Xcentre, 1.0 - Ycentre);                 // Reference point offset
   float2 distortion = offset - float2 (Xdistort, 1.0 - Ydistort);  // Distance of the distortion point from the offset

   offset = uv - offset;                                            // Calculate coordinates relative to offset point
   offset.x *= _OutputAspectRatio;                                  // Correct the X offset by the aspect ratio

   float displace = min (1.0, distance (0.0.xx, offset));           // Displacement of the chosen pixel from reference

   displace = (1.0 - cos (displace * PI)) * 0.5;                    // Distance curve rounded to soften distortion in the effect centre

   float area = max (0.0, Area - displace);                         // Limits the maximum range of the distortion (removes residual distortion)

   area = (1.0 - cos (area * HALF_PI)) * 0.5;                       // Soft edge of the distortion area (S-curve)
   displace += area;                                                // Offset the displacement with the corrected area value
   area *= Strength * Area * 1.5;                                   // Adjust the strength only within the active area
   distortion *= area / max (1e-9, displace);                       // Distortion decreases with distance from the effect centre

   float4 retval = tex2D (s_Input, uv + distortion);                // Take a distorted pixel sample from the sampler

   if (modeAlpha == 0) return retval;                               // Return with mirrored frame edges if modeAlpha is zero

   // From here on was originally executed in a separate function, fn_tex2D().  With code optimisations that is no longer necessary.

   float2 xy = uv - 0.5.xx;                                         // Centre sampler coordinates around 0 as midpoint
   float2 soft = float2 (1.0, _OutputAspectRatio);                  // Preload soft with aspect ratio adjustment

   soft *= Soft + (1.0 /_OutputWidth);                              // Calculate the softness range
   soft *= min (1.0.xx, (0.5.xx - abs (xy)) / max (1e-9, soft));    // Remove the interpolation (soft = 0) if the output pixel is on the frame border
   xy = 0.5.xx - abs (xy + distortion);                             // Distance from the edges of the output frame (negative values are outside)
   soft = min (1.0.xx, xy / max (1e-9, soft));                      // Reverses the direction of action.  Scale is proportional to distance from frame edge

   retval.a *= saturate (min (soft.x, soft.y));                     // Alpha edge softness ramps from 0 to 1

   // We now exit using a slightly restructured version of the exit code from the original shader ps_border()

   if (modeAlpha == 2) return retval;                               // Return with alpha transparency if modeAlpha is set to 2

   retval.rgb *= retval.a;                                          // Soft fade to black at frame edges by multiplying by alpha

   return float4 (retval.rgb, 1.0);                                 // Remove all transparency by turning alpha fully on
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Liquify
{
   pass P_1  { PixelShader = compile PROFILE ps_main (); }
}

