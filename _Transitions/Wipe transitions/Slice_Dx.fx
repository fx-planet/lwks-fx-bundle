// @Maintainer jwrl
// @Released 2023-01-29
// @Author jwrl
// @Created 2023-01-29

/**
 This transition splits the outgoing image into strips which then move off either
 horizontally or vertically to reveal the incoming image.  This updated version adds
 the ability to choose whether to wipe the outgoing image out or the incoming image in.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Slice_Dx.fx
//
// Version history:
//
// Built 2023-01-29 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Slice transition", "Mix", "Wipe transitions", "Separates and splits the image into strips which move on or off horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Mode, "Strip type", kNoGroup, 0, "Mode A|Mode B");
DeclareIntParam (SetTechnique, "Strip direction", kNoGroup, 1, "Right to left|Left to right|Top to bottom|Bottom to top");

DeclareBoolParam (Direction, "Invert direction", kNoGroup, false);

DeclareFloatParam (StripNumber, "Strip number", kNoGroup, kNoFlags, 10.0, 5.0, 20.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Slice right to left

DeclarePass (Fgd_0)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd_0)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Slice_Right)
{
   float strips   = max (2.0, round (StripNumber));
   float amount_0 = Direction ? 1.0 - Amount : Amount;
   float amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
   float amount_2 = pow (amount_0, 3.0);

   float2 xy = uv3;

   xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_1) + amount_2
                       : (ceil ((1.0 - xy.y) * strips) * amount_1) + amount_2;

   if (Direction)
      return (IsOutOfBounds (xy)) ? tex2D (Fgd_0, uv3) : tex2D (Bgd_0, xy);

   return (IsOutOfBounds (xy)) ? tex2D (Bgd_0, uv3) : tex2D (Fgd_0, xy);
}

//-----------------------------------------------------------------------------------------//

// technique Slice left to right

DeclarePass (Fgd_1)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd_1)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Slice_Left)
{
   float strips   = max (2.0, round (StripNumber));
   float amount_0 = Direction ? 1.0 - Amount : Amount;
   float amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
   float amount_2 = pow (amount_0, 3.0);

   float2 xy = uv3;

   xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_1) + amount_2
                       : (ceil ((1.0 - xy.y) * strips) * amount_1) + amount_2;

   if (Direction)
      return (IsOutOfBounds (xy)) ? tex2D (Fgd_1, uv3) : tex2D (Bgd_1, xy);

   return (IsOutOfBounds (xy)) ? tex2D (Bgd_1, uv3) : tex2D (Fgd_1, xy);
}

//-----------------------------------------------------------------------------------------//

// technique Slice top to bottom

DeclarePass (Fgd_2)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd_2)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Slice_top)
{
   float strips   = max (2.0, round (StripNumber));
   float amount_0 = Direction ? 1.0 - Amount : Amount;
   float amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
   float amount_2 = pow (amount_0, 3.0);

   float2 xy = uv3;

   xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_1) + amount_2
                       : (ceil ((1.0 - xy.x) * strips) * amount_1) + amount_2;

   if (Direction)
      return (IsOutOfBounds (xy)) ? tex2D (Fgd_2, uv3) : tex2D (Bgd_2, xy);

   return (IsOutOfBounds (xy)) ? tex2D (Bgd_2, uv3) : tex2D (Fgd_2, xy);
}

//-----------------------------------------------------------------------------------------//

// technique Slice bottom to top

DeclarePass (Fgd_3)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd_3)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Slice_Bottom)
{
   float strips   = max (2.0, round (StripNumber));
   float amount_0 = Direction ? 1.0 - Amount : Amount;
   float amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
   float amount_2 = pow (amount_0, 3.0);

   float2 xy = uv3;

   xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_1) + amount_2
                       : (ceil ((1.0 - xy.x) * strips) * amount_1) + amount_2;

   if (Direction)
      return (IsOutOfBounds (xy)) ? tex2D (Fgd_3, uv3) : tex2D (Bgd_3, xy);

   return (IsOutOfBounds (xy)) ? tex2D (Bgd_3, uv3) : tex2D (Fgd_3, xy);
}

