// @Maintainer jwrl
// @Released 2023-06-24
// @Author Gary Hango (khaver)
// @Created 2012-12-04

/**
 Camera Shake uses luminance variations in a clip to add motion horizontally, vertically
 and/or rotationally.  That clip can be either the source track or another video layer,
 and that second video layer may contain motion content or be a still frame.

 The motion source track is set up using the "Show motion track" box.  This will display
 the motion track source in the viewer overlaid with red, green and blue lines and three
 associated coloured ovals.  Playing through the clip will cause each oval to move from
 one end of its line to the other, corresponding to the play head position.  Red shows
 the horizontal motion track, green the vertical, and blue, rotation.

 Best results are produced when the start and end points of each line cover a good range
 of dark and light areas as the clip plays.  This can be done with either the sliders or
 by dragging with the mouse.  Once they are set adjust the bias and strength for the
 required amount of horizontal, vertical and rotational movement.

 The zoom, rotation and pan sliders can be used for additional trimming.  Each motion
 track may be smoothed and/or have its direction of action reversed.

 NOTE 1:  Because this effect relies on being able to manually set start and end points
 of the shake and rotation tracks it has not been possible to make it truly resolution
 independent.  What it does is lock the clip resolution to sequence resolution instead.

 NOTE 2:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CameraShake.fx
//
// Version history:
//
// Updated 2023-06-24 jwrl.
// Corrected a grouping bug.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-12 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Camera shake", "Stylize", "Video artefacts", "Adds simulated camera motion horizontally, vertically and/or rotationally", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (src, bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (UseMTrack, "Motion Track", kNoGroup, 0, "Source video|Background video");

DeclareBoolParam (MoTrack, "Show motion track", kNoGroup, false);

DeclareFloatParam (Zoom, "Zoom", "Master", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (Rotate, "Rotate", "Master", kNoFlags, 0.0, -30.0, 30.0);

DeclareFloatParam (PanX, "Pan", "Master", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (PanY, "Pan", "Master", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareFloatParam (XBias, "Bias", "Horizontal", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (XStrength, "Strength", "Horizontal", kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (HRev, "Reverse", "Horizontal", false);
DeclareBoolParam (HSmooth, "Smooth", "Horizontal", false);

DeclareFloatParam (h1x, "H-Start", "Horizontal", "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (h1y, "H-Start", "Horizontal", "SpecifiesPointY", 0.9, 0.0, 1.0);
DeclareFloatParam (h2x, "H-End", "Horizontal", "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (h2y, "H-End", "Horizontal", "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (YBias, "Bias", "Vertical", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (YStrength, "Strength", "Vertical", kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (VRev, "Reverse", "Vertical", false);
DeclareBoolParam (VSmooth, "Smooth", "Vertical", false);

DeclareFloatParam (v1x, "V-Start", "Vertical", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (v1y, "V-Start", "Vertical", "SpecifiesPointY", 0.9, 0.0, 1.0);
DeclareFloatParam (v2x, "V-End", "Vertical", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (v2y, "V-End", "Vertical", "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (RBias, "Bias", "Rotation", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (RStrength, "Strength", "Rotation", kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (RRev, "Reverse", "Rotation", false);
DeclareBoolParam (RSmooth, "Smooth", "Rotation", false);

DeclareFloatParam (r1x, "R-Start", "Rotation", "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (r1y, "R-Start", "Rotation", "SpecifiesPointY", 0.9, 0.0, 1.0);
DeclareFloatParam (r2x, "R-End", "Rotation", "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (r2y, "R-End", "Rotation", "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (_Progress);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool isBetween (float2 a, float2 b, float2 c)
{
   float A = c.x - a.x;
   float B = c.y - a.y;
   float C = b.x - a.x;
   float D = b.y - a.y;
 
   float dt = A * C + B * D;
   float lensq = C * C + D * D;
   float param = dt / lensq;
   float xx, yy;
 
   if ((param < 0.0) || ((a.x == b.x) && (a.y == b.y))) {
      xx = a.x;
      yy = a.y;
   }
   else if (param > 1.0) {
      xx = b.x;
      yy = b.y;
   }
   else {
      xx = a.x + param * C;
      yy = a.y + param * D;
   }

   float dx = c.x - xx;
   float dy = c.y - yy;
   float dist = sqrt(dx * dx + dy * dy);

   return (dist < 0.0008);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (srcbg)
{
   float4 color = UseMTrack ? ReadPixel (bg, uv2) : ReadPixel (src, uv1);

   float value = (color.r + color.g + color.b) / 3.0;

   return float4 (value.xxx, color.a);
}

DeclarePass (motrack)
{
   //***********Horizontal motion line

   float2 hstart = float2 (h1x, 1.0 - h1y);
   float2 hend = float2 (h2x, 1.0 - h2y);
   float2 hpoint = float2 (lerp (h1x, h2x, _Progress), lerp (1.0 - h1y, 1.0 - h2y, _Progress)); //Move the sample point along the line

   //***********Vertical motion line

   float2 vstart = float2 (v1x, 1.0 - v1y);
   float2 vend = float2 (v2x, 1.0 - v2y);
   float2 vpoint = float2 (lerp (v1x, v2x, _Progress), lerp (1.0 - v1y, 1.0 - v2y, _Progress)); //Move the sample point along the line

   //***********Rotation motion line

   float2 rstart = float2 (r1x, 1.0 - r1y);
   float2 rend = float2 (r2x, 1.0 - r2y);
   float2 rpoint = float2 (lerp (r1x, r2x, _Progress), lerp (1.0 - r1y, 1.0 - r2y, _Progress)); //Move the sample point along the line

   float4 premo = tex2D (srcbg, uv3);

   float2 pix = float2 (1.0, _OutputAspectRatio) / _OutputWidth;

    //***********Average of 5 pixels

   if (HSmooth) { premo.r = (tex2D (srcbg, uv3 - pix).g
                           + tex2D (srcbg, uv3 + pix).g + tex2D (srcbg, uv3 - pix).g
                           + tex2D (srcbg, float2 (uv3.x + pix.x, uv3.y - pix.y)).g
                           + tex2D (srcbg, float2 (uv3.x - pix.x, uv3.y + pix.y)).g) / 5.0;
   }

   if (VSmooth) { premo.g = (tex2D (srcbg, uv3 - pix).g
                           + tex2D (srcbg, uv3 + pix).g + tex2D (srcbg, uv3 - pix).g
                           + tex2D (srcbg, float2 (uv3.x + pix.x, uv3.y - pix.y)).g
                           + tex2D (srcbg, float2 (uv3.x - pix.x, uv3.y + pix.y)).g) / 5.0;
   }

   if (RSmooth) { premo.b = (tex2D (srcbg, uv3 - pix).g
                           + tex2D (srcbg, uv3 + pix).g + tex2D (srcbg, uv3 - pix).g
                           + tex2D (srcbg, float2 (uv3.x + pix.x, uv3.y - pix.y)).g
                           + tex2D (srcbg, float2 (uv3.x - pix.x, uv3.y + pix.y)).g) / 5.0;
   }

   if (MoTrack) {
      if (isBetween (hstart, hend, uv3)) premo = float2 (1.0, 0.0).xyyx;
      if (isBetween (vstart, vend, uv3)) premo = float2 (0.0, 1.0).xyxy;
      if (isBetween (rstart, rend, uv3)) premo = float2 (0.0, 1.0).xxyy;
      if (distance (uv3, hpoint) < 0.005) premo = float2 (1.0, 0.0).xyyx;
      if (distance (uv3, vpoint) < 0.005) premo = float2 (0.0, 1.0).xyxy;
      if (distance (uv3, rpoint) < 0.005) premo = float2 (0.0, 1.0).xxyy;
   }

   return premo;
}

DeclareEntryPoint (CameraShake)
{
   //***********Horizontal motion line

   float2 hpoint = float2 (lerp (h1x, h2x, _Progress), lerp (1.0 - h1y, 1.0 - h2y, _Progress)); //Move the sample point along the line

   //***********Vertical motion line

   float2 vpoint = float2 (lerp (v1x, v2x, _Progress), lerp (1.0 - v1y, 1.0 - v2y, _Progress)); //Move the sample point along the line

   //***********Rotation motion line

   float2 rpoint = float2 (lerp (r1x, r2x, _Progress), lerp (1.0 - r1y, 1.0 - r2y, _Progress)); //Move the sample point along the line

   //***********Get luma values from the motion sampler video (source video or background video)

   float hcolor = tex2D (motrack, hpoint).r; //Luma value for horizontal   
   float vcolor = tex2D (motrack, vpoint).g; //Luma value for vertical
   float rcolor = tex2D (motrack, rpoint).b; //Luma value for rotation

   float hdelta = (hcolor - XBias) * XStrength; //Modify horizontal sample value
   float vdelta = (vcolor - YBias) * YStrength; //Modify vertical sample value
   float rdelta = (rcolor - RBias) * RStrength; //Modify rotation sample value

   if (HRev) hdelta = -hdelta;
   if (VRev) vdelta = -vdelta;
   if (RRev) rdelta = -rdelta;

   float2 coord = uv1 + float2 (hdelta, vdelta);

   //************Master zoom

   float2 xy = (coord - 0.5.xx) / Zoom;

   xy.y /= _OutputAspectRatio;

   //************Master rotation angle    

   float angle = radians (Rotate + (rdelta * 100.0)); //Add rotation motion to master rotation angle

   //************Get rotated coordinates

   float2 rotoff;

   sincos (angle, rotoff.x, rotoff.y);

   float2 xy1 = xy * rotoff.yx;
   float2 xy2 = xy * rotoff * _OutputAspectRatio;

   xy  = float2 (xy1.x + xy1.y - PanX, xy2.y - xy2.x + PanY) + 0.5.xx;

   return MoTrack ? tex2D (motrack, uv3) : ReadPixel (src, xy); //Add shake to input video
}

