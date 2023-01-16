// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect transitions between two video sources using a mixed key.  The result is
 that one image appears to "erode" into the other as if being eaten away by acid.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Erode_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Erosion", "Mix", "Abstract transitions", "Transitions between two video sources using a mixed key based on both", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint ()
{
   float a_1 = Amount * 1.5;
   float a_2 = max (0.0, a_1 - 0.5);

   a_1 = min (a_1, 1.0);

   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 m_1 = (Fgnd + Bgnd) * 0.5;
   float4 m_2 = max (m_1.r, max (m_1.g, m_1.b)) >= a_1 ? Fgnd : m_1;

   return max (m_2.r, max (m_2.g, m_2.b)) >= a_2 ? m_2 : Bgnd;
}

