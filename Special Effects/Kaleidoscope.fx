// @Maintainer jwrl
// @Released 2023-01-11
// @Author khaver
// @Created 2011-06-28

/**
 This kaleidoscope effect varies the number of sides, position and scale.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Kaleidoscope.fx
//
// Version history:
//
// Updated 2023-01-11 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Kaleidoscope", "Stylize", "Special Effects", "This kaleidoscope effect varies the number of sides, position and scale", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Complexity", kNoGroup, 0, "One|Two|Three|Four");

DeclareFloatParam (ORGX, "Pan", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (ORGY, "Pan", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Zoom, "Zoom", kNoGroup, kNoFlags, 1.0, 0.0, 2.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_zoom (sampler S, float2 uv)
{
   float2 zoomit = ((uv - 0.5.xx) / Zoom) + 0.5.xx;

   zoomit += float2 (0.5 - ORGX, ORGY - 0.5);

   return saturate (ReadPixel (S, zoomit));
}

float4 fn_main (sampler S, float2 uv)
{
   uv -= 0.5.xx;

   return saturate (tex2D (S, abs (uv)));
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Technique one

DeclarePass (Inp_1)
{ return ReadPixel (Input, uv1); }

DeclarePass (Sample1_1)
{ return fn_zoom (Inp_1, uv2); }

DeclareEntryPoint (Kaleidoscope_One)
{ return fn_main (Sample1_1, uv2); }


// Technique two

DeclarePass (Inp_2)
{ return ReadPixel (Input, uv1); }

DeclarePass (Sample1_2)
{ return fn_zoom (Inp_2, uv2); }

DeclarePass (Sample2_2)
{ return fn_main (Sample1_2, uv2); }

DeclareEntryPoint (Kaleidoscope_Two)
{ return fn_main (Sample2_2, uv2); }


// Technique three

DeclarePass (Inp_3)
{ return ReadPixel (Input, uv1); }

DeclarePass (Sample1_3)
{ return fn_zoom (Inp_3, uv2); }

DeclarePass (Sample2_3)
{ return fn_main (Sample1_3, uv2); }

DeclarePass (Sample3_3)
{ return fn_main (Sample2_3, uv2); }

DeclareEntryPoint (Kaleidoscope_Three)
{ return fn_main (Sample3_3, uv2); }


// Technique four

DeclarePass (Inp_4)
{ return ReadPixel (Input, uv1); }

DeclarePass (Sample1_4)
{ return fn_zoom (Inp_4, uv2); }

DeclarePass (Sample2_4)
{ return fn_main (Sample1_4, uv2); }

DeclarePass (Sample3_4)
{ return fn_main (Sample2_4, uv2); }

DeclarePass (Sample4_4)
{ return fn_main (Sample3_4, uv2); }

DeclareEntryPoint (Kaleidoscope_Four)
{ return fn_main (Sample4_4, uv2); }

