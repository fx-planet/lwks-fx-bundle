// @Maintainer jwrl
// @Released 2023-01-30
// @Author jwrl
// @Created 2023-01-30

/**
 This is is a truly bizarre transition.  Sort of a stripy blurry dissolve, I guess.  It
 supports titles and other blended effects.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
 Unlike with LW transitions there is no mask.  Instead the ability to crop the effect
 to the background is provided, which dissolves between the cropped areas during the
 transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Transmogrify_Kx.fx
//
// Version history:
//
// Built 2023-01-30 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Transmogrify burst (keyed)", "Mix", "Abstract transitions", "Breaks the outgoing effect into a cloud of particles which blow apart.", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SCALE 0.000545

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

// technique Transmogrify_Kx_F

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

DeclareEntryPoint (Transmogrify_Kx_F)
{
   float2 pixSize = uv3 * float2 (1.0, _OutputAspectRatio) * SCALE;

   pixSize += ((uv3 * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5).xx;

   float2 xy = saturate (pixSize + sqrt (1.0 - _Progress).xx);

   xy.y = 1.0 - xy.x;
   xy = lerp (xy, uv3, Amount);

   float4 Fgnd = tex2D (Super_F, xy);
   float4 Bgnd = tex2D (Bg_F, uv3);
   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;

      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique Transmogrify_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclareEntryPoint (Transmogrify_Kx_I)
{
   float2 pixSize = uv3 * float2 (1.0, _OutputAspectRatio) * SCALE;

   pixSize += ((uv3 * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5).xx;

   float2 xy = saturate (pixSize + sqrt (1.0 - _Progress).xx);

   xy.y = 1.0 - xy.x;
   xy = lerp (xy, uv3, Amount);

   float4 Fgnd = tex2D (Super_I, xy);
   float4 Bgnd = tex2D (Bg_I, uv3);
   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;

      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique Transmogrify_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclareEntryPoint (Transmogrify_Kx_O)
{
   float2 pixSize = uv3 * float2 (1.0, _OutputAspectRatio) * SCALE;

   pixSize += ((uv3 * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5).xx;

   float2 xy = saturate (pixSize + sqrt (_Progress).xx);

   float amount = 1.0 - Amount;

   xy = lerp (xy, uv3, amount);

   float4 Fgnd = tex2D (Super_O, xy);
   float4 Bgnd = tex2D (Bg_O, uv3);
   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - Amount));

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;

      retval = lerp (Fgnd, Bgnd, 1.0 - Amount);
   }

   return retval;
}

