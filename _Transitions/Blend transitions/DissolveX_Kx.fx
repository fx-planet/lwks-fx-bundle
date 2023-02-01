// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This alpha and delta dissolve allows blend modes to be applied during the transition
 using a drop down menu to select different dissolve methods.  The intention behind
 this effect was to get as close as possible visually to the standard Photoshop blend
 modes.

 In addition to the Lightworks blends, this effect provides Linear burn, Darker colour,
 Vivid light, Linear light, Pin light, Hard mix, Divide, Hue and Saturation.  The
 Lightworks effect Add has been replaced by Linear Dodge which is functionally identical,
 Burn has been replaced by Colour burn, and Dodge by Colour dodge.  "In Front" has been
 replaced by "Normal" to better match the Photoshop model.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// User effect DissolveX_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("DissolveX (keyed)", "Mix", "Blend transitions", "Separates foreground from background and dissolves it while blending it during the transition", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (Ttype, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta unfolded|Standard transitions");
DeclareIntParam (SetTechnique, "Method", kNoGroup, 0, "Normal|Darken|Multiply|Colour Burn|Linear Burn|Darker Colour|Lighten|Screen|Colour Dodge|Linear Dodge (Add)|Lighter Colour|Overlay|Soft Light|Hard Light|Vivid Light|Linear Light|Pin Light|Hard Mix|Difference|Exclusion|Subtract|Divide|Hue|Saturation|Colour|Luminosity");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Timing, "Timing", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define CrR     0.439
#define CrG     0.368
#define CrB     0.071

#define CbR     0.148
#define CbG     0.291
#define CbB     0.439

#define Rr_R    1.596
#define Rg_R    0.813
#define Rg_B    0.391
#define Rb_B    2.018

#define WHITE   (1.0).xxxx

#define LUMA    float4(0.2989, 0.5866, 0.1145, 0.0)

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

