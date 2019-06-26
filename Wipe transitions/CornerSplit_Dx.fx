// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2017-08-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_Corners_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_Corners.mp4

/**
This is a four-way split which moves the image to or from the corners of the frame.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CornerSplit_Dx.fx
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Corner split";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Splits an image four ways to or from the corners of the frame";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Halfway : RenderColorTarget;

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

sampler s_Halfway = sampler_state
{
   Texture   = <Halfway>;
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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 open_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x - posAmt + 0.5, uv.y);
   float2 xy2 = float2 (uv.x - negAmt + 0.5, uv.y);

   return (uv.x > posAmt) ? tex2D (s_Foreground, xy1) : (uv.x < negAmt) ? tex2D (s_Foreground, xy2) : EMPTY;
}

float4 open_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   float4 retval = (uv.y > posAmt) ? tex2D (s_Halfway, xy1) : (uv.y < negAmt) ? tex2D (s_Halfway, xy2) : EMPTY;

   return lerp (tex2D (s_Background, uv), retval, retval.a);
}

float4 shut_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv.x - posAmt + 0.5, uv.y);
   float2 xy2 = float2 (uv.x - negAmt + 0.5, uv.y);

   return (uv.x > posAmt) ? tex2D (s_Background, xy1) : (uv.x < negAmt) ? tex2D (s_Background, xy2) : EMPTY;
}

float4 shut_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   float4 retval = (uv.y > posAmt) ? tex2D (s_Halfway, xy1) : (uv.y < negAmt) ? tex2D (s_Halfway, xy2) : EMPTY;

   return lerp (tex2D (s_Foreground, uv), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique openCorner
{
   pass P_1
   < string Script = "RenderColorTarget0 = Halfway;"; >
   { PixelShader = compile PROFILE open_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE open_main (); }
}


technique shutCorner
{
   pass P_1
   < string Script = "RenderColorTarget0 = Halfway;"; >
   { PixelShader = compile PROFILE shut_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE shut_main (); }
}
