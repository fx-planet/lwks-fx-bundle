// @Maintainer jwrl
// @Released 2022-02-07
// @Author jwrl
// @Author khaver
// @Created 2022-02-07
// @see https://forum.lwks.com/attachments/vignettegrade_640-png.40173/

/**
 This is an attempt to duplicate some of the functionality of powertools colourgrading.
 Gamma, contrast, gain, brightness and saturation can be adjusted as you would expect
 with any colourgrade tool.  In addition it's possible to independently adjust the
 saturation of midtones, blacks and whites.  The individual red, green and blue values
 of the grade can also be fine tuned.

 The grade can be masked using a slightly simplified version of khaver's Polygrade 16
 effect.  The edges of the mask can be feathered, and a background colour can be turned
 on to assist in mask set up.  The mask can also be inverted.  The zoom, aspect ratio
 and position adjustments of the original polymask effect have been discarded.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PowerGrade.fx
//
// Version history:
//
// Created 2022-02-07 jwrl.
// The masking is based on khaver's PolyMask_16, and the colour grade on my vignette grade.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Power grade";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "Mimics powertools colour grades using a polymask 16 shape";
   bool CanSize       = true;
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

#define PI 3.1415926536

#define MASK_COLOUR float3(0.0, 0.5, 1.0).xyxz

int _Index[16] = { 15, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 };

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);
DefineTarget (Grade, s_Grade);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float GradeAmount
<
   string Description = "Grade amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Gamma
<
   string Group = "Master levels";
   string Description = "Gamma";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Contrast
<
   string Group = "Master levels";
   string Description = "Contrast";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Gain
<
   string Group = "Master levels";
   string Description = "Gain";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Brightness
<
   string Group = "Master levels";
   string Description = "Brightness";
   string Flags = "DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Saturation
<
   string Group = "Master levels";
   string Description = "Saturation";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Saturate_W
<
   string Group = "Saturation zones";
   string Description = "Whites";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Saturate_M
<
   string Group = "Saturation zones";
   string Description = "Mids";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Saturate_B
<
   string Group = "Saturation zones";
   string Description = "Blacks";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Trim_R
<
   string Group = "RGB fine tuning";
   string Description = "Red trim";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Trim_G
<
   string Group = "RGB fine tuning";
   string Description = "Green trim";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Trim_B
<
   string Group = "RGB fine tuning";
   string Description = "Blue trim";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

bool ShowMask
<
   string Group = "Masking";
   string Description = "Show mask";
> = false;

bool Invert
<
   string Group = "Masking";
   string Description = "Invert mask";
> = true;

float Feather
<
   string Group = "Masking";
   string Description = "Feather mask";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.0;

float P1X
<
   string Group = "Coordinates";
   string Description = "P 1";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.432;

float P1Y
<
   string Group = "Coordinates";
   string Description = "P 1";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.155;

float P2X
<
   string Group = "Coordinates";
   string Description = "P 2";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.305;

float P2Y
<
   string Group = "Coordinates";
   string Description = "P 2";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.207;

float P3X
<
   string Group = "Coordinates";
   string Description = "P 3";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.207;

float P3Y
<
   string Group = "Coordinates";
   string Description = "P 3";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.305;

float P4X
<
   string Group = "Coordinates";
   string Description = "P 4";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.155;

float P4Y
<
   string Group = "Coordinates";
   string Description = "P 4";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.432;

float P5X
<
   string Group = "Coordinates";
   string Description = "P 5";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.155;

float P5Y
<
   string Group = "Coordinates";
   string Description = "P 5";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.568;

float P6X
<
   string Group = "Coordinates";
   string Description = "P 6";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.207;

float P6Y
<
   string Group = "Coordinates";
   string Description = "P 6";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.695;

float P7X
<
   string Group = "Coordinates";
   string Description = "P 7";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.305;

float P7Y
<
   string Group = "Coordinates";
   string Description = "P 7";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.793;

float P8X
<
   string Group = "Coordinates";
   string Description = "P 8";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.432;

float P8Y
<
   string Group = "Coordinates";
   string Description = "P 8";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.845;

float P9X
<
   string Group = "Coordinates";
   string Description = "P 9";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.568;

float P9Y
<
   string Group = "Coordinates";
   string Description = "P 9";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.845;

float P10X
<
   string Group = "Coordinates";
   string Description = "P 10";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.695;

float P10Y
<
   string Group = "Coordinates";
   string Description = "P 10";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.793;

float P11X
<
   string Group = "Coordinates";
   string Description = "P 11";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.793;

float P11Y
<
   string Group = "Coordinates";
   string Description = "P 11";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.695;

float P12X
<
   string Group = "Coordinates";
   string Description = "P 12";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.845;

float P12Y
<
   string Group = "Coordinates";
   string Description = "P 12";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.568;

float P13X
<
   string Group = "Coordinates";
   string Description = "P 13";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.845;

float P13Y
<
   string Group = "Coordinates";
   string Description = "P 13";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.432;

float P14X
<
   string Group = "Coordinates";
   string Description = "P 14";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.793;

float P14Y
<
   string Group = "Coordinates";
   string Description = "P 14";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.305;

float P15X
<
   string Group = "Coordinates";
   string Description = "P 15";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.695;

float P15Y
<
   string Group = "Coordinates";
   string Description = "P 15";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.207;

float P16X
<
   string Group = "Coordinates";
   string Description = "P 16";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.568;

float P16Y
<
   string Group = "Coordinates";
   string Description = "P 16";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.155;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_rgb2hsv (float4 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float4 hsv  = float3 (0.0, Cmax, rgb.a).xxyz;

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float4 fn_hsv2rgb (float4 hsv)
{
   if (hsv.y == 0.0) return hsv.zzzw;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (1.0 - hsv.y * (1.0 - f));

   if (i == 0) return float4 (hsv.z, r, p, hsv.w);
   if (i == 1) return float4 (q, hsv.z, p, hsv.w);
   if (i == 2) return float4 (p, hsv.z, r, hsv.w);
   if (i == 3) return float4 (p, q, hsv.zw);
   if (i == 4) return float4 (r, p, hsv.zw);

   return float4 (hsv.z, p, q, hsv.w);
}

float fn_LineDistance (float2 xy, float2 l1, float2 l2)
{
   float2 Delta = l2 - l1;
   float2 D_sqr = Delta * Delta;
   float2 uv = (xy - l1) * Delta;

   float u = (uv.x + uv.y) / (D_sqr.x + D_sqr.y);

   float2 closestPointOnLine = (u < 0.0) ? l1 : (u > 1.0) ? l2 : l1 + (u * Delta);

   return distance (xy, closestPointOnLine);
}

float fn_PolyDistance (float2 xy, float2 poly [16])
{
   float result = 100.0;

   for (int i = 0; i < 16; i++) {
      int j = _Index [i];

      float2 currentPoint  = poly [i];
      float2 previousPoint = poly [j];

      float segmentDistance = fn_LineDistance (xy, previousPoint, currentPoint);

      if (segmentDistance < result) result = segmentDistance;
   }

   return result;
}

float fn_makePoly (float2 xy, float2 poly [16])
{
   float retval = 0.0;

   for (int i = 0; i < 16; i++) {
      int j = _Index [i];

      if (((poly [j].y > xy.y ) != (poly [i].y > xy.y)) &&
          (xy.x < (poly [i].x - poly [j].x) * (xy.y - poly [j].y) / (poly [i].y - poly [j].y) + poly [j].x))
      retval = abs (retval - 1.0);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip geometry
// and rotation are handled without too much effort.  With 2022.2 it may be redundant.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

// This is the core colour grading process.  To do list: execute this as part of ps_main()
// so that we only need to do it when required.

float4 ps_grade (float2 uv : TEXCOORD2) : COLOR
{
   // This grading operation is done in the HSV domain because it makes life a lot easier
   // when dealing with saturation.  Immediately we get the video we convert it.

   float4 inp = GetPixel (s_Input, uv);
   float4 hsv = fn_rgb2hsv (inp);

   // Now we obtain the three overlapping grading zones.

   float mids = 0.5 + (cos (smoothstep (0.0, 0.5, abs (0.5 - hsv.z)) * PI) * 0.5);
   float high = (hsv.z > 0.5) ? 1.0 - mids : 0.0;
   float lows = (hsv.z < 0.5) ? 1.0 - mids : 0.0;

   // Saturation is now adjusted in the three zones, then the master saturation
   // is applied.

   hsv.y = lerp (hsv.y, hsv.y * Saturate_W, high);
   hsv.y = lerp (hsv.y, hsv.y * Saturate_M, mids);
   hsv.y = lerp (hsv.y, hsv.y * Saturate_B, lows);
   hsv.y = hsv.y * Saturation;

   // Now we adjust the luminance gamma, gain, brightness and contrast

   hsv.z = ((((pow (hsv.z, 1.0 / Gamma) * Gain) + Brightness) - 0.5) * Contrast) + 0.5;

   // The graded RGB version is now recovered into retval, and the amount red, green and
   // blue adjustment is set.  Then we ensure that retval is legal and return.

   float4 retval = fn_hsv2rgb (hsv);

   retval.r = lerp (inp.r, retval.r, Trim_R);
   retval.g = lerp (inp.g, retval.g, Trim_G);
   retval.b = lerp (inp.b, retval.b, Trim_B);
   retval.a = inp.a;

   return saturate (retval);
}

// This is a cut down version of khaver's Polymask 16 effect used for masking the grade.

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   float2 poly [16] = { { P1X,  1.0 - P1Y },  { P2X,  1.0 - P2Y },  { P3X,  1.0 - P3Y },
                        { P4X,  1.0 - P4Y },  { P5X,  1.0 - P5Y },  { P6X,  1.0 - P6Y },
                        { P7X,  1.0 - P7Y },  { P8X,  1.0 - P8Y },  { P9X,  1.0 - P9Y },
                        { P10X, 1.0 - P10Y }, { P11X, 1.0 - P11Y }, { P12X, 1.0 - P12Y },
                        { P13X, 1.0 - P13Y }, { P14X, 1.0 - P14Y }, { P15X, 1.0 - P15Y },
	                { P16X, 1.0 - P16Y } };

   float mask  = fn_makePoly (uv, poly);
   float range = fn_PolyDistance (uv, poly);

   if (range < Feather) {
      range *= 0.5 / Feather;
      mask   = (mask > 0.5) ? 0.5 + range : 0.5 - range;
   }

   float Mask = (Invert) ? 1.0 - mask : mask;

   float4 Bgnd = (ShowMask) ? MASK_COLOUR : GetPixel (s_Input, uv);
   float4 Fgnd = lerp (GetPixel (s_Grade, uv), Bgnd, Mask);

   return lerp (Bgnd, Fgnd, GradeAmount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique PowerGrade
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Grade;"; > ExecuteShader (ps_grade)
   pass P_3 ExecuteShader (ps_main)
}

