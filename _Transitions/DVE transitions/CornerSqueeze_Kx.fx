// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This is similar to the alpha corner squeeze effect, except that it expands the blended
 foreground from the corners or compresses it to the corners of the screen.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// User effect CornerSqueeze_Fx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Corner squeeze (keyed)", "Mix", "DVE transitions", "Squeezes or expands the foreground to or from the corners of the screen", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta unfolded|Standard transitions");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler B, float2 xy1, float2 xy2)
{
   float4 Fgnd = ReadPixel (Fg, xy1);

   if (Source == 0) {
      float4 Bgnd = tex2D (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 fn_horiz (sampler Super, float2 uv)
{
   float negAmt = Amount * 0.5;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 ((uv.x + Amount - 1.0) / Amount, uv.y);
   float2 xy2 = float2 (uv.x / Amount, uv.y);

   float4 retval = (uv.x > posAmt) ? tex2D (Super, xy1)
                 : (uv.x < negAmt) ? tex2D (Super, xy2) : kTransparentBlack;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique CornerSqueeze_Fx_F

DeclarePass (Bg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Super_F)
{
   float4 Fgnd = tex2D (Bg_F, uv3);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (Bg, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

DeclarePass (Horiz_F)
{ return fn_horiz (Super_F, uv3); }

DeclareEntryPoint (CornerSqueeze_F)
{
   float negAmt = Amount * 0.5;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv3.x, (uv3.y + Amount - 1.0) / Amount);
   float2 xy2 = float2 (uv3.x, uv3.y / Amount);

   float4 Fgnd = (uv3.y > posAmt) ? tex2D (Horiz_F, xy1)
               : (uv3.y < negAmt) ? tex2D (Horiz_F, xy2) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (uv1)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_F, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique CornerSqueeze_Fx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclarePass (Horiz_I)
{ return fn_horiz (Super_I, uv3); }

DeclareEntryPoint (CornerSqueeze_I)
{
   float negAmt = Amount * 0.5;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv3.x, (uv3.y + Amount - 1.0) / Amount);
   float2 xy2 = float2 (uv3.x, uv3.y / Amount);

   float4 Fgnd = (uv3.y > posAmt) ? tex2D (Horiz_I, xy1)
               : (uv3.y < negAmt) ? tex2D (Horiz_I, xy2) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (uv2)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_I, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique CornerSqueeze_Fx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclarePass (Horiz_O)
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) * 0.5;

   float2 xy1 = float2 ((uv3.x - Amount) / negAmt, uv3.y);
   float2 xy2 = float2 (uv3.x / negAmt, uv3.y);

   negAmt *= 0.5;

   float4 retval = (uv3.x > posAmt) ? tex2D (Super_O, xy1)
                 : (uv3.x < negAmt) ? tex2D (Super_O, xy2) : kTransparentBlack;

   return retval;
}

DeclareEntryPoint (CornerSqueeze_O)
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) * 0.5;

   float2 xy1 = float2 (uv3.x, (uv3.y - Amount) / negAmt);
   float2 xy2 = float2 (uv3.x, uv3.y / negAmt);

   negAmt *= 0.5;

   float4 Fgnd = (uv3.y > posAmt) ? tex2D (Horiz_O, xy1)
               : (uv3.y < negAmt) ? tex2D (Horiz_O, xy2) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (uv2)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_O, uv3), Fgnd, Fgnd.a);
}

