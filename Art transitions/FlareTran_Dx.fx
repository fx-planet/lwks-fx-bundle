// @Maintainer jwrl
// @Released 2021-07-25
// @Author khaver
// @Created 2014-08-30
// @see https://www.lwks.com/media/kunena/attachments/6375/FlareTran_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/FlareTran.mp4

/**
 FlareTran is a transition that dissolves through an over-exposure style flare.  Amongst
 other things it can be used to simulate the burn out effect that happens when a film
 camera stops.  With mixed size and aspect ratio media it may be necessary to experiment
 with swapping the target track and/or adjusting the strength of the effect to get the
 best result.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlareTran_Dx.fx
//
// Version history:
//
// Modified 2021-07-25 jwrl.
// Added CanSize switch for 2021 support.
// Restructured I/O coordinates and pixel recovery to support variable resolution.
//
// Built 2014-08-30 khaver.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Flare Tran";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "Dissolves between images through an over-exposure style of flare";
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
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, InputSampler);
DefineTarget (RawBg, OutputSampler);
DefineTarget (Sample, Samp1);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool Swap
<
	string Description = "Swap target track";
> = false;

float CentreX
<
   string Description = "Origin";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float CentreY
<
   string Description = "Origin";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float stretch
<
   string Description = "Stretch";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 5.0;

float Timing
<
   string Description = "Timing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float adjust
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_RawBg, uv); }

float4 ps_adjust (float2 uv : TEXCOORD3) : COLOR
{
   float flare = 1.0 - abs ((adjust * 2.0) - 1.0);

   float4 Color = (Swap) ? tex2D (OutputSampler, uv) : tex2D (InputSampler, uv);

   if (Color.r < 1.0 - flare) Color.r = 0.0;
   if (Color.g < 1.0 - flare) Color.g = 0.0;
   if (Color.b < 1.0 - flare) Color.b = 0.0;

   return Color;
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float Stretch = 10.0 - stretch;

   float2 xy0 = float2 (CentreX, 1.0 - CentreY);
   float2 xy1 = uv - xy0;

   float2 amount = Stretch / float2 (_OutputWidth, _OutputHeight);
   float2 adj = amount;

   // jwrl: Rather than the hard cut between sources in khaver's original, I have amended
   // it to be a dissolve that occupies 10% of the transition duration.  The original was
   // source = (adjust < Timing) ? tex2D (InputSampler, xy1) : tex2D (OutputSampler, xy1);

   float mid_trans = saturate ((adjust - (Timing * 0.5) - 0.25) * 10.0);

   float4 source = lerp (tex2D (InputSampler, uv), tex2D (OutputSampler, uv), mid_trans);
   float4 ret = tex2D (Samp1, xy0 + (xy1 * adj));

   for (int count = 1; count < 15; count++) {
      adj += amount;
      ret += tex2D (Samp1, xy0 + (xy1 * adj)) * count * Strength;
   }

   ret /= 17.0;
   ret = ret + source;

   return saturate (float4 (ret.rgb, 1.0));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Flare
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pass1 < string Script = "RenderColorTarget0 = Sample;"; > ExecuteShader (ps_adjust)
   pass Pass2 ExecuteShader (ps_main)
}
