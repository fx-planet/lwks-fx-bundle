//--------------------------------------------------------------//
// Lightworks user effect EdgeGlow.fx
//
// Created by LW user jwrl 30 June 2016.
//
// This is an effect that can use image levels or the edges of
// the image to produce a glow effect.  The resulting glow can
// be applied to the image using any of five blend modes.
//
// The glow can use the native image colours, a preset colour,
// or two colours which cycle.  Cycle rate can be adjusted,
// and the detected edges can be mixed back over the effect.
//
// Cross platform compatibility check 27 July 2017 jwrl.
//
// Added workaround for the interlaced media height bug in
// Lightworks effects.
//
// Explicitly defined a float4 variable to address the
// different behaviour of the D3D and Cg compilers.
//
// Used SetTechnique instead of conditional execution to
// achieve the differing blend modes.  It isn't much, I
// know, but every little helps.  Halved the samplers used
// by the glow for the same reason.
//
// Version 14.1 update 5 December 2017 by jwrl.
//
// Added LINUX and OSX test to allow support for changing
// "Clamp" to "ClampToEdge" on those platforms.  It will now
// function correctly when used with Lightworks versions 14.5
// and higher under Linux or OS-X and fixes a bug associated
// with using this effect with transitions on those platforms.
//
// The bug still exists when using older versions of Lightworks.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Edge glow";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture Edge : RenderColorTarget;

texture Glow_1   : RenderColorTarget;
texture Glow_2   : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef OSX
#define Clamp ClampToEdge
#endif

sampler FgdSampler = sampler_state {
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler EdgSampler = sampler_state {
   Texture   = <Edge>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler g1_Sampler = sampler_state
{
   Texture   = <Glow_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler g2_Sampler = sampler_state
{
   Texture   = <Glow_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

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
   bool SupportsAlpha = true;
> = { 1.0, 0.75, 0.0, 1.0 };

float4 Colour_2
<
   string Group = "Glow colour";
   string Description = "Colour 2";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 0.0, 1.0 };

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define LOOP     12
#define DIVIDE   49        // (LOOP * 4) + 1

#define RADIUS_1 4.0
#define RADIUS_2 10.0
#define RADIUS_3 20.0
#define RADIUS_4 35.0

#define ANGLE    0.261799

#define R_VALUE    0.3
#define G_VALUE    0.59
#define B_VALUE    0.11

#define HALF_PI    1.570796

#define BLACK  (0.0).xxxx

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

float fn_get_edge (float2 uv)
{
   float4 Fgd = tex2D (FgdSampler, uv);

   return (Fgd.r + Fgd.g + Fgd.b) / 3.0;
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_edges (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (FgdSampler, uv);
   float edges, pattern;

   if (lCycle == 1) {
      float nVal = 0.0;
      float xVal = 4.0 * lRate / _OutputWidth;
      float yVal = xVal * _OutputAspectRatio;

      float p2 = -1.0 * fn_get_edge (uv + float2 (xVal, yVal));
      float p1 = p2;

      p1 += -2.0 * fn_get_edge (uv + float2 (xVal, nVal));
      p1 += -1.0 * fn_get_edge (uv + float2 (xVal, -yVal));
      p1 +=  1.0 * fn_get_edge (uv + float2 (-xVal, yVal));
      p1 +=  2.0 * fn_get_edge (uv + float2 (-xVal, nVal));
      p1 +=  1.0 * fn_get_edge (uv + float2 (-xVal, -yVal));

      p2 += -2.0 * fn_get_edge (uv + float2 (nVal, yVal));
      p2 += -1.0 * fn_get_edge (uv + float2 (-xVal, yVal));
      p2 +=  1.0 * fn_get_edge (uv + float2 (xVal, -yVal));
      p2 +=  2.0 * fn_get_edge (uv + float2 (nVal, -yVal));
      p2 +=  1.0 * fn_get_edge (uv + float2 (-xVal, -yVal));

      edges = saturate (p1 * p1 + p2 * p2);
   }
   else {
      edges = dot (Fgd.rgb, float3 (R_VALUE, G_VALUE, B_VALUE));

      if (edges < (1.0 - lRate)) edges = 0.0;
   }

   pattern = _Progress * (1.0 + (cRate * 20.0)) * 5.0;

   if (cCycle == 0) return lerp (BLACK, Fgd, edges);

   float4 part_1 = edges * Colour_1;
   float4 part_2 = edges * Colour_2;

   pattern = (cCycle == 2) ? (sin (pattern) * 0.5) + 0.5 : 0.0;

   return lerp (part_1, part_2, pattern);
}

float4 ps_glow (float2 uv : TEXCOORD1, uniform sampler gloSampler, uniform float base) : COLOR
{
   float4 retval = tex2D (gloSampler, uv);

   if (Size <= 0.0) return retval;

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * base * Size / _OutputWidth;

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
   float4 retval = tex2D (g2_Sampler, uv);

   float sizeComp = saturate (Size * 4.0);

   sizeComp = sin (sizeComp * HALF_PI);
   retval = lerp (BLACK, retval, sizeComp);

   if (lCycle != 1) return retval;

   float4 Glow = max (retval, tex2D (EdgSampler, uv));

   return lerp (retval, Glow, EdgeMix);
}

float4 ps_add_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd  = tex2D (FgdSampler, uv);
   float4 Glow = saturate (Fgd + tex2D (g1_Sampler, uv));

   return lerp (Fgd, Glow, Amount);
}

float4 ps_screen_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd    = tex2D (FgdSampler, uv);
   float4 Glow   = tex2D (g1_Sampler, uv);
   float4 retval = saturate (Fgd + Glow - (Fgd * Glow));

   return lerp (Fgd, retval, Amount);
}

float4 ps_lighten_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd  = tex2D (FgdSampler, uv);
   float4 Glow = max (Fgd, tex2D (g1_Sampler, uv));

   return lerp (Fgd, Glow, Amount);
}

float4 ps_soft_glow_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd    = tex2D (FgdSampler, uv);
   float4 Glow   = Fgd * tex2D (g1_Sampler, uv);
   float4 retval = saturate (Fgd + Glow - (Fgd * Glow));

   return lerp (Fgd, retval, Amount);
}

