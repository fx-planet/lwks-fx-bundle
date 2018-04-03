// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Adx_Transmogrify.fx
//
// Created by LW user jwrl 27 May 2016
// @Author jwrl
// @Created "27 May 2016"
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaTransmogMix.fx by jwrl 8 August 2017 for
// name consistency through the alpha dissolve range.
//
// This is a truly bizarre transition.  It can transition
// into or out of a title or between titles.  It then
// composites the result over a background layer.
//
// Alpha levels can be boosted to support Lightworks titles,
// which is the default setting.  The boost technique uses
// gamma rather than simple amplification to correct alpha
// levels.  This closely matches the way that Lightworks
// handles titles internally.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  When a height parameter is needed in an
// effect one cannot reliably use _OutputHeight.  It returns
// only half the actual frame height when interlaced media is
// playing.  In this effect the output height is obtained by
// dividing _OutputWidth by _OutputAspectRatio which is a
// reliable solution regardless of the pixel aspect ratio.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha transmogrify";
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
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg1Sampler = sampler_state {
   Texture   = <Fg1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state {
   Texture   = <Bgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
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
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.0;

int SetTechnique
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Transition";
   string Enum = "Fade in,Fade out,Dissolve FX1 > FX2,Dissolve FX2 > FX1";
> = 0;

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

float _OutputAspectRatio;
float _OutputWidth;

#define Output_Height (_OutputWidth/_OutputAspectRatio)

float _Progress;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
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

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixSize = (uv / float2 (_OutputWidth, Output_Height));

   float rand = (uv * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5;

   pixSize += rand.xx;

   float2 xy = saturate (pixSize + sqrt (1.0 - _Progress));

   xy = lerp (float2 (xy.x, 1.0 - xy.y), uv, Amount);

   float4 Fgnd = tex2D (FgdSampler, xy);
   float4 Bgnd = tex2D (BgdSampler, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixSize = (uv / float2 (_OutputWidth, Output_Height));

   float rand = (uv * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5;

   pixSize += rand.xx;

   float2 xy = lerp (uv, saturate (pixSize + sqrt (_Progress)), Amount);

   float4 Fgnd = tex2D (FgdSampler, xy);
   float4 Bgnd = tex2D (BgdSampler, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - Amount));
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixSize = (uv / float2 (_OutputWidth, Output_Height));

   float rand = (uv * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5;

   pixSize += rand.xx;

   float2 xy = saturate (pixSize + sqrt (1.0 - _Progress));

   xy = lerp (float2 (xy.x, 1.0 - xy.y), uv, Amount);

   float4 Fgnd = tex2D (Fg1Sampler, xy);
   float4 Bgnd = lerp (tex2D (BgdSampler, uv), Fgnd, Fgnd.a * Amount);

   xy     = lerp (uv, saturate (pixSize + sqrt (_Progress)), Amount);
   Fgnd   = tex2D (FgdSampler, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - Amount));
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique transmogrify_in
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique transmogrify_out
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique transmogrify_1_2
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_I (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique transmogrify_2_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_O (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

