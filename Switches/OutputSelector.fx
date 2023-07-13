// @Maintainer jwrl
// @Released 2023-07-13
// @Author baopao
// @Created 2014-02-02

/**
 This effect is a simple device to select from up to four different outputs.  It was designed
 for, and is extremely useful on complex effects builds to check the output of masking or
 cropping, the DVE setup, colour correction pass or whatever else you may need.

 Since it has very little overhead it may be safely left in situ when the effects setup
 process is complete.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/
//-----------------------------------------------------------------------------------------//
// Lightworks user effect OutputSelector.fx
//
// Version history:
//
// Updated 2023-07-13 jwrl.
// Corrected creation date.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Output selector", "User", "Switches", "A simple effect to select from up to four different outputs for monitoring purposes", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (In_1, In_2, In_3, In_4);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Output", kNoGroup, 0, "Input 1|Input 2|Input 3|Input 4");

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (OutputSelector_Input_1)
{ return ReadPixel (In_1, uv1); }

DeclareEntryPoint (OutputSelector_Input_2)
{ return ReadPixel (In_2, uv2); }

DeclareEntryPoint (OutputSelector_Input_3)
{ return ReadPixel (In_3, uv3); }

DeclareEntryPoint (OutputSelector_Input_4)
{ return ReadPixel (In_4, uv4); }

