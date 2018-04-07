// @Maintainer jwrl
// @Released 2018-04-05
// @Author Gary Hango (khaver)
// 
// @see https://www.lwks.com/media/kunena/attachments/6375/Camera_Shake.png
// @see https://www.lwks.com/media/kunena/attachments/6375/CameraMotion.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect CameraShake.fx
//
// Camera Shake uses luminance variations in a clip to add motion horizontally, vertically
// and/or rotationally.  That clip can be either the source track or another video layer,
// and that second video layer may contain motion content or be a still frame.
//
// The motion source track is set up using the "Show motion track" box.  This will display
// the motion track source in the viewer overlaid with red, green and blue lines and three
// associated coloured ovals.  Playing through the clip will cause each oval to move from
// one end of its line to the other, corresponding to the play head position.  Red shows
// the horizontal motion track, green the vertical, and blue, rotation.
//
// Best results are produced when the start and end points of each line cover a good range
// of dark and light areas as the clip plays.  This can be done with either the sliders or
// by dragging with the mouse.  Once they are set adjust the bias and strength for the
// required amount of horizontal, vertical and rotational movement.
//
// The zoom, rotation and pan sliders can be used for additional trimming.  Each motion
// track may be smoothed and/or have its direction of action reversed.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Bug fix 26 February 2017 by jwrl:
// Added workaround for the interlaced media height bug in Lightworks effects.
//
// Cross platform compatibility check 2 August 2017 jwrl.
// Explicitly defined samplers to avoid cross platform default sampler differences.
//
// Version 14.5 update 5 December 2017 by jwrl.
// Added LINUX and MAC test to allow support for changing "Clamp" to "ClampToEdge" on
// those platforms.  It will now function correctly when used with Lightworks versions
// 14.5 and higher under Linux or OS-X and fixes a bug associated with using this effect
// with transitions on those platforms.  The bug still exists when using older versions
// of Lightworks.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Camera Shake";
   string Category    = "Stylize";
   string SubCategory = "Motion";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture src;
texture bg;

texture srcbg : RenderColorTarget;
texture motrack : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef MAC
#define Clamp ClampToEdge
#endif

// The samplers below originally had the address modes and filter settings commented out
// so that default values would be used.  This is quite valid in Windows, but can produce
// unexpected results when using Mac/Linux.  They have now been uncommented to explicitly
// define the settings - jwrl.

sampler BackgroundSampler = sampler_state { Texture = <bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
 };
sampler InputSampler = sampler_state { Texture = <src>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
 };
sampler PremoSampler = sampler_state { Texture = <srcbg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
 };
sampler MotionSampler = sampler_state { Texture = <motrack>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
 };

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
   float MinVal = 0.00;
   float MaxVal = 2.00;
> = 1.0;

float Rotate //Master rotation control
<
   string Description = "Rotate";
   string Group = "Master";
   float MinVal = -30.00;
   float MaxVal = 30.00;
> = 0.0;

float PanX //Master pan control
<
   string Description = "Pan";
   string Group = "Master";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float PanY //Master pan control
<
   string Description = "Pan";
   string Group = "Master";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float XBias //Middle luma value for horizontal motion sample
<
   string Description = "Bias";
   string Group = "Horizontal";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5; // Default value

float XStrength //Horizontal motion strength
<
   string Description = "Strength";
   string Group = "Horizontal";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
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
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float h1y //Start of the horizontal motion sample line
<
   string Description = "H-Start";
   string Group = "Horizontal";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float h2x //End of the horizontal motion sample line
<
   string Description = "H-End";
   string Group = "Horizontal";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float h2y //End of the horizontal motion sample line
<
   string Description = "H-End";
   string Group = "Horizontal";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float YBias //Middle luma value for vertical motion sample
<
   string Description = "Bias";
   string Group = "Vertical";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5; // Default value

float YStrength //Vertical motion strength
<
   string Description = "Strength";
   string Group = "Vertical";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
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
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float v1y //Start of the vertical motion sample line
<
   string Description = "V-Start";
   string Group = "Vertical";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float v2x //End of the vertical motion sample line
<
   string Description = "V-End";
   string Group = "Vertical";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float v2y //End of the vertical motion sample line
<
   string Description = "V-End";
   string Group = "Rotation";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float RBias //Middle luma value for rotation sample
