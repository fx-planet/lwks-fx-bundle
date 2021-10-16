// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/WhipPan_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/WhipPan.mp4

/**
 This effect performs a whip pan style of transition between two sources.  Unlike the
 blur dissolve effect, this also pans the incoming and outgoing vision sources.  This
 revised version allows the whip pan angle to be set over the range of plus or minus
 180 degrees.  The original was limited to horizontal and vertical moves.

 To better handle varying aspect ratios masking has been provided to limit the blur
 range to the input frame boundaries.  This changes as the effect progresses to allow
 for differing incoming and outgoing media aspect ratios.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhipPan_Dx.fx
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
   string Description = "Whip pan";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Uses a directional blur to simulate a whip pan between two sources";
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

#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define PI        3.14159265359

#define SAMPLES   60
#define SAMPSCALE 61

#define STRENGTH  0.01

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

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

float Angle
<
   string Description = "Angle";
   float MinVal = -180.00;
   float MaxVal = 180.0;
> = 0.0;

float Spread
<
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_RawBg, uv); }

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float amount = saturate (Amount);   // Just in case someone types in silly numbers

   float2 blur1, blur2;

   sincos (radians (Angle), blur1.y, blur1.x);
   sincos (radians (Angle + 180.0), blur2.y, blur2.x);

   blur1  *= Spread * amount;
   blur2  *= Spread * (1.0 - amount);
   blur1.x = -blur1.x;
   blur2.x = -blur2.x;

   float2 xy1 = uv + (blur1 * 3.0);
   float2 xy2 = uv + (blur2 * 3.0);

   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   if (Spread > 0.0) {
      blur1 *= STRENGTH;
      blur2 *= STRENGTH;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur1;
         xy2 += blur2;
         Fgnd += tex2D (s_Foreground, xy1);
         Bgnd += tex2D (s_Background, xy2);
      }
    
      Fgnd /= SAMPSCALE;
      Bgnd /= SAMPSCALE;
   }

   return lerp (Fgnd, Bgnd, 0.5 - (cos (amount * PI) / 2.0));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WhipPan_Dx
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_main)
}

