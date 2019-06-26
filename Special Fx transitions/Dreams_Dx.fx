// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2015-11-26
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Dreams_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DreamSequence.mp4

/**
This effect starts off by rippling the outgoing image for the first third of the effect,
then dissolves to the new image for the next third, then loses the ripple over the
remainder of the effect.  It simulates Hollywood's classic dream effect.  The default
settings give exactly that result.

It's based on khaver's water effect, but some parameters have been changed to better
mimic the original film effect.  Two directional blurs have also been added, one very
much weaker than the other.  Their comparative strengths depend on the predominant
direction of the wave effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dreams_Dx.fx
//
// This has been written to be compatible with both D3D and Cg shader versions.  It
// should therefore be fully cross platform compliant.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//
// Update August 4 2017 by jwrl.
// All samplers fully defined to avoid differences in their default states between
// Windows and Linux/Mac compilers.
//
// Update August 10 2017 by jwrl.
// Renamed from Dreaming.fx for consistency across the dissolve range.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
// Changed "Fgd" to "Fg" and "Bgd" to "Bg".
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dream sequence";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Ripples the images as it dissolves between them";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture BlurXinput : RenderColorTarget;
texture BlurYinput : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture = <Fg>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture = <Bg>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_BlurX = sampler_state
{
   Texture = <BlurXinput>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_BlurY = sampler_state
{
   Texture = <BlurYinput>;
   AddressU = Mirror;
   AddressV = Mirror;
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

float Speed
<
   string Description = "Speed";
   float MinVal = 0.00;
   float MaxVal = 125.0;
> = 25.0;

float BlurAmt
<
   string Description = "Blur";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool wavy
<
   string Description = "Wavy";
> = true;

float WavesX
<
   string Description = "Frequency";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 100.0;
> = 0.0;

float WavesY
<
   string Description = "Frequency";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 100.0;
> = 20.0;

float StrengthX
<
   string Description = "Strength";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0000;
   float MaxVal = 0.100;
> = 0.0;

float StrengthY
<
   string Description = "Strength";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0000;
   float MaxVal = 0.100;
> = 0.02;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _Progress;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_XYwave (float2 xy, float2 wv, float amt)
{
   float2 result = xy;
   float waveRate = Speed / 2;

   float2 strength = float2 (StrengthX, StrengthY) * amt;

   if (wavy) {
      result.x += sin ((_Progress * waveRate) + result.y * wv.y) * strength.y;
      result.y += cos ((_Progress * waveRate) + result.x * wv.x) * strength.x;
      }
   else {
      result.x += sin ((_Progress * waveRate) + result.x * wv.x) * strength.x;
      result.y += cos ((_Progress * waveRate) + result.y * wv.y) * strength.y;
      }

   return result;
}

float4 fn_blur_sub (sampler blurSampler, float2 blurXY, float2 blurOffs)
{
   float Samples = 60.0;
   float Mix = min (1.0, abs (2.5 - abs ((Amount * 5.0) - 2.5)));

   float4 result  = 0.0.xxxx;
   float4 blurInp = tex2D (blurSampler, blurXY);

   for (int i = 0; i < Samples; i++) {
      result += tex2D (blurSampler, blurXY - blurOffs * i);
      }
    
   result /= Samples;

   return lerp (blurInp, result, Mix);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_dreams (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float wAmount = min (1.0, abs (1.5 - abs ((Amount * 3.0) - 1.5)));

   float mixAmount = saturate ((Amount * 2.0) - 0.5);

   float2 waves = float2 ((WavesX * 2.0), (WavesY * 2.0));

   xy1 = fn_XYwave (xy1, waves, wAmount);
   xy2 = fn_XYwave (xy2, waves, wAmount);

   float4 fgProc = tex2D (s_Foreground, xy1);
   float4 bgProc = tex2D (s_Background, xy2);

   return lerp (fgProc, bgProc, mixAmount);
}

float4 ps_blur (float2 xy : TEXCOORD1) : COLOR
{
   float BlurX;

   if (StrengthX > StrengthY) { BlurX = wavy ? BlurAmt : (BlurAmt / 2.0); }
   else BlurX = wavy ? (BlurAmt / 2) : BlurAmt;

   float2 offset = float2 (BlurX, 0.0) * 0.0005;

   return (BlurX > 0.0) ? fn_blur_sub (s_BlurX, xy, offset) : tex2D (s_BlurX, xy);
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float BlurY;

   if (StrengthX > StrengthY) { BlurY = wavy ? (BlurAmt / 2) : (BlurAmt * 2); }
      else BlurY = wavy ? (BlurAmt * 2) : (BlurAmt / 2);

   float2 offset = float2 (0.0, BlurY) * 0.0005;

   return (BlurY > 0.0) ? fn_blur_sub (s_BlurY, xy, offset) : tex2D (s_BlurY, xy);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dreams_Dx
{
   pass P_1
   < string Script = "RenderColorTarget0 = BlurXinput;"; >
   { PixelShader = compile PROFILE ps_dreams (); }

   pass P_2
   < string Script = "RenderColorTarget0 = BlurYinput;"; >
   { PixelShader = compile PROFILE ps_blur (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}
