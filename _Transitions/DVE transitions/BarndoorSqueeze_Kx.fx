// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This is similar to the split squeeze effect, customised to suit its use with blended
 effects.  It moves the separated foreground image halves apart and squeezes them to
 the edges of the screen or expands the halves from the edges.  It can operate either
 vertically or horizontally depending on the user setting.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// User effect BarndoorSqueeze_Fx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Barn door squeeze (keyed)", "Mix", "DVE transitions", "Splits the foreground and squeezes the halves apart horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (Ttype, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta unfolded|Standard transitions");
DeclareIntParam (SetTechnique, "Transition direction", kNoGroup, 0, "Expand horizontal|Expand vertical|Squeeze horizontal|Squeeze vertical");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Split, "Split centre", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen_F (sampler F, float2 xy1, float2 xy2)
{
   float4 Fgnd = tex2D (F, xy2);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (Bg, xy1);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
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

// technique BarndoorExpand_Eh

DeclarePass (Bg_Eh)
{ return Ttype == 0 ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (Super_Eh)
{ return Ttype == 0 ? fn_keygen_F (Bg_Eh, uv2, uv3) : fn_keygen (Bg_Eh, uv1, uv3); }

DeclareEntryPoint (BarndoorExpand_Eh)
{
   float2 xy = Ttype == 0 ? uv1 : uv2;

   float Amt = Ttype == 2 ? 1.0 - Amount : Amount;
   float amount = Amt - 1.0;
   float negAmt = Amt * Split;
   float posAmt = 1.0 - (Amt * (1.0 - Split));

   float4 Fgnd = (uv3.x > posAmt) ? tex2D (Super_Eh, float2 ((uv3.x + amount) / Amt, uv3.y))
               : (uv3.x < negAmt) ? tex2D (Super_Eh, float2 (uv3.x / Amt, uv3.y)) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (xy)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_Eh, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique BarndoorExpand_Ev

DeclarePass (Bg_Ev)
{ return Ttype == 0 ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (Super_Ev)
{ return Ttype == 0 ? fn_keygen_F (Bg_Ev, uv2, uv3) : fn_keygen (Bg_Ev, uv1, uv3); }

DeclareEntryPoint (BarndoorExpand_Ev)
{
   float2 xy = Ttype == 0 ? uv1 : uv2;

   float Amt = Ttype == 2 ? 1.0 - Amount : Amount;
   float amount = Amt - 1.0;
   float negAmt = Amt * (1.0 - Split);
   float posAmt = 1.0 - (Amt * Split);

   float4 Fgnd = (uv3.y > posAmt) ? tex2D (Super_Ev, float2 (uv3.x, (uv3.y + amount) / Amt))
               : (uv3.y < negAmt) ? tex2D (Super_Ev, float2 (uv3.x, uv3.y / Amt)) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (xy)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_Ev, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique BarndoorSqueeze_Sh

DeclarePass (Bg_Sh)
{ return Ttype == 0 ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (Super_Sh)
{ return Ttype == 0 ? fn_keygen_F (Bg_Sh, uv2, uv3) : fn_keygen (Bg_Sh, uv1, uv3); }

DeclareEntryPoint (BarndoorSqueeze_Sh)
{
   float2 xy = Ttype == 0 ? uv1 : uv2;

   float Amt = Ttype == 2 ? 1.0 - Amount : Amount;
   float amount = 1.0 - Amount;
   float negAmt = amount * Split;
   float posAmt = 1.0 - (amount * (1.0 - Split));

   float4 Fgnd = (uv3.x > posAmt) ? tex2D (Super_Sh, float2 ((uv3.x - Amt) / amount, uv3.y))
               : (uv3.x < negAmt) ? tex2D (Super_Sh, float2 (uv3.x / amount, uv3.y)) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (xy)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_Sh, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique BarndoorSqueeze_Sv

DeclarePass (Bg_Sv)
{ return Ttype == 0 ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (Super_Sv)
{ return Ttype == 0 ? fn_keygen_F (Bg_Sv, uv2, uv3) : fn_keygen (Bg_Sv, uv1, uv3); }

DeclareEntryPoint (BarndoorSqueeze_Sv)
{
   float2 xy = Ttype == 0 ? uv1 : uv2;

   float Amt = Ttype == 2 ? 1.0 - Amount : Amount;
   float amount = 1.0 - Amt;
   float negAmt = amount * (1.0 - Split);
   float posAmt = 1.0 - (amount * Split);

   float4 Fgnd = (uv3.y > posAmt) ? tex2D (Super_Sv, float2 (uv3.x, (uv3.y - Amt) / amount))
               : (uv3.y < negAmt) ? tex2D (Super_Sv, float2 (uv3.x, uv3.y / amount)) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (xy)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_Sv, uv3), Fgnd, Fgnd.a);
}

