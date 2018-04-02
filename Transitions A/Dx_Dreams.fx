// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Dx_Dreams.fx
//
// Written by LW user jwrl November 2015
// @Author jwrl
// @CreationDate "November 2015"
//
// This effect starts off by rippling the outgoing image for
// the first third of the effect, then dissolves to the new
// image for the next third, then loses the ripple over the
// remainder of the effect.  It simulates Hollywood's classic
// dream effect.  The default settings give exactly that
// result.
//
// It's based on khaver's water effect, but some parameters
// have been changed to better mimic the original film effect.
// Two directional blurs have also been added, one very much
// weaker than the other.  Their comparative strengths depend
// on the predominant direction of the wave effect.
//
// This has been written to be compatible with both D3D and
// Cg shader versions.  It should therefore be fully cross
// platform compliant.
//
// Update August 4 2017 by jwrl.
// All samplers fully defined to avoid differences in their
// default states between Windows and Linux/Mac compilers.
//
// Update August 10 2017 by jwrl - renamed from Dreaming.fx
// for consistency across the dissolve range.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dream sequence";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fgd;
texture Bgd;

texture BlurXinput : RenderColorTarget;
texture BlurYinput : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture = <Fgd>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture = <Bgd>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler XinSampler = sampler_state
{
   Texture = <BlurXinput>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler YinSampler = sampler_state
{
   Texture = <BlurYinput>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

float _Progress;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

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

//   Mix = (Mix < 1.0) ? Mix : ((Mix > 4.0) ? (5.0 - Mix) : 1.0);

   float4 result  = 0.0.xxxx;
   float4 blurInp = tex2D (blurSampler, blurXY);

   for (int i = 0; i < Samples; i++) {
      result += tex2D (blurSampler, blurXY - blurOffs * i);
      }
    
   result /= Samples;

   return lerp (blurInp, result, Mix);
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_dreams (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
/*
   float wAmount  = (Amount * 3.0);

   wAmount = (wAmount > 2.0) ? (3.0 - wAmount) : ((wAmount < 1.0) ? wAmount : 1.0);
*/
   float wAmount = min (1.0, abs (1.5 - abs ((Amount * 3.0) - 1.5)));

   float mixAmount = saturate ((Amount * 2.0) - 0.5);

//   mixAmount = (mixAmount < 0.0) ? 0.0 : ((mixAmount > 1.0) ? 1.0 : mixAmount);

   float2 waves = float2 ((WavesX * 2.0), (WavesY * 2.0));

   xy1 = fn_XYwave (xy1, waves, wAmount);
   xy2 = fn_XYwave (xy2, waves, wAmount);

   float4 fgProc = tex2D (FgSampler, xy1);
   float4 bgProc = tex2D (BgSampler, xy2);

   return lerp (fgProc, bgProc, mixAmount);
}

float4 ps_blur (float2 xy : TEXCOORD1) : COLOR
{
   float BlurX;

   if (StrengthX > StrengthY) { BlurX = wavy ? BlurAmt : (BlurAmt / 2.0); }
   else BlurX = wavy ? (BlurAmt / 2) : BlurAmt;

   float2 offset = float2 (BlurX, 0.0) * 0.0005;

   return (BlurX > 0.0) ? fn_blur_sub (XinSampler, xy, offset) : tex2D (XinSampler, xy);
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float BlurY;

   if (StrengthX > StrengthY) { BlurY = wavy ? (BlurAmt / 2) : (BlurAmt * 2); }
      else BlurY = wavy ? (BlurAmt * 2) : (BlurAmt / 2);

   float2 offset = float2 (0.0, BlurY) * 0.0005;

   return (BlurY > 0.0) ? fn_blur_sub (YinSampler, xy, offset) : tex2D (YinSampler, xy);
}

//--------------------------------------------------------------
// Techniques
//--------------------------------------------------------------

technique Dreaming
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

