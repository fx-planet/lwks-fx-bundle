//--------------------------------------------------------------//
// Lightworks user effect
//
// Created by LW user schrauber  13 November 2017
//
// 
// Phase of the transition effect:
//
// Progress 0 to 0.5:
//  -Whirl begins to wind, and reaches the highest speed of rotation at Progress 0.5.
//  -Increasing negative zoom in the center.
//
// Progress 0.5  to  1: Unroll
//     Progress 0.5  to  0.75: constant zoom
//     Progress 0.75 to  1 : Positive zoom (geyser), oscillating zoom, subside
//        Progress 0.78 to 0.95 : Mixing the inputs, starting in the center
//
//
// Version 14.1 update 5 December 2017 by jwrl.
//
// Added LINUX and OSX test to allow support for changing
// "Clamp" to "ClampToEdge" on those platforms.  It will now
// function correctly when used with Lightworks versions 14.5
// and higher under Linux or OS-X and fixes a bug associated
// with using this effect with transitions on those platforms.
//
// The bug still exists when using older versions of Lightworks.
//--------------------------------------------------------------//


int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Swirl mix";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;





//--------------------------------------------------------------//
// Inputs und Samplers
//--------------------------------------------------------------//

#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef OSX
#define Clamp ClampToEdge
#endif

texture Fg;
sampler FgSampler = sampler_state
{
   Texture = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};


texture Bg;
sampler BgSampler = sampler_state
{
   Texture = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};





texture FgTwist : RenderColorTarget;
sampler FgTwistSampler = sampler_state
{
   Texture   = <FgTwist>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};


texture BgTwist : RenderColorTarget;
sampler BgTwistSampler = sampler_state
{
   Texture   = <BgTwist>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};



