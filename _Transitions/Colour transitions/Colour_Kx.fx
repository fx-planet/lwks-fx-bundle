// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This effect fades a blended foreground such as a title or image key in or out through
 a user-selected colour gradient.  The gradient can be a single flat colour, a vertical
 gradient, a horizontal gradient or a four corner gradient.  The colour is at its
 maximum strength half way through the transition.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Colour_Kx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Dissolve thru colour (keyed)", "Mix", "Colour transitions", "Fades the blended foreground in or out through a colour gradient", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (cAmount, "Colour mix", "Colour setup", kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (gradSetup, "Show gradient full screen", "Colour setup", false);

DeclareIntParam (cGradient, "Gradient", "Colour setup", 5, "Flat (uses only the top left colour)|Horizontal blend (top left > top right)|Horizontal blend to centre (TL > TR > TL)|Vertical blend (top left > bottom left)|Vertical blend to centre (TL > BL > TL)|Four way gradient|Four way gradient to centre|Four way gradient to centre (horizontal)|Four way gradient to centre (vertical)|Radial (TL outer > TR centre)");

DeclareFloatParam (OffsX, "Grad. midpoint", "Colour setup", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (OffsY, "Grad. midpoint", "Colour setup", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareColourParam (topLeft, "Top left", "Colour setup", kNoFlags, 0.0, 0.0, 0.0, 1.0);
DeclareColourParam (topRight, "Top right", "Colour setup", kNoFlags, 0.5, 0.0, 0.8, 1.0);
DeclareColourParam (botLeft, "Bottom left", "Colour setup", kNoFlags, 0.0, 0.0, 1.0, 1.0);
DeclareColourParam (botRight, "Bottom right", "Colour setup", kNoFlags, 0.0, 0.8, 0.5, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.1415926536
#define HALF_PI 1.5707963268

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

float4 fn_colour (float2 uv)
{
   if (cGradient == 0) return topLeft;

   float4 retval;

   float buff_1, buff_2, horiz, vert = 1.0 - OffsY;
   float buff_0 = (OffsX <= 0.0)  ? (uv.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv.x / 2.0 :
                  (OffsX > uv.x) ? uv.x / (2.0 * OffsX) : ((uv.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   if ((cGradient == 2) || (cGradient == 6) || (cGradient == 8) || (cGradient == 9)) horiz = sin (PI * buff_0);
   else {
      sincos (HALF_PI * buff_0, buff_1, buff_2);
      buff_2 = 1.0 - buff_2;
      horiz = lerp (buff_1, buff_2, buff_0);
   }

   buff_0 = (vert <= 0.0) ? (uv.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv.y / 2.0 :
            (vert > uv.y) ? uv.y / (2.0 * vert) : ((uv.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   if ((cGradient == 4) || (cGradient == 6) || (cGradient == 7) || (cGradient == 9)) vert = sin (PI * buff_0);
   else {
      sincos (HALF_PI * buff_0, buff_1, buff_2);
      buff_2 = 1.0 - buff_2;
      vert = lerp (buff_1, buff_2, buff_0);
   }

   if ((cGradient == 3) || (cGradient == 4)) { retval = lerp (topLeft, botLeft, vert); }
   else {
      retval = lerp (topLeft, topRight, horiz);
   
      if (cGradient == 9) retval = lerp (topLeft, retval, vert);
      else if (cGradient > 4) {
         float4 botRow = lerp (botLeft, botRight, horiz);
         retval = lerp (retval, botRow, vert);
      }
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Colour_Kx_F

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

DeclareEntryPoint (Colour_Fx_F)
{
   float4 gradient = fn_colour (uv0);

   if (gradSetup) return gradient;

   float4 Fgnd = CropEdges && IsOutOfBounds (uv1) ? kTransparentBlack : tex2D (Super_F, uv3);
   float4 Bgnd = tex2D (Bg_F, uv3);

   float level = min (1.0, cAmount * 2.0);
   float c_Amt = cos (saturate (level * Amount) * HALF_PI);

   level = sin (Amount * HALF_PI);
   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (Bgnd, Fgnd, Fgnd.a * level);
}


// technique Colour_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclareEntryPoint (Colour_Fx_I)
{
   float4 gradient = fn_colour (uv0);

   if (gradSetup) return gradient;

   float4 Fgnd = CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : tex2D (Super_I, uv3);
   float4 Bgnd = tex2D (Bg_I, uv3);

   float level = min (1.0, cAmount * 2.0);
   float c_Amt = cos (saturate (level * Amount) * HALF_PI);

   level = sin (Amount * HALF_PI);
   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (Bgnd, Fgnd, Fgnd.a * level);
}


// technique Colour_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_O)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclareEntryPoint (Colour_Fx_O)
{
   float4 gradient = fn_colour (uv0);

   if (gradSetup) return gradient;

   float4 Fgnd = CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : tex2D (Super_O, uv3);
   float4 Bgnd = tex2D (Bg_O, uv3);

   float level = min (1.0, cAmount * 2.0);
   float c_Amt = sin (saturate (level * Amount) * HALF_PI);

   level = cos (Amount * HALF_PI);
   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (Bgnd, Fgnd, Fgnd.a * level);
}

