// @Maintainer jwrl
// @Released 2023-01-12
// @Author jwrl
// @Created 2023-01-12

/**
 This effect is designed to modulate the input with a texture from an external piece of
 art.  The texture may be coloured but only the luminance value will be used.  New in
 this version is a means of adjusting the texture levels and inverting them, and a way
 to deal with the edges of frame of both video and texture has also been added.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Texturiser.fx
//
// Version history:
//
// Built 2023-01-12 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Texturiser", "Stylize", "Textures", "Generates bump mapped textures on an image using external texture artwork", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Art, Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Overlay", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Size, "Size", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Depth, "Depth", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (OffsetX, "X", "Offset", kNoFlags, 0.5, -1.0, 2.0);
DeclareFloatParam (OffsetY, "Y", "Offset", kNoFlags, 0.5, -1.0, 2.0);

DeclareIntParam (VideoMode, "Video mode", kNoGroup, 0, "Single|Tiled|Mirrored");
DeclareIntParam (TextureMode, "Texture mode", "Art setup", 1, "Single|Tiled|Mirrored");

DeclareBoolParam (InvertTexture, "Invert texture", "Art setup", false);

DeclareFloatParam (Gamma, "Gamma", "Art setup", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (Contrast, "Contrast", "Art setup", "DisplayAsPercentage", 1.0, 0.0, 2.0);
DeclareFloatParam (Gain, "Gain", "Art setup", "DisplayAsPercentage", 1.0, 0.0, 2.0);
DeclareFloatParam (Brightness, "Brightness", "Art setup", "DisplayAsPercentage", 0.0, -1.0, 1.0);

DeclareBoolParam (ShowTexture, "Show texture", "Art setup", false);

DeclareIntParam (_InpOrientation);

DeclareFloat4Param (_InpExtents);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define AMT       0.2   // Amount scale factor
#define DPTH      1.5   // Depth scale factor
#define SIZE      0.75  // Size scale factor
#define REDUCTION 0.9   // Foreground reduction for texture add

#define BLACK float4(0.0.xxx, 1.0)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 Mirrored (float2 uv)
{ return 1.0.xx - (abs (frac (abs (uv) / 2.0) - 0.5.xx) * 2.0); }

float2 Tiled (float2 uv)
{ return frac (1.0.xx + frac (uv)); }

float2 fixOffset (float displace)
{
   float2 offset = _InpOrientation == 90  ? 0.5.xx - float2 (OffsetY, OffsetX)
                 : _InpOrientation == 180 ? float2 (OffsetX - 0.5, 0.5 - OffsetY)
                 : _InpOrientation == 270 ? float2 (OffsetY, OffsetX) - 0.5.xx
                                          : float2 (0.5 - OffsetX, OffsetY - 0.5);

   return offset * abs (_InpExtents.xy - _InpExtents.zw) * displace / 100.0;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Artwork)
{
   float2 xy = ((uv1 - 0.5.xx) * (1.0 - (Size * SIZE))) + 0.5.xx;

   float4 retval = TextureMode == 1 ? tex2D (Art, Tiled (xy))
                 : TextureMode == 2 ? tex2D (Art, Mirrored (xy))
                 : IsOutOfBounds (xy) ? BLACK : tex2D (Art, xy);

   float luma = (retval.r + retval.g + retval.b) / 3.0;

   if (InvertTexture) luma = 1.0 - luma;

   luma = ((((pow (luma, 1.0 / Gamma) * Gain) + Brightness) - 0.5) * Contrast) + 0.5;

   return float4 (luma.xxx, retval.a);
}

DeclareEntryPoint (Texturiser)
{
   float amt = Amount * AMT;

   float4 Tex = tex2D (Artwork, uv3);

   if (ShowTexture) return Tex;

   Tex.rgb *= Depth * DPTH;

   float2 xy = uv2 + fixOffset (Tex.g);

   float4 Fgd = VideoMode == 1 ? tex2D (Inp, Tiled (xy))
              : VideoMode == 2 ? tex2D (Inp, Mirrored (xy)) : tex2D (Inp, xy);

   float alpha = Fgd.a;

   Fgd = saturate (Fgd + (Tex * amt));
   Fgd = lerp (Fgd, Tex, amt);

   if ((VideoMode == 0) && IsOutOfBounds (xy)) Fgd = BLACK;

   return IsOutOfBounds (uv2) ? kTransparentBlack : float4 (Fgd.rgb, alpha);
}