float2 fn_init (sampler F, float2 xy1, out float4 fgd, sampler B, float2 xy2, out float4 bgd)
{
   float4 Fgnd = ReadPixel (F, xy1);
   float4 Bgnd = ReadPixel (B, xy2);

   if (Source == 0) {

      if (Ttype == 0) {
         float4 Key = Bgnd;

         Bgnd = Fgnd;
         Fgnd = Key;
      }

      Fgnd.a    = smoothstep (0.0, KeyGain, distance (Fgnd.rgb, Bgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   fgd = Fgnd;
   bgd = Bgnd;

   float amount = Ttype == 2 ? 1.0 - Amount : Amount;
   float timeRef = (saturate (Timing) * 0.8) + 0.1;
   float timing  = saturate (amount / timeRef);

   return float2 (timing, saturate ((amount - timeRef) / (1.0 - timeRef)));
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Normal)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = lerp (Bgnd, (Fgnd + Bgnd) / 2.0, Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

//--------------------------------------- GROUP 1 -----------------------------------------//

DeclareEntryPoint (Darken)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = lerp (Bgnd, min (Fgnd, Bgnd), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (Multiply)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = lerp (Bgnd, Bgnd * Fgnd, Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (ColourBurn)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r == 0.0) ? Fgnd.r : max (1.0 - ((1.0 - Bgnd.r) / Fgnd.r), 0.0);
   blnd.g = (Fgnd.g == 0.0) ? Fgnd.g : max (1.0 - ((1.0 - Bgnd.g) / Fgnd.g), 0.0);
   blnd.b = (Fgnd.b == 0.0) ? Fgnd.b : max (1.0 - ((1.0 - Bgnd.b) / Fgnd.b), 0.0);

   blnd = lerp (Bgnd, min (blnd, WHITE), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (LinearBurn)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = lerp (Bgnd, max (Fgnd + Bgnd - WHITE, kTransparentBlack), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (DarkerColour)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float  luma = dot (Bgnd, LUMA);

   float4 blnd = (dot (Fgnd, LUMA) < luma) ? Fgnd : Bgnd;

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

//--------------------------------------- GROUP 2 -----------------------------------------//

DeclareEntryPoint (Lighten)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = lerp (Bgnd, max (Fgnd, Bgnd), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (Screen)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = lerp (Bgnd, saturate (Fgnd + Bgnd - (Fgnd * Bgnd)), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (ColourDodge)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (1.0 - Fgnd.r);
   blnd.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (1.0 - Fgnd.g);
   blnd.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (1.0 - Fgnd.b);

   blnd = lerp (Bgnd, min (blnd, WHITE), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (LinearDodge)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = lerp (Bgnd, min (Fgnd + Bgnd, WHITE), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (LighterColour)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float  luma = dot (Bgnd, LUMA);

   float4 blnd = (dot (Fgnd, LUMA) > luma) ? Fgnd : Bgnd;

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

//--------------------------------------- GROUP 3 -----------------------------------------//

DeclareEntryPoint (Overlay)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = Fgnd;

   float3 retMin = 2.0 * Bgnd.rgb * Fgnd.rgb;
   float3 retMax = 1.0.xxx - 2.0 * (1.0.xxx - Fgnd.rgb) * (1.0.xxx - Bgnd.rgb);

   blnd.r = (Bgnd.r <= 0.5) ? retMin.r : retMax.r;
   blnd.g = (Bgnd.g <= 0.5) ? retMin.g : retMax.g;
   blnd.b = (Bgnd.b <= 0.5) ? retMin.b : retMax.b;

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (SoftLight)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = Fgnd;

   float3 retMax = (2.0 * Fgnd.rgb) - 1.0.xxx;
   float3 retMin = Bgnd.rgb * (retMax * (1.0.xxx - Bgnd.rgb) + 1.0.xxx);

   retMax *= sqrt (Bgnd.rgb) - Bgnd.rgb;
   retMax += Bgnd.rgb;

   blnd.r = (Fgnd.r <= 0.5) ? retMin.r : retMax.r;
   blnd.g = (Fgnd.g <= 0.5) ? retMin.g : retMax.g;
   blnd.b = (Fgnd.b <= 0.5) ? retMin.b : retMax.b;

   blnd = lerp (Bgnd, saturate (blnd), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (HardLight)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = Fgnd;

   float3 retMin = saturate (2.0 * Bgnd.rgb * Fgnd.rgb);
   float3 retMax = saturate (1.0.xxx - 2.0 * (1.0.xxx - Bgnd.rgb) * (1.0.xxx - Fgnd.rgb));

   blnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   blnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   blnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (VividLight)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = Fgnd;

   float3 retMax, retMin;

   retMin.r = (Fgnd.r == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.r) / (2.0 * Fgnd.r)), 0.0);
   retMin.g = (Fgnd.g == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.g) / (2.0 * Fgnd.g)), 0.0);
   retMin.b = (Fgnd.b == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.b) / (2.0 * Fgnd.b)), 0.0);

   retMax.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (2.0 * (1.0 - Fgnd.r));
   retMax.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (2.0 * (1.0 - Fgnd.g));
   retMax.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (2.0 * (1.0 - Fgnd.b));

   retMin = min (retMin, (1.0).xxx);
   retMax = min (retMax, (1.0).xxx);

   blnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   blnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   blnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (LinearLight)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 retMin = max ((2.0 * Fgnd) + Bgnd - WHITE, kTransparentBlack);
   float4 retMax = min ((2.0 * Fgnd) + Bgnd - WHITE, WHITE);
   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   blnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   blnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (PinLight)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = Fgnd;

   float3 retMax = 2.0 * Fgnd.rgb;
   float3 retMin = retMax - 1.0.xxx;

   blnd.r = (Bgnd.r > retMax.r) ? retMax.r : (Bgnd.r < retMin.r) ? retMin.r : Bgnd.r;
   blnd.g = (Bgnd.g > retMax.g) ? retMax.g : (Bgnd.g < retMin.g) ? retMin.g : Bgnd.g;
   blnd.b = (Bgnd.b > retMax.b) ? retMax.b : (Bgnd.b < retMin.b) ? retMin.b : Bgnd.b;

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (HardMix)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = Fgnd;

   float3 ref = 1.0.xxx - Bgnd.rgb;

   blnd.r = (Fgnd.r < ref.r) ? 0.0 : 1.0;
   blnd.g = (Fgnd.g < ref.g) ? 0.0 : 1.0;
   blnd.b = (Fgnd.b < ref.b) ? 0.0 : 1.0;

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

//--------------------------------------- GROUP 4 -----------------------------------------//

DeclareEntryPoint (Difference)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = lerp (Bgnd, abs (Fgnd - Bgnd), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (Exclusion)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = lerp (Bgnd, saturate (Fgnd + Bgnd - (2.0 * Fgnd * Bgnd)), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (Subtract)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = lerp (Bgnd, max (Bgnd - Fgnd, kTransparentBlack), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (Divide)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r == 0.0) ? 1.0 : min (Bgnd.r / Fgnd.r, 1.0);
   blnd.g = (Fgnd.g == 0.0) ? 1.0 : min (Bgnd.g / Fgnd.g, 1.0);
   blnd.b = (Fgnd.b == 0.0) ? 1.0 : min (Bgnd.b / Fgnd.b, 1.0);

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

//--------------------------------------- GROUP 5 -----------------------------------------//

DeclareEntryPoint (Hue)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.xw = (fn_rgb2hsv (Fgnd)).xw;

   blnd = lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (Saturation)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.yw = fn_rgb2hsv (Fgnd).yw;

   blnd = lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (Colour)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = fn_rgb2hsv (Fgnd);

   blnd.x = (fn_rgb2hsv (Bgnd)).x;

   blnd = lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

DeclareEntryPoint (Luminosity)
{
   float4 Fgnd, Bgnd;

   float2 amount = fn_init (Fg, uv1, Fgnd, Bg, uv2, Bgnd);

   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.zw = (fn_rgb2hsv (Fgnd)).zw;

   blnd = lerp (Bgnd, fn_hsv2rgb (blnd), blnd.a * amount.x);

   blnd = lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : blnd;
}

