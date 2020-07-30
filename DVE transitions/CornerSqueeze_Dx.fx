// @Maintainer jwrl
// @Released 2020-07-30
// @Author jwrl
// @Created 2017-08-26
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_CnrSqueeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_CnrSqueeze.mp4

/**
 This is based on the corner wipe effect, modified to squeeze or expand the divided
 section of the frame.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CornerSqueeze_Dx.fx
//
// Version history:
//
// Modified 2020-07-30 jwrl.
// Reformatted the effect header.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Corner squeeze";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "A corner wipe effect that squeezes or expands the divided section of the frame";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture PartSqueeze : RenderColorTarget;

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

sampler s_PartSqueeze = sampler_state
{
   Texture   = <PartSqueeze>;
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY (0.0).xxxx

#pragma warning ( disable : 3571 )

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

   return (uv.x > posAmt) ? tex2D (s_Foreground, xy1) : (uv.x < negAmt)
                          ? tex2D (s_Foreground, xy2) : EMPTY;
}

float4 sqz_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x, (uv.y - Amount) / negAmt);
   float2 xy2 = float2 (uv.x, uv.y / negAmt);

   negAmt /= 2.0;

   float4 retval = (uv.y > posAmt) ? tex2D (s_PartSqueeze, xy1) : (uv.y < negAmt)
                                   ? tex2D (s_PartSqueeze, xy2) : EMPTY;

   return lerp (tex2D (s_Background, uv), retval, retval.a);
}

float4 exp_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 ((uv.x + Amount - 1.0) / Amount, uv.y);
   float2 xy2 = float2 (uv.x / Amount, uv.y);

   return (uv.x > posAmt) ? tex2D (s_Background, xy1) : (uv.x < negAmt)
                          ? tex2D (s_Background, xy2) : EMPTY;
}

float4 exp_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv.x, (uv.y + Amount - 1.0) / Amount);
   float2 xy2 = float2 (uv.x, uv.y / Amount);

   float4 retval = (uv.y > posAmt) ? tex2D (s_PartSqueeze, xy1) : (uv.y < negAmt)
                                   ? tex2D (s_PartSqueeze, xy2) : EMPTY;

   return lerp (tex2D (s_Foreground, uv), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique squeezeCorner
{
   pass P_1
   < string Script = "RenderColorTarget0 = PartSqueeze;"; >
   { PixelShader = compile PROFILE sqz_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE sqz_main (); }
}

technique expandCorner
{
   pass P_1
   < string Script = "RenderColorTarget0 = PartSqueeze;"; >
   { PixelShader = compile PROFILE exp_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE exp_main (); }
}
