// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This is really the classic barn door effect, but since a wipe with that name already exists
 in Lightworks another name had to be found.  This version moves the separated foreground
 halves apart rather than just wipes them off.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// User effect BarnDoorSplit_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
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
DeclareIntParam (Ttype, "Transition position", kNoGroup, 2, "At start if delta key folded|At start if non-delta unfolded|Standard transitions");
DeclareIntParam (SetTechnique, "Transition direction", kNoGroup, 0, "Horizontal|Vertical");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Split, "Split centre", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen_F (sampler F, float2 xy1, float2 xy2)
{
   float4 Fgnd = tex2D (F, xy2);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (Bg, xy1);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

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

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique BarnDoorSplit_Kx_H

DeclarePass (Bg_H)
{ return Ttype == 0 ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (Super_H)
{ return Ttype == 0 ? fn_keygen_F (Bg_H, uv2, uv3) : fn_keygen (Bg_H, uv1, uv3); }

DeclareEntryPoint (BarnDoorSplit_Kx_H)
{
   float amount = Ttype == 2 ? Amount : 1.0 - Amount;
   float range  = amount * max (Split, 1.0 - Split);

   float2 xy3 = Ttype == 0 ? uv1 : uv2;
   float2 xy2 = float2 (range, 0.0);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Bgd = Ttype == 0 ? ReadPixel (Fg, uv1) : tex2D (Bg_H, uv3);
   float4 Fgd = ((xy1.x < Split) && (xy2.x > Split)) ? kTransparentBlack
              : (uv3.x > Split) ? tex2D (Super_H, xy1) : tex2D (Super_H, xy2);

   if (CropEdges && IsOutOfBounds (xy3)) Fgd = kTransparentBlack;

   return lerp (Bgd, Fgd, Fgd.a);
}

//-----------------------------------------------------------------------------------------//

// technique BarnDoorSplit_Kx_V

DeclarePass (Bg_V)
{ return Ttype == 0 ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (Super_V)
{ return Ttype == 0 ? fn_keygen_F (Bg_V, uv2, uv3) : fn_keygen (Bg_V, uv1, uv3); }

DeclareEntryPoint (BarnDoorSplit_Kx_V)
{
   float amount = Ttype == 2 ? Amount : 1.0 - Amount;
   float split = 1.0 - Split;
   float range = amount * max (Split, split);

   float2 xy3 = Ttype == 0 ? uv1 : uv2;
   float2 xy2 = float2 (0.0, range);
   float2 xy1 = uv3 - xy2;

   xy2 += uv3;

   float4 Bgd = Ttype == 0 ? ReadPixel (Fg, uv1) : tex2D (Bg_H, uv3);
   float4 Fgd = ((xy1.y < split) && (xy2.y > split)) ? kTransparentBlack
              : (uv3.y > split) ? tex2D (Super_V, xy1) : tex2D (Super_V, xy2);

   if (CropEdges && IsOutOfBounds (xy3)) Fgd = kTransparentBlack;

   return lerp (Bgd, Fgd, Fgd.a);
}

