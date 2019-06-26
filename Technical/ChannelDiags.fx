// @Maintainer jwrl
// @Released 2019-02-12
// @Author jwrl
// @Created 2015-12-20
// @see https://www.lwks.com/media/kunena/attachments/6375/Channels_640a.png

/**
This is a diagnostic tool that can be used to display individual RGB channels, luminance,
summed RGB, U, V and alpha channels.

Note: the alpha channel is preserved for potential later use in other effects.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChannelDiags.fx
//
// Modified 18 June 2016 by jwrl.
// Added RGB sum, B - Y and R - Y display.
//
// Modified 16 August 2016 by jwrl.
// Added 709 luminance matrix and the ability to show any or all RGB as negative.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
//
// Rewrite by LW user jwrl 5 November 2018.
// Rewritten to add 2020 support and clean up code.
//
// Modified by LW user jwrl 6 December 2018.
// Renamed effect.
// Changed subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 12 Feb 2019 by user jwrl:
// Changed input addressing to defaults.  This allows it to be used on older LW versions.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Channel diagnostics";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "Can be used to display individual RGB channels, luminance, summed RGB, U, V and alpha channels";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Colour space";
   string Enum = "Rec-601 (Standard definition),Rec-709 (High definition),Rec-2020 (Ultra high definition)";
> = 1;

int Channel
<
   string Description = "Display channel";
   string Enum = "Bypass,Luminance (Y),RGB sum,Red,Green,Blue,Alpha,B-Y (U/Pb/Cb),R-Y (V/Pr/Cr)";
> = 0;

bool Negative
<
   string Description = "Display as negative";
> = false;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define MATRIX601  float3(0.2989, 0.5866, 0.1145)
#define MATRIX709  float3(0.2126, 0.7152, 0.0722)
#define MATRIX2020 float3(0.2627, 0.678,  0.0593)

#define U_601      0.564
#define V_601      0.713

#define U_709      0.635
#define V_709      0.539

#define U_2020     0.5315
#define V_2020     0.6782

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_601 (float2 xy : TEXCOORD1) : COLOR
{
   float4 RGBval = tex2D (s_Input, xy);

   if ((Channel == 1) || (Channel > 6)) {
      float luma = dot (RGBval.rgb, MATRIX601);

      if (Channel == 7) luma = saturate (((luma - RGBval.b) * U_601) + 0.5);
      if (Channel == 8) luma = saturate (((luma - RGBval.r) * V_601) + 0.5);

      RGBval.rgb = luma.xxx;
   }

   if (Channel == 2) RGBval.rgb = float ((RGBval.r + RGBval.g + RGBval.b) / 3.0).xxx;
   if (Channel == 3) RGBval.rgb = RGBval.rrr;
   if (Channel == 4) RGBval.rgb = RGBval.ggg;
   if (Channel == 5) RGBval.rgb = RGBval.bbb;
   if (Channel == 6) RGBval.rgb = RGBval.aaa;

   if (Negative) RGBval.rgb = 1.0.xxx - RGBval.rgb;

   return RGBval;
}

float4 ps_main_709 (float2 xy : TEXCOORD1) : COLOR
{
   float4 RGBval = tex2D (s_Input, xy);

   if ((Channel == 1) || (Channel > 6)) {
      float luma = dot (RGBval.rgb, MATRIX709);

      if (Channel == 7) luma = saturate (((luma - RGBval.b) * U_709) + 0.5);
      if (Channel == 8) luma = saturate (((luma - RGBval.r) * V_709) + 0.5);

      RGBval.rgb = luma.xxx;
   }

   if (Channel == 2) RGBval.rgb = float ((RGBval.r + RGBval.g + RGBval.b) / 3.0).xxx;
   if (Channel == 3) RGBval.rgb = RGBval.rrr;
   if (Channel == 4) RGBval.rgb = RGBval.ggg;
   if (Channel == 5) RGBval.rgb = RGBval.bbb;
   if (Channel == 6) RGBval.rgb = RGBval.aaa;

   if (Negative) RGBval.rgb = 1.0.xxx - RGBval.rgb;

   return RGBval;
}

float4 ps_main_2020 (float2 xy : TEXCOORD1) : COLOR
{
   float4 RGBval = tex2D (s_Input, xy);

   if ((Channel == 1) || (Channel > 6)) {
      float luma = dot (RGBval.rgb, MATRIX2020);

      if (Channel == 7) luma = saturate (((luma - RGBval.b) * U_2020) + 0.5);
      if (Channel == 8) luma = saturate (((luma - RGBval.r) * V_2020) + 0.5);

      RGBval.rgb = luma.xxx;
   }

   if (Channel == 2) RGBval.rgb = float ((RGBval.r + RGBval.g + RGBval.b) / 3.0).xxx;
   if (Channel == 3) RGBval.rgb = RGBval.rrr;
   if (Channel == 4) RGBval.rgb = RGBval.ggg;
   if (Channel == 5) RGBval.rgb = RGBval.bbb;
   if (Channel == 6) RGBval.rgb = RGBval.aaa;

   if (Negative) RGBval.rgb = 1.0.xxx - RGBval.rgb;

   return RGBval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ChannelDiags_601
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_601 (); }
}

technique ChannelDiags_709
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_709 (); }
}
technique ChannelDiags_2020
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_2020 (); }
}

