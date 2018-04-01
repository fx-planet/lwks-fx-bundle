//--------------------------------------------------------------//
// Lightworks user effect Adx_Pinch.fx
// Created by jwrl 27 October 2017.
//
// This effect pinches the outgoing video to a user-defined
// point to reveal the incoming shot.  It can also reverse the
// process to bring in the incoming video.  It's the alpha
// version of Wx_Pinch.
//
// Version 14.5 update 24 March 2018 by jwrl.
//
// Legality checking has been added to correct for a bug
// in XY sampler addressing on Linux and OS-X platforms.
// This effect should now function correctly when used with
// all current and previous Lightworks versions.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha Pinch";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Inp_1;
texture Inp_2;
texture Inp_3;

texture In_1 : RenderColorTarget;
texture In_2 : RenderColorTarget;

texture Bgd : RenderColorTarget;

texture Amt : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler In1Sampler = sampler_state
{
   Texture = <Inp_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In2Sampler = sampler_state
{
   Texture = <Inp_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In3Sampler = sampler_state
{
   Texture   = <Inp_3>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg1Sampler = sampler_state
{
   Texture   = <In_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg2Sampler = sampler_state
{
   Texture   = <In_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler AmtSampler = sampler_state
{
   Texture   = <Amt>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Bgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
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
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float centreX
<
   string Description = "Pinch centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreY
<
   string Description = "Pinch centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int SetTechnique
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Transition";
   string Enum = "Wipe in,Wipe out,Wipe FX1 > FX2,Wipe FX2 > FX1";
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

#define MID_PT  (0.5).xx

#define HALF_PI 1.5707963

#define EMPTY   (0.0).xxxx

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_amt_inp (float2 uv : TEXCOORD1) : COLOR
{
   return ((Amount * 0.5) + 0.5).xxxx;
}

float4 ps_amt_op (float2 uv : TEXCOORD1) : COLOR
{
   return (Amount * 0.5).xxxx;
}

float4 ps_amt_std (float2 uv : TEXCOORD1) : COLOR
{
   return Amount.xxxx;
}

float4 ps_inp_1 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In1Sampler, uv);
}

float4 ps_inp_2 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In2Sampler, uv);
}

float4 ps_inp_3 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In3Sampler, uv);
}

float4 ps_fg_2 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (Fg2Sampler, uv);
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float amount = tex2D (AmtSampler, uv).x;

   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, amount);
   float2 xy = (uv - centre) * (1.0 + pow ((1.0 - sin (amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy * 2.0), -cos ((amount + 0.01) * HALF_PI));

   xy *= scale;
   xy += MID_PT;

   float4 Fgd = fn_illegal (xy) ? EMPTY : tex2D (Fg1Sampler, xy);

   if (Boost_On) Fgd.a = pow (Fgd.a, 1.0 / max (1.0, Boost_I + 1.0));

   return lerp (tex2D (BgdSampler, uv), Fgd, Fgd.a);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float amount = tex2D (AmtSampler, uv).x;

   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), amount);
   float2 xy = (uv - centre) * (1.0 + pow ((1.0 - cos (amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy * 2.0), -sin (amount * HALF_PI));

   xy *= scale;
   xy += MID_PT;

   float4 Fgd = fn_illegal (xy) ? EMPTY : tex2D (Fg1Sampler, xy);

   if (Boost_On) Fgd.a = pow (Fgd.a, 1.0 / max (1.0, Boost_O + 1.0));

   return lerp (tex2D (BgdSampler, uv), Fgd, Fgd.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique PinchIn
{
   pass P_1
   < string Script = "RenderColorTarget0 = Amt;"; >
   { PixelShader = compile PROFILE ps_amt_inp (); }

   pass P_2
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique PinchOut
{
   pass P_1
   < string Script = "RenderColorTarget0 = Amt;"; >
   { PixelShader = compile PROFILE ps_amt_op (); }

   pass P_2
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique PinchFX1_FX2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Amt;"; >
   { PixelShader = compile PROFILE ps_amt_std (); }

   pass P_2
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_3 (); }

   pass P_4
   < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_main_out (); }

   pass P_5
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_6
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_fg_2 (); }

   pass P_7
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique PinchFX2_FX1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Amt;"; >
   { PixelShader = compile PROFILE ps_amt_std (); }

   pass P_2
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_3 (); }

   pass P_4
   < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_main_out (); }

   pass P_5
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_6
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_fg_2 (); }

   pass P_7
   { PixelShader = compile PROFILE ps_main_in (); }
}

