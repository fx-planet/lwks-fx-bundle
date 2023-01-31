// @Maintainer jwrl
// @Released 2023-01-31
// @Author jwrl
// @Created 2023-01-31

/**
 This effect dissolves a blended foreground image in or out through a complex colour
 translation while performing what is essentially a non-additive mix.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourSizzler_Kx.fx
//
// This effect is a combination of two previous effects, ColourSizzler_Ax and
// ColourSizzler_Adx.
//
// Version history:
//
// Built 2023-01-31 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Colour sizzler (keyed)", "Mix", "Colour transitions", "Transitions the blended foreground in or out using a complex colour translation", CanSize);

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

DeclareFloatParam (Saturation, "Saturation", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (HueCycle, "Cycle rate", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SQRT_3  1.7320508076
#define TWO_PI  6.2831853072

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen_F (sampler F, sampler B, float2 xy)
{
   float4 Fgnd = tex2D (F, xy);

   if (Source == 0) {
      float4 Bgnd = tex2D (B, xy);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 fn_keygen (sampler F, sampler B, float2 xy)
{
   float4 Fgnd = tex2D (F, xy);

   if (Source == 0) {
      float4 Bgnd = tex2D (B, xy);

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

// technique ColourSizzler_Kx_F

DeclarePass (Fg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_F)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (ColourSizzler_Kx_F)
{
   float amount = 1.0 - Amount;

   float4 Fgnd = CropEdges && IsOutOfBounds (uv1) ? kTransparentBlack : fn_keygen_F (Fg_F, Bg_F, uv3);
   float4 Bgnd = tex2D (Bg_F, uv3);
   float4 Svid = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 Temp = max (Svid * min (1.0, 2.0 * (1.0 - amount)), Bgnd * min (1.0, 2.0 * amount));

   Svid = max (Svid, Bgnd);

   float Luma  = 0.1 + (0.5 * Svid.x);
   float Satn  = Svid.y * Saturation;
   float Hue   = frac (Svid.z + (amount * HueCycle));
   float HueX3 = 3.0 * Hue;

   Hue = SQRT_3 * tan ((Hue - ((floor (HueX3) + 0.5) / 3.0)) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   Svid.rgb = (HueX3 < 1.0) ? float3 (Green, Blue, Red)
            : (HueX3 < 2.0) ? float3 (Red, Green, Blue)
                            : float3 (Blue, Red, Green);

   float mixval = abs (2.0 * (0.5 - amount));

   mixval *= mixval;
   Temp    = lerp (Svid, Temp, mixval);
   Fgnd.a  = Fgnd.a > 0.0 ? lerp (1.0, Fgnd.a, amount) : 0.0;

   return lerp (Bgnd, Temp, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique ColourSizzler_Kx_I

DeclarePass (Fg_I)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (ColourSizzler_Kx_I)
{
   float amount = 1.0 - Amount;

   float4 Fgnd = CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : fn_keygen (Fg_I, Bg_I, uv3);
   float4 Bgnd = tex2D (Bg_I, uv3);
   float4 Svid = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 Temp = max (Svid * min (1.0, 2.0 * (1.0 - amount)), Bgnd * min (1.0, 2.0 * amount));

   Svid = max (Svid, Bgnd);

   float Luma  = 0.1 + (0.5 * Svid.x);
   float Satn  = Svid.y * Saturation;
   float Hue   = frac (Svid.z + (amount * HueCycle));
   float HueX3 = 3.0 * Hue;

   Hue = SQRT_3 * tan ((Hue - ((floor (HueX3) + 0.5) / 3.0)) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   Svid.rgb = (HueX3 < 1.0) ? float3 (Green, Blue, Red)
            : (HueX3 < 2.0) ? float3 (Red, Green, Blue)
                            : float3 (Blue, Red, Green);

   float mixval = abs (2.0 * (0.5 - amount));

   mixval *= mixval;
   Temp    = lerp (Svid, Temp, mixval);
   Fgnd.a  = Fgnd.a > 0.0 ? lerp (1.0, Fgnd.a, amount) : 0.0;

   return lerp (Bgnd, Temp, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique ColourSizzler_Kx_O

DeclarePass (Fg_O)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (ColourSizzler_Kx_O)
{
   float4 Fgnd = CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : fn_keygen (Fg_O, Bg_O, uv3);
   float4 Bgnd = tex2D (Bg_O, uv3);
   float4 Svid = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 Temp = max (Svid * min (1.0, 2.0 * (1.0 - Amount)), Bgnd * min (1.0, 2.0 * Amount));

   Svid = max (Svid, Bgnd);

   float Luma  = 0.1 + (0.5 * Svid.x);
   float Satn  = Svid.y * Saturation;
   float Hue   = frac (Svid.z + (Amount * HueCycle));
   float HueX3 = 3.0 * Hue;

   Hue = SQRT_3 * tan ((Hue - ((floor (HueX3) + 0.5) / 3.0)) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   Svid.rgb = (HueX3 < 1.0) ? float3 (Green, Blue, Red)
            : (HueX3 < 2.0) ? float3 (Red, Green, Blue)
                            : float3 (Blue, Red, Green);

   float mixval = abs (2.0 * (0.5 - Amount));

   mixval *= mixval;
   Temp    = lerp (Svid, Temp, mixval);
   Fgnd.a  = Fgnd.a > 0.0 ? lerp (1.0, Fgnd.a, Amount) : 0.0;

   return lerp (Bgnd, Temp, Fgnd.a);
}

