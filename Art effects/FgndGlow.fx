// @Maintainer jwrl
// @Released 2023-08-02
// @Author jwrl
// @Created 2020-10-16

/**
 This effect uses a glow based on the Lightworks Glow effect, with the blur section
 rewritten to apply a glow to the foreground component of a blended image, image key
 or title.  The background remains "un-glowed".  The effect can be applied to a title
 or video with transparency by first disconnecting any input or blend effect, or the
 foreground video can be extracted.  In that case it is separated from the background
 by means of a delta or difference key.

 In this version the blur used to create the glow has been considerably improved, so
 that the range has been much enhanced.  Also two new parameters have been added.
 The first is Fg overlay, which is used to restore the clarity of the foreground if
 the blend mode has affected it.  The second is a switch to enable use of a colour
 when in glow from luminance mode.  The blend options used for the glow as before are
 a subset of the standard blend modes widely seen in most art software.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FgndGlow.fx
//
//
// Version history:
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-05-14 jwrl.
// Header reformatted.
//
// Conversion 2022-12-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Foreground glow", "Stylize", "Art Effects", "An effect that applies a glow to the foreground of a keyed or blended image", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Blend, "Blend glow using", kNoGroup, 1, "Lighten|Screen|Add|Lighter Colour");

DeclareIntParam (SetTechnique, "Mode", "Glow", 0, "Glow from luminance|Glow from reds|Glow from greens|Glow from blues|Set up delta key");
DeclareFloatParam (Tolerance, "Tolerance", "Glow", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Feather, "Feather", "Glow", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Size, "Size", "Glow", kNoFlags, 4.0, 1.0, 10.0);
DeclareFloatParam (Strength, "Strength", "Glow", kNoFlags, 0.5, 0.0, 1.0);
DeclareColourParam (Colour, "Colour", "Glow", kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareIntParam (Source, "Source selection (disconnect title and image key inputs)", "Blend mode", 1, "Extracted foreground|Image key/Title pre LW 2023.2|Video, image key or title");
DeclareFloatParam (KeyGain, "Trim key", "Blend mode", kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (FgOverlay, "Fg overlay", "Extras", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (UseColour, "Luminance uses glow colour", "Extras", false);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define ANGLE    0.2617993878
#define RADIUS_1 0.0004
#define RADIUS_2 0.001
#define RADIUS_3 0.002

#define LOOP     12
#define DIVIDE   49

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_comp (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Fgnd = ReadPixel (F, xy1);
    
   if (Source == 0) return Fgnd;

   float4 Bgnd = ReadPixel (B, xy2);

   if (Source == 1) {
      Fgnd.a = pow (abs (Fgnd.a), 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   if (IsOutOfBounds (xy1)) return kTransparentBlack;

   float4 Fgnd = tex2D (F, xy1);

   if (Source == 0) {
      Fgnd.a = smoothstep (0.0, KeyGain, distance (ReadPixel (B, xy2).rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (abs (Fgnd.a), 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 fn_glow (sampler G, float2 uv, float R)
{
   if (IsOutOfBounds (uv)) return kTransparentBlack;

   float4 retval = tex2D (G, uv);

   if (Size > 0.0) {
      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Size * R;

      float angle = 0.0;

      for (int i = 0; i < LOOP; i++) {
         sincos (angle, xy.x, xy.y);
         xy *= radius;
         retval += tex2D (G, uv + xy);
         retval += tex2D (G, uv - xy);
         xy += xy;
         retval += tex2D (G, uv + xy);
         retval += tex2D (G, uv - xy);
         angle += ANGLE;
      }

      retval /= DIVIDE;
   }

   return retval;
}

float4 fn_main (sampler G, sampler K, float2 uv, sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd = ReadPixel (B, xy2);

   if (IsOutOfBounds (uv)) return Bgnd;

   float4 Fgnd = tex2D (K, uv);
   float4 retval = tex2D (G, uv);
   float4 Comp = Source == 0 ? tex2D (F, xy1)
                             : float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), Bgnd.a);

   retval = pow (abs (retval), 1.0 / (1.0 + Strength));

   if (Blend == 0) { retval.rgb = max (retval.rgb, Comp.rgb); }
   else if (Blend == 1) { retval.rgb = retval.rgb + Comp.rgb - (retval.rgb * Comp.rgb); }
   else if (Blend == 2) { retval.rgb = min (retval.rgb + Comp.rgb, 1.0.xxx); }
   else {
      float lumaDiff = retval.r + retval.g + retval.b - Comp.r - Comp.g - Comp.b;

      if (lumaDiff < 0.0) retval.rgb = Comp.rgb;
   }

   Comp.rgb = lerp (Comp.rgb, saturate (retval.rgb), Strength);
   Comp.rgb = lerp (Comp.rgb, Fgnd.rgb, Fgnd.a * FgOverlay);

   return lerp (Bgnd, Comp, tex2D (Mask, uv).x);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (KeyL)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (GlowLx)
{
   float4 retval = tex2D (KeyL, uv3);
   float4 surround = UseColour ? Colour : retval;

   float feather = Feather * 0.5;
   float srcLum = ((retval.r * 0.3) + (retval.g * 0.59) + (retval.b * 0.11)) * retval.a;

   if (srcLum < Tolerance) return kTransparentBlack;

   if (srcLum >= (Tolerance + feather)) return surround;

   return lerp (kTransparentBlack, surround, (srcLum - Tolerance) / feather);
}

DeclarePass (GlowLy)
{ return fn_glow (GlowLx, uv3, RADIUS_1); }

DeclarePass (GlowL)
{ return fn_glow (GlowLy, uv3, RADIUS_2); }

DeclareEntryPoint (FgndGlowLuminance)
{
   float4 retval = fn_main (GlowL, KeyL, uv3, Fg, uv1, Bg, uv2);
   float4 video  = fn_comp (Fg, uv1, Bg, uv2);

   return lerp (video, retval, tex2D (Mask, uv1).x);
}

//-----------------------------------------------------------------------------------------//

DeclarePass (KeyR)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (GlowRx)
{
   float4 retval = tex2D (KeyR, uv3);

   return ((retval.r * retval.a) < Tolerance) ? kTransparentBlack : retval;
}

DeclarePass (GlowRy)
{ return fn_glow (GlowRx, uv3, RADIUS_1); }

DeclarePass (GlowR)
{ return fn_glow (GlowRy, uv3, RADIUS_2); }

DeclareEntryPoint (FgndGlowReds)
{
   float4 retval = fn_main (GlowR, KeyR, uv3, Fg, uv1, Bg, uv2);
   float4 video  = fn_comp (Fg, uv1, Bg, uv2);

   return lerp (video, retval, tex2D (Mask, uv1).x);
}

//-----------------------------------------------------------------------------------------//

DeclarePass (KeyG)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (GlowGx)
{
   float4 retval = tex2D (KeyG, uv3);

   return ((retval.g * retval.a) < Tolerance) ? kTransparentBlack : retval;
}

DeclarePass (GlowGy)
{ return fn_glow (GlowGx, uv3, RADIUS_1); }

DeclarePass (GlowG)
{ return fn_glow (GlowGy, uv3, RADIUS_2); }

DeclareEntryPoint (FgndGlowGreens)
{
   float4 retval = fn_main (GlowG, KeyG, uv3, Fg, uv1, Bg, uv2);
   float4 video  = fn_comp (Fg, uv1, Bg, uv2);

   return lerp (video, retval, tex2D (Mask, uv1).x);
}

//-----------------------------------------------------------------------------------------//

DeclarePass (KeyB)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (GlowBx)
{
   float4 retval = tex2D (KeyB, uv3);

   return ((retval.b * retval.a) < Tolerance) ? kTransparentBlack : retval;
}

DeclarePass (GlowBy)
{ return fn_glow (GlowBx, uv3, RADIUS_1); }

DeclarePass (GlowB)
{ return fn_glow (GlowBy, uv3, RADIUS_2); }

DeclareEntryPoint (FgndGlowBlues)
{
   float4 retval = fn_main (GlowB, KeyB, uv3, Fg, uv1, Bg, uv2);
   float4 video  = fn_comp (Fg, uv1, Bg, uv2);

   return lerp (video, retval, tex2D (Mask, uv1).x);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (FgndGlowKeySetup)
{
   float4 retval = fn_keygen (Fg, uv1, Bg, uv2);

   return lerp (kTransparentBlack, retval, tex2D (Mask, uv1).x);
}

