// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This effect either:
   Zooms into the outgoing image as it dissolves to the new image which zooms in to
   fill the frame.
 OR
   Zooms out of the outgoing image and dissolves to the new one while it's zooming out
   to full frame.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Zoom_Dx.fx
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Zoom dissolve", "Mix", "Blur transitions", "Zooms between the two sources", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Direction, "Direction", "Zoom", 0, "Zoom in|Zoom out");

DeclareFloatParam (Strength, "Strength", "Zoom", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Xcentre, "Zoom centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre, "Zoom centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI   1.5707963268

#define SAMPLE    80
#define DIVISOR   82.0

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Spin_Dx)
{
   float4 outgoing = tex2D (Fgd, uv3);
   float4 incoming = tex2D (Bgd, uv3);

   if (Strength > 0.0) {
      float strength_1, strength_2, scale_1 = 1.0, scale_2 = 1.0;

      sincos (Amount * HALF_PI, strength_2, strength_1);

      strength_1 = Strength * (1.0 - strength_1);
      strength_2 = Strength * (1.0 - strength_2);

      if (Direction == 0) scale_1 -= strength_1;
      else scale_2 -= strength_2;

      float2 centreXY = float2 (Xcentre, 1.0 - Ycentre);
      float2 xy0 = uv3 - centreXY;
      float2 xy1, xy2;

      strength_1 /= SAMPLE;
      strength_2 /= SAMPLE;

      for (int i = 0; i <= SAMPLE; i++) {
         xy1 = xy0 * scale_1 + centreXY;
         xy2 = xy0 * scale_2 + centreXY;
         outgoing += tex2D (Fgd, xy1);
         incoming += tex2D (Bgd, xy2);
         scale_1  += strength_1;
         scale_2  += strength_2;
      }

      outgoing /= DIVISOR;
      incoming /= DIVISOR;
   }

   return lerp (outgoing, incoming, Amount);
}

