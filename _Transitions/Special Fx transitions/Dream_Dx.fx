// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
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
// Lightworks user effect Dream_Dx.fx
//
// This is a rebuild of an earlier effect, Dreams_Dx.fx, to meet the needs of Lightworks
// version 2021.1 and higher.
//
// Version history:
//
// Rewrite 2021-07-25 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dream sequence";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Ripples the images as it dissolves between them";
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

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = Mirror;                \
   AddressV  = Mirror;                \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

float _Progress;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);
DefineTarget (BlurXinput, s_BlurX);
DefineTarget (BlurYinput, s_BlurY);

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
   float MinVal = 0.0;
   float MaxVal = 125.0;
> = 25.0;

float BlurAmt
<
   string Description = "Blur";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool Wavy
<
   string Description = "Wavy";
> = true;

float WavesX
<
   string Description = "Frequency";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float WavesY
<
   string Description = "Frequency";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float StrengthX
<
   string Description = "Strength";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float StrengthY
<
   string Description = "Strength";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_XYwave (float2 xy1, float2 xy2, float amt)
{
   float waveRate = _Progress * Speed / 2.0;

   float2 xy = (xy1 * xy2) + waveRate.xx;
   float2 strength = float2 (StrengthX, StrengthY) * amt;

   return Wavy ? xy1 + (float2 (sin (xy.y), cos (xy.x)) * strength.yx)
               : xy1 + (float2 (sin (xy.x), cos (xy.y)) * strength);
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

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_RawBg, uv); }

float4 ps_dreams (float2 uv : TEXCOORD3) : COLOR
{
   float wAmount = min (1.0, abs (1.5 - abs ((Amount * 3.0) - 1.5))) / 10.0;

   float mixAmount = saturate ((Amount * 2.0) - 0.5);

   float2 waves = float2 (WavesX, WavesY) * 20.0;
   float2 xy = fn_XYwave (uv, waves, wAmount);

   float4 fgProc = tex2D (s_Foreground, xy);
   float4 bgProc = tex2D (s_Background, xy);

   return lerp (fgProc, bgProc, mixAmount);
}

float4 ps_blur (float2 uv : TEXCOORD3) : COLOR
{
   float BlurX;

   if (StrengthX > StrengthY) { BlurX = Wavy ? BlurAmt : (BlurAmt / 2.0); }
   else BlurX = Wavy ? (BlurAmt / 2.0) : BlurAmt;

   float2 offset = float2 (BlurX, 0.0) * 0.0005;

   return (BlurX > 0.0) ? fn_blur_sub (s_BlurX, uv, offset) : tex2D (s_BlurX, uv);
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float BlurY;

   if (StrengthX > StrengthY) { BlurY = Wavy ? (BlurAmt / 2) : (BlurAmt * 2.0); }
      else BlurY = Wavy ? (BlurAmt * 2) : (BlurAmt / 2);

   float2 offset = float2 (0.0, BlurY) * 0.0005;

   return (BlurY > 0.0) ? fn_blur_sub (s_BlurY, uv, offset) : tex2D (s_BlurY, uv);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dream_Dx
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = BlurXinput;"; > ExecuteShader (ps_dreams)
   pass P_2 < string Script = "RenderColorTarget0 = BlurYinput;"; > ExecuteShader (ps_blur)
   pass P_3 ExecuteShader (ps_main)
}

