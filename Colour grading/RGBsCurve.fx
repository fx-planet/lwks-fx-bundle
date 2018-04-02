// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect RGBsCurve.fx
//
// Created by LW user jwrl 4 January 2017
// @Author: jwrl
// @CreationDate: "4 January 2017"
//
// This Lightworks effect allows the master luminance S curve
// of the input to be adjusted.  Individual adjustment of RGB
// S curves is also possible.  It does this by applying a
// symmetrical quadratic level change to the image.
//
// Added the ability to set the curve profile 8 January 2017.
//
// The knee of the curve may be set either as a master S
// profile or by means of individual YRGB settings.  More and
// more positive values progressively increase the slope of
// the S profile. A value of zero corresponds to a linear
// transfer rate with no visible effect, while values below
// zero invert the profile.  The profile in this version is
// always symmetrical, ie., a breakpoint at 10% will always
// have a corresponding breakpoint at 90%, 20% and 80% will
// be paired, as will 30% and 70% and so on.
//
// Note: the individual profile settings in this effect are
// internally legalised to fall within the range of -1.00 to
// 1.00.  Unlike most Lightworks effects, manually entering
// values outside those limits will result in the same effect
// as if that profile was set to the corresponding maximum
// positive or negative value.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "S curve adjustment";
   string Category    = "Colour";
   string SubCategory = "Technical";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Inp;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InpSampler = sampler_state
{
   Texture = <Inp>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Y_amt
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int SetTechnique
<
   string Description = "Profile generation";
   string Enum = "Exponential,Trigonometric,Logarithmic";
> = 0;

int SetRange
<
   string Description = "Video range";
   string Enum = "Legal BT.709,Full gamut (sRGB)";
> = 0;

float Ycurve
<
   string Description = "Master profile";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float R_amt
<
   string Group = "RGB channels";
   string Description = "Red amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float G_amt
<
   string Group = "RGB channels";
   string Description = "Green amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float B_amt
<
   string Group = "RGB channels";
   string Description = "Blue amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

bool Lock
<
   string Group = "RGB channels";
   string Description = "RGB profiles controlled by master profile (settings below disabled).";
> = true;

float Rcurve
<
   string Group = "RGB channels";
   string Description = "Red profile";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Gcurve
<
   string Group = "RGB channels";
   string Description = "Green profile";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Bcurve
<
   string Group = "RGB channels";
   string Description = "Blue profile";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define PI       3.1415927
#define THIRD_PI 1.0471976

#define E_SCALE  0.25

#define B_POINT  0.0627451
#define W_SCALE  1.1643836
#define W_RANGE  0.8588235

#define L_DIFF   0.1039928

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_exponential (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (InpSampler, uv);

   float rCurve, gCurve, bCurve, rRange, gRange, bRange;
   float yCurve = 1.0 + (4.0 * min (abs (Ycurve * E_SCALE), 1.0));
   float range  = (SetRange == 1) ? 1.0 : W_RANGE;
   float yRange = lerp (1.0, range, abs (Ycurve));

   if (Lock) {
      rCurve = yCurve; gCurve = yCurve; bCurve = yCurve;
      rRange = yRange; gRange = yRange; bRange = yRange;
   }
   else {
      rCurve = 1.0 + (4.0 * min (abs (Rcurve * E_SCALE), 1.0));
      gCurve = 1.0 + (4.0 * min (abs (Gcurve * E_SCALE), 1.0));
      bCurve = 1.0 + (4.0 * min (abs (Bcurve * E_SCALE), 1.0));
      rRange = lerp (1.0, range, abs (Rcurve));
      gRange = lerp (1.0, range, abs (Gcurve));
      bRange = lerp (1.0, range, abs (Bcurve));
   }

   float3 vidY = 1.0.xxx - abs ((2.0 * Fgnd.rgb) - 1.0.xxx);

   vidY   = (1.0.xxx - pow (vidY, yCurve)) * yRange / 2.0;
   vidY.r = (Fgnd.r > 0.5) ? 0.5 + vidY.r : 0.5 - vidY.r;
   vidY.g = (Fgnd.g > 0.5) ? 0.5 + vidY.g : 0.5 - vidY.g;
   vidY.b = (Fgnd.b > 0.5) ? 0.5 + vidY.b : 0.5 - vidY.b;

   if (Ycurve < 0.0) vidY = ((Fgnd.rgb - 0.5.xxx) * yRange) - vidY + Fgnd.rgb + 0.5.xxx;

   vidY = lerp (Fgnd.rgb, vidY, Y_amt);

   float3 vidC = 1.0.xxx - abs ((2.0 * vidY) - 1.0.xxx);

   vidC.r = (1.0 - pow (vidC.r, rCurve)) * rRange / 2.0;
   vidC.r = (vidY.r > 0.5) ? 0.5 + vidC.r : 0.5 - vidC.r;
   vidC.g = (1.0 - pow (vidC.g, rCurve)) * gRange / 2.0;
   vidC.g = (vidY.g > 0.5) ? 0.5 + vidC.g : 0.5 - vidC.g;
   vidC.b = (1.0 - pow (vidC.b, rCurve)) * bRange / 2.0;
   vidC.b = (vidY.b > 0.5) ? 0.5 + vidC.b : 0.5 - vidC.b;

   if (Rcurve < 0.0) vidC.r = ((vidY.r - 0.5) * rRange) - vidC.r + vidY.r + 0.5;

   if (Gcurve < 0.0) vidC.g = ((vidY.g - 0.5) * gRange) - vidC.g + vidY.g + 0.5;

   if (Bcurve < 0.0) vidC.b = ((vidY.b - 0.5) * bRange) - vidC.b + vidY.b + 0.5;

   Fgnd.r = lerp (vidY.r, vidC.r, R_amt);
   Fgnd.g = lerp (vidY.g, vidC.g, G_amt);
   Fgnd.b = lerp (vidY.b, vidC.b, B_amt);

   return Fgnd;
}

float4 ps_trig (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (InpSampler, uv);

   float3 Vfix = Fgnd.rgb;

   float range, rCurve, gCurve, bCurve;

   if (SetRange == 0) {
      Vfix  = min (1.0, max (0.0, Vfix - B_POINT) * W_SCALE);
      range = W_RANGE;
   }
   else range = 1.0;

   float3 vidY = 0.5.xxx - cos (PI * Vfix) * range / 2.0;
   float3 v1_Y = 0.5.xxx + sin (THIRD_PI * (Fgnd.rgb - 0.5.xxx));

   v1_Y = lerp (Fgnd.rgb, v1_Y, min (1.0, abs (Ycurve * 10.0)));
   vidY = lerp (v1_Y, vidY, abs (Ycurve));

   if (Ycurve < 0.0) vidY = saturate (Fgnd.rgb + Fgnd.rgb - vidY);

   vidY = lerp (Fgnd.rgb, vidY, Y_amt);

   float3 vidC = 0.5.xxx - cos (PI * vidY) * range / 2.0;
   float3 v1_C = 0.5.xxx + sin (THIRD_PI * (vidY - 0.5.xxx));

   if (Lock) {
      rCurve = Ycurve;
      gCurve = Ycurve;
      bCurve = Ycurve;
   }
   else {
      rCurve = Rcurve;
      gCurve = Gcurve;
      bCurve = Bcurve;
   }

   v1_C.r = lerp (vidY.r, v1_C.r, min (1.0, abs (rCurve * 10.0)));
   vidC.r = lerp (v1_C.r, vidC.r, abs (rCurve));

   if (rCurve < 0.0) vidC.r = saturate (vidY.r + vidY.r - vidC.r);

   v1_C.g = lerp (vidY.g, v1_C.g, min (1.0, abs (gCurve * 10.0)));
   vidC.g = lerp (v1_C.g, vidC.g, abs (gCurve));

   if (gCurve < 0.0) vidC.g = saturate (vidY.g + vidY.g - vidC.g);

   v1_C.b = lerp (vidY.b, v1_C.b, min (1.0, abs (bCurve * 10.0)));
   vidC.b = lerp (v1_C.b, vidC.b, abs (bCurve));

   if (bCurve < 0.0) vidC.b = saturate (vidY.b + vidY.b - vidC.b);

   Fgnd.r = lerp (vidY.r, vidC.r, R_amt);
   Fgnd.g = lerp (vidY.g, vidC.g, G_amt);
   Fgnd.b = lerp (vidY.b, vidC.b, B_amt);

   return Fgnd;
}

float4 ps_log (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (InpSampler, uv);

   float rCurve, gCurve, bCurve, rScale, gScale, bScale;
   float scale = (SetRange == 1) ? 1.0 : 1.0 - (L_DIFF * max (Ycurve, 0.0));

   float3 vidY = log10 (1.0.xxx + abs (18.0 * (Fgnd.rgb - 0.5.xxx))) * scale / 2.0;

   vidY.r = (Fgnd.r > 0.5) ? 0.5 + vidY.r : 0.5 - vidY.r;
   vidY.g = (Fgnd.g > 0.5) ? 0.5 + vidY.g : 0.5 - vidY.g;
   vidY.b = (Fgnd.b > 0.5) ? 0.5 + vidY.b : 0.5 - vidY.b;

   vidY = lerp (Fgnd.rgb, vidY, abs (Ycurve) * Y_amt);

   if (Ycurve < 0.0) vidY = saturate (Fgnd.rgb + (Fgnd.rgb - vidY) / 3.0);

   float3 vidC = log10 (1.0.xxx + abs (18.0 * (vidY - 0.5.xxx))) / 2.0;

   if (Lock) {
      rCurve = Ycurve;
      gCurve = Ycurve;
      bCurve = Ycurve;

      rScale = scale;
      gScale = scale;
      bScale = scale;
   }
   else {
      rCurve = Rcurve;
      gCurve = Gcurve;
      bCurve = Bcurve;

      rScale = 1.0;
      gScale = 1.0;
      bScale = 1.0;

      if (SetRange == 0) {
         rScale -= L_DIFF * max (rCurve, 0.0);
         gScale -= L_DIFF * max (gCurve, 0.0);
         bScale -= L_DIFF * max (bCurve, 0.0);
      }
   }

   vidC.r *= rScale;
   vidC.r = (vidY.r > 0.5) ? 0.5 + vidC.r : 0.5 - vidC.r;

   if (rCurve < 0.0) vidC.r = saturate (vidY.r + (vidY.r - vidC.r) / 3.0);

   vidC.r = lerp (vidY.r, vidC.r, abs (rCurve) * R_amt);
   vidC.g *= gScale;
   vidC.g = (vidY.g > 0.5) ? 0.5 + vidC.g : 0.5 - vidC.g;

   if (gCurve < 0.0) vidC.g = saturate (vidY.g + (vidY.g - vidC.g) / 3.0);

   vidC.g = lerp (vidY.g, vidC.g, abs (gCurve) * G_amt);
   vidC.b *= bScale;
   vidC.b = (vidY.b > 0.5) ? 0.5 + vidC.b : 0.5 - vidC.b;

   if (bCurve < 0.0) vidC.b = saturate (vidY.b + (vidY.b - vidC.b) / 3.0);

   vidC.b = lerp (vidY.b, vidC.b, abs (bCurve) * B_amt);
   Fgnd.rgb = vidC.rgb;

   return Fgnd;
}

//--------------------------------------------------------------//
// Technique
//--------------------------------------------------------------//

technique exponential
{
   pass P_1
   { PixelShader = compile PROFILE ps_exponential (); }
}

technique trigCurve
{
   pass P_1
   { PixelShader = compile PROFILE ps_trig (); }
}

technique logCurve
{
   pass P_1
   { PixelShader = compile PROFILE ps_log (); }
}

