// @Maintainer jwrl
// @Released 2023-01-25
// @Author jwrl
// @Created 2023-01-25

/**
 This is a special effect that generates single and double rainbows.  The blue end of the
 spectrum has adjustable falloff to give a fade out that is more like what happens in
 nature.   The rainbow is blended with the background image using a modified screen blend
 that can be adjusted in strength according to the inverse of the background brightness.
 It can also be varied in blend softness.  The default crop settings will produce a 90
 degree arc (plus and minus 45 degrees), but can be adjusted to whatever angle you need
 over a 180 degree range.

 The secondary rainbow is inverted and inherits Amount, Radius, Width, Falloff and Origin
 from the primary rainbow.  The master Amount is modified by the secondary rainbow Amount,
 and master Radius and Width are modified by the secondary rainbow Offset.  The secondary
 rainbow's crop angle and feathering are independent of the master rainbow settings.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rainbow.fx
//
// Version history:
//
// Built 2023-01-25 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Rainbow", "Stylize", "Special Effects", "Here's why there are so many songs about rainbows, frog", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Radius, "Radius", kNoGroup, kNoFlags, 0.5, 0.1, 2.0);
DeclareFloatParam (Width, "Width", kNoGroup, kNoFlags, 0.125, 0.05, 0.4);
DeclareFloatParam (Falloff, "Falloff", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Pos_X, "Origin", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Pos_Y, "Origin", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (L_angle, "Left angle", "Primary rainbow cropping", kNoFlags, 45.0, 0.0, 180.0);
DeclareFloatParam (L_soft, "Left softness", "Primary rainbow cropping", kNoFlags, 0.175, 0.0, 1.0);
DeclareFloatParam (R_angle, "Right angle", "Primary rainbow cropping", kNoFlags, -45.0, -180.0, 0.0);
DeclareFloatParam (R_soft, "Right softness", "Primary rainbow cropping", kNoFlags, 0.175, 0.0, 1.0);

DeclareFloatParam (Amount_2, "Amount", "Secondary rainbow offsets", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Offset, "Displacement", "Secondary rainbow offsets", kNoFlags, 0.2, 0.0, 1.0);

DeclareFloatParam (L_angle_2, "Left angle", "Secondary rainbow cropping", kNoFlags, 45.0, 0.0, 180.0);
DeclareFloatParam (L_soft_2, "Left softness", "Secondary rainbow cropping", kNoFlags, 0.175, 0.0, 1.0);
DeclareFloatParam (R_angle_2, "Right angle", "Secondary rainbow cropping", kNoFlags, -45.0, -180.0, 0.0);
DeclareFloatParam (R_soft_2, "Right softness", "Secondary rainbow cropping", kNoFlags, 0.175, 0.0, 1.0);

DeclareFloatParam (Clip, "Amount", "Background breakthrough", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Range, "Softness", "Background breakthrough", kNoFlags, 0.2, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define INNER      true
#define OUTER      false

#define CIRCLE     0.7927904259
#define RADIUS     1.6666666667

#define HUE        float3(1.0, 2.0 / 3.0, 1.0 / 3.0)
#define LUMA       float3(0.2989, 0.5866, 0.1145)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_get_mask (sampler S, float2 xy, float4 m_rng, bool inner)
{
   if (xy.y < 0.0) return 0.0;

   float c, s;

   sincos (radians (-m_rng.w), s, c);

   float2 edges = float2 (-m_rng.w * m_rng.x, m_rng.y * m_rng.z) / 450.0;
   float3 xyz = float3 (-xy.x, (edges - xy.yy) / _OutputAspectRatio) * 0.25;
   float2 uv = mul (float2x2 (c, -s, s, c), xyz.xy);

   uv.x += 0.5;
   uv.y *= _OutputAspectRatio;

   float mask = inner ? tex2D (S, uv).w : tex2D (S, uv).y;

   sincos (radians (-m_rng.y), s, c);
   uv = mul (float2x2 (c, -s, s, c), xyz.xz);
   uv.x += 0.5;
   uv.y *= _OutputAspectRatio;

   return inner ? 1.0 - max (mask, tex2D (S, uv).x)
                : 1.0 - max (mask, tex2D (S, uv).z);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (MaskBounds)
{
   float rng = uv0.y * 10.0;
   float L_1 = (rng > L_soft) ? 1.0 : rng / max (1e-10, L_soft);
   float R_1 = (rng > R_soft) ? 1.0 : rng / max (1e-10, R_soft);
   float L_2 = (rng > L_soft_2) ? 1.0 : rng / max (1e-10, L_soft_2);
   float R_2 = (rng > R_soft_2) ? 1.0 : rng / max (1e-10, R_soft_2);

   return float4 (R_1, L_2, R_2, L_1);
}

DeclareEntryPoint (Rainbow)
{
   float4 Bgnd = ReadPixel (Inp, uv1);
   float4 Rmsk = float4 (L_soft, R_angle, R_soft, L_angle);

   if (Bgnd.a <= 0.0) return kTransparentBlack;

   float2 xy = float2 (Pos_X - uv2.x, 1.0 - uv2.y - Pos_Y);

   float radius  = max (1.0e-6, Radius);
   float outer   = length (float2 (xy.x, xy.y / _OutputAspectRatio)) * RADIUS;
   float inner   = radius * CIRCLE;
   float width   = radius * Width;
   float rainbow = saturate ((outer - inner) / width);
   float alpha   = saturate (2.0 - abs ((rainbow * 4.0) - 2.0));
   float bg_vis  = dot (Bgnd.rgb, LUMA);

   bg_vis = saturate ((bg_vis - (Range * 0.25) + Clip - 1.0) / max (1.0e-6, Range));

   float4 Fgnd = saturate (((1.0 - rainbow) * 4.0 / 3.0) - 1.0 / 6.0).xxxx;

   rainbow *= alpha;

   Fgnd.rgb = saturate (abs (frac (saturate (Fgnd.g - 0.1).xxx + HUE) * 6.0 - 3.0) - 1.0.xxx);
   Fgnd.a   = lerp (alpha, rainbow, Falloff);
   Fgnd.rgb = Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb);
   Fgnd.a  -= bg_vis;

   Fgnd = saturate (Fgnd);
   Fgnd = lerp (Bgnd, Fgnd, Fgnd.a * Amount);
   Bgnd = lerp (Bgnd, Fgnd, fn_get_mask (MaskBounds, xy, Rmsk, INNER));

   if (Amount_2 <= 0.0) return Bgnd;

   Rmsk   = float4 (L_soft_2, R_angle_2, R_soft_2, L_angle_2);
   radius = (Offset * 0.8) + 1.2;
   inner *= radius;
   width *= sqrt (radius);

   rainbow = saturate ((outer - inner) / width);
   alpha   = saturate (2.0 - abs ((rainbow * 4.0) - 2.0));

   Fgnd = saturate ((rainbow * 4.0 / 3.0) - 1.0 / 6.0).xxxx;

   rainbow  = (1.0 - rainbow);
   rainbow *= rainbow * alpha;

   Fgnd.rgb = saturate (abs (frac (saturate (Fgnd.g - 0.1).xxx + HUE) * 6.0 - 3.0) - 1.0.xxx);
   Fgnd.a   = lerp (alpha, rainbow, Falloff);
   Fgnd.rgb = Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb);
   Fgnd.a  -= bg_vis;

   Fgnd = saturate (Fgnd);
   Fgnd = lerp (Bgnd, Fgnd, Fgnd.a * Amount * Amount_2);

   return lerp (Bgnd, Fgnd, fn_get_mask (MaskBounds, xy, Rmsk, OUTER));
}

