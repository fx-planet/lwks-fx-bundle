// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2016-05-07
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Zoom_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/ZoomDissolve.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_Zoom.fx
//
// This effect either:
//   Zooms into the outgoing image as it dissolves to the new image which zooms in to
//   fill the frame.
// OR
//   Zooms out of the outgoing image and dissolves to the new one while it's zooming out
//   to full frame.
//
// The blur algorithm I've found in too many places to be able to reliably attribute it.
// I'd like to be able to credit the original author(s) if I knew who he/she/they were.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Update August 10 2017 by jwrl.
// Renamed from zoom_mix.fx for consistency across the dissolve range.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Zoom dissolve";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture inProc  : RenderColorTarget;
texture outProc : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler inSampler  = sampler_state
{
   Texture   = <inProc>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler outSampler = sampler_state
{
   Texture   = <outProc>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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

int SetTechnique
<
   string Group = "Zoom";
   string Description = "Direction";
   string Enum = "Zoom in,Zoom out";
> = 0;

float zoomAmount
<
   string Group = "Zoom";
   string Description = "Strength";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Xcentre
<
   string Description = "Zoom centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Zoom centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI   1.570796

#define SAMPLE    80
#define DIVISOR   81.0

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_zoom_A_Fg (float2 xy : TEXCOORD1) : COLOR
{
   if (zoomAmount == 0.0)  return tex2D (FgSampler, xy);

   float zoomStrength = zoomAmount * (1.0 - cos (Amount * HALF_PI));
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 uv = xy - zoomCentre;

   float4 retval = (0.0).xxxx;

   for (int i = 0; i <= SAMPLE; i++) {
      retval += tex2D (FgSampler, uv * scale + zoomCentre);
      scale  += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_A_Bg (float2 xy : TEXCOORD1) : COLOR
{
   if (zoomAmount == 0.0)  return tex2D (BgSampler, xy);

   float zoomStrength = zoomAmount * (1.0 - sin (Amount * HALF_PI));
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 uv = xy - zoomCentre;

   float4 retval = (0.0).xxxx;

   for (int i = 0; i <= SAMPLE; i++) {
      retval += tex2D (BgSampler, uv * scale + zoomCentre);
      scale  += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_B_Fg (float2 xy : TEXCOORD1) : COLOR
{
   if (zoomAmount == 0.0)  return tex2D (FgSampler, xy);

   float zoomStrength = zoomAmount * (1.0 - cos (Amount * HALF_PI)) / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 uv = xy - zoomCentre;

   float4 retval = (0.0).xxxx;

   for (int i = 0; i <= SAMPLE; i++) {
      retval += tex2D (FgSampler, uv * scale + zoomCentre);
      scale  += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_B_Bg (float2 xy : TEXCOORD1) : COLOR
{
   if (zoomAmount == 0.0)  return tex2D (BgSampler, xy);

   float zoomStrength = zoomAmount * sqrt (1.0 - sin (Amount * HALF_PI)) / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 uv = xy - zoomCentre;

   float4 retval = (0.0).xxxx;

   for (int i = 0; i <= SAMPLE; i++) {
      retval += tex2D (BgSampler, uv * scale + zoomCentre);
      scale  += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 fgImage = tex2D (inSampler, xy1);
   float4 bgImage = tex2D (outSampler, xy2);

   return lerp (fgImage, bgImage, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ZoomDissolveIn
{
   pass P_1
   < string Script = "RenderColorTarget0 = outProc;"; >
   { PixelShader = compile PROFILE ps_zoom_B_Bg (); }

   pass P_2
   < string Script = "RenderColorTarget0 = inProc;"; >
   { PixelShader = compile PROFILE ps_zoom_A_Fg (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique ZoomDissolveOut
{
   pass P_1
   < string Script = "RenderColorTarget0 = outProc;"; >
   { PixelShader = compile PROFILE ps_zoom_A_Bg (); }

   pass P_2
   < string Script = "RenderColorTarget0 = inProc;"; >
   { PixelShader = compile PROFILE ps_zoom_B_Fg (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}
