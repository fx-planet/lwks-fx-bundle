// @Maintainer jwrl
// @Released 2021-08-07
// @Author jwrl
// @Created 2021-08-07
// @see https://www.lwks.com/media/kunena/attachments/6375/EdgeGlow_640.png

/**
 Edge glow (EdgeGlowFx.fx) is an effect that can use image levels or the edges of the
 image to produce a glow effect.  The resulting glow can be applied to the image using
 any of five blend modes.

 The glow can use the native image colours, a preset colour, or two colours which cycle.
 Cycle rate can be adjusted, and the detected edges can be mixed back over the effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect EdgeGlowFx.fx
//
// Version history:
//
// Rewrite 2021-08-07 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Edge glow";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "Adds a level-based or edge-based glow to an image";
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

#define DeclareInput( TEXTURE, SAMPLER ) \
                                         \
   texture TEXTURE;                      \
                                         \
   sampler SAMPLER = sampler_state       \
   {                                     \
      Texture   = <TEXTURE>;             \
      AddressU  = ClampToEdge;           \
      AddressV  = ClampToEdge;           \
      MinFilter = Linear;                \
      MagFilter = Linear;                \
      MipFilter = Linear;                \
   }

#define DeclareTarget( TARGET, TSAMPLE ) \
                                         \
   texture TARGET : RenderColorTarget;   \
                                         \
   sampler TSAMPLE = sampler_state       \
   {                                     \
      Texture   = <TARGET>;              \
      AddressU  = Mirror;                \
      AddressV  = Mirror;                \
      MinFilter = Linear;                \
      MagFilter = Linear;                \
      MipFilter = Linear;                \
   }

#define ExecuteShader(SHD) { PixelShader = compile PROFILE SHD (); }
#define CompP(SHD, PA, PB) { PixelShader = compile PROFILE SHD (PA, PB); }

#define EMPTY    0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define LOOP     12
#define DIVIDE   49

#define RADIUS_1 4.0
#define RADIUS_2 10.0
#define RADIUS_3 20.0
#define RADIUS_4 35.0

#define ANGLE    0.2617993878

#define R_VALUE  0.3
#define G_VALUE  0.59
#define B_VALUE  0.11

#define L_RATE   0.002
#define G_SIZE   0.0005

#define HALF_PI  1.5707963268

float _Progress;
float _Length;

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DeclareInput (Input, s_Input);

DeclareTarget (Edge, s_Edge);
DeclareTarget (Glow_1, s_Glow_1);
DeclareTarget (Glow_2, s_Glow_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int lCycle
<
   string Group = "Glow";
   string Description = "Mode";
   string Enum = "Luminance,Edge detect";
> = 1;

float lRate
<
   string Group = "Glow";
   string Description = "Sensitivity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float Size
<
   string Group = "Glow";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float EdgeMix
<
   string Group = "Glow";
   string Description = "Edge mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

int cCycle
<
   string Group = "Glow colour";
   string Description = "Mode";
   string Enum = "Image colour,Colour 1,Cycle colours";
> = 1;

int SetTechnique
<
   string Group = "Glow colour";
   string Description = "Blend";
   string Enum = "Add,Screen,Lighten,Soft glow,Vivid light";
> = 1;

float cRate
<
   string Group = "Glow colour";
   string Description = "Cycle rate";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float4 Colour_1
<
   string Group = "Glow colour";
   string Description = "Colour 1";
   bool SupportsAlpha = false;
> = { 1.0, 0.75, 0.0, 1.0 };

float4 Colour_2
<
   string Group = "Glow colour";
   string Description = "Colour 2";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 0.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_get_luma (float2 uv)
{
   float4 Fgd = GetPixel (s_Input, uv);

   return (Fgd.r + Fgd.g + Fgd.b) / 3.0;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_edges (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = GetPixel (s_Input, uv);
   float edges, pattern;

   if (lCycle == 1) {
      float nVal = 0.0;
      float xVal = L_RATE * lRate;
      float yVal = xVal * _OutputAspectRatio;

      float p2 = -1.0 * fn_get_luma (uv + float2 (xVal, yVal));
      float p1 = p2;

      p1 += fn_get_luma (uv - float2 (xVal, yVal));
      p1 += fn_get_luma (uv - float2 (xVal, -yVal));
      p1 -= fn_get_luma (uv + float2 (xVal, -yVal));
      p1 -= fn_get_luma (uv + float2 (xVal, nVal)) * 2.0;
      p1 += fn_get_luma (uv - float2 (xVal, nVal)) * 2.0;

      p2 += fn_get_luma (uv - float2 (xVal, yVal));
      p2 -= fn_get_luma (uv - float2 (xVal, -yVal));
      p2 += fn_get_luma (uv + float2 (xVal, -yVal));
      p2 -= fn_get_luma (uv + float2 (nVal, yVal)) * 2.0;
      p2 += fn_get_luma (uv - float2 (nVal, yVal)) * 2.0;

      edges = saturate (p1 * p1 + p2 * p2);
   }
   else {
      edges = dot (Fgd.rgb, float3 (R_VALUE, G_VALUE, B_VALUE));

      if (edges < (1.0 - lRate)) edges = 0.0;
   }

   pattern = _Progress * _Length * (1.0 + (cRate * 20.0));

   if (cCycle == 0) return lerp (EMPTY, Fgd, edges);

   float4 part_1 = edges * Colour_1;
   float4 part_2 = edges * Colour_2;

   pattern = (cCycle == 2) ? (sin (pattern) * 0.5) + 0.5 : 0.0;

   return lerp (part_1, part_2, pattern);
}

float4 ps_glow (float2 uv : TEXCOORD2, uniform sampler gloSampler, uniform float base) : COLOR
{
   float4 retval = tex2D (gloSampler, uv);

   if (Size <= 0.0) return retval;

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * base * Size * G_SIZE;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      retval += tex2D (gloSampler, uv + xy);
      retval += tex2D (gloSampler, uv - xy);
      xy += xy;
      retval += tex2D (gloSampler, uv + xy);
      retval += tex2D (gloSampler, uv - xy);
   }

   return retval / DIVIDE;
}

float4 ps_build_glow (float2 uv : TEXCOORD2) : COLOR
{
   float4 retval = tex2D (s_Glow_2, uv);

   float sizeComp = saturate (Size * 4.0);

   sizeComp = sin (sizeComp * HALF_PI);
   retval = lerp (EMPTY, retval, sizeComp);

   if (lCycle != 1) return retval;

   float4 Glow = max (retval, tex2D (s_Edge, uv));

   return lerp (retval, Glow, EdgeMix);
}

float4 ps_add_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Input, uv1);
   float4 Glow = saturate (Fgnd + tex2D (s_Glow_1, uv2));

   return lerp (Fgnd, Glow, Amount);
}

float4 ps_screen_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd   = GetPixel (s_Input, uv1);
   float4 Glow   = tex2D (s_Glow_1, uv2);
   float4 retval = saturate (Fgnd + Glow - (Fgnd * Glow));

   return lerp (Fgnd, retval, Amount);
}

float4 ps_lighten_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Input, uv1);
   float4 Glow = max (Fgnd, tex2D (s_Glow_1, uv2));

   return lerp (Fgnd, Glow, Amount);
}

float4 ps_soft_glow_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd   = GetPixel (s_Input, uv1);
   float4 Glow   = Fgnd * tex2D (s_Glow_1, uv2);
   float4 retval = saturate (Fgnd + Glow - (Fgnd * Glow));

   return lerp (Fgnd, retval, Amount);
}

float4 ps_vivid_light_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Input, uv1);
   float4 Glow = saturate ((tex2D (s_Glow_1, uv2) * 2.0) + Fgnd - 1.0.xxxx);

   return lerp (Fgnd, Glow, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique addEdge
{
   pass P_1 < string Script = "RenderColorTarget0 = Edge;"; > ExecuteShader (ps_edges)

   pass P_2 < string Script = "RenderColorTarget0 = Glow_1;"; > CompP (ps_glow, s_Edge, RADIUS_1)
   pass P_3 < string Script = "RenderColorTarget0 = Glow_2;"; > CompP (ps_glow, s_Glow_1, RADIUS_2)
   pass P_4 < string Script = "RenderColorTarget0 = Glow_1;"; > CompP (ps_glow, s_Glow_2, RADIUS_3)
   pass P_5 < string Script = "RenderColorTarget0 = Glow_2;"; > CompP (ps_glow, s_Glow_1, RADIUS_4)

   pass P_6 < string Script = "RenderColorTarget0 = Glow_1;"; > ExecuteShader (ps_build_glow)

   pass P_7 ExecuteShader (ps_add_main)
}

technique screenEdge
{
   pass P_1 < string Script = "RenderColorTarget0 = Edge;"; > ExecuteShader (ps_edges)

   pass P_2 < string Script = "RenderColorTarget0 = Glow_1;"; > CompP (ps_glow, s_Edge, RADIUS_1)
   pass P_3 < string Script = "RenderColorTarget0 = Glow_2;"; > CompP (ps_glow, s_Glow_1, RADIUS_2)
   pass P_4 < string Script = "RenderColorTarget0 = Glow_1;"; > CompP (ps_glow, s_Glow_2, RADIUS_3)
   pass P_5 < string Script = "RenderColorTarget0 = Glow_2;"; > CompP (ps_glow, s_Glow_1, RADIUS_4)

   pass P_6 < string Script = "RenderColorTarget0 = Glow_1;"; > ExecuteShader (ps_build_glow)

   pass P_7 ExecuteShader (ps_screen_main)
}

technique lightenEdge
{
   pass P_1 < string Script = "RenderColorTarget0 = Edge;"; > ExecuteShader (ps_edges)

   pass P_2 < string Script = "RenderColorTarget0 = Glow_1;"; > CompP (ps_glow, s_Edge, RADIUS_1)
   pass P_3 < string Script = "RenderColorTarget0 = Glow_2;"; > CompP (ps_glow, s_Glow_1, RADIUS_2)
   pass P_4 < string Script = "RenderColorTarget0 = Glow_1;"; > CompP (ps_glow, s_Glow_2, RADIUS_3)
   pass P_5 < string Script = "RenderColorTarget0 = Glow_2;"; > CompP (ps_glow, s_Glow_1, RADIUS_4)

   pass P_6 < string Script = "RenderColorTarget0 = Glow_1;"; > ExecuteShader (ps_build_glow)

   pass P_7 ExecuteShader (ps_lighten_main)
}

technique softGlowEdge
{
   pass P_1 < string Script = "RenderColorTarget0 = Edge;"; > ExecuteShader (ps_edges)

   pass P_2 < string Script = "RenderColorTarget0 = Glow_1;"; > CompP (ps_glow, s_Edge, RADIUS_1)
   pass P_3 < string Script = "RenderColorTarget0 = Glow_2;"; > CompP (ps_glow, s_Glow_1, RADIUS_2)
   pass P_4 < string Script = "RenderColorTarget0 = Glow_1;"; > CompP (ps_glow, s_Glow_2, RADIUS_3)
   pass P_5 < string Script = "RenderColorTarget0 = Glow_2;"; > CompP (ps_glow, s_Glow_1, RADIUS_4)

   pass P_6 < string Script = "RenderColorTarget0 = Glow_1;"; > ExecuteShader (ps_build_glow)

   pass P_7 ExecuteShader (ps_soft_glow_main)
}

technique vividLightEdge
{
   pass P_1 < string Script = "RenderColorTarget0 = Edge;"; > ExecuteShader (ps_edges)

   pass P_2 < string Script = "RenderColorTarget0 = Glow_1;"; > CompP (ps_glow, s_Edge, RADIUS_1)
   pass P_3 < string Script = "RenderColorTarget0 = Glow_2;"; > CompP (ps_glow, s_Glow_1, RADIUS_2)
   pass P_4 < string Script = "RenderColorTarget0 = Glow_1;"; > CompP (ps_glow, s_Glow_2, RADIUS_3)
   pass P_5 < string Script = "RenderColorTarget0 = Glow_2;"; > CompP (ps_glow, s_Glow_1, RADIUS_4)

   pass P_6 < string Script = "RenderColorTarget0 = Glow_1;"; > ExecuteShader (ps_build_glow)

   pass P_7 ExecuteShader (ps_vivid_light_main)
}

