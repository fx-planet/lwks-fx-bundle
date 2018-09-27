// @Maintainer jwrl
// @Released 2018-09-26
// @Author jwrl
// @Created 2015-12-20
// @see https://www.lwks.com/media/kunena/attachments/6375/Channels_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Channels.fx
//
// This is a diagnostic tool that can be used to display individual RGB channels,
// luminance, summed RGB, U, V and alpha channels.
//
// Note: the alpha channel is preserved for potential later use in other effects.
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
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Channels";
   string Category    = "User";
   string SubCategory = "Broadcast";
   string Notes       = "Can be used to display individual RGB channels, luminance, summed RGB, U, V and alpha channels";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state {
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Channel
<
   string Description = "Display channel";
   string Enum = "Bypass,Luminance 709,RGB sum,Red,Green,Blue,Alpha,Luminance (Y),B-Y (U/Pb/Cb),R-Y (V/Pr/Cr)";
> = 0;

bool Negative
<
   string Description = "Display as negative";
> = false;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define R_MATRIX 0.2989
#define G_MATRIX 0.5866
#define B_MATRIX 0.1145

#define R_MAT709 0.2126
#define G_MAT709 0.7152
#define B_MAT709 0.0722

#define U_SCALE  0.564
#define V_SCALE  0.713

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 RGBval = tex2D (FgSampler, xy);

   if (Channel == 1) RGBval.rgb = float ((RGBval.r * R_MAT709) + (RGBval.g * G_MAT709) + (RGBval.b * B_MAT709)).xxx;
   if (Channel == 2) RGBval.rgb = float ((RGBval.r + RGBval.g + RGBval.b) / 3.0).xxx;

   if (Channel == 3) RGBval.rgb = RGBval.rrr;
   if (Channel == 4) RGBval.rgb = RGBval.ggg;
   if (Channel == 5) RGBval.rgb = RGBval.bbb;
   if (Channel == 6) RGBval.rgb = RGBval.aaa;

   if (Channel >= 7) {
      float luma = dot (RGBval.rgb, float3 (R_MATRIX, G_MATRIX, B_MATRIX));

      if (Channel == 8) luma = saturate (((luma - RGBval.b) * U_SCALE) + 0.5);
      if (Channel == 9) luma = saturate (((luma - RGBval.r) * V_SCALE) + 0.5);

      RGBval.rgb = luma.xxx;
   }

   if (Negative) RGBval.rgb = 1.0 - RGBval.rgb;

   return RGBval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique showChannels
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
