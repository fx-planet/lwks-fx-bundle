// @Maintainer jwrl
// @Released 2023-05-15
// @Author jwrl
// @Created 2025-04-11

/**
 Simple star is a glint effect which creates star filter-like highlights, with 4, 5,
 6, 7 or 8 arms selectable.  The star it creates can be scaled, spun and positioned.
 It can also be coloured with a basic flat colour or can be mixed with a prismatic
 spectrum for more dramatic effect.

 The four, six and eight pointed stars are possible with optical star filters and match
 the look produced by those filters reasonably closely.  The five and seven pointed
 stars are absolutely impossible to produce with any real world filter, and have just
 been included for fun.

 This effect will break resolution independence.  It was a choice between doing that and
 breaking on-screen position tracking and star geometry.  I think that from the user's
 point of view it's much more important to preserve geometry and tracking.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SimpleStar.fx
//
// Original author's notes:
// This effect was inspired by khaver's GlintFx.fx.  It uses quite a different method to
// that though, since it generates the star from scratch and not from highlights in the
// background video.
//
// It first develops a simple symmetrical horizontal line containing a colour spectrum.
// The centre of the line has a white circular overlay which becomes the centre hotspot
// of the star.  That line is bisected to generate stars with odd numbers of arms.  No
// trig functions are needed to generate the stars from either the full or half line.
//
// Once the selected star is created it is opened in ps_main(), positioned, rotated and
// coloured and mixed as required.  Smaller star points around the centre hotspot are
// added, and an anular halo is finally overlaid.
//
// This looks considerably more complex than it in fact is.  Although between three and
// four passes are used the simplicity of each one should keep the overall GPU load low.
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Simple star", "Stylize", "Simple tools", "Creates a single rotatable star glint, with 4, 5, 6, 7 or 8 arms", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Rainbow, "Rainbow mix", "Star colour", "DisplayAsPercentage", 0.5, 0.0, 2.0);

DeclareColourParam (Colour, "Base colour", "Star colour", kNoFlags, 0.7, 0.9, 1.0, 1.0);

DeclareIntParam (SetTechnique, "Number of points", "Star points", 0, "4|5|6|7|8");

DeclareFloatParam (Strength, "Strength", "Star points", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Size, "Size", "Star points", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Rotation, "Rotation", "Star points", kNoFlags, 0.0, -180.0, 180.0);

DeclareFloatParam (CentreX, "Star position", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Star position", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define CENTRE      0.5.xx

#define RADIUS      0.03125
#define LENGTH      0.125
#define WIDTH       0.003

#define RING_RAD    0.0175
#define RING_AMT    6.0
#define RING_LVL    0.375

#define SINE_22_5   0.3826834324
#define COSINE_22_5 0.9238795325

#define SINE_45     0.7071067812

#define SINE_51     0.7818314825
#define COSINE_51   0.6234898019

#define SINE_60     0.8660254038
#define COSINE_60   0.5

#define SINE_72     0.9510565163
#define COSINE_72   0.3090169944

#define SINE_103    0.97492791218
#define COSINE_103 -0.22252093396

#define SINE_144    0.5877852523
#define COSINE_144 -0.8090169944

#define SINE_154    0.4338837391
#define COSINE_154 -0.9009688679

#define QUAD_PI     12.566370614
#define ONE_THIRD   0.3333333333
#define SCALE_45    1.2374368671   // 1.75 * sine 45

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 firstLine (float2 uv)
{
   // This function produces a horizontal line with a centre bulge.  It's the basic
   // building block we use to build the stars.  A rainbow pattern is returned in
   // the RGB channels while the alpha channel holds a luminance only version.

   float2 xy = abs (uv - CENTRE);

   float l_size = Size * LENGTH;
   float width  = WIDTH * _OutputAspectRatio;
   float h_line = max (0.0, 1.0 - xy.x / l_size);

   // Now h_line ramps 1 > 0 > 1 and is used to create a colour spectrum

   float4 retval = float4 (sin (h_line * QUAD_PI).xxx, 1.0);

   retval.r = sin ((h_line + ONE_THIRD) * QUAD_PI);
   retval.b = sin ((h_line - ONE_THIRD) * QUAD_PI);

   // Mask the edges of h_line to create a horizontal line

   h_line *= max (0.0, 1.0 - xy.y / width);

   // The colour spectrum is now offset and scaled by half the value of h_line
   // This means that instead of swinging plus or minus 1 they are now legal.
   // The alpha channel which now also contains h_line will be used in ps_main()
   // along with the parameter Colour to produce a coloured star.

   retval = h_line * (retval + 1.0.xxxx) * 0.5;

   // The next step is to create a white hot centre in the middle of the line
   // To begin with it's stretched along the line to make a 2:1 oval shape.

   xy /= float2 (2.0, _OutputAspectRatio);
   l_size = Size * RADIUS;

   float d = length (xy) / l_size;

   // Add the oval to the centre of the line at 50%

   retval += max (0.0, 0.5 - d).xxxx;

   // Now reset the X value in xy to create a circle using the same parameters

   xy.x *= 2.0;
   d = length (xy) / l_size;

   // Return a mix of the line, oval and circle clamped between 0 and 1.

   return saturate (retval + max (0.0, 0.5 - d).xxxx);
}

float4 halveLine (sampler baseLine, float2 uv)
{
   // This shader takes the horizontal line created in ps_line() and rotates
   // it through 90 degrees.  It then bisects it, discarding the lower half.
   // This is used as the basic building block of the five pointed star.

   // Rotate uv by 90 degrees and put it in xy

   float2 xy = ((uv - CENTRE) * float2 (_OutputAspectRatio, 1.0 / _OutputAspectRatio)).yx;

   // If xy.x is beyond the centre of frame it's offset by 10.  This is
   // a quick and dirty way of blanking one half of the line - see below.

   if (xy.x > 0.0) xy.x += 10.0;

   xy += CENTRE;

   // Using ReadPixel() returns the shader contents only if xy is legal

   return ReadPixel (baseLine, xy);
}

float4 star_4 (sampler baseLine, float2 uv)
{
   // This takes the horizontal line created in ps_line() and rotates it through
   // 90 degrees.  It then adds it to the original to create a four pointed star.

   // Rotate uv by 90 degrees and put it in xy

   float2 xy = (((uv - CENTRE) * float2 (_OutputAspectRatio, 1.0 / _OutputAspectRatio)) + CENTRE).yx;

   // Recover the original horizontal line and a copy rotated through 90 degrees

   float4 retval = ReadPixel (baseLine, uv);
   float4 overlay = ReadPixel (baseLine, xy);

   // Return the overlaid pair of lines to give a four armed star

   return max (retval, overlay);
}

float4 main (sampler finalStar, float2 xy, float2 uv)
{
   // Calculate the coordinates for the rotated and/or repositioned star

   float cosine, sine;

   sincos (radians (Rotation), sine, cosine);

   float2 aspect = float2 (_OutputAspectRatio, -1.0 / _OutputAspectRatio);
   float2 psn = float2 (CentreX, 1.0 - CentreY);
   float2 xy0 = xy - psn;
   float2 xy1 = xy0 * sine * aspect;

   xy0 = (xy0 * cosine) - xy1.yx;

   // Now set up the coordinates to rotate and scale the star so that we have small
   // stars at the centre.  Angles of 45 and plus and minus 22.5 degrees are used.

   xy1 = xy0 * 2.0;         // Scale xy1 for the mini stars

   float2 xy2 = xy1 * SINE_22_5;
   float2 xy3 = xy1 * COSINE_22_5 * aspect;

   xy2 += CENTRE;          // Reset xy2 to the global coordinates

   xy1 = xy2 + xy3.yx;     // Mini star #1
   xy2 = xy2 - xy3.yx;     // Mini star #2
   xy3 = xy0 * SCALE_45;   // This incorporates both the scale and cos/sin 45 degrees
   xy0 += CENTRE;          // Reset xy0 to the global coordinates to get the main star

   // We add the aspect ratio corrected and rotated xy3 to give the 45 degree version

   xy3 += float2 ((xy3 * aspect) + CENTRE).yx;

   // Recover the input video and the star, using our blanking function for the star

   float4 Star = ReadPixel (finalStar, xy0);
   float4 Bgnd = ReadPixel (Inp, uv);

   // Now get the first mini star from the star alpha using ReadPixel()

   float xtra = ReadPixel (finalStar, xy1).a;

   // Get the other two and combine them with the main star as a luminance value

   xtra = max (xtra, ReadPixel (finalStar, xy2).a);
   xtra = max (xtra, ReadPixel (finalStar, xy3).a);
   xtra = max ((xtra * 4.0) - 2.0, 0.0) * 0.4;
   Star = max (Star, xtra.xxxx);

   // Mix the user selected colour with the rainbow pattern

   Star = lerp (Colour * Star.a, Star, Rainbow);

   // The next step is to create the halo/ring.  Put the current position into
   // xy0 and centre it around Star position with aspect ratio correction

   xy0 = (xy - psn) * float2 (1.0, 1.0 / _OutputAspectRatio);

   // Scale the Size parameter to the ring radius and calculate the radius

   float ring = length (xy0) / (Size * RING_RAD);

   // The ring is now overlaid as a desaturated yellow over the star.  This
   // is as close as possible to the colour of the star arms at this point

   ring = saturate (1.0 - (abs (1.0 - ring) * RING_AMT));
   Star = max (Star, float2 (ring, ring * 0.7).xyxx * RING_LVL);

   // Combine the star with the video using a screen blend

   Star = saturate (Star + Bgnd - (Star * Bgnd));

   return lerp (Bgnd, Star, Strength);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// 4 point star

DeclarePass (Line_4pt)
{ return firstLine (uv0); }

DeclarePass (Star_4pt)
{ return star_4 (Line_4pt, uv2); }

DeclareEntryPoint (SimpleStar_4point)
{ return main (Star_4pt, uv2, uv1); }

// 5 point star

DeclarePass (Line_5pt)
{ return firstLine (uv0); }

DeclarePass (HalfLine_5pt)
{ return halveLine (Line_5pt, uv2); }

DeclarePass (Star_5pt)
{
   // This takes the vertical half line created in ps_halve_line() and rotates it
   // through plus and minus 72 degrees, then plus and minus 144 degrees.  These
   // including the original are the elements used to create the five pointed star.

   // Set up rotation vectors scaling through 72 and 144 degrees

   float2 xy1 = uv2 - CENTRE;
   float2 xy  = xy1 * float2 (_OutputAspectRatio, -1.0 / _OutputAspectRatio);
   float2 xy2 = xy * SINE_72;
   float2 xy3 = (xy1 * COSINE_144) + CENTRE;
   float2 xy4 = xy * SINE_144;

   xy1 = (xy1 * COSINE_72) + CENTRE;
   xy  = xy1 + xy2.yx;
   xy1 = xy1 - xy2.yx;

   // Recover the vertical half line and two copies rotated through plus and minus 72 degrees

   float4 retval = tex2D (HalfLine_5pt, uv2);
   float4 ovrly1 = ReadPixel (HalfLine_5pt, xy);
   float4 ovrly2 = ReadPixel (HalfLine_5pt, xy1);

   // Combine them to create three points of a five armed star.

   retval = max (max (retval, ovrly1), ovrly2);

   // Recover two more copies of the half line rotated through plus and minus 144 degrees

   xy  = xy3 + xy4.yx;
   xy1 = xy3 - xy4.yx;

   ovrly1 = ReadPixel (HalfLine_5pt, xy);
   ovrly2 = ReadPixel (HalfLine_5pt, xy1);

   // Combine the two to create the final five armed star.

   return max (max (retval, ovrly1), ovrly2);
}

DeclareEntryPoint (SimpleStar_5point)
{ return main (Star_5pt, uv0, uv1); }

// 6 point star

DeclarePass (Line_6pt)
{ return firstLine (uv2); }

DeclarePass (Star_6pt)
{
   // This takes the horizontal line created in ps_line() and rotates it through
   // plus and minus 60 degrees.  It then uses them to create a six pointed star.
   // Since the only difference between this and the 5 point star is that the full
   // length line is used, it isn't commented.

   float2 xy1 = uv2 - CENTRE;
   float2 xy2 = (xy1 * float2 (_OutputAspectRatio, -1.0 / _OutputAspectRatio)) * SINE_60;

   xy1 = (xy1 * COSINE_60) + CENTRE;

   float2 xy = xy1 + xy2.yx;

   xy1 -= xy2.yx;

   float4 retval = tex2D (Line_6pt, uv2);
   float4 ovrly1 = ReadPixel (Line_6pt, xy);
   float4 ovrly2 = ReadPixel (Line_6pt, xy1);

   return max (max (retval, ovrly1), ovrly2);
}

DeclareEntryPoint (SimpleStar_6Point)
{ return main (Star_6pt, uv2, uv1); }

// 7 point star

DeclarePass (Line_7pt)
{ return firstLine (uv0); }

DeclarePass (HalfLine_7pt)
{ return halveLine (Line_7pt, uv2); }

DeclarePass (Star_7pt)
{
   // This takes the vertical half line created in ps_halve_line() and rotates it
   // through plus and minus 51 and 103 degrees, then plus and minus 154 degrees.
   // These, including the original half line, are the elements used to create the
   // seven pointed star.

   float2 xy1 = uv2 - CENTRE;
   float2 xy  = xy1 * float2 (_OutputAspectRatio, -1.0 / _OutputAspectRatio);
   float2 xy2 = xy * SINE_51;
   float2 xy3 = (xy1 * COSINE_103) + CENTRE;
   float2 xy4 = xy * SINE_103;
   float2 xy5 = (xy1 * COSINE_154) + CENTRE;
   float2 xy6 = xy * SINE_154;

   xy1 = (xy1 * COSINE_51) + CENTRE;
   xy  = xy1 + xy2.yx;
   xy1 = xy1 - xy2.yx;

   float4 retval = tex2D (HalfLine_7pt, uv2);
   float4 ovrly1 = ReadPixel (HalfLine_7pt, xy);
   float4 ovrly2 = ReadPixel (HalfLine_7pt, xy1);

   retval = max (max (retval, ovrly1), ovrly2);

   xy  = xy3 + xy4.yx;
   xy1 = xy3 - xy4.yx;

   ovrly1 = ReadPixel (HalfLine_7pt, xy);
   ovrly2 = ReadPixel (HalfLine_7pt, xy1);
   retval = max (max (retval, ovrly1), ovrly2);

   xy  = xy5 + xy6.yx;
   xy1 = xy5 - xy6.yx;

   ovrly1 = ReadPixel (HalfLine_7pt, xy);
   ovrly2 = ReadPixel (HalfLine_7pt, xy1);

   return max (max (retval, ovrly1), ovrly2);
}

DeclareEntryPoint (SimpleStar_7point)
{ return main (Star_7pt, uv2, uv1); }

// 8 point star

DeclarePass (Line_8pt)
{ return firstLine (uv0); }

DeclarePass (HalfStar_8pt)
{ return star_4 (Line_8pt, uv2); }

DeclarePass (Star_8pt)
{
   // This takes the four point star created in ps_star_4() and rotates it through
   // 45 degrees.  It then adds it to the original to create an eight pointed star.

   // Rotate uv2 through 45 degrees and put it in xy

   float2 xy  = (uv2 - CENTRE) * SINE_45;
   float2 xy1 = xy * float2 (_OutputAspectRatio, -1.0 / _OutputAspectRatio);

   xy += xy1.yx + CENTRE;

   // Recover the four point star and a copy rotated through 45 degrees

   float4 retval = tex2D (HalfStar_8pt, uv2);
   float4 overlay = ReadPixel (HalfStar_8pt, xy);

   // Return the eight pointed star

   return max (retval, overlay);
}

DeclareEntryPoint (SimpleStar_8point)
{ return main (Star_8pt, uv2, uv1); }

