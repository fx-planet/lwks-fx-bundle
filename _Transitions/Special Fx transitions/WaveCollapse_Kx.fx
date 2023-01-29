// @Maintainer jwrl
// @Released 2023-01-29
// @Author jwrl
// @Created 2023-01-29

/**
 This is a transition that splits the foreground image into sinusoidal strips or waves
 and compresses them to or expands them from zero height.  The vertical centring can be
 adjusted so that the foreground expands symmetrically or asymmetrically.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WaveCollapse_Kx.fx
//
// Version history:
//
// Built 2023-01-29 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Wave collapse (keyed)", "Mix", "Special Fx transitions", "Expands or compresses the foreground to sinusoidal strips or waves", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Spacing, "Spacing", "Waves", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (centreY, "Vertical centre", "Waves", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HEIGHT   20.0

#define PI       3.1415926536
#define HALF_PI  1.5707963268

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

// technique WaveCollapse_Kx_F

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

DeclareEntryPoint (WaveCollapse_F)
{
   float Width = 10.0 + (Spacing * 40.0);
   float Height = ((1.0 - cos (HALF_PI - (Amount * HALF_PI))) * HEIGHT) + 1.0;

   float2 xy;

   xy.x = saturate (uv3.x + (sin (Width * uv3.y * PI) * (1.0 - Amount)));
   xy.y = saturate (((uv3.y - centreY) * Height) + centreY);

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : tex2D (Super_F, xy);

   return lerp (tex2D (Bg_F, uv3), Fgnd, Fgnd.a * saturate (Amount * 5.0));
}

//-----------------------------------------------------------------------------------------//

// technique WaveCollapse_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclareEntryPoint (WaveCollapse_I)
{
   float Width = 10.0 + (Spacing * 40.0);
   float Height = ((1.0 - cos (HALF_PI - (Amount * HALF_PI))) * HEIGHT) + 1.0;

   float2 xy;

   xy.x = saturate (uv3.x + (sin (Width * uv3.y * PI) * (1.0 - Amount)));
   xy.y = saturate (((uv3.y - centreY) * Height) + centreY);

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_I, xy);

   return lerp (tex2D (Bg_I, uv3), Fgnd, Fgnd.a * saturate (Amount * 5.0));
}

//-----------------------------------------------------------------------------------------//

// technique WaveCollapse_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclareEntryPoint (WaveCollapse_O)
{
   float Width = 10.0 + (Spacing * 40.0);
   float Height = ((1.0 - cos (Amount * HALF_PI)) * HEIGHT) + 1.0;

   float2 xy;

   xy.x = saturate (uv3.x + (sin (Width * uv3.y * PI) * Amount));
   xy.y = saturate (((uv3.y - centreY) * Height) + centreY);

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_O, xy);

   return lerp (tex2D (Bg_O, uv3), Fgnd, Fgnd.a * saturate ((1.0 - Amount) * 5.0));
}

