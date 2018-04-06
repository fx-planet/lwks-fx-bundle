// @Maintainer jwrl
// @Released 2018-04-06
// @Author jwrl
// @Created 2016-06-10
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaBorderTrans_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaBorder.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Adx_Borders.fx
//
// An alpha transition that generates borders from the title(s) then blows them apart
// in four directions.  Each quadrant can be individually coloured.
//
// Alpha levels are boosted to support Lightworks titles, which is the default setting.
// The boost amount is tied to the incoming and outgoing titles, rather than FX1 and FX2
// as with the earlier version.
//
// The boost technique also now uses gamma rather than gain to adjust the alpha levels.
// This more closely matches the way that Lightworks handles titles.
//
// LW 14+ version by jwrl 19 May 2017
// Added subcategory "Alpha"
//
// Modified 8 August 2017 by jwrl.
// Renamed from AlphaBorderMix.fx for name consistency through alpha dissolve range.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha border transition";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture In1;
texture In2;
texture In3;

texture Fg : RenderColorTarget;
texture Bg : RenderColorTarget;

texture border_1 : RenderColorTarget;
texture border_2 : RenderColorTarget;
texture diss_bgd : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler In1Sampler = sampler_state
{
   Texture = <In1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In2Sampler = sampler_state
{
   Texture = <In2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FgSampler = sampler_state {
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler B1_Sampler = sampler_state {
   Texture   = <border_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler B2_Sampler = sampler_state {
   Texture   = <border_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In3Sampler = sampler_state {
   Texture   = <In3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state {
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler DbSampler = sampler_state {
   Texture   = <diss_bgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
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
   float KF0 = 0.0;
   float KF1 = 1.0;
> = 0.5;

int SetTechnique
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Transition";
   string Enum = "Fade in,Fade out,Dissolve FX1 > FX2,Dissolve FX2 > FX1";
> = 0;

float Radius
<
   string Group = "Borders";
   string Description = "Radius";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Displace
<
   string Group = "Borders";
   string Description = "Displacement";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 Colour_1
<
   string Group = "Colours";
   string Description = "Outline 1";
   bool SupportsAlpha = true;
> = { 0.6, 0.9, 1.0, 1.0 };

float4 Colour_2
<
   string Group = "Colours";
   string Description = "Outline 2";
   bool SupportsAlpha = true;
> = { 0.3, 0.6, 1.0, 1.0 };

float4 Colour_3
<
   string Group = "Colours";
   string Description = "Outline 3";
   bool SupportsAlpha = true;
> = { 0.9, 0.6, 1.0, 1.0 };

float4 Colour_4
<
   string Group = "Colours";
   string Description = "Outline 4";
   bool SupportsAlpha = true;
> = { 0.6, 0.3, 1.0, 1.0 };

bool Boost_On
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Enable alpha boost";
> = false;

float Boost_O
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Boost outgoing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Boost_I
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Boost incoming";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LOOP_1   30
#define RADIUS_1 0.01
#define ANGLE_1  0.10472

#define LOOP_2   24
#define RADIUS_2 0.00666667
#define ANGLE_2  0.1309

#define OFFSET   0.5
#define X_OFFSET 0.5625
#define Y_OFFSET 1.77778

#define HALF_PI  1.570796

#define BLACK    (0.0).xxxx

#define FADE_IN  true
#define FADE_OUT false

float _OutputPixelWidth  = 1.0;
float _OutputPixelHeight = 1.0;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mode_sw_1 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In1Sampler, uv);
}

float4 ps_mode_sw_2 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In2Sampler, uv);
}

float4 ps_mode_sw_3 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In3Sampler, uv);
}

float4 ps_set_src (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (DbSampler, uv);
}

float4 ps_border_1_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = BLACK;

   if (Radius == 0.0) return retval;

   float radScale = cos (Amount * HALF_PI);

   float2 radius = float2 (_OutputPixelWidth, _OutputPixelHeight) * Radius * radScale * RADIUS_1;
   float2 xy;

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy.x, xy.y);
      xy *= radius;
      retval = max (retval, tex2D (FgSampler, uv + xy));
      retval = max (retval, tex2D (FgSampler, uv - xy));
   }

   return retval;
}

float4 ps_border_1_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = BLACK;

   if (Radius == 0.0) return retval;

   float radScale = sin (Amount * HALF_PI);

   float2 radius = float2 (_OutputPixelWidth, _OutputPixelHeight) * Radius * radScale * RADIUS_1;
   float2 xy;

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy.x, xy.y);
      xy *= radius;
      retval = max (retval, tex2D (FgSampler, uv + xy));
      retval = max (retval, tex2D (FgSampler, uv - xy));
   }

   return retval;
}

float4 ps_border_2_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (B1_Sampler, uv);

   if (Radius == 0.0) return retval;

   float radScale = cos (Amount * HALF_PI);
   float alpha = saturate (tex2D (FgSampler, uv).a * 2.0);

   float2 radius = float2 (_OutputPixelWidth, _OutputPixelHeight) * Radius * radScale * RADIUS_2;
   float2 xy;

   for (int i = 0; i < LOOP_2; i++) {
      sincos ((i * ANGLE_2), xy.x, xy.y);
      xy *= radius;
      retval = max (retval, tex2D (B1_Sampler, uv + xy));
      retval = max (retval, tex2D (B1_Sampler, uv - xy));
   }

   return lerp (retval, 0.0.xxxx, alpha);
}

