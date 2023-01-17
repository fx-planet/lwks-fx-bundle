// @Maintainer jwrl
// @Released 2023-01-17
// @Author jwrl
// @Released 2023-01-17

/**
 This effect is a simple 2D DVE with the ability to apply a circular, diamond or square
 shaped mask.  The foreground image can be sized, positioned, flipped and flopped.  Since
 flipping or flopping will change the direction of movement of the foreground position
 parameters it may be advisable to adjust the position before changing the foreground
 orientation.

 The aspect ratio of the mask can be adjusted, so ellipses and rectangles can be created.
 The aspect ratio will also affect the edge softness and border thickness.  Sufficient
 range has been given to the mask size parameter to allow the frame to be filled if
 needed.  If the foreground aspect ratio and size doesn't match the background size and
 aspect ratio any foreground overflow will be filled with opaque black.

 The mask can be repositioned, taking the foreground image with it.  The edges of the
 mask can be bordered with a bicolour shaded surround.  Drop shadowing is included, and
 the border and shadow can be independently feathered.

 There is no LW masking provided, since the vignette is felt to be sufficient for most
 reasonable needs.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DVEvignette.fx
//
// Version history:
//
// Built 2023-01-17 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("DVE with vignette", "DVE", "DVE Extras", "A simple DVE with circular, diamond or square shaped masking", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (FgSize, "Size change", "Foreground", kNoFlags, 0.0, -1.0, 1.0);

DeclareIntParam (FlipFlop, "Foreground orientation", "Foreground", 0, "Normal|Flip|Flop|Flip / flop");

DeclareFloatParam (FgPosX, "Position", "Foreground", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (FgPosY, "Position", "Foreground", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareIntParam (SetTechnique, "Mask shape", "Mask", 0, "Circle / ellipse|Square / rectangle|Diamond");

DeclareFloatParam (Radius, "Mask size", "Mask", kNoFlags, 0.125, 0.0, 1.0);
DeclareFloatParam (Aspect, "Aspect ratio", "Mask", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (OverlayPosX, "Centre", "Mask", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (OverlayPosY, "Centre", "Mask", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (BorderWidth, "Width", "Border", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (BorderFeather, "Edge softness", "Border", kNoFlags, 0.05, 0.0, 1.0);

DeclareColourParam (BorderColour, "Inner colour", "Border", kNoFlags, 0.2, 0.8, 0.8, 1.0);
DeclareColourParam (BorderColour_1, "Outer colour", "Border", kNoFlags, 0.2, 0.1, 1.0, 1.0);

DeclareFloatParam (Shadow, "Opacity", "Drop shadow", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (ShadowSoft, "Softness", "Drop shadow", kNoFlags, 0.05, 0.0, 1.0);

DeclareFloatParam (ShadowX, "Offset", "Drop shadow", "SpecifiesPointX", 0.25, -1.0, 1.0);
DeclareFloatParam (ShadowY, "Offset", "Drop shadow", "SpecifiesPointY", 0.25, -1.0, 1.0);

DeclareFloatParam (BgSize, "Size change", "Background", kNoFlags, 0.0, -1.0, 1.0);

DeclareIntParam (BgFlipFlop, "Background orientation", "Background", 0, "Normal|Flip|Flop|Flip / flop");

DeclareFloatParam (BgPosX, "Position", "Background", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (BgPosY, "Position", "Background", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareIntParam (_FgOrientation);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0,1.0).xxxy

#define odd(X) (X - floor (X / 2.0) * 2.0)

#define RADIUS_SCALE  1.6666666667
#define SQUARE_SCALE  2.0
#define FEATHER_SCALE 0.05
#define FEATHER_DMND  0.0375
#define FEATHER_SOFT  0.0005
#define BORDER_SCALE  0.1
#define BORDER_DMND   0.075

#define CIRCLE        2.0327959639
#define SQUARE        2.0
#define DIAMOND       1.4142135624

#define MIN_SIZE      0.9
#define MAX_SIZE      9.0
#define MAX_ASPECT    5.0
#define MIN_ASPECT    0.9999999999

#define FLIP          1
#define FLOP          2
#define FLIP_FLOP     3

#define FRAME_CENTRE  0.5.xx

#define HALF_PI       1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_main (sampler Fgd, float2 uv, sampler Bgd, float2 uv_2)
{
   float2 xy1 = uv - float2 (ShadowX, ShadowY * _OutputAspectRatio) * 0.04;
   float2 xy2 = float2 (1.0, _OutputAspectRatio) * FEATHER_SOFT;
   float2 xy3 = (uv_2 - FRAME_CENTRE) * (1.0 - (max (BgSize, 0.0) * MIN_SIZE) - (min (BgSize, 0.0) * MAX_SIZE));

   xy3.x = odd (BgFlipFlop)  ? 0.5 + BgPosX - xy3.x : 0.5 + xy3.x - BgPosX;
   xy3.y = BgFlipFlop > FLIP ? 0.5 - xy3.y - BgPosY : 0.5 + xy3.y + BgPosY;

   float alpha    = IsOutOfBounds (xy1) ? 0.0 : tex2D (Fgd, xy1).a * 0.03125;
   float softness = ShadowSoft * 4.0;
   float amount   = 0.125;
   float feather  = 0.0;

   for (int i = 0; i < 4; i++) {
      feather += softness;
      amount  /= 2.0;

      alpha += tex2D (Fgd, xy1 + float2 (xy2.x, 0.0) * feather).a * amount;
      alpha += tex2D (Fgd, xy1 - float2 (xy2.x, 0.0) * feather).a * amount;

      alpha += tex2D (Fgd, xy1 + float2 (0.0, xy2.y) * feather).a * amount;
      alpha += tex2D (Fgd, xy1 - float2 (0.0, xy2.y) * feather).a * amount;

      alpha += tex2D (Fgd, xy1 + xy2 * feather).a * amount;
      alpha += tex2D (Fgd, xy1 - xy2 * feather).a * amount;

      alpha += tex2D (Fgd, xy1 + float2 (xy2.x, -xy2.y) * feather).a * amount;
      alpha += tex2D (Fgd, xy1 - float2 (xy2.x, -xy2.y) * feather).a * amount;
   }

   alpha = saturate (alpha * Shadow * 0.5);

   float4 Fgnd   = ReadPixel (Fgd, uv);
   float4 Bgnd   = ReadPixel (Bgd, xy3);
   float4 retval = float4 (lerp (Bgnd.rgb, 0.0.xxx, alpha), Bgnd.a);

   return lerp (retval, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Technique Circular DVE vignette

DeclarePass (cFg)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclarePass (cInp)
{
   float2 xy1 = float2 (uv3.x - OverlayPosX, uv3.y + OverlayPosY);
   float2 FgPos = float2 (FgPosX, -FgPosY);

   if (odd (FlipFlop)) {
      xy1.x = 0.5 - xy1.x;
      FgPos.x = -FgPos.x;
   }
   else xy1.x += 0.5;

   if (FlipFlop > FLIP) {
      xy1.y = 1.5 - xy1.y;
      FgPos.y = -FgPos.y;
   }
   else xy1.y -= 0.5;

   float aspctR = Aspect - 0.5;
   float size   = 1.0 - (max (FgSize, 0.0) * MIN_SIZE) - (min (FgSize, 0.0) * MAX_SIZE);
   float scope  = max (0.0, Radius) * CIRCLE;
   float fthr   = BorderFeather * FEATHER_SCALE;
   float border = scope + BorderWidth * BORDER_SCALE;
   float offset = scope - fthr;
   float mix    = border + fthr - offset;

   aspctR = 1.0 - max (aspctR, 0.0) - (min (aspctR, 0.0) * 8.0);

   float2 range = FRAME_CENTRE - xy1;
   float2 xy2   = FRAME_CENTRE - (range * size) - FgPos;

   float radius = length (float2 (range.x / aspctR, (range.y / _OutputAspectRatio) * aspctR)) * RADIUS_SCALE;
   float alpha  = (fthr > 0.0) ? saturate ((border + fthr - radius) / (fthr * 2.0)) : 1.0;

   mix = (mix > 0.0) ? saturate ((radius - offset) / mix) : 0.0;

   float4 retval = IsOutOfBounds (xy2) ? BLACK : tex2D (cFg, xy2);
   float4 colour = float4 (lerp (BorderColour.rgb, BorderColour_1.rgb, mix), alpha);

   if (radius > border + fthr) return kTransparentBlack;

   if (radius < offset) return retval;

   alpha  = (fthr > 0.0) ? saturate ((scope + fthr - radius) / (fthr * 2.0)) : 0.0;
   colour = lerp (colour, retval, alpha);
   mix    = sin (min (BorderWidth * 10.0, 1.0) * HALF_PI);

   return lerp (float4 (retval.rgb, alpha), colour, mix);
}

DeclareEntryPoint (DVEvignetteCircle)
{ return fn_main (cInp, uv3, Bg, uv2); }


// Technique Square DVE vignette

DeclarePass (sFg)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclarePass (sInp)
{
   float2 xy1 = float2 (uv3.x - OverlayPosX, uv3.y + OverlayPosY);
   float2 FgPos = float2 (FgPosX, -FgPosY);

   if (odd (FlipFlop)) {
      xy1.x = 0.5 - xy1.x;
      FgPos.x = -FgPos.x;
   }
   else xy1.x += 0.5;

   if (FlipFlop > FLIP) {
      xy1.y = 1.5 - xy1.y;
      FgPos.y = -FgPos.y;
   }
   else xy1.y -= 0.5;

   float aspctR = Aspect - 0.5;
   float size   = 1.0 - (max (FgSize, 0.0) * MIN_SIZE) - (min (FgSize, 0.0) * MAX_SIZE);
   float scope  = max (0.0, Radius) * SQUARE;
   float fthr   = BorderFeather * FEATHER_SCALE;
   float border = scope + BorderWidth * BORDER_SCALE;
   float offset = scope - fthr;
   float mix    = border + fthr - offset;

   aspctR = 1.0 - max (aspctR, 0.0) - (min (aspctR, 0.0) * 8.0);

   float2 range = FRAME_CENTRE - xy1;
   float2 xy2   = FRAME_CENTRE - (range * size) - FgPos;

   float square = max (abs (range.x / aspctR), abs (range.y * aspctR / _OutputAspectRatio)) * SQUARE_SCALE;
   float alpha  = (fthr > 0.0) ? saturate ((border + fthr - square) / (fthr * 2.0)) : 1.0;

   mix = (mix > 0.0) ? saturate ((square - offset) / mix) : 0.0;

   float4 retval = IsOutOfBounds (xy2) ? BLACK : tex2D (sFg, xy2);
   float4 colour = float4 (lerp (BorderColour.rgb, BorderColour_1.rgb, mix), alpha);

   if (square > border + fthr) return kTransparentBlack;

   if (square < offset) return retval;

   alpha  = (fthr > 0.0) ? saturate ((scope + fthr - square) / (fthr * 2.0)) : 0.0;
   colour = lerp (colour, retval, alpha);
   mix    = sin (min (BorderWidth * 10.0, 1.0) * HALF_PI);

   return lerp (float4 (retval.rgb, alpha), colour, mix);
}

DeclareEntryPoint (DVEvignetteSquare)
{ return fn_main (sInp, uv3, Bg, uv2); }


// Technique Diamond DVE vignette

DeclarePass (dFg)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclarePass (dInp)
{
   float2 xy1 = float2 (uv3.x - OverlayPosX, uv3.y + OverlayPosY);
   float2 FgPos = float2 (FgPosX, -FgPosY);

   if (odd (FlipFlop)) {
      xy1.x = 0.5 - xy1.x;
      FgPos.x = -FgPos.x;
   }
   else xy1.x += 0.5;

   if (FlipFlop > FLIP) {
      xy1.y = 1.5 - xy1.y;
      FgPos.y = -FgPos.y;
   }
   else xy1.y -= 0.5;

   float aspect  = 1.0 - (max (Aspect - 0.5, 0.0) * MIN_ASPECT) + (max (0.5 - Aspect, 0.0) * MAX_ASPECT);
   float size    = 1.0 - (max (FgSize, 0.0) * MIN_SIZE) - (min (FgSize, 0.0) * MAX_SIZE);
   float scope   = max (0.0, Radius) * DIAMOND;
   float border  = scope + (BorderWidth * BORDER_DMND);
   float fthr    = BorderFeather * FEATHER_DMND;
   float offset  = max (scope - fthr, 0.0);
   float mix     = border + fthr - offset;
   float diamond = (abs (xy1.x - 0.5) / aspect) + (abs (xy1.y - 0.5) * aspect / _OutputAspectRatio);
   float alpha   = (fthr > 0.0) ? saturate ((border + fthr - diamond) / (fthr * 2.0)) : 1.0;

   float2 range  = FRAME_CENTRE - xy1;
   float2 xy2   = FRAME_CENTRE - (range * size) - FgPos;

   mix = (mix > 0.0) ? saturate ((diamond - offset) / mix) : 0.0;

   float4 retval = IsOutOfBounds (xy2) ? BLACK : tex2D (dFg, xy2);
   float4 colour = float4 (lerp (BorderColour.rgb, BorderColour_1.rgb, mix), alpha);

   if (diamond > border + fthr) return kTransparentBlack;
   
   if (diamond < offset) return retval;

   alpha  = (fthr > 0.0) ? saturate ((scope + fthr - diamond) / (fthr * 2.0)) : 0.0;
   colour = lerp (colour, retval, alpha);
   mix    = sin (min (BorderWidth * 10.0, 1.0) * HALF_PI);

   return lerp (float4 (retval.rgb, alpha), colour, mix);
}

DeclareEntryPoint (DVEvignetteDiamond)
{ return fn_main (dInp, uv3, Bg, uv2); }

