// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This effect is used to transition into or out of blended foregrounds, and is useful with
 titles.  The title fades in from blocks that progressively reduce in size or builds into
 larger and larger blocks as it fades.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Block_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Block dissolve (keyed)", "Mix", "Geometric transitions", "Builds a blended foreground into larger and larger blocks as it fades in or out", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta unfolded|Standard transitions");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (blockSize, "Size", "Blocks", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (AR, "Aspect ratio", "Blocks", kNoFlags, 1.0, 0.25, 4.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLOCKS  0.1

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_block_gen (float2 xy, float range)
{
   float AspectRatio = clamp (AR, 0.01, 10.0);
   float Xsize = max (1e-10, range) * blockSize * BLOCKS;
   float Ysize = Xsize * AspectRatio * _OutputAspectRatio;

   float2 xy1;

   xy1.x = (round ((xy.x - 0.5) / Xsize) * Xsize) + 0.5;
   xy1.y = (round ((xy.y - 0.5) / Ysize) * Ysize) + 0.5;

   return xy1;
}

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

// technique Block_Kx_F

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

DeclareEntryPoint (Block_Kx_F)
{
   float2 xy = (blockSize > 0.0) ? fn_block_gen (uv3, cos (Amount * HALF_PI)) : uv3;

   float4 Fgnd = tex2D (Super_F, xy);

   if (CropEdges && IsOutOfBounds (uv1)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_F, uv3), Fgnd, Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//

// technique Block_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclareEntryPoint (Block_Kx_I)
{
   float2 xy = (blockSize > 0.0) ? fn_block_gen (uv3, cos (Amount * HALF_PI)) : uv3;

   float4 Fgnd = tex2D (Super_I, xy);

   if (CropEdges && IsOutOfBounds (uv2)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_I, uv3), Fgnd, Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//

// technique Block_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclareEntryPoint (Block_Kx_O)
{
   float2 xy = (blockSize > 0.0) ? fn_block_gen (uv3, sin (Amount * HALF_PI)) : uv3;

   float4 Fgnd = tex2D (Super_O, xy);

   if (CropEdges && IsOutOfBounds (uv2)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_O, uv3), Fgnd, Fgnd.a * Amount);
}

