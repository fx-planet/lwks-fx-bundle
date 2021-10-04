// @Maintainer jwrl
// @Released 2021-10-03
// @Author jwrl
// @Created 2020-08-08
// @see https://www.lwks.com/media/kunena/attachments/6375/Rainbow_v_2_640.png

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
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rainbow.fx
//
// This effect was built after experience with an earlier rainbow effect, which tried to
// be all things to all people, and in my opinion, failed dismally.  This was written with
// a new user interface and re-engineered mask generation.  The previous version produced
// unexpected hard edges under the right conditions as the masks were rotated.  This uses
// a more direct method of generating the masks.
//
// However this means that the now pointless extra pass used to generate a second mask for
// the double rainbow could be dropped.  Another side effect was that providing independent
// mask softness adjustment for the outer rainbow became possible.  Because the moondog
// effect was dropped it is also now possible to specify the crop angles in degrees.  We
// have also improved the mask edge softness and opacity falloff over brighter backgrounds.
//
// Version history:
//
// Update 2021-10-05 jwrl.
// Removed v2 attribute.
//
// Update 2020-11-15 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified jwrl 2020-08-12:
// Improved width and falloff calculations for the secondary rainbow.
// Tightened mask recovery code.
// Added background breakthrough controls - really just a feathered, inverted luma key.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Rainbow";
   string Category    = "Stylize";
   string SubCategory = "Special Effects";
   string Notes       = "Here's why there are so many songs about rainbows, frog";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
texture TEXTURE;                      \
                                      \
sampler SAMPLER = sampler_state       \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY      0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define INNER      true
#define OUTER      false

#define CIRCLE     0.7927904259
#define RADIUS     1.6666666667

#define EMPTY      0.0.xxxx

#define HUE        float3(1.0, 2.0 / 3.0, 1.0 / 3.0)
#define LUMA       float3(0.2989, 0.5866, 0.1145)

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

DefineTarget (Msk, s_Mask);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Radius
<
   string Description = "Radius";
   float MinVal = 0.1;
   float MaxVal = 2.0;
> = 0.5;

float Width
<
   string Description = "Width";
   float MinVal = 0.05;
   float MaxVal = 0.4;
> = 0.125;

float Falloff
<
   string Description = "Falloff";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Pos_X
<
   string Description = "Origin";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Pos_Y
<
   string Description = "Origin";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float L_angle
<
   string Group = "Primary rainbow cropping";
   string Description = "Left angle";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 45.0;

float L_soft
<
   string Group = "Primary rainbow cropping";
   string Description = "Left softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.175;

float R_angle
<
   string Group = "Primary rainbow cropping";
   string Description = "Right angle";
   float MinVal = -180.0;
   float MaxVal = 0.0;
> = -45.0;

float R_soft
<
   string Group = "Primary rainbow cropping";
   string Description = "Right softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.175;

float Amount_2
<
   string Group = "Secondary rainbow offsets";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Offset
<
   string Group = "Secondary rainbow offsets";
   string Description = "Displacement";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float L_angle_2
<
   string Group = "Secondary rainbow cropping";
   string Description = "Left angle";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 45.0;

float L_soft_2
<
   string Group = "Secondary rainbow cropping";
   string Description = "Left softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.175;

float R_angle_2
<
   string Group = "Secondary rainbow cropping";
   string Description = "Right angle";
   float MinVal = -180.0;
   float MaxVal = 0.0;
> = -45.0;

float R_soft_2
<
   string Group = "Secondary rainbow cropping";
   string Description = "Right softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.175;

float Clip
<
   string Group = "Background breakthrough";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Range
<
   string Group = "Background breakthrough";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_get_mask (float4 m_rng, float2 xy, bool inner)
{
   if (xy.y < 0.0) return 0.0;

   float c, s;

   sincos (radians (-m_rng.w), s, c);

   float2 edges = float2 (-m_rng.w * m_rng.x, m_rng.y * m_rng.z) / 450.0;
   float3 xyz = float3 (-xy.x, (edges - xy.yy) / _OutputAspectRatio) * 0.25;
   float2 uv = mul (float2x2 (c, -s, s, c), xyz.xy);

   uv.x += 0.5;
   uv.y *= _OutputAspectRatio;

   float mask = inner ? GetPixel (s_Mask, uv).w : GetPixel (s_Mask, uv).y;

   sincos (radians (-m_rng.y), s, c);
   uv = mul (float2x2 (c, -s, s, c), xyz.xz);
   uv.x += 0.5;
   uv.y *= _OutputAspectRatio;

   return inner ? 1.0 - max (mask, GetPixel (s_Mask, uv).x)
                : 1.0 - max (mask, GetPixel (s_Mask, uv).z);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mask (float2 uv : TEXCOORD0) : COLOR
{
   float rng = uv.y * 10.0;
   float L_1 = (rng > L_soft) ? 1.0 : rng / max (1e-10, L_soft);
   float R_1 = (rng > R_soft) ? 1.0 : rng / max (1e-10, R_soft);
   float L_2 = (rng > L_soft_2) ? 1.0 : rng / max (1e-10, L_soft_2);
   float R_2 = (rng > R_soft_2) ? 1.0 : rng / max (1e-10, R_soft_2);

   return float4 (R_1, L_2, R_2, L_1);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = tex2D (s_Input, uv);
   float4 Mask = float4 (L_soft, R_angle, R_soft, L_angle);

   float2 xy = float2 (Pos_X - uv.x, 1.0 - uv.y - Pos_Y);

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
   Bgnd = lerp (Bgnd, Fgnd, fn_get_mask (Mask, xy, INNER));

   if (Amount_2 <= 0.0) return Bgnd;

   Mask   = float4 (L_soft_2, R_angle_2, R_soft_2, L_angle_2);
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

   return lerp (Bgnd, Fgnd, fn_get_mask (Mask, xy, OUTER));
}

//-----------------------------------------------------------------------------------------//;
// Techniques;
//-----------------------------------------------------------------------------------------//;

technique Rainbow_v2
{
   pass P_1 < string Script = "RenderColorTarget0 = Msk;"; > ExecuteShader (ps_mask)
   pass P_2 ExecuteShader (ps_main)
}

