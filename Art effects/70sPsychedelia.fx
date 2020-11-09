// @Maintainer jwrl
// @Released 2020-11-08
// @Author jwrl
// @Created 2016-05-11
// @see https://www.lwks.com/media/kunena/attachments/6375/70s_psych_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Contours_7_2016-08-16.png

/**
 70s Psychedelia (70sPsychedelia.fx) creates a wide range of contouring effects from your
 original image.  Mixing over the original image can be adjusted from 0% to 100%, and the
 hue, saturation, and contour pattern can be tweaked.  The contours can also be smudged
 by a variable amount.

 This is an entirely original effect, but feel free to do what you will with it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 70sPsychedelia.fx
//
// Version history:
//
// Update 2020-11-08 jwrl.
// Added CanSize switch for 2021 support.
//
// Major rewrite 10 June 2020 jwrl.
// Changed sampler addressing to defaults.  On some GPUs apparently the mirror addressing
// previously used imposed too heavy a load and can even crash Lightworks.
// Because of that, mirrored the edge pixels internally using the function fn_tex2D().
// Merged previous ps_gene() and ps_hueSat() into ps_contour().
// Simplified the antialias to a quarter of its original size.
// Simplified the HSV processing considerably.
// Modified the smudger to give a smoother result.
// Added gain adjustment for contrast enhancement.
// Removed the now redundant monochrome trimming.
//
// Parameter alterations:
// Changed Contour to range from 0 to 12 and clamped it to a minimum of 0.0.
// Increased Smudger's blur amount and clamped it to go no lower than 0.0.
// Changed Saturation to run from 0% to 200%, using the "DisplayAsPercentage" flag.
// Replaced Monochrome parameter with Gain.
//
// Update 2020-11-08 jwrl.
// Added CanSize switch for 2021 support.
//
// Modified 23 December 2018 jwrl.
// Changed filename and subcategory.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified 29 September 2018 jwrl.
// Added notes to header.
//
// Modified 2018-07-09 jwrl:
// Removed dependency on pixel size.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles interlaced media.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "70s Psychedelia";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "An extreme highly adjustable posterization effect";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Contours : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Inp>; };

sampler s_Contours = sampler_state { Texture = <Contours>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Pattern mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Contouring
<
   string Description = "Contour level";
   float MinVal = 0.0;
   float MaxVal = 12.0;
> = 12.0;

float Smudge
<
   string Description = "Smudger";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float4 ColourOne
<
   string Group = "Colours";
   string Description = "Colour one";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

float4 ColourTwo
<
   string Group = "Colours";
   string Description = "Colour two";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 0.0, 1.0 };

float4 ColourBase
<
   string Group = "Colours";
   string Description = "Base colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float HueShift
<
   string Group = "Colours";
   string Description = "Hue";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

float Saturation
<
   string Group = "Colours";
   string Description = "Saturation";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Gain
<
   string Group = "Colours";
   string Description = "Gain";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LUMA_VAL   float3 (0.3, 0.59, 0.11)
#define HUE        float3 (1.0, 2.0 / 3.0, 1.0 / 3.0)

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   float2 xy = 1.0.xx - abs (1.0.xx - abs (uv));   // Mirrors the edge pixels if overflow

   return tex2D (s_Sampler, xy);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_contour (float2 uv : TEXCOORD1) : COLOR
{
   float angle = 0.0;

   // The first thing that is done is to blur the image slightly.  This is done to
   // minimise any noise, aliassing, or other video artefacts before contouring.

   float2 halftex = float2 (1.0, _OutputAspectRatio) / (_OutputWidth + _OutputWidth);
   float2 scale   = halftex * 4.25;
   float2 xy, xy1 = uv + halftex;

   float4 retval = fn_tex2D (s_Input, uv);

   for (int i = 0; i < 12; i++) {
      sincos (angle, xy.y, xy.x);
      xy *= scale;
      retval += fn_tex2D (s_Input, xy + xy1);
      angle += 30.0;
   }

   retval /= 13.0;

   // The next block of code creates the contours, mixing the three colours

   float amtC = max (Contouring, 0.0) + 0.325;
   float Col1 = frac ((0.5 + retval.r + retval.b) * 2.242 * amtC);
   float Col2 = frac ((0.5 + retval.g) * amtC);

   float3 rgb = max (ColourBase, max ((ColourOne * Col1), (ColourTwo * Col2))).rgb;

   rgb += min (ColourBase, min (ColourOne * Col1, ColourTwo * Col2)).rgb;
   rgb /= 2.0;

   // This is a synthetic luminance value to preserve contrast when using
   // heavily saturated colours.

   float luma  = saturate (Col1 * 0.333333 + Col2 * 0.666667);

   // From here on we use a modified version of RGB-HSV-RGB conversion to process
   // the hue and saturation adjustments.  The V component is replaced with the
   // synthetic luma value, which enhances the contouring produced by the effect.

   float4 p = lerp (float4 (rgb.bg, -1.0, 2.0 / 3.0),
                    float4 (rgb.gb, 0.0, -1.0 / 3.0), step (rgb.b, rgb.g));
   float4 q = lerp (float4 (p.xyw, rgb.r), float4 (rgb.r, p.yzx), step (p.x, rgb.r));

   float d = q.x - min (q.w, q.y);

   float3 hsv = float3 (abs (q.z + (q.w - q.y) / (6.0 * d)), d / q.x, luma);

   // Hue shift and saturation is now adjusted using frac() to control overflow in
   // the hue.  Range limiting for saturation only needs to ensure it's positive.

   hsv.x += (clamp (HueShift, -180.0, 180.0) / 360.0) + 1.0;
   hsv.x  = frac (hsv.x);
   hsv.y *= max (Saturation, 0.0);

   // Finally we convert back to RGB, adjust the gain and get out.

   rgb = saturate (abs (frac (hsv.xxx + HUE) * 6.0 - 3.0.xxx) - 1.0.xxx);
   rgb = hsv.z * lerp (1.0.xxx, rgb, hsv.y);
   rgb = saturate (((rgb - 0.5.xxx) * Gain) + 0.5.xxx);

   return float4 (rgb, retval.a);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd   = tex2D (s_Input, uv);
   float4 retval = tex2D (s_Contours, uv);

   // The smudger is implemented as a variation on a radial blur first.  The range
   // of adjustment is limited to run between zero and an arbitrary value of 0.002.

   float2 xy1, xy2 = float2 (1.0, _OutputAspectRatio) * max (Smudge, 0.0) * 0.002;

   float angle = 0.0;

   for (int i = 0; i < 15; i++) {
      sincos (angle, xy1.x, xy1.y);    // Put sin into x component, cos into y.
      xy1 *= xy2;                      // Scale xy1 by aspect ratio and smudge amount.

      retval += fn_tex2D (s_Contours, uv + xy1);   // Sample at 0 radians first, then
      retval += fn_tex2D (s_Contours, uv - xy1);   // at Pi radians (180 degrees).

      xy1 *= 1.5;                      // Offset xy1 by 50% for a second sample pass.

      retval += fn_tex2D (s_Contours, uv + xy1);
      retval += fn_tex2D (s_Contours, uv - xy1);

      angle += 12.0;                   // Add 12 radians to the angle and go again.
   }

   // Divide the smudger result by four times the number of loop passes plus one.  This
   // value is because of the number of samples inside the loop plus the initial one.

   retval /= 61.0;

   // We then composite the result with the input image and quit.

   return lerp (Fgnd, retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Psychedelia
{
   pass P_1
   < string Script = "RenderColorTarget0 = Contours;"; >
   { PixelShader = compile PROFILE ps_contour (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