float4 ps_border_2_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (B1_Sampler, uv);

   if (Radius == 0.0) return retval;

   float radScale = sin (Amount * HALF_PI);
   float alpha = saturate (tex2D (FgSampler, uv).a * 2.0);

   float2 radius = float2 (_OutputPixelWidth, _OutputPixelHeight) * Radius * radScale * RADIUS_2;
   float2 xy;

   for (int i = 0; i < LOOP_2; i++) {
      sincos ((i * ANGLE_2), xy.x, xy.y);
      xy *= radius;
      retval = max (retval, tex2D (B1_Sampler, uv + xy));
      retval = max (retval, tex2D (B1_Sampler, uv - xy));
   }

   return lerp (retval, 0.0.xxxx, alpha);
}

float4 ps_main (float2 uv : TEXCOORD1, uniform bool fade_in, uniform float enhanceKey) : COLOR
{
   float4 Bgd = tex2D (BgSampler, uv);
   float2 xy = float2 (_OutputPixelWidth, _OutputPixelHeight);
   float Outline, Offset, Opacity;

   if (fade_in) {
      Outline = sin (Amount * HALF_PI);
      Offset  = (1.0 - Amount) * Displace * OFFSET;
      Opacity = 1.0 - cos (Amount * HALF_PI);
      Opacity = 1.0 - cos (Opacity * HALF_PI);
   }
   else {
      Outline = cos (Amount * HALF_PI);
      Offset  = Amount * Displace * OFFSET;
      Opacity = sin (Amount * HALF_PI);
      Opacity = 1.0 - sin (Opacity * HALF_PI);
      xy.x = -xy.x;
   }

   xy *= Offset;

   float2 xy1 = uv + xy;
   float2 xy2 = uv - xy;

   xy = float2 (xy.x * X_OFFSET, (-xy.y) * Y_OFFSET);

   float2 xy3 = uv + xy;
   float2 xy4 = uv - xy;

   float4 Fg1 = tex2D (FgSampler, xy1);
   float4 Fg2 = tex2D (FgSampler, xy2);

   float Edge = tex2D (B2_Sampler, xy1).a;

   float4 retval = lerp (BLACK, Colour_1, Edge);

   Fg1 = lerp (BLACK, Fg1, Fg1.a);
   Fg1 = lerp (Fg1, Fg2, Fg2.a);
   Fg2 = tex2D (FgSampler, xy3);
   Fg1 = lerp (Fg1, Fg2, Fg2.a);
   Fg2 = tex2D (FgSampler, xy4);
   Fg1 = lerp (Fg1, Fg2, Fg2.a);

   if (Boost_On) Fg1.a = pow (Fg1.a, 1.0 / max (1.0, enhanceKey + 1.0));

   Edge = tex2D (B2_Sampler, xy2).a;
   retval = lerp (retval, Colour_2, Edge);
   Edge = tex2D (B2_Sampler, xy3).a;
   retval = lerp (retval, Colour_3, Edge);
   Edge = tex2D (B2_Sampler, xy4).a;
   retval = lerp (retval, Colour_4, Edge);

   Fg2 = lerp (Bgd, Fg1, Fg1.a * Opacity);

   return lerp (Fg2, retval, retval.a * Outline);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique fade_in
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = border_1;"; >
   { PixelShader = compile PROFILE ps_border_1_in (); }

   pass P_4 < string Script = "RenderColorTarget0 = border_2;"; >
   { PixelShader = compile PROFILE ps_border_2_in (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (FADE_IN, Boost_I); }
}

technique fade_out
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = border_1;"; >
   { PixelShader = compile PROFILE ps_border_1_out (); }

   pass P_4 < string Script = "RenderColorTarget0 = border_2;"; >
   { PixelShader = compile PROFILE ps_border_2_out (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (FADE_OUT, Boost_O); }
}

technique diss_Fx1_Fx2
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_3 < string Script = "RenderColorTarget0 = border_1;"; >
   { PixelShader = compile PROFILE ps_border_1_out (); }

   pass P_4 < string Script = "RenderColorTarget0 = border_2;"; >
   { PixelShader = compile PROFILE ps_border_2_out (); }

   pass P_5 < string Script = "RenderColorTarget0 = diss_bgd;"; >
   { PixelShader = compile PROFILE ps_main (FADE_OUT, Boost_O); }

   pass P_6 < string Script = "RenderColorTarget0 = Fg;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_7 < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_set_src (); }

   pass P_8 < string Script = "RenderColorTarget0 = border_1;"; >
   { PixelShader = compile PROFILE ps_border_1_in (); }

   pass P_9 < string Script = "RenderColorTarget0 = border_2;"; >
   { PixelShader = compile PROFILE ps_border_2_in (); }

   pass P_10
   { PixelShader = compile PROFILE ps_main (FADE_IN, Boost_I); }
}

technique diss_Fx2_Fx1
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_3 < string Script = "RenderColorTarget0 = border_1;"; >
   { PixelShader = compile PROFILE ps_border_1_out (); }

   pass P_4 < string Script = "RenderColorTarget0 = border_2;"; >
   { PixelShader = compile PROFILE ps_border_2_out (); }

   pass P_5 < string Script = "RenderColorTarget0 = diss_bgd;"; >
   { PixelShader = compile PROFILE ps_main (FADE_OUT, Boost_O); }

   pass P_6 < string Script = "RenderColorTarget0 = Fg;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_7 < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_set_src (); }

   pass P_8 < string Script = "RenderColorTarget0 = border_1;"; >
   { PixelShader = compile PROFILE ps_border_1_in (); }

   pass P_9 < string Script = "RenderColorTarget0 = border_2;"; >
   { PixelShader = compile PROFILE ps_border_2_in (); }

   pass P_10
   { PixelShader = compile PROFILE ps_main (FADE_IN, Boost_I); }
}