<
   string Description = "Bias";
   string Group = "Rotation";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5; // Default value

float RStrength //Rotation strength
<
   string Description = "Strength";
   string Group = "Rotation";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
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
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float r1y //Start of the rotation sample line
<
   string Description = "R-Start";
   string Group = "Rotation";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float r2x //End of the rotation sample line
<
   string Description = "R-End";
   string Group = "Rotation";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float r2y //End of the rotation sample line
<
   string Description = "R-End";
   string Group = "Rotation";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool isBetween(float2 a,float2 b,float2 c) {
 float A = c.x - a.x;
 float B = c.y - a.y;
 float C = b.x - a.x;
 float D = b.y - a.y;
 
 float dt = A * C + B * D;
 float lensq = C * C + D * D;
 float param = dt / lensq;
 float xx, yy;
 
 if (param < 0.0 || (a.x == b.x && a.y == b.y)) {
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
 if (dist < 0.0008) return true;
 else return false;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 InorBack (float2 uv : TEXCOORD1 ) : COLOR
{
	float4 color;
	if (UseMTrack) color =  tex2D(BackgroundSampler, uv);
	else color =  tex2D(InputSampler, uv);
	float value = (color.r + color.g + color.b) / 3.0;
	return float4(value,value,value,1);
}

float4 motionsample (float2 uv : TEXCOORD1 ) : COLOR
{

   //***********Horizontal motion line
   float2 hstart = float2(h1x,1.0f-h1y);
   float2 hend = float2(h2x,1.0f-h2y);
   float2 hpoint = float2(lerp(h1x,h2x,_Progress),lerp(1.0f-h1y,1.0f-h2y,_Progress)); //Move the sample point along the line
   
   //***********Vertical motion line
   float2 vstart = float2(v1x,1.0f-v1y);
   float2 vend = float2(v2x,1.0f-v2y);
   float2 vpoint = float2(lerp(v1x,v2x,_Progress),lerp(1.0f-v1y,1.0f-v2y,_Progress)); //Move the sample point along the line
   
   //***********Rotation motion line
   float2 rstart = float2(r1x,1.0f-r1y);
   float2 rend = float2(r2x,1.0f-r2y);
   float2 rpoint = float2(lerp(r1x,r2x,_Progress),lerp(1.0f-r1y,1.0f-r2y,_Progress)); //Move the sample point along the line
   

  float4 premo = tex2D(PremoSampler, uv);
/*
  // This will not work reliably with interlaced mmedia due to a Lightworks effects bug.
  float2 pix;
  pix.x = 1.0 / _OutputWidth;
  pix.y = 1.0 / _OutputHeight;
*/
  float2 pix = float2 (1.0, _OutputAspectRatio) / _OutputWidth;   // Workaround for LW interlaced media height bug - jwrl.
   if (HSmooth) { //Average of 5 pixels
	premo.r = (
                 tex2D(PremoSampler,uv-pix).g
                 + tex2D(PremoSampler,uv+pix).g
                 + tex2D(PremoSampler,uv-pix).g
                 + tex2D(PremoSampler,float2(uv.x+pix.x,uv.y-pix.y)).g
                 + tex2D(PremoSampler,float2(uv.x-pix.x,uv.y+pix.y)).g
                 )
                 / 5.0f;
   }
     if (VSmooth) { //Average of 5 pixels
       premo.g = (
                 tex2D(PremoSampler,uv-pix).g
                 + tex2D(PremoSampler,uv+pix).g
                 + tex2D(PremoSampler,uv-pix).g
                 + tex2D(PremoSampler,float2(uv.x+pix.x,uv.y-pix.y)).g
                 + tex2D(PremoSampler,float2(uv.x-pix.x,uv.y+pix.y)).g
                 )
                 / 5.0f;
     }
     if (RSmooth) { //Average of 5 pixels
       premo.b = (
                 tex2D(PremoSampler,uv-pix).g
                 + tex2D(PremoSampler,uv+pix).g
                 + tex2D(PremoSampler,uv-pix).g
                 + tex2D(PremoSampler,float2(uv.x+pix.x,uv.y-pix.y)).g
                 + tex2D(PremoSampler,float2(uv.x-pix.x,uv.y+pix.y)).g
                 )
                 / 5.0f;
     }
       	if (MoTrack){
   		if (isBetween(hstart, hend, uv)) premo = float4(1,0,0,1);
   		if (isBetween(vstart, vend, uv)) premo = float4(0,1,0,1);
   		if (isBetween(rstart, rend, uv)) premo = float4(0,0,1,1);
   		if (distance(uv,hpoint) < 0.005) premo = float4(1,0,0,1);
   		if (distance(uv,vpoint) < 0.005) premo = float4(0,1,0,1);
   		if (distance(uv,rpoint) < 0.005) premo = float4(0,0,1,1);
   	}

  return premo;
 }

float4 main( float2 uv : TEXCOORD1 ) : COLOR
{

   //***********Horizontal motion line
   float2 hpoint = float2(lerp(h1x,h2x,_Progress),lerp(1.0f-h1y,1.0f-h2y,_Progress)); //Move the sample point along the line
   
   //***********Vertical motion line
   float2 vpoint = float2(lerp(v1x,v2x,_Progress),lerp(1.0f-v1y,1.0f-v2y,_Progress)); //Move the sample point along the line
   
   //***********Rotation motion line
   float2 rpoint = float2(lerp(r1x,r2x,_Progress),lerp(1.0f-r1y,1.0f-r2y,_Progress)); //Move the sample point along the line
  
   float hcolor, vcolor, rcolor;
   
   //***********Get luma values from the motion sampler video (source video or background video)
     hcolor = tex2D(MotionSampler,hpoint).r; //Luma value for horizontal   
     vcolor = tex2D(MotionSampler,vpoint).g; //Luma value for vertical
     rcolor = tex2D(MotionSampler,rpoint).b; //Luma value for rotation
   float hdelta, vdelta, rdelta;
   if (hcolor < XBias) hdelta = (XBias - hcolor) * -XStrength; //Modify horizontal sample value
   else hdelta = (hcolor - XBias) * XStrength;
   if (hcolor == XBias) hdelta = 0.0f;
   if (vcolor < YBias) vdelta = (YBias - vcolor) * -YStrength; //Modify vertical sample value
   else vdelta = (vcolor - YBias) * YStrength;
   if (vcolor == YBias) vdelta = 0.0f;
   if (rcolor < RBias) rdelta = (RBias - rcolor) * -RStrength; //Modify rotation sample value
   else rdelta = (rcolor - RBias) * RStrength;
   if (rcolor == RBias) rdelta = 0.0f;
   hdelta = HRev ? hdelta * -1.0f : hdelta;
   vdelta = VRev ? vdelta * -1.0f : vdelta;
   rdelta = RRev ? rdelta * -1.0f : rdelta;
   float2 coord = float2(uv.x + hdelta,uv.y + vdelta);
   
   float X = coord.x - 0.5;
   float Y = coord.y - 0.5;
   
   //************Master zoom
   X = X/Zoom;
   Y = Y/(Zoom*_OutputAspectRatio);
   
   //************Master rotation angle    
   float angle = radians(Rotate+(rdelta*100.0f)); //Add rotation motion to master rotation angle
   
   //************Get rotated coordinates
   float2 rotoff;
   sincos(angle, rotoff.x, rotoff.y);
   float temp = (X * rotoff.y) + (Y * (rotoff.x));
   Y = ((X * -rotoff.x) + (Y * rotoff.y))*_OutputAspectRatio;
   X = temp;
   
   //************Master pan
   X = X - PanX;
   Y = Y + PanY;
   
   X += 0.5;
   Y += 0.5;

   
  float4 orig;
   
  if (MoTrack)
  {
	orig = tex2D(MotionSampler, uv);
  }
	
  else 
  {
	orig = tex2D(InputSampler,float2(X,Y)); //Add shake to input video
	if (X < 0.0f || Y < 0.0f || X > 1.0f || Y > 1.0f) orig = 0.0f; //Blacken borders 
  }
  return orig;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique CameraShake
{
    pass Pass0
   <
      string Script = "RenderColorTarget0 = srcbg;";
   >
   {
      PixelShader = compile PROFILE InorBack();
   }
  pass Pass1
   <
      string Script = "RenderColorTarget0 = motrack;";
   >
   {
      PixelShader = compile PROFILE motionsample();
   }
   pass Pass2
   {
      PixelShader = compile PROFILE main();
   }
}
