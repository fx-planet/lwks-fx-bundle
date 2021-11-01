// @Maintainer jwrl
// @Released 2021-11-01
// @Author Gary Hango (khaver)
// @Created 2012-12-04
// @see https://www.lwks.com/media/kunena/attachments/6375/CameraShake_640.png

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

 NOTE:  Because this effect relies on being able to manually set start and end points
 of the shake and rotation tracks it has not been possible to make it truly resolution
 independent.  What it does is lock the clip resolution to sequence resolution instead.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CameraShakes.fx
//
// Version history:
//
// Update 2021-11-01 jwrl.
// Updated the original effect to better handle LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Camera shake";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Adds simulated camera motion horizontally, vertically and/or rotationally";
   bool CanSize       = false;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (src, s_Foreground);
DefineInput (bg, s_Background);

DefineTarget (srcbg, PremoSampler);
DefineTarget (motrack, MotionSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int UseMTrack //Select video track to use as the motion sampler
<
   string Description = "Motion Track";
   string Enum = "Source video,Background video";
> = 0;

bool MoTrack //Show the motion sampling track being used
<
   string Description = "Show motion track";
> = false;

float Zoom //Master zoom control
<
   string Description = "Zoom";
   string Group = "Master";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Rotate //Master rotation control
<
   string Description = "Rotate";
   string Group = "Master";
   float MinVal = -30.0;
   float MaxVal = 30.0;
> = 0.0;

float PanX //Master pan control
<
   string Description = "Pan";
   string Group = "Master";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float PanY //Master pan control
<
   string Description = "Pan";
   string Group = "Master";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float XBias //Middle luma value for horizontal motion sample
<
   string Description = "Bias";
   string Group = "Horizontal";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5; // Default value

float XStrength //Horizontal motion strength
<
   string Description = "Strength";
   string Group = "Horizontal";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0f; // Default value

bool HRev //Reverse horizontal motion
<
   string Description = "Reverse";
   string Group = "Horizontal";
> = false;

bool HSmooth //Smooth horizontal motion - average of 5 pixels.
<
   string Description = "Smooth";
   string Group = "Horizontal";
> = false;

float h1x //Start of the horizontal motion sample line
<
   string Description = "H-Start";
   string Group = "Horizontal";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float h1y //Start of the horizontal motion sample line
<
   string Description = "H-Start";
   string Group = "Horizontal";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float h2x //End of the horizontal motion sample line
<
   string Description = "H-End";
   string Group = "Horizontal";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float h2y //End of the horizontal motion sample line
<
   string Description = "H-End";
   string Group = "Horizontal";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float YBias //Middle luma value for vertical motion sample
<
   string Description = "Bias";
   string Group = "Vertical";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5; // Default value

float YStrength //Vertical motion strength
<
   string Description = "Strength";
   string Group = "Vertical";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0f; // Default value

bool VRev //Reverse vertical motion
<
   string Description = "Reverse";
   string Group = "Vertical";
> = false;

bool VSmooth //Smooth vertical motion - average of 5 pixels.
<
   string Description = "Smooth";
   string Group = "Vertical";
> = false;

float v1x //Start of the vertical motion sample line
<
   string Description = "V-Start";
   string Group = "Vertical";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float v1y //Start of the vertical motion sample line
<
   string Description = "V-Start";
   string Group = "Vertical";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float v2x //End of the vertical motion sample line
<
   string Description = "V-End";
   string Group = "Vertical";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float v2y //End of the vertical motion sample line
<
   string Description = "V-End";
   string Group = "Rotation";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float RBias //Middle luma value for rotation sample
<
   string Description = "Bias";
   string Group = "Rotation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5; // Default value

float RStrength //Rotation strength
<
   string Description = "Strength";
   string Group = "Rotation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0f; // Default value

bool RRev //Reverse rotation
<
   string Description = "Reverse";
  string Group = "Rotation";
> = false;

bool RSmooth //Smooth rotation
<
   string Description = "Smooth";
   string Group = "Rotation";
> = false;

float r1x //Start of the rotation sample line
<
   string Description = "R-Start";
   string Group = "Rotation";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float r1y //Start of the rotation sample line
<
   string Description = "R-Start";
   string Group = "Rotation";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float r2x //End of the rotation sample line
<
   string Description = "R-End";
   string Group = "Rotation";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float r2y //End of the rotation sample line
<
   string Description = "R-End";
   string Group = "Rotation";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 InorBack (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 color = UseMTrack ? tex2D (s_Background, uv2) : tex2D (s_Foreground, uv1);

   float value = (color.r + color.g + color.b) / 3.0;

   return float4 (value.xxx, color.a);
}

float4 motionsample (float2 uv : TEXCOORD3) : COLOR
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

   float4 premo = tex2D (PremoSampler, uv);

   float2 pix = float2 (1.0, _OutputAspectRatio) / _OutputWidth;

    //***********Average of 5 pixels

   if (HSmooth) { premo.r = (tex2D (PremoSampler, uv - pix).g
                           + tex2D (PremoSampler, uv + pix).g + tex2D (PremoSampler, uv - pix).g
                           + tex2D (PremoSampler, float2 (uv.x + pix.x, uv.y - pix.y)).g
                           + tex2D (PremoSampler, float2 (uv.x - pix.x, uv.y + pix.y)).g) / 5.0;
   }

   if (VSmooth) { premo.g = (tex2D (PremoSampler, uv - pix).g
                           + tex2D (PremoSampler, uv + pix).g + tex2D (PremoSampler, uv - pix).g
                           + tex2D (PremoSampler, float2 (uv.x + pix.x, uv.y - pix.y)).g
                           + tex2D (PremoSampler, float2 (uv.x - pix.x, uv.y + pix.y)).g) / 5.0;
   }

   if (RSmooth) { premo.b = (tex2D (PremoSampler, uv - pix).g
                           + tex2D (PremoSampler, uv + pix).g + tex2D (PremoSampler, uv - pix).g
                           + tex2D (PremoSampler, float2 (uv.x + pix.x, uv.y - pix.y)).g
                           + tex2D (PremoSampler, float2 (uv.x - pix.x, uv.y + pix.y)).g) / 5.0;
   }

   if (MoTrack) {
      if (isBetween (hstart, hend, uv)) premo = float2 (1.0, 0.0).xyyx;
      if (isBetween (vstart, vend, uv)) premo = float2 (0.0, 1.0).xyxy;
      if (isBetween (rstart, rend, uv)) premo = float2 (0.0, 1.0).xxyy;
      if (distance (uv, hpoint) < 0.005) premo = float2 (1.0, 0.0).xyyx;
      if (distance (uv, vpoint) < 0.005) premo = float2 (0.0, 1.0).xyxy;
      if (distance (uv, rpoint) < 0.005) premo = float2 (0.0, 1.0).xxyy;
   }

   return premo;
}

