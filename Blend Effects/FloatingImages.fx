// @Maintainer jwrl
// @Released 2023-01-23
// @Author jwrl
// @Created 2023-01-23

/**
 "Floating images" generates up to four floating images from a single foreground
 image.  The foreground may have an alpha channel, a bad alpha channel or no alpha
 channel at all, the effect will still work.  The position, size and density of the
 floating images are fully adjustable.

 Unlike other scalable effects, the size adjustment follows a square law.  The reason
 for this is simple: a square law scale gives a linear increase in size, removing the
 "slow down" effect as the image enlarges.  Range settings are from zero to the square
 root of ten (a little over three) so that the linear scaling range is zero to ten.

 Masking is applied to the foreground before the duplication process.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FloatingImages.fx
//
// Version history:
//
// Built 2023-01-23 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Floating images", "Mix", "Blend Effects", "Generates up to four overlayed images from a foreground graphic", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Source, "Source selection", "Disconnect title and image key inputs", 1, "Crawl/Roll/Title/Image key|Video/External image|Extracted foreground");

DeclareFloatParam (A_Opac, "Opacity", "Overlay 1 (always enabled)", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (A_Zoom, "Scale", "Overlay 1 (always enabled)", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (A_Xc, "Position", "Overlay 1 (always enabled)", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (A_Yc, "Position", "Overlay 1 (always enabled)", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareBoolParam (B_On, "Enabled", "Overlay 2", false);
DeclareFloatParam (B_Opac, "Opacity", "Overlay 2", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (B_Zoom, "Scale", "Overlay 2", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (B_Xc, "Position", "Overlay 2", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (B_Yc, "Position", "Overlay 2", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareBoolParam (C_On, "Enabled", "Overlay 3", false);
DeclareFloatParam (C_Opac, "Opacity", "Overlay 3", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (C_Zoom, "Scale", "Overlay 3", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (C_Xc, "Position", "Overlay 3", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (C_Yc, "Position", "Overlay 3", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareBoolParam (D_On, "Enabled", "Overlay 4", false);
DeclareFloatParam (D_Opac, "Opacity", "Overlay 4", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (D_Zoom, "Scale", "Overlay 4", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (D_Xc, "Position", "Overlay 4", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (D_Yc, "Position", "Overlay 4", "SpecifiesPointY", 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (FgKey)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Fgd = tex2D (Fg, uv1);

   if (Source == 0) {
      Fgd.a    = pow (Fgd.a, 0.5);
      Fgd.rgb /= Fgd.a;
   }
   else if (Source == 2) {
      float4 Bgd = ReadPixel (Bg, uv2);

      float kDiff = distance (Fgd.g, Bgd.g);

      kDiff = max (kDiff, distance (Fgd.r, Bgd.r));
      kDiff = max (kDiff, distance (Fgd.b, Bgd.b));

      Fgd.a = smoothstep (0.0, 0.25, kDiff);
      Fgd.rgb *= Fgd.a;
   }

   return Fgd;
}

DeclareEntryPoint (FloatingImages)
{
   float4 Fgnd, Bgnd = ReadPixel (Bg, uv2);
   float4 ret = Bgnd;

   float2 xy;

   if (D_On) {
      xy = ((uv3 - float2 (D_Xc, 1.0 - D_Yc)) / (D_Zoom *  D_Zoom)) + 0.5.xx;
      Fgnd = tex2D (FgKey, xy);
      Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * D_Opac);
   }

   if (C_On) {
      xy = ((uv3 - float2 (C_Xc, 1.0 - C_Yc)) / (C_Zoom *  C_Zoom)) + 0.5.xx;
      Fgnd = tex2D (FgKey, xy);
      Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * C_Opac);
   }

   if (B_On) {
      xy = ((uv3 - float2 (B_Xc, 1.0 - B_Yc)) / (B_Zoom *  B_Zoom)) + 0.5.xx;
      Fgnd = tex2D (FgKey, xy);
      Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * B_Opac);
   }

   xy = ((uv3 - float2 (A_Xc, 1.0 - A_Yc)) / (A_Zoom *  A_Zoom)) + 0.5.xx;
   Fgnd = tex2D (FgKey, xy);

   Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * A_Opac);

   return lerp (ret, Bgnd, tex2D (Mask, uv1).x);
}

