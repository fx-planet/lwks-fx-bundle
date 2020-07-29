// @Maintainer jwrl
// @Released 2020-07-29
// @Author jwrl
// @Created 2016-05-07
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Zoom_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/ZoomDissolve.mp4

/**
 This effect either:
   Zooms into the outgoing image as it dissolves to the new image which zooms in to
   fill the frame.
 OR
   Zooms out of the outgoing image and dissolves to the new one while it's zooming out
   to full frame.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Zoom_Dx.fx
//
// The blur algorithm I've found in too many places to be able to reliably attribute it.
// I'd like to be able to credit the original author(s) if I knew who he/she/they were.
//
// Version history:
//
// Modified 2020-07-29 jwrl.
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
//
// Update August 10 2017 by jwrl.
// Renamed from zoom_mix.fx for consistency across the dissolve range.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Zoom dissolve";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Zooms between the two sources";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture outProc : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Outgoing = sampler_state
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

#define HALF_PI   1.5707963268

#define SAMPLE    80
#define DIVISOR   81.0

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_zoom_in_Bg (float2 xy : TEXCOORD1) : COLOR
{
   if (zoomAmount <= 0.0) return tex2D (s_Background, xy);

   float zoomStrength = zoomAmount * sqrt (1.0 - sin (Amount * HALF_PI)) / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 uv = xy - zoomCentre;

   float4 retval = (0.0).xxxx;

   for (int i = 0; i <= SAMPLE; i++) {
      retval += tex2D (s_Background, uv * scale + zoomCentre);
      scale  += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_main_in (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 retval;

   if (zoomAmount <= 0.0) { retval = tex2D (s_Foreground, xy1); }
   else {
      float zoomStrength = zoomAmount * (1.0 - cos (Amount * HALF_PI));
      float scale = 1.0 - zoomStrength;

      zoomStrength /= SAMPLE;

      float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
      float2 uv = xy1 - zoomCentre;

      retval = (0.0).xxxx;

      for (int i = 0; i <= SAMPLE; i++) {
         retval += tex2D (s_Foreground, uv * scale + zoomCentre);
         scale  += zoomStrength;
      }

      retval /= DIVISOR;
   }

   return lerp (retval, tex2D (s_Outgoing, xy2), Amount);
}

float4 ps_zoom_out_Bg (float2 xy : TEXCOORD1) : COLOR
{
   if (zoomAmount <= 0.0) return tex2D (s_Background, xy);

   float zoomStrength = zoomAmount * (1.0 - sin (Amount * HALF_PI));
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 uv = xy - zoomCentre;

   float4 retval = (0.0).xxxx;

   for (int i = 0; i <= SAMPLE; i++) {
      retval += tex2D (s_Background, uv * scale + zoomCentre);
      scale  += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_main_out (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 retval;

   if (zoomAmount <= 0.0) { retval = tex2D (s_Foreground, xy1); }
   else {
      float zoomStrength = zoomAmount * (1.0 - cos (Amount * HALF_PI)) / SAMPLE;
      float scale = 1.0;

      float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
      float2 uv = xy1 - zoomCentre;

      retval = (0.0).xxxx;

      for (int i = 0; i <= SAMPLE; i++) {
         retval += tex2D (s_Foreground, uv * scale + zoomCentre);
         scale  += zoomStrength;
      }

      retval /= DIVISOR;
   }

   return lerp (retval, tex2D (s_Outgoing, xy2), Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dx_Zoom_In
{
   pass P_1
   < string Script = "RenderColorTarget0 = outProc;"; >
   { PixelShader = compile PROFILE ps_zoom_in_Bg (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Dx_Zoom_Out
{
   pass P_1
   < string Script = "RenderColorTarget0 = outProc;"; >
   { PixelShader = compile PROFILE ps_zoom_out_Bg (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_out (); }
}