float4 ps_vivid_light_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd  = tex2D (FgdSampler, uv);
   float4 Glow = saturate ((tex2D (g1_Sampler, uv) * 2.0) + Fgd - 1.0.xxxx);

   return lerp (Fgd, Glow, Amount);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique addEdge
{
   pass P_1
   < string Script = "RenderColorTarget0 = Edge;"; >
   { PixelShader = compile PROFILE ps_edges (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (EdgSampler, RADIUS_1); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (g1_Sampler, RADIUS_2); }

   pass P_4
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (g2_Sampler, RADIUS_3); }

   pass P_5
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (g1_Sampler, RADIUS_4); }

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
   { PixelShader = compile PROFILE ps_glow (EdgSampler, RADIUS_1); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (g1_Sampler, RADIUS_2); }

   pass P_4
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (g2_Sampler, RADIUS_3); }

   pass P_5
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (g1_Sampler, RADIUS_4); }

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
   { PixelShader = compile PROFILE ps_glow (EdgSampler, RADIUS_1); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (g1_Sampler, RADIUS_2); }

   pass P_4
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (g2_Sampler, RADIUS_3); }

   pass P_5
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (g1_Sampler, RADIUS_4); }

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
   { PixelShader = compile PROFILE ps_glow (EdgSampler, RADIUS_1); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (g1_Sampler, RADIUS_2); }

   pass P_4
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (g2_Sampler, RADIUS_3); }

   pass P_5
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (g1_Sampler, RADIUS_4); }

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
   { PixelShader = compile PROFILE ps_glow (EdgSampler, RADIUS_1); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (g1_Sampler, RADIUS_2); }

   pass P_4
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_glow (g2_Sampler, RADIUS_3); }

   pass P_5
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (g1_Sampler, RADIUS_4); }

   pass P_6
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_build_glow (); }

   pass P_7
   { PixelShader = compile PROFILE ps_vivid_light_main (); }
}

