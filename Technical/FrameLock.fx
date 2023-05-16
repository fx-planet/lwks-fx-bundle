// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2022-06-23

/**
 Frame lock locks the frame size and aspect ratio of the image to that of the sequence.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FrameLock.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-11 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Frame lock", "User", "Technical", "This effect locks the frame size and aspect ratio of the image", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (FrameLock)
{ return ReadPixel (Input, uv1); }

