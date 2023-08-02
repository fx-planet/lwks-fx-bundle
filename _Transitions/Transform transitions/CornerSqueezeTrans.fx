// @Maintainer jwrl
// @Released 2023-08-02
// @Author jwrl
// @Created 2017-08-26

/**
 This is similar to the alpha corner squeeze effect, except that it expands the blended
 foreground from the corners or compresses it to the corners of the screen.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// User effect CornerSqueezeTrans.fx
//
// Version history:
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-14 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
// Changed subcategory from "DVE transitions" to "Transform transitions".
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Corner squeeze transition", "Mix", "Transform transitions", "Squeezes or expands the foreground to or from the corners of the screen", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Ttype, "Transition", "Standard video", 0, "Squeeze to corners|Expand from corners");

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   if (!Blended) return float4 ((ReadPixel (Fg, uv1)).rgb, 1.0);

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
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

DeclarePass (Horiz)
{
   float4 retval;

   float negAmt, posAmt;

   float2 xy1, xy2;

   if ((Blended && SwapDir) || (!Blended && Ttype)) {
      negAmt = Amount * 0.5;
      posAmt = 1.0 - negAmt;

      xy1 = float2 ((uv3.x + Amount - 1.0) / Amount, uv3.y);
      xy2 = float2 (uv3.x / Amount, uv3.y);
   }
   else {
      negAmt = 1.0 - Amount;
      posAmt = (1.0 + Amount) * 0.5;

       xy1 = float2 ((uv3.x - Amount) / negAmt, uv3.y);
       xy2 = float2 (uv3.x / negAmt, uv3.y);

       negAmt *= 0.5;
   }

   if (!Blended && Ttype) {
      retval = (uv3.x > posAmt) ? tex2D (Bgd, xy1)
             : (uv3.x < negAmt) ? tex2D (Bgd, xy2) : kTransparentBlack;
   }
   else retval = (uv3.x > posAmt) ? tex2D (Fgd, xy1) :
                 (uv3.x < negAmt) ? tex2D (Fgd, xy2) : kTransparentBlack;

   return retval;
}

DeclareEntryPoint (CornerSqueezeTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);

   if (Blended && ShowKey) { return lerp (kTransparentBlack, Fgnd, Fgnd.a * tex2D (Mask, uv3).x); }

   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg = Blended ? Bgnd : Fgnd;
   float4 retval = !Blended && Ttype ? Fgnd : Bgnd;

   float negAmt, posAmt;

   float2 xy1, xy2;

   if ((Blended && SwapDir) || (!Blended && Ttype)) {
      negAmt = Amount * 0.5;
      posAmt = 1.0 - negAmt;

      xy1 = float2 (uv3.x, (uv3.y + Amount - 1.0) / Amount);
      xy2 = float2 (uv3.x, uv3.y / Amount);
   }
   else {
      negAmt = 1.0 - Amount;
      posAmt = (1.0 + Amount) * 0.5;

      xy1 = float2 (uv3.x, (uv3.y - Amount) / negAmt);
      xy2 = float2 (uv3.x, uv3.y / negAmt);

      negAmt *= 0.5;
   }

   Fgnd = (uv3.y > posAmt) ? tex2D (Horiz, xy1) :
          (uv3.y < negAmt) ? tex2D (Horiz, xy2) : kTransparentBlack;

   retval = lerp (retval, Fgnd, Fgnd.a);

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}
