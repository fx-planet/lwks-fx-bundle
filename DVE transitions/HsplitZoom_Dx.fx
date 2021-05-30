// @Maintainer jwrl
// @Released 2021-05-30
// @Author jwrl
// @Created 2021-05-30
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_HsplitZoom_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_HsplitZoom.mp4

/**
 This effect splits the outgoing video horizontally and spreads it to reveal the incoming
 shot, which zooms up out of a colour background.  The default background colour is black.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect HsplitZoom_Dx.fx
//
// Version history:
//
// Built 2021-05-30 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "H split with zoom";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Splits the outgoing video horizontally to reveal the incoming zooming out of a colour";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define CompileShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define Illegal(XY) any(saturate (XY) - XY)

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float4 Colour
<
   string Description = "Background colour";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float Amt = Amount / 2.0;
   float minAmt = 0.5 - Amt;
   float maxAmt = 0.5 + Amt;

   float2 xy1 = float2 (((uv1.x > 0.5) ? uv1.x - Amt : uv1.x + Amt), uv1.y);
   float2 xy2 = ((uv2 - 0.5.xx) * (2.0 - sin (Amount * HALF_PI))) + 0.5.xx;
/*
   float2 xy1 = uv1;
   float2 xy2 = ((uv2 - 0.5.xx) * (2.0 - sin (Amount * HALF_PI))) + 0.5.xx;

   xy1.x += (uv1.x > 0.5) ? -Amt : Amt;
*/
   return ((uv1.x <= minAmt) || (uv1.x >= maxAmt)) ? tex2D (s_Foreground, xy1)
                          : Illegal (xy2) ? Colour : tex2D (s_Background, xy2);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique HsplitZoom_Dx
{
   pass P_1 CompileShader (ps_main)
}
