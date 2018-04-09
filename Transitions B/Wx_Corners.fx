// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2017-08-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_Corners_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_Corners.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Wx_Corners.fx
//
// This is a four-way split which moves the image to or from the corners of the frame.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Corner split";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Hc : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Corner open,Corner close";
> = 0;

float Amount
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY (0.0).xxxx

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 open_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x - posAmt + 0.5, uv.y);
   float2 xy2 = float2 (uv.x - negAmt + 0.5, uv.y);

   return (uv.x > posAmt) ? tex2D (FgSampler, xy1) : (uv.x < negAmt) ? tex2D (FgSampler, xy2) : EMPTY;
}

float4 open_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   float4 retval = (uv.y > posAmt) ? tex2D (HcSampler, xy1) : (uv.y < negAmt) ? tex2D (HcSampler, xy2) : EMPTY;

   return lerp (tex2D (BgSampler, uv), retval, retval.a);
}

float4 shut_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv.x - posAmt + 0.5, uv.y);
   float2 xy2 = float2 (uv.x - negAmt + 0.5, uv.y);

   return (uv.x > posAmt) ? tex2D (BgSampler, xy1) : (uv.x < negAmt) ? tex2D (BgSampler, xy2) : EMPTY;
}

float4 shut_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   float4 retval = (uv.y > posAmt) ? tex2D (HcSampler, xy1) : (uv.y < negAmt) ? tex2D (HcSampler, xy2) : EMPTY;

   return lerp (tex2D (FgSampler, uv), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique openCorner
{
   pass P_1
   < string Script = "RenderColorTarget0 = Hc;"; >
   { PixelShader = compile PROFILE open_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE open_main (); }
}


technique shutCorner
{
   pass P_1
   < string Script = "RenderColorTarget0 = Hc;"; >
   { PixelShader = compile PROFILE shut_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE shut_main (); }
}
