// @Maintainer jwrl
// @Released 2024-04-18
// @Author Jerker
// @Author khaver
// @Author jwrl
// @Created 2017-06-19

/**
 Originally released here as unsharp mask, this just that - a simple unsharp mask.  It
 may appear redundant, since the Lightworks effect does pretty much the same thing,
 but this one has a much expanded range and control of edge gain and contrast.  I've
 included it because I like the look of it, and because of that wider range.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ExpandedSharpen.fx
//
// *********************************** ORIGINAL HEADER **************************************
//
// Unsharp Mask by Jerker (Sound and Vision Unit) - was based on Big Blur by khaver, see
// below - and borrowed the main blur algorithm but simplified it by removing the red,
// green and blue color settings.  http://software.soundandvision.se
//
// Original description: Big Blur by khaver
//
// Smooth blur using a 12 tap circular kernel that rotates 5 degrees for each of 6 passes
// There's a checkbox for a 10 fold increase in the blur amount.  (This was removed and
// fixed at 5 in Jerker's effect.  He also had a bug in his version of the code that meant
// that although he included the six passes that khaver wrote, he only used five of them.
// That bug has been fixed - jwrl.)
//
// Further notes by jwrl.
//
// The effect was rewritten 19 July 2017.  Assumptions had been made about the way that
// shaders functioned in Lightworks that at best could only be described as coincidental
// if they were even true at all.  The original chromatic unsharpen shader was discarded
// altogether and instead the sharpening now just uses luminance.  Edge gain and contrast
// have also been provided, which were not available in the original effect.
//
// ******************************** END OF ORIGINAL HEADER **********************************
//
// Version history:
//
// Rewrite 2024-04-18 jwrl.
// Rewrite of the original effect to include masking.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Expanded sharpen", "Stylize", "Blurs and Sharpens", "If the Lightworks sharpen effects don't have enough range, try this.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (BlurAmt, "Unsharp radius", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (Threshold, "Threshold", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (EdgeGain, "Edge gain", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (EdgeGamma, "Edge contrast", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 0.15, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LUMA_DOT  float3(1.1955,2.3464,0.4581)
#define GAMMA_VAL 1.666666667

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_blur (sampler B, float2 uv, float ang)
{  
   float4 orig = tex2D (B, uv);

   if (BlurAmt <= 0.0) return orig;

   float angle = ang;
   float radius = BlurAmt * 100.0;

   float2 pixsize = 1.0.xx / float2 (_OutputWidth, _OutputHeight);
   float2 halfpix = pixsize / 2.0;
   float2 xy2, xy1 = uv + halfpix;

   float4 cOut = tex2D (B, xy1);

   for (int tap = 0; tap < 12; tap++) {
      sincos (angle, xy2.y, xy2.x);                             
      xy1 = uv + (halfpix * xy2 * radius);

      cOut += tex2D (B, xy1);
      angle += 0.5236;
   }

   cOut /= 13.0;

   return cOut;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique UnsharpMask

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclarePass (Pass1)
{ return fn_blur (Inp, uv2, 0.0); }

DeclarePass (Pass2)
{ return fn_blur (Pass1, uv2, 0.0873); }

DeclarePass (Pass3)
{ return fn_blur (Pass2, uv2, 0.1745); }

DeclarePass (Pass4)
{ return fn_blur (Pass3, uv2, 0.2618); }

DeclarePass (Pass5)
{ return fn_blur (Pass4, uv2, 0.3491); }

DeclarePass (Blur)
{ return fn_blur (Pass5, uv2, 0.4364); }

DeclareEntryPoint (UnsharpMask)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 retval = tex2D (Inp, uv2);

   if (Amount <= 0.0) return retval;

   float sharpMask = dot (retval.rgb, LUMA_DOT);
   float maskGamma = min (1.15, 1.1 - min (1.05, EdgeGamma)) * GAMMA_VAL;
   float maskGain  = EdgeGain * 2.0;

   sharpMask -= dot (tex2D (Blur, uv2).rgb, LUMA_DOT);
   maskGamma *= maskGamma;

   float sharp_pos = pow (max (0.0, sharpMask - Threshold), maskGamma) * maskGain;
   float sharp_neg = pow (max (0.0, -sharpMask - Threshold), maskGamma) * maskGain;

   float4 sharp  = float4 (retval.rgb + (sharp_pos - sharp_neg).xxx, retval.a);
   float4 result = lerp (retval, sharp, Amount);

   return lerp (retval, result, tex2D (Mask, uv2).x);
}

