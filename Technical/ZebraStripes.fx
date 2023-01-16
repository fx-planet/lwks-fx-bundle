// @Maintainer jwrl
// @Released 2023-01-11
// @Author jwrl
// @Created 2023-01-11

/**
 This effect displays zebra patterning in over white and under black areas of the frame.
 The settings are adjustable but default to 16-239 (8 bit).  Settings display as 8 bit
 values to make setting up simpler, but in a 10-bit project they will be internally
 scaled to 10 bits.  This is consistent with other Lightworks level settings.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks effect ZebraStripes.fx
//
// Version history:
//
// Built 2023-01-11 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Zebra pattern", "User", "Technical", "Displays zebra patterning in over white and under black areas of the frame", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (whites, "White level", kNoGroup, kNoFlags, 235.0, 0.0, 255.0);
DeclareFloatParam (blacks, "Black level", kNoGroup, kNoFlags, 16.0, 0.0, 255.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SCALE_PIXELS 66.666667   // 400.0

#define RED_LUMA     0.3
#define GREEN_LUMA   0.59
#define BLUE_LUMA    0.11

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (ZebraStripes)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 retval = tex2D (Inp, uv2);

   float luma = dot (retval.rgb, float3 (RED_LUMA, GREEN_LUMA, BLUE_LUMA));
   float peak_white = whites / 255.0;
   float full_black = blacks / 255.0;

   float2 xy = frac (uv2 * SCALE_PIXELS);

   if (luma >= peak_white) {
      retval.rgb += round (frac (xy.x + xy.y)).xxx;
      retval.rgb /= 2.0;
   }

   if (luma <= full_black) {
      retval.rgb += round (frac (xy.x + 1.0 - xy.y)).xxx;
      retval.rgb /= 2.0;
   }

   return retval;
}

