// @Maintainer jwrl
// @Released 2021-08-30
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
// Update 2021-08-30 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Liquify";
   string Category    = "Stylize";
   string SubCategory = "Distortion";
   string Notes       = "Distorts the image in a soft liquid manner";
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

#define SetTargetMode(TGT, SMP, MODE) \
                                      \
 texture TGT : RenderColorTarget;     \
                                      \
 sampler SMP = sampler_state          \
 {                                    \
   Texture   = <TGT>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputAspectRatio;
float _OutputWidth;

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Inputs and Samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

SetTargetMode (FixInp, s_Input, Mirror);

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
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass means that rotated video is handled correctly - jwrl.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   if (Overflow (uv1)) return EMPTY;                                // Quit if we're outside frame boundaries - applies with unmatched aspect ratios

   // This section is a heavily optimised version of the original shader ps_mirror()

   float2 offset = float2 (Xcentre, 1.0 - Ycentre);                 // Reference point offset
   float2 distortion = offset - float2 (Xdistort, 1.0 - Ydistort);  // Distance of the distortion point from the offset

   offset = uv2 - offset;                                           // Calculate coordinates relative to offset point
   offset.x *= _OutputAspectRatio;                                  // Correct the X offset by the aspect ratio

   float displace = min (1.0, distance (0.0.xx, offset));           // Displacement of the chosen pixel from reference

   displace = (1.0 - cos (displace * PI)) * 0.5;                    // Distance curve rounded to soften distortion in the effect centre

   float area = max (0.0, Area - displace);                         // Limits the maximum range of the distortion (removes residual distortion)

   area = (1.0 - cos (area * HALF_PI)) * 0.5;                       // Soft edge of the distortion area (S-curve)
   displace += area;                                                // Offset the displacement with the corrected area value
   area *= Strength * Area * 1.5;                                   // Adjust the strength only within the active area
   distortion *= area / max (1e-9, displace);                       // Distortion decreases with distance from the effect centre

   float4 retval = tex2D (s_Input, uv2 + distortion);               // Take a distorted pixel sample from the sampler

   if (modeAlpha == 0) return retval;                               // Return with mirrored frame edges if modeAlpha is zero

   // From here on was originally executed in a separate function.  With code optimisations that is no longer necessary.

   float2 xy = uv2 - 0.5.xx;                                        // Centre sampler coordinates around 0 as midpoint
   float2 soft = float2 (1.0, _OutputAspectRatio);                  // Preload soft with aspect ratio adjustment

   soft *= Soft + (1.0 /_OutputWidth);                              // Calculate the softness range
   soft *= min (1.0.xx, (0.5.xx - abs (xy)) / max (1e-9, soft));    // Remove the interpolation (soft = 0) if the output pixel is on the frame border
   xy = 0.5.xx - abs (xy + distortion);                             // Distance from the edges of the output frame (negative values are outside)
   soft = min (1.0.xx, xy / max (1e-9, soft));                      // Reverses the direction of action.  Scale is proportional to distance from frame edge

   retval.a *= saturate (min (soft.x, soft.y));                     // Alpha edge softness ramps from 0 to 1

   // We now exit using a slightly restructured version of the exit code from the original shader ps_border().  This gives a visible change when transparent
   // mode is selected, which will result in exactly the same appearance if the result is blended with black as is obtained when opaque black is selected.

   if (modeAlpha == 2) {
      retval.a = pow (retval.a, 0.5);                               // Getting the square root of alpha means that subsequent blends will look the same
      retval.rgb *= retval.a;                                       // when we multiply by the RGB by alpha then use lerp to combine with a background
   }
   else {
      retval.rgb *= retval.a;                                       // This is the original ps_border() exit condition for opaque black
      retval.a = 1.0;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Liquify
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (ps_main)
}

