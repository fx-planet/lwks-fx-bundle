// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2017-08-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_Split_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_split.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Wx_Split.fx
//
// This is really the classic barn door effect, but since a wipe with that name already
// exists in Lightworks another name had to be found.  The Editshare wipe is just that,
// a wipe.  It doesn't move the separated image parts apart.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Barn door split";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler Fgsampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Bgsampler = sampler_state
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
   string Enum = "Horizontal open,Horizontal close,Vertical open,Vertical close";
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

   return (uv.x > posAmt) ? tex2D (Fgsampler, xy1) : (uv.x < negAmt) ? tex2D (Fgsampler, xy2) : tex2D (Bgsampler, uv);
}

float4 shut_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv.x - posAmt + 0.5, uv.y);
   float2 xy2 = float2 (uv.x - negAmt + 0.5, uv.y);

   return (uv.x > posAmt) ? tex2D (Bgsampler, xy1) : (uv.x < negAmt) ? tex2D (Bgsampler, xy2) : tex2D (Fgsampler, uv);
}

float4 open_vert (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   return (uv.y > posAmt) ? tex2D (Fgsampler, xy1) : (uv.y < negAmt) ? tex2D (Fgsampler, xy2) : tex2D (Bgsampler, uv);
}

float4 shut_vert (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   return (uv.y > posAmt) ? tex2D (Bgsampler, xy1) : (uv.y < negAmt) ? tex2D (Bgsampler, xy2) : tex2D (Fgsampler, uv);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique openHoriz
{
   pass P_1
   { PixelShader = compile PROFILE open_horiz (); }
}

technique shutHoriz
{
   pass P_1
   { PixelShader = compile PROFILE shut_horiz (); }
}

technique openVert
{
   pass P_1
   { PixelShader = compile PROFILE open_vert (); }
}

technique shutVert
{
   pass P_1
   { PixelShader = compile PROFILE shut_vert (); }
}
