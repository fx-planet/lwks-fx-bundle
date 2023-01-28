// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This mimics the Lightworks squeeze effect but transitions alpha and delta keys in or out.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Squeeze_Fx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Squeeze transition (keyed)", "Mix", "DVE transitions", "Mimics the Lightworks squeeze effect with the blended foreground", CanSize);

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
DeclareIntParam (SetTechnique, "Type", kNoGroup, 0, "Squeeze Right|Squeeze Down|Squeeze Left|Squeeze Up");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

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

// SqueezeRight

DeclarePass (Fg_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_R)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_R)
{ return fn_keygen (Fg_R, Bg_R, uv3); }

DeclareEntryPoint (SqueezeRight)
{
   float4 Bgnd, Fgnd;

   float2 xy;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
                           : float2 ((uv3.x - 1.0) / (1.0 - Amount) + 1.0, uv3.y);
   }
   else xy = (Amount == 0.0) ? float2 (2.0, uv3.y) : float2 (uv3.x / Amount, uv3.y);

   if (Ttype == 0) {
      Bgnd = tex2D (Fg_R, uv3);
      Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : tex2D (Super_R, xy);
   }
   else {
      Bgnd = tex2D (Bg_R, uv3);
      Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_R, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}


// SqueezeDown

DeclarePass (Fg_D)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_D)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_D)
{ return fn_keygen (Fg_D, Bg_D, uv3); }

DeclareEntryPoint (SqueezeDown)
{
   float4 Bgnd, Fgnd;

   float2 xy;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, (uv3.y - 1.0) / (1.0 - Amount) + 1.0);
   }
   else xy = (Amount == 0.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, uv3.y / Amount);

   if (Ttype == 0) {
      Bgnd = tex2D (Fg_D, uv3);
      Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : tex2D (Super_D, xy);
   }
   else {
      Bgnd = tex2D (Bg_D, uv3);
      Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_D, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// SqueezeLeft

DeclarePass (Fg_L)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_L)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_L)
{ return fn_keygen (Fg_L, Bg_L, uv3); }

DeclareEntryPoint (SqueezeLeft)
{
   float4 Bgnd, Fgnd;

   float2 xy;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y) : float2 (uv3.x  / (1.0 - Amount), uv3.y);
   }
   else xy = (Amount == 0.0) ? float2 (2.0, uv3.y) : float2 ((uv3.x - 1.0) / Amount + 1.0, uv3.y);

   if (Ttype == 0) {
      Bgnd = tex2D (Fg_L, uv3);
      Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : tex2D (Super_L, xy);
   }
   else {
      Bgnd = tex2D (Bg_L, uv3);
      Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_L, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// SqueezeUp

DeclarePass (Fg_U)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_U)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_U)
{ return fn_keygen (Fg_U, Bg_U, uv3); }

DeclareEntryPoint (SqueezeUp)
{
   float4 Bgnd, Fgnd;

   float2 xy;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, uv3.y  / (1.0 - Amount));
   }
   else xy = (Amount == 0.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, (uv3.y - 1.0) / Amount + 1.0);

   if (Ttype == 0) {
      Bgnd = tex2D (Fg_U, uv3);
      Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : tex2D (Super_U, xy);
   }
   else {
      Bgnd = tex2D (Bg_U, uv3);
      Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_U, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

