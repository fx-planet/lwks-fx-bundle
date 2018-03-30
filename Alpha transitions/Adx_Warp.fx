//--------------------------------------------------------------//
// Lightworks user effect Adx_Warp.fx
//
// Created by LW user jwrl 27 May 2016
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaWarpMix.fx by jwrl 8 August 2017 for name
// consistency through the alpha dissolve range.
//
// This effect warps in or out of a title or between titles.
// It also composites the result over a background layer.
// The warp is driven by the background image, so will be
// different each time it's used.
//
// Alpha levels can be boosted to support Lightworks titles,
// which is the default setting.  The boost technique uses
// gamma rather than simple amplification to correct alpha
// levels.  This closely matches the way that Lightworks
// handles titles internally.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha warp dissolve";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture In1;
texture In2;
texture In3;

texture Fg1 : RenderColorTarget;
texture Bgd : RenderColorTarget;
texture Fg2 : RenderColorTarget;

texture Wrp1 : RenderColorTarget;
texture Wrp2 : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler In1Sampler = sampler_state
{
   Texture   = <In1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In2Sampler = sampler_state
{
   Texture   = <In2>;
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

sampler Fg1Sampler = sampler_state
{
   Texture   = <Fg1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg2Sampler = sampler_state
{
   Texture   = <Fg2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
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

sampler Wp1Sampler = sampler_state
{
   Texture   = <Wrp1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Wp2Sampler = sampler_state
{
   Texture   = <Wrp2>;
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
> = 0.5;

int SetTechnique
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Transition";
   string Enum = "Fade in,Fade out,Dissolve FX1 > FX2,Dissolve FX2 > FX1";
> = 0;

float Distortion
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Distortion";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

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
// Definitions and declarations
//--------------------------------------------------------------//

#define HALF_PI 1.570796

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

float4 ps_warp_A (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;
   float4 Img = tex2D (BgdSampler, uv);

   Img = (Img - 0.5.xxxx) * Distortion * 4.0;

   float Amt = 1.0 - sin (Amount * HALF_PI);

   xy.x = saturate (uv.x + (Img.y - 0.5) * Amt);
   Amt *= 2.0;
   xy.y = saturate (uv.y + (Img.z - Img.x) * Amt);

   return tex2D (Fg1Sampler, xy);
}

float4 ps_warp_B (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;
   float4 Img = tex2D (BgdSampler, uv);

   Img = (Img - 0.5.xxxx) * Distortion * 4.0;

   float Amt = 1.0 - cos (Amount * HALF_PI);

   xy.y = saturate (uv.y + (0.5 - Img.x) * Amt);
   Amt *= 2.0;
   xy.x = saturate (uv.x + (Img.y - Img.z) * Amt);

   return tex2D (Fg2Sampler, xy);
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (Wp1Sampler, uv);

   return lerp (tex2D (BgdSampler, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (Wp1Sampler, uv);

   return lerp (tex2D (BgdSampler, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd1 = tex2D (Wp1Sampler, uv);
   float4 Fgd2 = tex2D (Wp2Sampler, uv);

   float4 Bgnd = lerp (tex2D (BgdSampler, uv), Fgd1, Fgd1.a * Amount);

   return lerp (Bgnd, Fgd2, Fgd2.a * (1.0 - Amount));
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique WarpDissIn
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3 < string Script = "RenderColorTarget0 = Wrp1;"; >
   { PixelShader = compile PROFILE ps_warp_A (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique WarpDissOut
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3 < string Script = "RenderColorTarget0 = Wrp1;"; >
   { PixelShader = compile PROFILE ps_warp_B (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique WarpDiss_1_2
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4 < string Script = "RenderColorTarget0 = Wrp1;"; >
   { PixelShader = compile PROFILE ps_warp_A (); }

   pass P_5 < string Script = "RenderColorTarget0 = Wrp2;"; >
   { PixelShader = compile PROFILE ps_warp_B (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}

technique WarpDiss_2_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_O (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4 < string Script = "RenderColorTarget0 = Wrp1;"; >
   { PixelShader = compile PROFILE ps_warp_A (); }

   pass P_5 < string Script = "RenderColorTarget0 = Wrp2;"; >
   { PixelShader = compile PROFILE ps_warp_B (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}

