// @Maintainer jwrl
// @Released 2023-02-28
// @Author jwrl
// @Created 2023-02-28

/**
 This is a delta mask or difference matte effect originally based on work done by
 khaver which subtracts the reference from the foreground to produce an image with
 transparency.  This is then used to key the result over the background in the same
 way as a standard key.  The implementation is entirely my own.

 This effect allows the foreground to be keyed over transparent black allowing the
 output to be used with external blend or DVE effects if necessary.  It also allows
 the edges of the key to be eroded and/or feathered.

 NOTE: This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DeltaBlend.fx
//
// Version history:
//
// Built 2023-02-28 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Delta blend", "Key", "Key Extras", "This masks the foreground into the background using the reference input.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg, Ref);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (AssignBg, "Assign background", "Master settings", 0, "Use Bg input|Use Ref input");
DeclareIntParam (AssignRef, "Assign reference", "Master settings", 0, "Use Ref input|Use Bg input");

DeclareFloatParam (Clip, "Key clip", "Master settings", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Gain, "Key gain", "Master settings", kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (ErodeExpand, "Erode/expand", "Edge adjustment", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Feather, "Feather", "Edge adjustment", kNoFlags, 0.1, 0.0, 1.0);

DeclareIntParam (ShowKey, "Operating mode", kNoGroup, 0, "Key Fg over Bg or Ref|Display Fg masked by key|Display key signal only");

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define LOOP   12
#define DIVIDE 25

#define RADIUS 0.002
#define ANGLE  0.2617993878

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Bgd)
{ return AssignBg ? ReadPixel (Ref, uv3) : ReadPixel (Bg, uv2); }

DeclarePass (RefInp)
{ return AssignRef ? ReadPixel (Bg, uv2) : ReadPixel (Ref, uv3); }

DeclarePass (Fgd)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Rfnc = tex2D (RefInp, uv4);

   float cDiff = distance (Rfnc.r, Fgnd.r);
   float alpha = saturate ((cDiff - Clip) / Gain);

   cDiff = distance (Rfnc.g, Fgnd.g);
   alpha = max (alpha, saturate ((cDiff - Clip) / Gain));
   cDiff = distance (Rfnc.b, Fgnd.b);
   alpha = max (alpha, saturate ((cDiff - Clip) / Gain));

   Fgnd.a = min (Fgnd.a, alpha);

   return Fgnd;
}

DeclarePass (ErodedKey)
{
   float2 radius = float2 (1.0, _OutputAspectRatio) * RADIUS;
   float2 xy;

   float4 Fgnd = tex2D (Fgd, uv4);

   float alpha = Fgnd.a;
   float Emin = 12.0 - (11.5 * ErodeExpand);          // Calculate the minimum clip value required

   // Blur the alpha to spread the available clipping range.  After this it will be 0.0 - 25.0.

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      alpha += tex2D (Fgd, uv4 + xy).a;
      alpha += tex2D (Fgd, uv4 - xy).a;
   }

   alpha  = saturate (alpha - Emin);                  // Clip the alpha value inside a 0.0 to 1.0 range
   Fgnd.a = alpha * alpha * (3.0 - (2.0 * alpha));    // Now apply an S curve to the alpha range

   return Fgnd;
}

DeclareEntryPoint (DeltaKeyWithBg)
{
   float4 Fgnd = tex2D (ErodedKey, uv4);
   float4 Bgnd = tex2D (Bgd, uv4);
   float4 retval;

   float2 radius = float2 (1.0, _OutputAspectRatio) * Feather * RADIUS;
   float2 xy;

   float alpha = Fgnd.a;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      alpha += tex2D (ErodedKey, uv4 + xy).a;
      alpha += tex2D (ErodedKey, uv4 - xy).a;
      xy += xy;
      alpha += tex2D (ErodedKey, uv4 + xy).a;
      alpha += tex2D (ErodedKey, uv4 - xy).a;
   }

   alpha = saturate ((alpha / DIVIDE) - 1.0);
   Fgnd.a = min (Fgnd.a, alpha);

   if (ShowKey == 2) { retval = float4 (Fgnd.aaa, 1.0); }
   else {
      if (Fgnd.a == 0.0) Fgnd = kTransparentBlack;

      if (ShowKey == 1) { retval = float4 (Fgnd.rgb, 1.0); }
      else retval = lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
   }

   return lerp (Bgnd, retval, tex2D (Mask, uv4).x);
}

