// @Maintainer jwrl
// @Released 2023-01-11
// @Author jwrl
// @Created 2023-01-11

/**
 Frame lock locks the frame size and aspect ratio of the image to that of the sequence.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FrameLock.fx
//
// Version history:
//
// Built 2023-01-11 jwrl
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

