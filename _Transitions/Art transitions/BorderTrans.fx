// @Maintainer jwrl
// @Released 2023-08-02
// @Author jwrl
// @Created 2018-06-11

/**
 An effect transition that generates borders using a difference or delta key then uses
 them to make the image materialise from four directions or blow apart in four directions.
 Each quadrant is independently coloured.

 If the foreground and/or background resolution differ from the sequence resolution it
 will be necessary to adjust the delta key trim.  Normally you won't need to do this.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BorderTrans.fx
//
// Version history:
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-09 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-03-06 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Border transition", "Mix", "Art transitions", "The foreground materialises from four directions or dematerialises to four directions", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Radius, "Thickness", "Borders", kNoFlags, 0.3, 0.0, 1.0);
DeclareFloatParam (Displace, "Displacement", "Borders", kNoFlags, 0.5, 0.0, 1.0);

DeclareColourParam (Colour_1, "Outline 1", "Colours", kNoFlags, 0.6, 0.9, 1.0, 1.0);
DeclareColourParam (Colour_2, "Outline 2", "Colours", kNoFlags, 0.3, 0.6, 1.0, 1.0);
DeclareColourParam (Colour_3, "Outline 3", "Colours", kNoFlags, 0.9, 0.6, 1.0, 1.0);
DeclareColourParam (Colour_4, "Outline 4", "Colours", kNoFlags, 0.6, 0.3, 1.0, 1.0);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define NotEqual(XY_1,XY_2) (any ((XY_1 - XY_2) != 0.0))

#define DIVISOR  61.0

#define LOOP_1   30
#define ANGLE_1  0.10472   // 6 degrees in radians

#define LOOP_2   24
#define ANGLE_2  0.1309    // 7.5 degrees

#define HALF_PI  1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (Bg, uv2);
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      Fgnd = ReadPixel (Fg, uv1);
      Bgnd = ReadPixel (Bg, uv2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

DeclarePass (Bgd)
{ return (SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (Super)
{
   float4 retval = ReadPixel (Fgd, uv3);

   if (ShowKey) return lerp (kTransparentBlack, retval, retval.a);

   float2 radius = float2 (1.0, _OutputAspectRatio) * 0.00125;
   float2 xy1, xy2;

   float4 input  = retval;

   float amount = saturate (_Progress * 15.0);

   amount = min (amount, saturate ((1.0 - _Progress) * 15.0));

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy1.x, xy1.y);
      xy1 *= radius;
      xy2  = uv3 - xy1;
      xy1 += uv3;
      retval += ReadPixel (Fgd, xy1);
      retval += ReadPixel (Fgd, xy2);
   }

   return lerp (input, retval / DIVISOR, amount);
}

DeclarePass (Border_1)
{
   float4 retval = kTransparentBlack;

   if (!ShowKey && (Radius != 0.0)) {
      float radScale = SwapDir ? cos (Amount * HALF_PI) : sin (Amount * HALF_PI);

      float2 radius = float2 (1.0, _OutputAspectRatio) * Radius * radScale * 0.018;
      float2 xy1, xy2;

      for (int i = 0; i < LOOP_1; i++) {
         sincos ((i * ANGLE_1), xy1.x, xy1.y);
         xy1 *= radius;
         xy2  = uv3 - xy1;
         xy1 += uv3;
         retval = max (retval, ReadPixel (Super, xy1));
         retval = max (retval, ReadPixel (Super, xy2));
      }
   }

   return retval;
}

DeclarePass (Border_2)
{
   float4 retval = ReadPixel (Border_1, uv3);

   if (!ShowKey && (Radius != 0.0)) {
      float radScale = SwapDir ? cos (Amount * HALF_PI) : sin (Amount * HALF_PI);
      float alpha = saturate (ReadPixel (Super, uv3).a * 2.0);

      float2 radius = float2 (1.0, _OutputAspectRatio) * Radius * radScale * 0.012;
      float2 xy1, xy2;

      for (int i = 0; i < LOOP_2; i++) {
         sincos ((i * ANGLE_2), xy1.x, xy1.y);
         xy1 *= radius;
         xy2  = uv3 - xy1;
         xy1 += uv3;
         retval = max (retval, ReadPixel (Border_1, xy1));
         retval = max (retval, ReadPixel (Border_1, xy2));
      }

      retval = lerp (retval, kTransparentBlack, alpha);
   }

   return retval;
}

DeclareEntryPoint (BorderTrans)
{
   if (ShowKey) return lerp (kTransparentBlack, tex2D (Super, uv3), tex2D (Mask, uv3).x);

   float2 xy1 = (Displace / 2.0).xx;

   if (SwapDir) { xy1 *= 1.0 - Amount; }
   else {
      xy1 *= Amount;
      xy1.x = -xy1.x;
   }

   float2 xy2 = float2 (xy1.x / _OutputAspectRatio, -(xy1.y * _OutputAspectRatio));
   float2 xy3 = uv3 - xy1;
   float2 xy4 = uv3 + xy1;

   xy1  = uv3 - xy2;
   xy2 += uv3;

   float4 border = tex2D (Super, xy1);
   float4 retval = kTransparentBlack;
   float4 Bgnd = tex2D (Bgd, uv3);

   if (NotEqual (xy1, xy2)) {
      retval = tex2D (Super, xy2); border = lerp (border, retval, retval.a);
      retval = tex2D (Super, xy3); border = lerp (border, retval, retval.a);
      retval = tex2D (Super, xy4); border = lerp (border, retval, retval.a);

      retval = Colour_1 * tex2D (Border_2, xy1).a;
      retval = lerp (retval, Colour_2, tex2D (Border_2, xy2).a);
      retval = lerp (retval, Colour_3, tex2D (Border_2, xy3).a);
      retval = lerp (retval, Colour_4, tex2D (Border_2, xy4).a);

      float Outline, Opacity;

      if (SwapDir) { sincos ((Amount * HALF_PI), Outline, Opacity); }
      else sincos ((Amount * HALF_PI), Opacity, Outline);

      Opacity = 1.0 - sin (Opacity * HALF_PI);

      float4 Fgnd = lerp (Bgnd, border, border.a * Opacity);

      retval = lerp (Fgnd, retval, retval.a * Outline);
   }
   else retval = lerp (Bgnd, border, border.a);

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

