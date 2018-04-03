// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// User effect Wx_SplitSqueeze.fx
// Created by jwrl 25 August 2017.
// @Author jwrl
// @Created "25 August 2017"
//
// This is based on the barn door split effect, modified to
// squeeze or expand the divided section of the frame.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Barn door squeeze";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

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

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Squeeze horizontal,Expand horizontal,Squeeze vertical,Expand vertical";
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

   return (uv.x > posAmt) ? tex2D (FgSampler, xy1) : (uv.x < negAmt) ? tex2D (FgSampler, xy2) : tex2D (BgSampler, uv);
}

float4 exp_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 ((uv.x + Amount - 1.0) / Amount, uv.y);
   float2 xy2 = float2 (uv.x / Amount, uv.y);

   return (uv.x > posAmt) ? tex2D (BgSampler, xy1) : (uv.x < negAmt) ? tex2D (BgSampler, xy2) : tex2D (FgSampler, uv);
}

float4 sqz_vert (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x, (uv.y - Amount) / negAmt);
   float2 xy2 = float2 (uv.x, uv.y / negAmt);

   negAmt /= 2.0;

   return (uv.y > posAmt) ? tex2D (FgSampler, xy1) : (uv.y < negAmt) ? tex2D (FgSampler, xy2) : tex2D (BgSampler, uv);
}

float4 exp_vert (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv.x, (uv.y + Amount - 1.0) / Amount);
   float2 xy2 = float2 (uv.x, uv.y / Amount);

   return (uv.y > posAmt) ? tex2D (BgSampler, xy1) : (uv.y < negAmt) ? tex2D (BgSampler, xy2) : tex2D (FgSampler, uv);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique squeezeHoriz
{
   pass P_1
   { PixelShader = compile PROFILE sqz_horiz (); }
}

technique expandHoriz
{
   pass P_1
   { PixelShader = compile PROFILE exp_horiz (); }
}

technique squeezeVert
{
   pass P_1
   { PixelShader = compile PROFILE sqz_vert (); }
}

technique expandVert
{
   pass P_1
   { PixelShader = compile PROFILE exp_vert (); }
}

