//--------------------------------------------------------------//
// Lightworks user effect Channels.fx
//
// Created by LW user jwrl 20 December 2015
// This effect can show individual RGB channels and a range
// of other video components.
//
// Note: the alpha channel is preserved for potential later
// use in other effects.
//
// 18 June 2016: Added RGB sum, B - Y and R - Y display.
//
// 16 August 2016: Added 709 luminance matrix and the ability
//                 to show any or all RGB as negative.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Channels";
   string Category    = "User";
   string SubCategory = "Broadcast";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state {
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int Channel
<
   string Description = "Display channel";
   string Enum = "Bypass,Luminance 709,RGB sum,Red,Green,Blue,Alpha,Luminance (Y),B-Y (U/Pb/Cb),R-Y (V/Pr/Cr)";
> = 0;

bool Negative
<
   string Description = "Display as negative";
> = false;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define R_MATRIX 0.2989
#define G_MATRIX 0.5866
#define B_MATRIX 0.1145

#define R_MAT709 0.2126
#define G_MAT709 0.7152
#define B_MAT709 0.0722

#define U_SCALE  0.564
#define V_SCALE  0.713

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique showChannels
{
   pass Single_Pass
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

