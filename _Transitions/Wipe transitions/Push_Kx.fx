// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This mimics the Lightworks push effect but supports titles, image keys and other blended
 effects.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Push_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Push transition (keyed)", "Mix", "Wipe transitions", "Pushes the foreground on or off screen horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (Ttype, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareIntParam (SetTechnique, "Type", kNoGroup, 0, "Push Right|Push Down|Push Left|Push Up");

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd, Fgnd = ReadPixel (F, xy1);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = ReadPixel (B, xy2);
      }
      else Bgnd = ReadPixel (B, xy2);

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

// technique Push_right

DeclarePass (Super_R)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Push_right)
{
   float4 Bgnd;

   float2 bgd;
   float2 xy = (Ttype == 2) ? float2 (saturate (uv3.x + cos (HALF_PI * Amount) - 1.0), uv3.y)
                            : float2 (saturate (uv3.x - sin (HALF_PI * Amount) + 1.0), uv3.y);
   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = ReadPixel (Bg, uv2);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_R, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}


// technique Push_down

DeclarePass (Super_D)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Push_down)
{
   float4 Bgnd;

   float2 bgd;
   float2 xy = (Ttype == 2) ? float2 (uv3.x, saturate (uv3.y + cos (HALF_PI * Amount) - 1.0))
                            : float2 (uv3.x, saturate (uv3.y - sin (HALF_PI * Amount) + 1.0));
   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = ReadPixel (Bg, uv2);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_D, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}


// technique Push_left

DeclarePass (Super_L)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Push_left)
{
   float4 Bgnd;

   float2 bgd;
   float2 xy = (Ttype == 2) ? float2 (saturate (uv3.x - cos (HALF_PI * Amount) + 1.0), uv3.y)
                            : float2 (saturate (uv3.x + sin (HALF_PI * Amount) - 1.0), uv3.y);
   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = ReadPixel (Bg, uv2);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_L, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}


// technique Push_up

DeclarePass (Super_U)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Push_up)
{
   float4 Bgnd;

   float2 bgd;
   float2 xy = (Ttype == 2) ? float2 (uv3.x, saturate (uv3.y - cos (HALF_PI * Amount) + 1.0))
                            : float2 (uv3.x, saturate (uv3.y + sin (HALF_PI * Amount) - 1.0));
   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = ReadPixel (Bg, uv2);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_U, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

