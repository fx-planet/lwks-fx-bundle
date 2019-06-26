// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2017-08-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_Split_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_split.mp4

/**
This is really the classic barn door effect, but since a wipe with that name already exists
in Lightworks another name had to be found.  The Editshare wipe is just that, a wipe.  It
doesn't move the separated image parts apart.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BarnDoorSplit_Dx.fx
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Barn door split";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Splits the image in half and separates the halves horizontally or vertically";
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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 open_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x - posAmt + 0.5, uv.y);
   float2 xy2 = float2 (uv.x - negAmt + 0.5, uv.y);

   return (uv.x > posAmt) ? tex2D (s_Foreground, xy1) : (uv.x < negAmt)
                          ? tex2D (s_Foreground, xy2) : tex2D (s_Background, uv);
}

float4 shut_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv.x - posAmt + 0.5, uv.y);
   float2 xy2 = float2 (uv.x - negAmt + 0.5, uv.y);

   return (uv.x > posAmt) ? tex2D (s_Background, xy1) : (uv.x < negAmt)
                          ? tex2D (s_Background, xy2) : tex2D (s_Foreground, uv);
}

float4 open_vert (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   return (uv.y > posAmt) ? tex2D (s_Foreground, xy1) : (uv.y < negAmt)
                          ? tex2D (s_Foreground, xy2) : tex2D (s_Background, uv);
}

float4 shut_vert (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   return (uv.y > posAmt) ? tex2D (s_Background, xy1) : (uv.y < negAmt)
                          ? tex2D (s_Background, xy2) : tex2D (s_Foreground, uv);
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
