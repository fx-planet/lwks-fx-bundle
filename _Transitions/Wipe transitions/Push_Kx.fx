// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This mimics the Lightworks push effect but supports titles, image keys and other blended
 effects.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Push_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
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
DeclareIntParam (Ttype, "Transition position", kNoGroup, 2, "At start if delta key folded|At start if non-delta unfolded|Standard transitions");

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

float4 fn_keygen (sampler F, sampler B, float2 xy)
{
   float4 Bgnd, Fgnd = tex2D (F, xy);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = tex2D (B, xy);
      }
      else Bgnd = tex2D (B, xy);

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

DeclarePass (Fg_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_R)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_R)
{ return fn_keygen (Fg_R, Bg_R, uv3); }

DeclareEntryPoint (Push_right)
{
   float2 bg;
   float2 xy = Ttype == 2 ? float2 (saturate (uv3.x + cos (HALF_PI * Amount) - 1.0), uv3.y)
                          : float2 (saturate (uv3.x - sin (HALF_PI * Amount) + 1.0), uv3.y);
   float4 Bgnd;

   if (Ttype == 0) {
      bg = uv1;
      Bgnd = tex2D (Fg_R, uv3);
   }
   else {
      bg = uv2;
      Bgnd = tex2D (Bg_R, uv3);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bg)) ? kTransparentBlack : tex2D (Super_R, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Push_down

DeclarePass (Fg_D)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_D)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_D)
{ return fn_keygen (Fg_D, Bg_D, uv3); }

DeclareEntryPoint (Push_down)
{
   float2 bg;
   float2 xy = Ttype == 2 ? float2 (uv3.x, saturate (uv3.y + cos (HALF_PI * Amount) - 1.0))
                          : float2 (uv3.x, saturate (uv3.y - sin (HALF_PI * Amount) + 1.0));
   float4 Bgnd;

   if (Ttype == 0) {
      bg = uv1;
      Bgnd = tex2D (Fg_D, uv3);
   }
   else {
      bg = uv2;
      Bgnd = tex2D (Bg_D, uv3);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bg)) ? kTransparentBlack : tex2D (Super_D, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Push_left

DeclarePass (Fg_L)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_L)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_L)
{ return fn_keygen (Fg_L, Bg_L, uv3); }

DeclareEntryPoint (Push_left)
{
   float2 bg;
   float2 xy = Ttype == 2 ? float2 (saturate (uv3.x - cos (HALF_PI * Amount) + 1.0), uv3.y)
                          : float2 (saturate (uv3.x + sin (HALF_PI * Amount) - 1.0), uv3.y);
   float4 Bgnd;

   if (Ttype == 0) {
      bg = uv1;
      Bgnd = tex2D (Fg_L, uv3);
   }
   else {
      bg = uv2;
      Bgnd = tex2D (Bg_L, uv3);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bg)) ? kTransparentBlack : tex2D (Super_L, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Push_up

DeclarePass (Fg_U)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_U)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_U)
{ return fn_keygen (Fg_U, Bg_U, uv3); }

DeclareEntryPoint (Push_up)
{
   float2 bg;
   float2 xy = Ttype == 2 ? float2 (uv3.x, saturate (uv3.y - cos (HALF_PI * Amount) + 1.0))
                          : float2 (uv3.x, saturate (uv3.y + sin (HALF_PI * Amount) - 1.0));
   float4 Bgnd;

   if (Ttype == 0) {
      bg = uv1;
      Bgnd = tex2D (Fg_U, uv3);
   }
   else {
      bg = uv2;
      Bgnd = tex2D (Bg_U, uv3);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bg)) ? kTransparentBlack : tex2D (Super_U, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

