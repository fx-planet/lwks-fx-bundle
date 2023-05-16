// @Maintainer jwrl
// @Released 2023-05-16
// @Author baopao
// @Created 2014-02-01

/**
 Key despill is a background-based effect for removing the key colour spill in a chromakey
 composite.  It automatically separates the key from the background so that the defringing
 cannot pollute the background colour.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect KeyDespill.fx
//
// Despill Background Based http://www.alessandrodallafontana.com/ (baopao)
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Key despill", "Key", "Key Extras", "This is a background-based effect that removes key colour spill in a chromakey", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Key", kNoGroup, 0, "Green|Blue");

DeclareFloatParam (RedAmount, "Red amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLACK float2(0.0, 1.0).xxxy

#define BrdrPixel(SHADER,XY) (IsOutOfBounds(XY) ? BLACK : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_key_gen (sampler Fgd, float2 xy1, sampler Bgd, float2 xy2)
{
   float4 Fgnd = ReadPixel (Fgd, xy1);
   float4 Bgnd = ReadPixel (Bgd, xy2);

   float cDiff = distance (Bgnd.rgb, Fgnd.rgb);

   Fgnd.a = smoothstep (0.0, 0.05, cDiff);

   return Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (G_Key)
{ return fn_key_gen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (KeyDespillGreen)
{
   float4 Back = BrdrPixel (Bg, uv2);
   float4 color = tex2D (G_Key, uv3);

   float mask = saturate (color.g - lerp (color.r, color.b, RedAmount)) * color.a;

   color.g = color.g - mask;

   return color + (Back * mask);
}

DeclarePass (B_Key)
{ return fn_key_gen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (KeyDespillBlue)
{
   float4 Back = BrdrPixel (Bg, uv2);
   float4 color = tex2D (B_Key, uv3);

   float mask = saturate (color.b - lerp (color.r, color.g, RedAmount)) * color.a;

   color.b = color.b - mask;

   return color + (Back * mask);
}

