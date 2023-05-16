// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2021-11-15

/**
 This is an effect that is used to highlight sections of the input video, using circles,
 squares or arrows.  This is a complete rewrite of an original effect first published
 November 5 2021.  The main purpose of the rewrite was to improve the arrow geometry,
 but there have also been slight improvements made to the circle and square generation.

 This effect will break resolution independence.  It was a choice between doing that and
 breaking on-screen position tracking.  I think that from a user's point of view it's
 much more important to preserve the latter than the former.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect HighlightWidgets.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Highlight widgets", "Key", "Simple tools", "Used to highlight sections of video that you want to emphasize", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Choose widget", kNoGroup, 0, "Circle|Square|Arrow");

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Size, "Size", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Aspect, "Ratio (not for circles)", kNoGroup, kNoFlags, 1.0, 0.1, 10.0);
DeclareFloatParam (LineWeight, "Line weight", kNoGroup, kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (Border, "Border", kNoGroup, kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (Rotation, "Rotate arrow", kNoGroup, kNoFlags, 0.0, -180.0, 180.0);

DeclareFloatParam (CentreX, "Position", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Position", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareColourParam (Colour, "Colour", kNoGroup, kNoFlags, 1.0, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define LessThan(XY,REF) (all (XY <= REF))

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// This function is used to create the arrow shape.  Returns 1 when the shape is turned
// on, and 0 when it's not.  To provide a degree of antialias, where the selected pixel
// is within edge limits a value between 0 and 1 is returned to soften the edges.

float fn_arrow (float2 xy0, float2 xy1, float2 xy2, float s, float h1, float h2)
{
   float alias  = lerp (16.0, 2.0, sqrt (Size));               // Antialiasing scale by size
   float aliasX = alias / _OutputWidth;                        // Horizontal pixel range
   float aliasY = alias / _OutputHeight;                       // Vertical range
   float level1 = 0.0;
   float level2 = 0.0;

   // This first section maps the arrow shaft.  If the coordinates are completely within the
   // shaft a value of 1.0 is returned in level1.

   if (LessThan (xy0, xy1) && (xy0.x >= s)) {
      level1  = smoothstep (s, s + aliasX, xy0.x);             // Calculate X and Y antialias
      level1 *= smoothstep (xy1.y, xy1.y - aliasY, xy0.y);     // antialias amounts
   }

   // Now the arrow head is mapped.  The boundary is angled so this is somewhat more complex.

   if (LessThan (xy0, xy2) && (xy0.x >= h1)) {
      float slope = lerp (0.0, xy2.y, (h2 - xy0.x) / (h2 - h1));  // First we get the slope

      // The slope is dynamic - the value used depends on the horizontal position.  Antialias
      // is based on a quick and dirty check against whichever alias value is greater.

      if (xy0.y <= slope) level2 = smoothstep (slope, slope - max (aliasX, aliasY), xy0.y);

      level2 *= smoothstep (h1, h1 + aliasX, xy0.x);           // The base of the arrow head
   }

   return max (level1, level2);                                // Return the arrow mask
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (HighlightWidgets_Circle)
{
   float4 Bgnd = ReadPixel (Inp, uv1);                         // Background video
   float4 Fgnd = Bgnd;                                         // Composite overlay for mix

   // This next section is a simple way of creating a circle by using a radius around a
   // centre point.  Aspect ratio correction is applied to uv1 to ensure symmetry.

   float2 xy = _OutputHeight > _OutputWidth
             ? float2 ((uv1.x - CentreX) * _OutputAspectRatio, uv1.y + CentreY - 1.0)
             : float2 (uv1.x - CentreX, (uv1.y + CentreY - 1.0) / _OutputAspectRatio);

   float radius = distance (xy, 0.0.xx);                       // Distance of uv1 from centre
   float line_1 = 0.01 + (Size * 0.49);                        // Inner circle size
   float line_2 = line_1 + (LineWeight * 0.1);                 // Outer circle size
   float brdr_1 = Border * 0.03;                               // Border thickness
   float brdr_2 = line_2 + brdr_1;                             // Outer border size

   brdr_1 = max (0.0, line_1 - brdr_1);                        // Inner border size

   // The next few lines get the antialiased border, returning one when the border is fully
   // opaque and zero when it is fully transparent.  If the sample pixel falls inside that
   // range a value between zero and one is returned, thus smoothing the border edges.

   float alias = 2.0 / min (_OutputWidth, _OutputHeight);      // Antialias (cheated) offset
   float level = smoothstep (brdr_1 - alias, brdr_1, radius);  // Calculate the inner border

   level *= smoothstep (brdr_2 + alias, brdr_2, radius);       // Multiply by outer border

   Fgnd = lerp (Fgnd, BLACK, level);                           // Border added to composite

   level  = smoothstep (line_1 - alias, line_1, radius);       // Get antialased inner edge
   level *= smoothstep (line_2 + alias, line_2, radius);       // Combine it with outer edge

   Fgnd = lerp (Fgnd, Colour, level);                          // Overlay the circle

   return lerp (Bgnd, Fgnd, Amount);                           // Mix over the background
}

DeclareEntryPoint (HighlightWidgets_Square)
{
   float4 Bgnd = ReadPixel (Inp, uv1);                         // Background video
   float4 Fgnd = Bgnd;                                         // Overlay composite

   // This next section is on the face of it, confusing.  It relies on the fact that a square
   // has both vertical and horizontal symmetry.  This simplifies things enormously.  Unlike
   // the circle and arrow, no antialiasing is necessary with square sides.

   float2 asp = _OutputHeight > _OutputWidth
              ? float2 (1.0, _OutputAspectRatio)               // Aspect correction portrait
              : float2 (1.0 / _OutputAspectRatio, 1.0);        // Aspect correction landscape
   float2 xy1 = abs (uv1 - float2 (CentreX, 1.0 - CentreY));   // Centre the coordinates
   float2 xy2 = (0.01 + (Size * 0.74)) * asp;                  // Set up the square size

   if (Aspect > 1.0) xy2.x *= Aspect;                          // Scale horizontal / vertical
   else xy2.y /= Aspect;                                       // size to create rectangle

   float2 xy3 = xy2 + (asp * LineWeight * 0.1875);             // Add line weight to shape
   float2 xy4 = asp * Border * 0.075;                          // Aspect ratio correct border
   float2 xy5 = xy3 + xy4;                                     // Add it to the outer edge

   xy4 = xy2 - xy4;                                            // - and the inner edge

   // The next few lines are extremely simple.  Check if inside the border boundaries and if
   // so check if we need the border black or the shape fill colour.

   if (LessThan (xy1, xy5) && !LessThan (xy1, xy4))
      Fgnd = LessThan (xy1, xy3) && !LessThan (xy1, xy2) ? Colour : BLACK;

   return lerp (Bgnd, Fgnd, Amount);                           // Mix over background, quit
}

DeclareEntryPoint (HighlightWidgets_Arrow)
{
   float4 Bgnd = ReadPixel (Inp, uv1);                         // Background video
   float4 Fgnd = Bgnd;                                         // Overlay composite

   float brdr  = Border * 0.1125;                              // Border scaled
   float scale = lerp (0.04, 0.2, sqrt (Aspect - 0.1) / 3.15); // Default = 0.14
   float range = lerp (0.375, 0.695, LineWeight - 0.1);        // max = 0.625, min = 0.375
   float Lmin  = 0.1;                                          // Left edge of arrow shaft
   float Lmax  = 0.475;                                        // Left edge of arrow head
   float Bmin  = Lmin - brdr;                                  // Left edge of shaft border
   float Hmin  = Lmax - brdr;                                  // Left edge of head border
   float Htip  = 0.7;                                          // Right tip of arrow head
   float fixer = 16.0 / _OutputWidth;                          // Fix to join head to shaft
   float b = scale / (Htip - Lmax);                            // Init border for head angle
   float c, s;

   c = cos (atan (b));                                         // Get arrow head scale factor

   c = brdr / c;                                               // Preliminary border scale
   s = c + sqrt ((c * c) - (brdr * brdr));                     // Border head Y extension
   c /= b;                                                     // Border head X extension

   float Hmax = Htip + c;                                      // X offset for arrow head

   float2 xy01 = float2 (Lmax + fixer, range * scale);         // Right edge of arrow shaft
   float2 xy02 = float2 (Htip, scale);                         // Arrow head tip coordinate
   float2 xy11 = float2 (Lmax, xy01.y + brdr);                 // Right edge of shaft border
   float2 xy12 = float2 (Hmax, scale + s);                     // Arrow head border tip
   float2 xy   = _OutputHeight > _OutputWidth                  // Square and set position uv1
               ? float2 ((uv1.x - CentreX) * _OutputAspectRatio, uv1.y + CentreY - 1.0)
               : float2 (uv1.x - CentreX, (uv1.y + CentreY - 1.0) / _OutputAspectRatio);

   sincos (radians (Rotation), s, c);                          // Arrow rotation vectors

   xy = mul (float2x2 (c, s, -s, c), xy);                      // Rotate the coordinates
   xy /= ((Size * 1.0667) + 0.0667);                           // Scale them
   xy.x += 0.5;                                                // Centre the X coordinates
   xy.y = abs (xy.y);                                          // Mirror the Y coordinates

   // Overlay the border.  The antialias makes this complex and it's also needed for the
   // colourded arrow body so it's handled in a function.

   Fgnd = lerp (Fgnd, BLACK,
                fn_arrow (xy, xy11, xy12, Bmin, Hmin, Hmax));  // Antialiased arrow border

   // Repeat the function call for the coloured body of the arrow.

   Fgnd = lerp (Fgnd, Colour,
                fn_arrow (xy, xy01, xy02, Lmin, Lmax, Htip));  // Antialiased arrow body

   return lerp (Bgnd, Fgnd, Amount);                           // Mix over background, quit
}

