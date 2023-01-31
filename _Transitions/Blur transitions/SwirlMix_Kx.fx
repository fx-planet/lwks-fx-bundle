// @Maintainer jwrl
// @Released 2023-01-31
// @Author jwrl
// @Created 2023-01-31

/**
 This is a swirl effect similar to schrauber's swirl mix, but optimised for use with
 blended effects.  It has an adjustable axis of rotation and no matter how the spin
 axis and swirl settings are adjusted the distorted image will always stay within the
 frame boundaries.  If the swirl setting is set to zero the image will simply rotate
 around the spin axis.  The spin axis may be set using faders, or may be dragged
 interactively with the mouse in the sequence viewer.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SwirlMix_Kx.fx
//
// Version history:
//
// Built 2023-01-31 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Swirl mix (keyed)", "Mix", "Blur transitions", "A swirl mix effect that transitions in or out of the foreground", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key folded|At start if non-delta unfolded|Standard transitions");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Amplitude, "Swirl depth", "Swirl settings", kNoFlags, 0.5, -1.0, 1.0);
DeclareFloatParam (Rate, "Revolutions", "Swirl settings", kNoFlags, 0.0, -10.0, 10.0);
DeclareFloatParam (Start, "Start angle", "Swirl settings", kNoFlags, 0.0, -360.0, 360.0);

DeclareFloatParam (CentreX, "Position", "Spin axis", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Position", "Spin axis", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_Length);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define TWO_PI  6.2831853072
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

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique SwirlMix_Kx_F

DeclarePass (Bg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Title_F)
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

DeclareEntryPoint (SwirlMix_Kx_F)
{
   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 xy, xy1 = uv3 - centre;

   float3 spin = float3 (Amplitude, Start, Rate) * (1.0 - Amount);

   float amount = sin (Amount * HALF_PI);
   float angle = (length (xy1) * spin.x * TWO_PI) + radians (spin.y);
   float scale0, scale90;

   sincos (angle + (spin.z * _Length * PI), scale90, scale0);
   xy = (xy1 * scale0) - (float2 (xy1.y, -xy1.x) * scale90) + centre;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : ReadPixel (Title_F, xy);

   return lerp (tex2D (Bg_F, uv3), Fgnd, Fgnd.a * amount);
}

//-----------------------------------------------------------------------------------------//

// technique SwirlMix_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Title_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclareEntryPoint (SwirlMix_Kx_I)
{
   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 xy, xy1 = uv3 - centre;

   float3 spin = float3 (Amplitude, Start, Rate) * (1.0 - Amount);

   float amount = sin (Amount * HALF_PI);
   float angle = (length (xy1) * spin.x * TWO_PI) + radians (spin.y);
   float scale0, scale90;

   sincos (angle + (spin.z * _Length * PI), scale90, scale0);
   xy = (xy1 * scale0) - (float2 (xy1.y, -xy1.x) * scale90) + centre;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Title_I, xy);

   return lerp (tex2D (Bg_I, uv3), Fgnd, Fgnd.a * amount);
}

//-----------------------------------------------------------------------------------------//

// technique SwirlMix_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Title_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclareEntryPoint (SwirlMix_Kx_O)
{
   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 xy, xy1 = uv3 - centre;

   float3 spin = float3 (Amplitude, Start, Rate) * Amount;

   float amount = sin ((1.0 - Amount) * HALF_PI);
   float angle = (length (xy1) * spin.x * TWO_PI) + radians (spin.y);
   float scale0, scale90;

   sincos (angle + (spin.z * _Length * PI), scale90, scale0);
   xy = (xy1 * scale0) - (float2 (xy1.y, -xy1.x) * scale90) + centre;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Title_O, xy);

   return lerp (tex2D (Bg_O, uv3), Fgnd, Fgnd.a * amount);
}

