// @Maintainer jwrl
// @Released 2023-01-31
// @Author Robert Schütze
// @Author jwrl
// @Created 2022-06-01

/**
 This effect uses a fractal-like pattern to transition between two sources.  It operates
 in the same way as a normal dissolve or wipe transition.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
 Unlike with LW transitions there is no mask.  Instead the ability to crop the effect
 to the background is provided, which dissolves between the cropped areas during the
 transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fractal_Dx.fx
//
// The fractal component is a conversion of GLSL sandbox effect #308888 created by Robert
// Schütze (trirop) 07.12.2015.
//
// Version history:
//
// Built 2023-01-31 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Fractal dissolve", "Mix", "Abstract transitions", "Uses a fractal-like pattern to transition between two sources", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (fractalOffset, "Offset", "Fractal settings", kNoGroup, 0.5, 0.0, 1.0);
DeclareFloatParam (Rate, "Rate", "Fractal settings", kNoGroup, 0.5, 0.0, 1.0);
DeclareFloatParam (Border, "Edge size", "Fractal settings", kNoGroup, 0.1, 0.0, 1.0);
DeclareFloatParam (Feather, "Feather", "Fractal settings", kNoGroup, 0.1, 0.0, 1.0);

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Outgoing)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Incoming)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Fractal)
{
   float3 offset  = float3 (1.0.xx, Amount * Rate * 0.5);
   float3 fractal = float3 (uv0.x / _OutputAspectRatio, uv0.y, fractalOffset);

   for (int i = 0; i < 75; i++) {
      fractal.xzy = float3 (1.3, 0.999, 0.7) * (abs ((abs (fractal) / dot (fractal, fractal) - offset)));
   }

   return float4 (saturate (fractal), 1.0);
}

DeclareEntryPoint (Fractal_Dx)
{
   float amt_in   = min (1.0, Amount * 5.0);
   float amt_body = (Amount * 0.5) + 0.5;
   float amt_out  = max (0.0, (Amount * 5.0) - 4.0);

   float4 retval = tex2D (Fractal, uv3);
   float4 Fgnd   = tex2D (Outgoing, uv3);
   float4 Bgnd   = tex2D (Incoming, uv3);

   float fractal = max (retval.g, max (retval.r, retval.b));
   float bdWidth = Border * 0.1;
   float FthrRng = amt_body + Feather;
   float fracAmt = (fractal - amt_body) / Feather;

   if (fractal <= FthrRng) {
      if (fractal > (amt_body - bdWidth)) { retval = lerp (Bgnd, retval, fracAmt); }
      else retval = Bgnd;

      if (fractal > (amt_body + bdWidth)) { retval = lerp (retval, Fgnd, fracAmt); }
   }
   else retval = Fgnd;

   retval = lerp (lerp (Fgnd, retval, amt_in), Bgnd, amt_out);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;

      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

