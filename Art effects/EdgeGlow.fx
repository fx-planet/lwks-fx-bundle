// @Maintainer jwrl
// @Released 2018-09-26
// @Author jwrl
// @Created 2016-06-30
// @Licence GPLv3
// @see https://www.lwks.com/media/kunena/attachments/6375/EdgeGlow_640.png
//=========================================================================================//
// Lightworks user effect EdgeGlow.fx
//
// This is an effect that can use image levels or the edges of the image to produce a
// glow effect.  The resulting glow can be applied to the image using any of five blend
// modes.
//
// The glow can use the native image colours, a preset colour, or two colours which cycle.
// Cycle rate can be adjusted, and the detected edges can be mixed back over the effect.
//=========================================================================================//

//-----------------------------------------------------------------------------------------//
// For full GPLv3 licence details see https://www.gnu.org/licenses/gpl-3.0.en.html
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Cross platform compatibility check 27 July 2017 jwrl.
// Added workaround for the interlaced media height bug in Lightworks effects.
// Explicitly defined a float4 variable to address the different behaviour of the D3D
// and Cg compilers.
// Efficiency fix:  used SetTechnique instead of conditional execution to achieve the
// differing blend modes.
// Halved the samplers used by the glow for the same reason.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//
// Modified by LW user jwrl 5 July 2018.
// Made blur calculations frame based rather than pixel based.
// Changed clamp addressing to mirror addressing for glow calculations.  This also solves
// a potential cross-platform bug before it arises.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Edge glow";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "Adds a level-based or edge-based glow to an image";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Edge   : RenderColorTarget;
texture Glow_1 : RenderColorTarget;
texture Glow_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state {
   Texture   = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Edge = sampler_state {
   Texture   = <Edge>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Glow_1 = sampler_state
{
   Texture   = <Glow_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Glow_2 = sampler_state
{
   Texture   = <Glow_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

#define EMPTY    (0.0).xxxx

float _Progress;

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_get_edge (float2 uv)
{
   float4 Fgd = tex2D (s_Foreground, uv);

   return (Fgd.r + Fgd.g + Fgd.b) / 3.0;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_edges (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, uv);
   float edges, pattern;

   if (lCycle == 1) {
      float nVal = 0.0;
      float xVal = L_RATE * lRate;
      float yVal = xVal * _OutputAspectRatio;

      float p2 = -1.0 * fn_get_edge (uv + float2 (xVal, yVal));
      float p1 = p2;

      p1 += fn_get_edge (uv - float2 (xVal, yVal));
      p1 += fn_get_edge (uv - float2 (xVal, -yVal));
      p1 -= fn_get_edge (uv + float2 (xVal, -yVal));
      p1 -= fn_get_edge (uv + float2 (xVal, nVal)) * 2.0;
      p1 += fn_get_edge (uv - float2 (xVal, nVal)) * 2.0;

      p2 += fn_get_edge (uv - float2 (xVal, yVal));
      p2 -= fn_get_edge (uv - float2 (xVal, -yVal));
      p2 += fn_get_edge (uv + float2 (xVal, -yVal));
      p2 -= fn_get_edge (uv + float2 (nVal, yVal)) * 2.0;
      p2 += fn_get_edge (uv - float2 (nVal, yVal)) * 2.0;

      edges = saturate (p1 * p1 + p2 * p2);
   }
   else {
      edges = dot (Fgd.rgb, float3 (R_VALUE, G_VALUE, B_VALUE));

      if (edges < (1.0 - lRate)) edges = 0.0;
   }

   pattern = _Progress * (1.0 + (cRate * 20.0)) * 5.0;

   if (cCycle == 0) return lerp (EMPTY, Fgd, edges);

   float4 part_1 = edges * Colour_1;
   float4 part_2 = edges * Colour_2;

   pattern = (cCycle == 2) ? (sin (pattern) * 0.5) + 0.5 : 0.0;

   return lerp (part_1, part_2, pattern);
}

float4 ps_glow (float2 uv : TEXCOORD1, uniform sampler gloSampler, uniform float base) : COLOR
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

float4 ps_build_glow (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Glow_2, uv);

   float sizeComp = saturate (Size * 4.0);

   sizeComp = sin (sizeComp * HALF_PI);
   retval = lerp (EMPTY, retval, sizeComp);

   if (lCycle != 1) return retval;

   float4 Glow = max (retval, tex2D (s_Edge, uv));

   return lerp (retval, Glow, EdgeMix);
}

float4 ps_add_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd  = tex2D (s_Foreground, uv);
   float4 Glow = saturate (Fgd + tex2D (s_Glow_1, uv));

   return lerp (Fgd, Glow, Amount);
}

float4 ps_screen_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd    = tex2D (s_Foreground, uv);
   float4 Glow   = tex2D (s_Glow_1, uv);
   float4 retval = saturate (Fgd + Glow - (Fgd * Glow));

   return lerp (Fgd, retval, Amount);
}

float4 ps_lighten_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd  = tex2D (s_Foreground, uv);
   float4 Glow = max (Fgd, tex2D (s_Glow_1, uv));

   return lerp (Fgd, Glow, Amount);
}