texture FgZoom : RenderColorTarget;
sampler FgZoomSampler = sampler_state
{
   Texture   = <FgZoom>;
   AddressU  = Clamp;
   AddressU  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

texture BgZoom : RenderColorTarget;
sampler BgZoomSampler = sampler_state
{
   Texture   = <BgZoom>;
   AddressU  = Clamp;
   AddressU  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};



//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//



float Progress
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;


float Zoom
<
   string Description = "Swirl depth";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;


float Spin
<
   string Group = "Rotation";
   string Description = "Revolutions";
   float MinVal = -62.0;
   float MaxVal = 62.0;
> = 10.0;

float Border
<
   string Group = "Rotation";
   string Description = "Fill gaps";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;


//--------------------------------------------------------------//
// Common definitions, declarations, macros
//--------------------------------------------------------------//

float _OutputAspectRatio;
#define HALF_PI 1.5707963
#define PI      3.1415927
#define TWO_PI  6.2831853
#define CENTRE   0.5












//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//


float4 ps_rotation (float2 uvFg : TEXCOORD1, float2 uvBg : TEXCOORD2, uniform int texcoord, uniform sampler InpSampler) : COLOR
{ 
   // Relevant texture coordinates
   float2 uv = uvFg;
   if (texcoord == 2) uv = uvBg;


   // ----Shader definitions or declarations ----
   float4 retval;

   // Position vectors
   float2 posSpin;

   // Direction vectors
   float2 vCT;          // Vector between Center and Texel
   float2 vCT2;         // Vector between Center and Texel, correct the aspect ratio.

   // Others
   float distC;         // Distance from the center
   float Tsin, Tcos;    // Sine and cosine of the set angle.
   float WhirlCenter;   // Number of revolutions in the center. With increasing distance from the center, this number of revolutions decreases.
   float WhirlOutside;  // Unrolling from the outside. The number corresponds to the rotation in the center, with an undistorted rotation. (undistorted: WhirlOutside = WhirlCenter)
   float angle, overEdge;

   #define BORDER   (pow(1.0 - Border, 2.0) * 1000.0)     // Setting characteristic of the border width


   // ------ ROTATION --------
   vCT = uv - CENTRE;
   distC = length (float2 (vCT.x, vCT.y / _OutputAspectRatio));

   WhirlCenter  =  cos(Progress * PI) *-0.5 + 0.5;                           // Rotation starts slowly, gets faster, and ends slowly (S-curve).
   WhirlOutside =  cos(saturate((Progress * 2.0 -1.0)) * PI) *-0.5 + 0.5;    // Unrolling starts slowly from the middle of the effect runtime (S-curve).
   angle = radians
           ( 
            + (WhirlOutside * round(Spin) * 360.0 * distC)
            - (WhirlCenter  * round(Spin) * 360.0 * (1.0 - distC))
            * -1.0
           );
   vCT2 = float2(vCT.x * _OutputAspectRatio, vCT.y);
   sincos (angle, Tsin , Tcos);
   posSpin = float2 ((vCT2.x * Tcos - vCT2.y * Tsin), (vCT2.x * Tsin + vCT2.y * Tcos)); 
   posSpin = float2(posSpin.x / _OutputAspectRatio, posSpin.y ) + CENTRE;


   // ------ OUTPUT-------
   retval = tex2D (InpSampler, posSpin);

   overEdge =
      saturate( BORDER * max(
            max(abs(posSpin.x -0.5)-0.5, 0.0),
            max(abs(posSpin.y -0.5)-0.5, 0.0) ));

   return lerp(retval,
                float4 (0.0.xxx, retval.a),
                overEdge);
   

}
   
   












float4 ps_zoom (float2 uvFg : TEXCOORD1, float2 uvBg : TEXCOORD2, uniform int texcoord, uniform sampler TwistSampler) : COLOR
{ 


   // Relevant texture coordinates
   float2 uv = uvFg;
   if (texcoord == 2) uv = uvBg;


   // ----Shader definitions or declarations ----
   // Position vectors
   float2 posZoom;

   // Direction vectors
   float2 vCT;         // Vector between Center and Texel

   // Others
   float distC;        // Distance from the center
   float zoom;         // inverted zoom (> 0 = negative zoom, <0 = positive zoom)
   float distortion;
   float distortion2;  // Compensation distortion to avoid edge distortion.

   #define FREQ              20.0                             // Frequency of the zoom oscillation
   #define PHASE              0.5                             // 90 ° phase shift of the zoom oscillation. Valid from progress 0.75
   #define AREA            100.0                              // Area of the regional zoom
   #define ZOOMPOWER        12.0


   // --- Automatic zoom change in effect progress ----
   // Progress 0    to  0.5 : increasing negative zoom
   // Progress 0.5  to  0.75: constant zoom
   // Progress 0.75 to  1   : Oscillating zoom, subside
   zoom = min(Progress, 0.5);                                 // negative zoom  (Progress 0 to 0.75)
   zoom = Zoom * (cos(zoom * TWO_PI) *-0.5 + 0.5);            // Creates a smooth zoom start & zoom end (S-curve) from Progress 0 to 0.5
   if (Progress > 0.75)                                       // Progress 0.75 to 1 (Swinging zoom)
      {
         zoom = sin((Progress * FREQ - PHASE) * PI);           // Zoom oscillation
         zoom *= Zoom * saturate(1.0 - (Progress * 4.0 -3.0)); // Damping the zoom from progress 0.75   The formula scales the progress range from 0.75 ... 1   to   1 ... 0; 
      }


   // ------  Inverted regional zoom ------
   vCT = CENTRE - uv;
   distC = length (float2 (vCT.x * _OutputAspectRatio , vCT.y));
   distortion = (distC * ((distC * AREA) + 1.0) + 1.0); 
   distortion2 =  min(length(vCT), CENTRE) -CENTRE;                // The limitation to CENTRE (0.5) preventing distortion of the corners.
   zoom /= max( distortion, 1E-6);
   posZoom =  zoom  * ZOOMPOWER * distortion2 * vCT + uv; 
   


   // ------ OUTPUT-------
   return tex2D (TwistSampler, posZoom);           

}










float4 ps_mix (float2 uvFg: TEXCOORD1, float2 uvBg: TEXCOORD2, float2 uvmix: TEXCOORD0 ) : COLOR
{ 
  

   float2 vCT;      // Direction vector between Center and Texel
   float distC;     // Distance from the center
   float mix;

  vCT = CENTRE - uvmix;
  distC = length (float2 (vCT.x * _OutputAspectRatio , vCT.y));
  mix = saturate ((Progress - 0.78) * 6.0);       // Scales the progress range from > 0.78  to   0 ... 1
  mix = saturate(mix / distC);
  mix = cos(mix * PI) *-0.5 + 0.5;                // Makes the spatial boundary of the blended clips narrower.
  mix = cos(mix * PI) *-0.5 + 0.5;                // Makes the spatial boundary of the mixed clips even narrower.

  return lerp (tex2D (FgZoomSampler, uvFg),
               tex2D (BgZoomSampler, uvBg),
               mix);

}








//--------------------------------------------------------------
// Technique
//--------------------------------------------------------------


technique main
{
   pass P_1 < string Script = "RenderColorTarget0 = FgTwist;"; >    { PixelShader = compile PROFILE ps_rotation (1, FgSampler); }
   pass P_2 < string Script = "RenderColorTarget0 = BgTwist;"; >    { PixelShader = compile PROFILE ps_rotation (2, BgSampler); }
   pass P_3 < string Script = "RenderColorTarget0 = FgZoom;";  >    { PixelShader = compile PROFILE ps_zoom (1, FgTwistSampler); }
   pass P_4 < string Script = "RenderColorTarget0 = BgZoom;";  >    { PixelShader = compile PROFILE ps_zoom (2, BgTwistSampler); }
   pass P_5 { PixelShader = compile PROFILE ps_mix (); }

}


