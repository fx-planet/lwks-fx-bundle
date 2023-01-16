// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is really the classic barn door effect, but since a wipe with that name already exists
 in Lightworks another name had to be found.  This version moves the separated foreground
 halves apart rather than just wipes them off.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// User effect BarnDoorSplit_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Barn door split (keyed)", "Mix", "Wipe transitions", "Splits the foreground and separates the halves horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "H start (delta folded)|V start (delta folded)|At start (horizontal)|At end (horizontal)|At start (vertical)|At end (vertical)");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Split, "Split centre", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen_F (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Fgnd = ReadPixel (F, xy1);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Fgnd = ReadPixel (F, xy1);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Barndoor horizontal split start (folded)

DeclarePass (Super_HF)
{ return fn_keygen_F (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Hsplit_F)
{
   float range = (1.0 - Amount) * max (Split, 1.0 - Split);

   float2 xy2 = float2 (range, 0.0);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Fgd = ((xy1.x < Split) && (xy2.x > Split)) ? kTransparentBlack
              : (uv3.x > Split) ? ReadPixel (Super_HF, xy1) : ReadPixel (Super_HF, xy2);

   if (CropEdges && IsOutOfBounds (uv1)) Fgd = kTransparentBlack;

   return lerp (ReadPixel (Fg, uv1), Fgd, Fgd.a);
}


// technique Barndoor vertical split start (folded)

DeclarePass (Super_VF)
{ return fn_keygen_F (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Hsplit_V)
{
   float split = 1.0 - Split;
   float range = (1.0 - Amount) * max (Split, split);

   float2 xy2 = float2 (0.0, range);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Fgd = ((xy1.y < split) && (xy2.y > split)) ? kTransparentBlack
              : (uv3.y > split) ? ReadPixel (Super_VF, xy1) : ReadPixel (Super_VF, xy2);

   if (CropEdges && IsOutOfBounds (uv1)) Fgd = kTransparentBlack;

   return lerp (ReadPixel (Fg, uv1), Fgd, Fgd.a);
}


// technique Barndoor horizontal split start

DeclarePass (Super_HI)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Hsplit_I)
{
   float range = (1.0 - Amount) * max (Split, 1.0 - Split);

   float2 xy2 = float2 (range, 0.0);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Fgd = ((xy1.x < Split) && (xy2.x > Split)) ? kTransparentBlack
              : (uv3.x > Split) ? ReadPixel (Super_HI, xy1) : ReadPixel (Super_HI, xy2);

   if (CropEdges && IsOutOfBounds (uv2)) Fgd = kTransparentBlack;

   return lerp (ReadPixel (Bg, uv2), Fgd, Fgd.a);
}


// technique Barndoor horizontal split end

DeclarePass (Super_HO)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Hsplit_O)
{
   float range = Amount * max (Split, 1.0 - Split);

   float2 xy2 = float2 (range, 0.0);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Fgd = ((xy1.x < Split) && (xy2.x > Split)) ? kTransparentBlack
              : (uv3.x > Split) ? ReadPixel (Super_HO, xy1) : ReadPixel (Super_HO, xy2);

   if (CropEdges && IsOutOfBounds (uv2)) Fgd = kTransparentBlack;

   return lerp (ReadPixel (Bg, uv2), Fgd, Fgd.a);
}


// technique Barndoor vertical split start

DeclarePass (Super_VI)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Vsplit_I)
{
   float split = 1.0 - Split;
   float range = (1.0 - Amount) * max (Split, split);

   float2 xy2 = float2 (0.0, range);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Fgd = ((xy1.y < split) && (xy2.y > split)) ? kTransparentBlack
              : (uv3.y > split) ? ReadPixel (Super_VI, xy1) : ReadPixel (Super_VI, xy2);

   if (CropEdges && IsOutOfBounds (uv2)) Fgd = kTransparentBlack;

   return lerp (ReadPixel (Bg, uv2), Fgd, Fgd.a);
}


// technique Barndoor vertical split end

DeclarePass (Super_VO)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Vsplit_O)
{
   float split = 1.0 - Split;
   float range = Amount * max (Split, split);

   float2 xy2 = float2 (0.0, range);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Fgd = ((xy1.y < split) && (xy2.y > split)) ? kTransparentBlack
              : (uv3.y > split) ? ReadPixel (Super_VO, xy1) : ReadPixel (Super_VO, xy2);

   if (CropEdges && IsOutOfBounds (uv2)) Fgd = kTransparentBlack;

   return lerp (ReadPixel (Bg, uv2), Fgd, Fgd.a);
}

