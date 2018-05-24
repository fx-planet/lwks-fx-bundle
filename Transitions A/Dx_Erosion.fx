// @Maintainer jwrl
// @Released 2018-04-19
// @Author jwrl
// @Created 2016-12-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Erosion_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Erosion.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_Erosion.fx
//
// This effect transitions between two video sources using a mixed key.  The result is
// that one image appears to "erode" into the other as if being eaten away by acid.
//
// Modified 2018-04-19 by jwrl.
// The creation date is correct:  this was developed in its present form in late 2016,
// but not released until this date.  The addition of a subcategory and cosmetic changes
// to match my current formatting and naming practices are the only changes made prior
// to this release.  I have no idea why I originally chose to withold it.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Erosion";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Outgoing = sampler_state { Texture = <Fg>; };
sampler s_Incoming = sampler_state { Texture = <Bg>; };

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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float a_1 = Amount * 2.0;
   float a_2 = max (0.0, a_1 - 1.0);

   a_1 = min (a_1, 1.0);

   float4 Fgd = tex2D (s_Outgoing, uv);
   float4 Bgd = tex2D (s_Incoming, uv);
   float4 m_1 = (Fgd + Bgd) * 0.5;
   float4 m_2 = max (m_1.r, max (m_1.g, m_1.b)) >= a_1 ? Fgd : m_1;

   return max (m_2.r, max (m_2.g, m_2.b)) >= a_2 ? m_2 : Bgd;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Erosion
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

