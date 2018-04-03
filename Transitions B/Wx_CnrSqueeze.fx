// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// User effect Wx_CnrSqueeze.fx
// Created by jwrl 26 August 2017.
// @Author jwrl
// @Created "26 August 2017"
//
// This is based on the corner wipe effect, modified to squeeze
// or expand the divided section of the frame.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Corner squeeze";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture Hc : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler HcSampler = sampler_state
{
   Texture   = <Hc>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Squeeze to corners,Expand from corners";
> = 0;

float Amount
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define EMPTY (0.0).xxxx

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 sqz_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 ((uv.x - Amount) / negAmt, uv.y);
   float2 xy2 = float2 (uv.x / negAmt, uv.y);

   negAmt /= 2.0;

   return (uv.x > posAmt) ? tex2D (FgSampler, xy1) : (uv.x < negAmt) ? tex2D (FgSampler, xy2) : EMPTY;
}

float4 sqz_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x, (uv.y - Amount) / negAmt);
   float2 xy2 = float2 (uv.x, uv.y / negAmt);

   negAmt /= 2.0;

   float4 retval = (uv.y > posAmt) ? tex2D (HcSampler, xy1) : (uv.y < negAmt) ? tex2D (HcSampler, xy2) : EMPTY;

   return lerp (tex2D (BgSampler, uv), retval, retval.a);
}

float4 exp_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 ((uv.x + Amount - 1.0) / Amount, uv.y);
   float2 xy2 = float2 (uv.x / Amount, uv.y);

   return (uv.x > posAmt) ? tex2D (BgSampler, xy1) : (uv.x < negAmt) ? tex2D (BgSampler, xy2) : EMPTY;
}

float4 exp_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv.x, (uv.y + Amount - 1.0) / Amount);
   float2 xy2 = float2 (uv.x, uv.y / Amount);

   float4 retval = (uv.y > posAmt) ? tex2D (HcSampler, xy1) : (uv.y < negAmt) ? tex2D (HcSampler, xy2) : EMPTY;

   return lerp (tex2D (FgSampler, uv), retval, retval.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique squeezeCorner
{
   pass P_1
   < string Script = "RenderColorTarget0 = Hc;"; >
   { PixelShader = compile PROFILE sqz_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE sqz_main (); }
}

technique expandCorner
{
   pass P_1
   < string Script = "RenderColorTarget0 = Hc;"; >
   { PixelShader = compile PROFILE exp_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE exp_main (); }
}

