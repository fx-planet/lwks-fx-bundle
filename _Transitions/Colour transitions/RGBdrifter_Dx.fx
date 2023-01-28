// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This transitions between the two images using different curves for each of red, green
 and blue.  One colour and alpha is always linear, and the other two can be set using
 the colour profile selection.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBdrifter_Dx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("RGB drifter", "Mix", "Colour transitions", "Dissolves between the two images using different curves for each of red, green and blue", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Select colour profile", kNoGroup, 0, "Red to blue|Blue to red|Red to green|Green to red|Green to blue|Blue to green");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI 1.5707963268

#define CURVE   4.0

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Out_R_B)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Inc_R_B)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_R_B)
{
   float4 vidOut = tex2D (Out_R_B, uv3);
   float4 vidIn  = tex2D (Inc_R_B, uv3);
   float4 retval;

   float amt_R = pow (1.0 - Amount, CURVE);
   float amt_B = pow (Amount, CURVE);

   retval.ga = lerp (vidOut.ga, vidIn.ga, Amount);
   retval.r  = lerp (vidIn.r, vidOut.r, amt_R);
   retval.b  = lerp (vidOut.b, vidIn.b, amt_B);

   return retval;
}

DeclarePass (Out_B_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Inc_B_R)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_B_R)
{
   float4 vidOut = tex2D (Out_B_R, uv3);
   float4 vidIn  = tex2D (Inc_B_R, uv3);
   float4 retval;

   float amt_R = pow (Amount, CURVE);
   float amt_B = pow (1.0 - Amount, CURVE);

   retval.ga = lerp (vidOut.ga, vidIn.ga, Amount);
   retval.r  = lerp (vidOut.r, vidIn.r, amt_R);
   retval.b  = lerp (vidIn.b, vidOut.b, amt_B);

   return retval;
}

DeclarePass (Out_R_G)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Inc_R_G)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_R_G)
{
   float4 vidOut = tex2D (Out_R_G, uv3);
   float4 vidIn  = tex2D (Inc_R_G, uv3);
   float4 retval;

   float amt_R = pow (1.0 - Amount, CURVE);
   float amt_G = pow (Amount, CURVE);

   retval.ba = lerp (vidOut.ba, vidIn.ba, Amount);
   retval.r  = lerp (vidIn.r, vidOut.r, amt_R);
   retval.g  = lerp (vidOut.g, vidIn.g, amt_G);

   return retval;
}

DeclarePass (Out_G_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Inc_G_R)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_G_R)
{
   float4 vidOut = tex2D (Out_G_R, uv3);
   float4 vidIn  = tex2D (Inc_G_R, uv3);
   float4 retval;

   float amt_R = pow (Amount, CURVE);
   float amt_G = pow (1.0 - Amount, CURVE);

   retval.ba = lerp (vidOut.ba, vidIn.ba, Amount);
   retval.r  = lerp (vidOut.r, vidIn.r, amt_R);
   retval.g  = lerp (vidIn.g, vidOut.g, amt_G);

   return retval;
}

DeclarePass (Out_G_B)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Inc_G_B)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_G_B)
{
   float4 vidOut = tex2D (Out_G_B, uv3);
   float4 vidIn  = tex2D (Inc_G_B, uv3);
   float4 retval;

   float amt_G = pow (1.0 - Amount, CURVE);
   float amt_B = pow (Amount, CURVE);

   retval.ra = lerp (vidOut.ra, vidIn.ra, Amount);
   retval.g  = lerp (vidIn.g, vidOut.g, amt_G);
   retval.b  = lerp (vidOut.b, vidIn.b, amt_B);

   return retval;
}

DeclarePass (Out_B_G)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Inc_B_G)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_B_G)
{
   float4 vidOut = tex2D (Out_B_G, uv3);
   float4 vidIn  = tex2D (Inc_B_G, uv3);
   float4 retval;

   float amt_G = pow (Amount, CURVE);
   float amt_B = pow (1.0 - Amount, CURVE);

   retval.ra = lerp (vidOut.ra, vidIn.ra, Amount);
   retval.g  = lerp (vidOut.g, vidIn.g, amt_G);
   retval.b  = lerp (vidIn.b, vidOut.b, amt_B);

   return retval;
}