float4 main (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   //***********Horizontal motion line

   float2 hpoint = float2 (lerp (h1x, h2x, _Progress), lerp (1.0 - h1y, 1.0 - h2y, _Progress)); //Move the sample point along the line

   //***********Vertical motion line

   float2 vpoint = float2 (lerp (v1x, v2x, _Progress), lerp (1.0 - v1y, 1.0 - v2y, _Progress)); //Move the sample point along the line

   //***********Rotation motion line

   float2 rpoint = float2 (lerp (r1x, r2x, _Progress), lerp (1.0 - r1y, 1.0 - r2y, _Progress)); //Move the sample point along the line

   //***********Get luma values from the motion sampler video (source video or background video)

   float hcolor = tex2D (MotionSampler, hpoint).r; //Luma value for horizontal   
   float vcolor = tex2D (MotionSampler, vpoint).g; //Luma value for vertical
   float rcolor = tex2D (MotionSampler, rpoint).b; //Luma value for rotation

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

   return MoTrack ? tex2D (MotionSampler, uv3) : GetPixel (s_Foreground, xy); //Add shake to input video
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique CameraShake
{
   pass P_1 < string Script = "RenderColorTarget0 = srcbg;"; > ExecuteShader (InorBack)
   pass P_2 < string Script = "RenderColorTarget0 = motrack;"; > ExecuteShader (motionsample)
   pass P_3 ExecuteShader (main)
}

