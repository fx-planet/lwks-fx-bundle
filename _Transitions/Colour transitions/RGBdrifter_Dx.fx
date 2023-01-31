// @Maintainer jwrl
// @Released 2023-01-31
// @Author jwrl
// @Created 2023-01-31

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
// Built 2023-01-31 jwrl.
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

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

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

// technique RGBdrifter_R_B

DeclarePass (Out_R_B)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Inc_R_B)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_R_B)
{
   float4 Fgnd = tex2D (Out_R_B, uv3);
   float4 Bgnd  = tex2D (Inc_R_B, uv3);
   float4 retval;

   float amt_R = pow (1.0 - Amount, CURVE);
   float amt_B = pow (Amount, CURVE);

   retval.ga = lerp (Fgnd.ga, Bgnd.ga, Amount);
   retval.r  = lerp (Bgnd.r, Fgnd.r, amt_R);
   retval.b  = lerp (Fgnd.b, Bgnd.b, amt_B);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;
      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique RGBdrifter_B_R

DeclarePass (Out_B_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Inc_B_R)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_B_R)
{
   float4 Fgnd = tex2D (Out_B_R, uv3);
   float4 Bgnd  = tex2D (Inc_B_R, uv3);
   float4 retval;

   float amt_R = pow (Amount, CURVE);
   float amt_B = pow (1.0 - Amount, CURVE);

   retval.ga = lerp (Fgnd.ga, Bgnd.ga, Amount);
   retval.r  = lerp (Fgnd.r, Bgnd.r, amt_R);
   retval.b  = lerp (Bgnd.b, Fgnd.b, amt_B);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;
      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique RGBdrifter_R_G

DeclarePass (Out_R_G)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Inc_R_G)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_R_G)
{
   float4 Fgnd = tex2D (Out_R_G, uv3);
   float4 Bgnd  = tex2D (Inc_R_G, uv3);
   float4 retval;

   float amt_R = pow (1.0 - Amount, CURVE);
   float amt_G = pow (Amount, CURVE);

   retval.ba = lerp (Fgnd.ba, Bgnd.ba, Amount);
   retval.r  = lerp (Bgnd.r, Fgnd.r, amt_R);
   retval.g  = lerp (Fgnd.g, Bgnd.g, amt_G);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;
      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique RGBdrifter_G_R

DeclarePass (Out_G_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Inc_G_R)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_G_R)
{
   float4 Fgnd = tex2D (Out_G_R, uv3);
   float4 Bgnd  = tex2D (Inc_G_R, uv3);
   float4 retval;

   float amt_R = pow (Amount, CURVE);
   float amt_G = pow (1.0 - Amount, CURVE);

   retval.ba = lerp (Fgnd.ba, Bgnd.ba, Amount);
   retval.r  = lerp (Fgnd.r, Bgnd.r, amt_R);
   retval.g  = lerp (Bgnd.g, Fgnd.g, amt_G);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;
      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique RGBdrifter_G_B

DeclarePass (Out_G_B)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Inc_G_B)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_G_B)
{
   float4 Fgnd = tex2D (Out_G_B, uv3);
   float4 Bgnd  = tex2D (Inc_G_B, uv3);
   float4 retval;

   float amt_G = pow (1.0 - Amount, CURVE);
   float amt_B = pow (Amount, CURVE);

   retval.ra = lerp (Fgnd.ra, Bgnd.ra, Amount);
   retval.g  = lerp (Bgnd.g, Fgnd.g, amt_G);
   retval.b  = lerp (Fgnd.b, Bgnd.b, amt_B);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;
      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique RGBdrifter_B_G

DeclarePass (Out_B_G)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Inc_B_G)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_B_G)
{
   float4 Fgnd = tex2D (Out_B_G, uv3);
   float4 Bgnd  = tex2D (Inc_B_G, uv3);
   float4 retval;

   float amt_G = pow (Amount, CURVE);
   float amt_B = pow (1.0 - Amount, CURVE);

   retval.ra = lerp (Fgnd.ra, Bgnd.ra, Amount);
   retval.g  = lerp (Fgnd.g, Bgnd.g, amt_G);
   retval.b  = lerp (Bgnd.b, Fgnd.b, amt_B);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;
      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

