// @Maintainer jwrl
// @Released 2024-01-21
// @Author baopao
// @Author jwrl
// @Created 2024-01-21

/**
 "Blend with unpremultiply" provides the functionality of the Lightworks blend effect with
 the option to unpremutliply or premultiply the foreground input.  Those two settings can
 either crispen the edges of the blend or remove the hard outline you can get with
 premultiplied images.

 The blend modes match the Lightworks blend effect, but the alpha channel / transparency is
 handled differently.  In the lightworks effect the alpha channel is turned fully on, while
 in this effect the foreground and background alphas are combined, allowing blend effects
 to be cascaded.

 Because I have matched the Lightworks blend effects several of the standard Photoshop
 blends have not been included.  Against my better judgment I have also included Average,
 which in my opinion is pointless, because it's identical to setting Fg Opacity to 50%
 when you use In Front as the blend mode.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BlendWithUnpremultiply.fx
//
// This effect is all original work and does NOT use any Lightworks code.
//
// Version history:
//
// Created 2024-01-21 jwrl.
// Combined code from baopao's Unpremultiply and jwrl's Enhanced blend tools.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Blend with unpremultiply", "Mix", "Blend Effects", "Can remove the hard outline you can get with premultiplied blend effects", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Unpremultiply, "Premultiply mode", kNoGroup, 0, "No Change|Unpremultiply|Premultiply");

DeclareIntParam (SetTechnique, "Blend mode", kNoGroup, 0, "In Front|Add|Subtract|Multiply|Screen|Overlay|Soft Light|Hard Light|Exclusion|Lighten|Darken|Average|Difference|Colour|Luminosity|Dodge|Burn");

DeclareFloatParam (Ammount, "Fg Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

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

float4 fn_Premul (sampler S, float2 xy)
{
   float4 retval = IsOutOfBounds (xy) ? 0.0.xxxx : tex2D (S, xy);

   if (Unpremultiply == 1) { retval.rgb /= retval.a; }
   else if (Unpremultiply == 2) retval.rgb *= retval.a;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (InFront)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   return float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Add)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   Fgnd.rgb = min (Fgnd.rgb + Bgnd.rgb, 1.0.xxx);

   return float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Subtract)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   Fgnd.rgb = saturate (Fgnd.rgb - Bgnd.rgb);

   return float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Multiply)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   Fgnd.rgb *= Bgnd.rgb;

   return float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Screen)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   return float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Overlay)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float3 retMin = 2.0 * Bgnd.rgb * Fgnd.rgb;
   float3 retMax = 1.0.xxx - 2.0 * (1.0.xxx - Fgnd.rgb) * (1.0.xxx - Bgnd.rgb);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   Fgnd.r = (Bgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Bgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Bgnd.b <= 0.5) ? retMin.b : retMax.b;

   return float4 (lerp (Bgnd.rgb, saturate (Fgnd.rgb), alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (SoftLight)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float3 retMax = (2.0 * Fgnd.rgb) - 1.0.xxx;
   float3 retMin = Bgnd.rgb * (retMax * (1.0.xxx - Bgnd.rgb) + 1.0.xxx);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   retMax *= sqrt (Bgnd.rgb) - Bgnd.rgb;
   retMax += Bgnd.rgb;

   Fgnd.r = (Fgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b <= 0.5) ? retMin.b : retMax.b;

   return float4 (lerp (Bgnd.rgb, saturate (Fgnd.rgb), alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (HardLight)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float3 retMin = saturate (2.0 * Bgnd.rgb * Fgnd.rgb);
   float3 retMax = saturate (1.0.xxx - 2.0 * (1.0.xxx - Bgnd.rgb) * (1.0.xxx - Fgnd.rgb));

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Exclusion)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb * (1.0.xxx - (2.0 * Fgnd.rgb)));

   return float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Lighten)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   Fgnd.rgb = max (Fgnd.rgb, Bgnd.rgb);

   return float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Darken)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   Fgnd.rgb = min (Fgnd.rgb, Bgnd.rgb);

   return float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Average)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   Fgnd.rgb = (Fgnd.rgb + Bgnd.rgb) / 2.0;

   return float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Difference)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   Fgnd.rgb = abs (Fgnd.rgb - Bgnd.rgb);

   return float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Colour)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float4 blnd = fn_rgb2hsv (Fgnd);
   float4 hsv = fn_rgb2hsv (Bgnd);

   blnd.y = max (blnd.y, hsv.y);
   blnd.z = hsv.z;

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   return float4 (lerp (Bgnd.rgb, fn_hsv2rgb (blnd).rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Luminosity)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float4 blnd = fn_rgb2hsv (Bgnd);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   blnd.zw = (fn_rgb2hsv (Fgnd)).zw;

   return float4 (lerp (Bgnd.rgb, fn_hsv2rgb (blnd).rgb, alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Dodge)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   Fgnd.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (1.0 - Fgnd.r);
   Fgnd.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (1.0 - Fgnd.g);
   Fgnd.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (1.0 - Fgnd.b);

   return float4 (lerp (Bgnd.rgb, min (Fgnd.rgb, 1.0.xxx), alpha), max (Bgnd.a, alpha));
}

DeclareEntryPoint (Burn)
{
   float4 Fgnd = fn_Premul (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = (ReadPixel (Mask, uv3) * Fgnd.a * Ammount).x;

   if (Fgnd.r > 0.0) Fgnd.r = 1.0 - ((1.0 - Bgnd.r) / Fgnd.r);
   if (Fgnd.g > 0.0) Fgnd.g = 1.0 - ((1.0 - Bgnd.g) / Fgnd.g);
   if (Fgnd.b > 0.0) Fgnd.b = 1.0 - ((1.0 - Bgnd.b) / Fgnd.b);

   return float4 (lerp (Bgnd.rgb, min (Fgnd.rgb, 1.0.xxx), alpha), max (Bgnd.a, alpha));
}

