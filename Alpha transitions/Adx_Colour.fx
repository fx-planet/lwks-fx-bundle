// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Adx_Colour.fx
//
// Created by LW user jwrl 28 May 2016
// @Author jwrl
// @Created "28 May 2016"
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaColourMix.fx by jwrl 8 August 2017 for
// name consistency through alpha dissolve range.
//
// This effect dips through a user-selected colour from one
// title to another or fades to or from that colour.  The
// colour field used can be a single flat colour, a vertical
// gradient, a horizontal gradient or a four corner gradient.
// It can also composite the result over a background layer.
//
// If fading a title in or out it uses non-linear transitions
// to reveal the colour at its maximum strength midway through
// the transition.
//
// Alpha levels are boosted to support Lightworks titles, which
// is now the default setting.  The boost amount is tied to the
// incoming and outgoing titles, rather than FX1 and FX2 as
// with the earlier version.
//
// The boost technique also now uses gamma rather than gain to
// adjust the alpha levels.  This more closely matches the way
// that Lightworks handles titles.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha dissolve thru colour";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture In1;
texture In2;
texture In3;

texture Fgd : RenderColorTarget;
texture Fg1 : RenderColorTarget;
texture Bgd : RenderColorTarget;

texture colourFrame : RenderColorTarget;

texture preMix : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler In1Sampler = sampler_state {
   Texture = <In1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In2Sampler = sampler_state {
   Texture = <In2>;
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

sampler FgdSampler = sampler_state {
   Texture   = <Fgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg1Sampler = sampler_state {
   Texture   = <Fg1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler  = sampler_state {
   Texture   = <Bgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler colourSampler = sampler_state {
   Texture   = <colourFrame>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler preSampler = sampler_state {
   Texture   = <preMix>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Params
//--------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Transition";
   string Enum = "Fade in,Fade out,Dissolve FX1 > FX2,Dissolve FX2 > FX1";
> = 0;

float cAmount
<
   string Group = "Colour setup";
   string Description = "Colour mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool gradSetup
<
   string Group = "Colour setup";
   string Description = "Show gradient full screen";
> = false;

int colourGrad
<
   string Group = "Colour setup";
   string Description = "Colour gradient";
   string Enum = "Top left flat colour,Top to bottom left,Top left to top right,Four way gradient";
> = 0;

float4 topLeft
<
   string Description = "Top Left";
   string Group = "Colour setup";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 1.0, 1.0 };

float4 topRight
<
   string Description = "Top Right";
   string Group = "Colour setup";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 0.0, 1.0 };

float4 botLeft
<
   string Description = "Bottom Left";
   string Group = "Colour setup";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float4 botRight
<
   string Description = "Bottom Right";
   string Group = "Colour setup";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 1.0, 1.0 };

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

//--------------------------------------------------------------//
// Definitions and stuff
//--------------------------------------------------------------//

#define HALF_PI 1.570796

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Pixel Shaders
//--------------------------------------------------------------//

float4 ps_mode_sw_1_I (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (In1Sampler, uv);

   if (Boost_On) retval.a = pow (retval.a, 1.0 / max (1.0, Boost_I + 1.0));

   return retval;
}

float4 ps_mode_sw_1_O (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (In1Sampler, uv);

   if (Boost_On) retval.a = pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0));

   return retval;
}

float4 ps_mode_sw_2_I (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (In2Sampler, uv);

   if (Boost_On) retval.a = pow (retval.a, 1.0 / max (1.0, Boost_I + 1.0));

   return retval;
}

float4 ps_mode_sw_2_O (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (In2Sampler, uv);

   if (Boost_On) retval.a = pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0));

   return retval;
}

float4 ps_mode_sw_2_B (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In2Sampler, uv);
}

float4 ps_mode_sw_3_B (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In3Sampler, uv);
}

float4 ps_colour (float2 uv : TEXCOORD1) : COLOR
{
   if (colourGrad == 0) return topLeft;

   if (colourGrad == 1) return lerp (topLeft, botLeft, uv.y);

   float4 topRow = lerp (topLeft, topRight, uv.x);

   if (colourGrad == 2) return topRow;

   float4 botRow = lerp (botLeft, botRight, uv.x);

   return lerp (topRow, botRow, uv.y);
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 gradient = tex2D (colourSampler, uv);

   if (gradSetup) return gradient;

   float level = min (1.0, cAmount * 2.0);
   float c_Amt = sin (saturate (level * (1.0 - Amount)) * HALF_PI);

   level = sin (Amount * HALF_PI);

   float4 Fgnd = tex2D (FgdSampler, uv);
   float4 Bgnd = tex2D (BgdSampler, uv);

   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (Bgnd, Fgnd, Fgnd.a * level);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 gradient = tex2D (colourSampler, uv);

   if (gradSetup) return gradient;

   float level = min (1.0, cAmount * 2.0);
   float c_Amt = sin (saturate (level * Amount) * HALF_PI);

   level = cos (Amount * HALF_PI);

   float4 Fgnd = tex2D (FgdSampler, uv);
   float4 Bgnd = tex2D (BgdSampler, uv);

   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (Bgnd, Fgnd, Fgnd.a * level);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 gradient = tex2D (colourSampler, uv);

   if (gradSetup) return gradient;

   float c_Amt = sin (saturate (2.0 * cAmount * Amount) * HALF_PI);
   float level = cos (Amount * HALF_PI);

   float4 Fgnd = tex2D (Fg1Sampler, uv);
   float4 Bgnd = tex2D (BgdSampler, uv);

   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);
   Bgnd     = lerp (Bgnd, Fgnd, Fgnd.a * level);

   c_Amt = sin (saturate (2.0 * cAmount * (1.0 - Amount)) * HALF_PI);
   level = sin (Amount * HALF_PI);

   Fgnd     = tex2D (FgdSampler, uv);
   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (Bgnd, Fgnd, Fgnd.a * level);
}

//--------------------------------------------------------------//
// Technique
//--------------------------------------------------------------//

technique fade_in
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3 < string Script = "RenderColorTarget0 = colourFrame;"; >
   { PixelShader = compile PROFILE ps_colour (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique fade_out
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3 < string Script = "RenderColorTarget0 = colourFrame;"; >
   { PixelShader = compile PROFILE ps_colour (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique diss_Fx1_Fx2
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_I (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4 < string Script = "RenderColorTarget0 = colourFrame;"; >
   { PixelShader = compile PROFILE ps_colour (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

technique diss_Fx2_Fx1
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4 < string Script = "RenderColorTarget0 = colourFrame;"; >
   { PixelShader = compile PROFILE ps_colour (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

