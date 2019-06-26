// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2017-08-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_SplitSqueeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_SplitSqueeze.mp4

/**
This is based on the barn door split effect, modified to squeeze or expand the divided
section of the frame.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BarndoorSqueeze_Dx.fx
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Barn door squeeze";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "A barn door effect that squeezes the outgoing video to the edges of frame to reveal the incoming video";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 sqz_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 ((uv.x - Amount) / negAmt, uv.y);
   float2 xy2 = float2 (uv.x / negAmt, uv.y);

   negAmt /= 2.0;

   return (uv.x > posAmt) ? tex2D (s_Foreground, xy1) : (uv.x < negAmt) ? tex2D (s_Foreground, xy2) : tex2D (s_Background, uv);
}

float4 exp_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 ((uv.x + Amount - 1.0) / Amount, uv.y);
   float2 xy2 = float2 (uv.x / Amount, uv.y);

   return (uv.x > posAmt) ? tex2D (s_Background, xy1) : (uv.x < negAmt) ? tex2D (s_Background, xy2) : tex2D (s_Foreground, uv);
}

float4 sqz_vert (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x, (uv.y - Amount) / negAmt);
   float2 xy2 = float2 (uv.x, uv.y / negAmt);

   negAmt /= 2.0;

   return (uv.y > posAmt) ? tex2D (s_Foreground, xy1) : (uv.y < negAmt) ? tex2D (s_Foreground, xy2) : tex2D (s_Background, uv);
}

float4 exp_vert (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv.x, (uv.y + Amount - 1.0) / Amount);
   float2 xy2 = float2 (uv.x, uv.y / Amount);

   return (uv.y > posAmt) ? tex2D (s_Background, xy1) : (uv.y < negAmt) ? tex2D (s_Background, xy2) : tex2D (s_Foreground, uv);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

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