float4 ps_soft_glow_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd    = tex2D (s_Foreground, uv);
   float4 Glow   = Fgd * tex2D (s_Glow_1, uv);
   float4 retval = saturate (Fgd + Glow - (Fgd * Glow));

   return lerp (Fgd, retval, Amount);
}

float4 ps_vivid_light_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd  = tex2D (s_Foreground, uv);
   float4 Glow = saturate ((tex2D (s_Glow_1, uv) * 2.0) + Fgd - 1.0.xxxx);

   return lerp (Fgd, Glow, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique addEdge
{
   pass P_1
   < string Script = "RenderColorTarget0 = Edge;"; >
   { PixelShader = compile PROFILE ps_edges (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (s_Edge, RADIUS_1); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_1, RADIUS_2); }

   pass P_4
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_2, RADIUS_3); }

   pass P_5
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_1, RADIUS_4); }

   pass P_6
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_build_glow (); }

   pass P_7
   { PixelShader = compile PROFILE ps_add_main (); }
}

technique screenEdge
{
   pass P_1
   < string Script = "RenderColorTarget0 = Edge;"; >
   { PixelShader = compile PROFILE ps_edges (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (s_Edge, RADIUS_1); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_1, RADIUS_2); }

   pass P_4
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_2, RADIUS_3); }

   pass P_5
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_1, RADIUS_4); }

   pass P_6
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_build_glow (); }

   pass P_7
   { PixelShader = compile PROFILE ps_screen_main (); }
}

technique lightenEdge
{
   pass P_1
   < string Script = "RenderColorTarget0 = Edge;"; >
   { PixelShader = compile PROFILE ps_edges (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (s_Edge, RADIUS_1); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_1, RADIUS_2); }

   pass P_4
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_2, RADIUS_3); }

   pass P_5
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_1, RADIUS_4); }

   pass P_6
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_build_glow (); }

   pass P_7
   { PixelShader = compile PROFILE ps_lighten_main (); }
}

technique softGlowEdge
{
   pass P_1
   < string Script = "RenderColorTarget0 = Edge;"; >
   { PixelShader = compile PROFILE ps_edges (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (s_Edge, RADIUS_1); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_1, RADIUS_2); }

   pass P_4
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_2, RADIUS_3); }

   pass P_5
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_1, RADIUS_4); }

   pass P_6
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_build_glow (); }

   pass P_7
   { PixelShader = compile PROFILE ps_soft_glow_main (); }
}

technique vividLightEdge
{
   pass P_1
   < string Script = "RenderColorTarget0 = Edge;"; >
   { PixelShader = compile PROFILE ps_edges (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (s_Edge, RADIUS_1); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_1, RADIUS_2); }

   pass P_4
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_2, RADIUS_3); }

   pass P_5
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (s_Glow_1, RADIUS_4); }

   pass P_6
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_build_glow (); }

   pass P_7
   { PixelShader = compile PROFILE ps_vivid_light_main (); }
}
