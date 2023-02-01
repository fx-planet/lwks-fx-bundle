// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This rotates a blended foreground such as a title or image key out or in.  It's a
 combination of the functionality of two previous effects, Rotate_Ax and Rotate_Adx.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rotating_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Rotating trans (keyed)", "Mix", "Geometric transitions", "Rotates a title, image key or other blended foreground in or out", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (Ttype, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta|Standard transitions");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareIntParam (SetTechnique, "Transition type", kNoGroup, 0, "Rotate Right|Rotate Down|Rotate Left|Rotate Up");

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

float4 fn_keygen (sampler F, sampler B, float2 xy)
{
   float4 Bgnd, Fgnd = ReadPixel (F, xy);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = ReadPixel (B, xy);
      }
      else Bgnd = ReadPixel (B, xy);

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

// technique Rotate_Right

DeclarePass (Fg_R)
{ return ReadPixel (Fg, uv1; }

DeclarePass (Bg_R)
{ return ReadPixel (Bg, uv2; }

DeclarePass (Super_R)
{ return fn_keygen (Fg_R, Bg_R, uv3); }

DeclareEntryPoint (Rotate_Right)
{
   float4 Bgnd;

   float2 xy, bgd;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
         : float2 ((uv3.x - 1.0) / (1.0 - Amount) - (Amount * 0.2) + 1.0, ((uv3.y - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv3.y) * uv3.x * sin (Amount * HALF_PI));
      Bgnd = tex2D (Bg_R, uv3);
      bgd = uv3;
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv3.y)
         : float2 ((uv3.x / Amount) - ((1.0 - Amount) * 0.2), ((uv3.y - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv3.y) * uv3.x * cos (Amount * HALF_PI));

      if (Ttype == 0) {
         Bgnd = tex2D (Fg_R, uv3);
         bgd = uv3;
      }
      else {
         Bgnd = tex2D (Bg_R, uv3);
         bgd = uv3;
      }
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : tex2D (Super_R, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Rotate_Down

DeclarePass (Fg_D)
{ return ReadPixel (Fg, uv1; }

DeclarePass (Bg_D)
{ return ReadPixel (Bg, uv2; }

DeclarePass (Super_D)
{ return fn_keygen (Fg_D, Bg_D, uv3); }

DeclareEntryPoint (Rotate_Down)
{
   float4 Bgnd;

   float2 xy, bgd;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
         : float2 (((uv3.x - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv3.x) * uv3.y * sin (Amount * HALF_PI), (uv3.y - 1.0) / (1.0 - Amount) - (Amount * 0.2) + 1.0);
      Bgnd = tex2D (Bg_D, uv3);
      bgd = uv3;
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv3.y)
         : float2 (((uv3.x - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv3.x) * uv3.y * cos (Amount * HALF_PI), (uv3.y / Amount) - ((1.0 - Amount) * 0.2));

      if (Ttype == 0) {
         Bgnd = tex2D (Fg_D, uv3);
         bgd = uv3;
      }
      else {
         Bgnd = tex2D (Bg_D, uv3);
         bgd = uv3;
      }
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : tex2D (Super_D, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Rotate_Left

DeclarePass (Fg_L)
{ return ReadPixel (Fg, uv1; }

DeclarePass (Bg_L)
{ return ReadPixel (Bg, uv2; }

DeclarePass (Super_L)
{ return fn_keygen (Fg_L, Bg_L, uv3); }

DeclareEntryPoint (Rotate_Left)
{
   float4 Bgnd;

   float2 xy, bgd;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
         : float2 (uv3.x / (1.0 - Amount) + (Amount * 0.2), ((uv3.y - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv3.y) * (1.0 - uv3.x) * sin (Amount * HALF_PI));
      Bgnd = tex2D (Bg_L, uv3);
      bgd = uv3;
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv3.y)
         : float2 ((uv3.x - 1.0) / Amount + 1.0 + ((1.0 - Amount) * 0.2), ((uv3.y - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv3.y) * (1.0 - uv3.x) * cos (Amount * HALF_PI));

      if (Ttype == 0) {
         Bgnd = tex2D (Fg_L, uv3);
         bgd = uv3;
      }
      else {
         Bgnd = tex2D (Bg_L, uv3);
         bgd = uv3;
      }
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : tex2D (Super_L, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Rotate_Up

DeclarePass (Fg_U)
{ return ReadPixel (Fg, uv1; }

DeclarePass (Bg_U)
{ return ReadPixel (Bg, uv2; }

DeclarePass (Super_U)
{ return fn_keygen (Fg_U, Bg_U, uv3); }

DeclareEntryPoint (Rotate_Up)
{
   float4 Bgnd;

   float2 xy, bgd;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
         : float2 (((uv3.x - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv3.x) * (1.0 - uv3.y) * sin (Amount * HALF_PI), uv3.y / (1.0 - Amount) + (Amount * 0.2));
      Bgnd = tex2D (Bg_U, uv3);
      bgd = uv3;
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv3.y)
         : float2 (((uv3.x - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv3.x) * (1.0 - uv3.y) * cos (Amount * HALF_PI), (uv3.y - 1.0) / Amount + 1.0 + ((1.0 - Amount) * 0.2));

      if (Ttype == 0) {
         Bgnd = tex2D (Fg_U, uv3);
         bgd = uv3;
      }
      else {
         Bgnd = tex2D (Bg_U, uv3);
         bgd = uv3;
      }
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : tex2D (Super_U, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

