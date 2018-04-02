// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Adx_Optical.fx
//
// Created by LW user jwrl 31 July 2016
// @Author: jwrl
// @CreationDate: "31 July 2016"
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaOpticalMix.fx by jwrl 8 August 2017 for
// name consistency through alpha dissolve range.
//
//  Bug fix to correct ambiguous declaration affecting Linux
//  and Mac versions only 9 July 2017.
//
// An alpha transition that simulates the burn effect of the
// classic film optical.
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
   string Description = "Alpha optical transition";
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
texture Bgd : RenderColorTarget;
texture Bg1 : RenderColorTarget;

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

sampler BgdSampler = sampler_state {
   Texture   = <Bgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Bg1Sampler = sampler_state {
   Texture   = <Bg1>;
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

#define PI      3.141593
#define HALF_PI 1.570796

#define EMPTY   0.0.xxxx

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
   float4 Bgnd = tex2D (Bg1Sampler, uv);
   float4 Fgnd = tex2D (FgdSampler, uv);

   float amount = max (0.0, Amount - 0.5);
   float alpha  = Fgnd.a * sin (Amount * HALF_PI);

   float4 Fx     = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = max (EMPTY, Bgnd - alpha.xxxx);

   Fgnd.a *= 0.5 - (cos (Amount * PI) / 2.0);
   retval = min (1.0.xxxx, lerp (EMPTY, Fgnd, Fgnd.a) + retval);

   return lerp (retval, Fx, amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = tex2D (BgdSampler, uv);
   float4 Fgnd = tex2D (FgdSampler, uv);

   float amount = max (0.0, 0.5 - Amount);
   float alpha  = Fgnd.a * sin (HALF_PI - Amount * HALF_PI);

   float4 Fx     = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = max (EMPTY, Bgnd - alpha.xxxx);

   Fgnd.a *= 0.5 - (cos (PI - Amount * PI) / 2.0);
   retval = min (1.0.xxxx, lerp (EMPTY, Fgnd, Fgnd.a) + retval);

   return lerp (retval, Fx, amount);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique fade_in
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique fade_out
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique diss_Fx1_Fx2
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bg1;"; >
   { PixelShader = compile PROFILE ps_main_out (); }

   pass P_4 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_I (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique diss_Fx2_Fx1
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bg1;"; >
   { PixelShader = compile PROFILE ps_main_out (); }

   pass P_4 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main_in (); }
}

