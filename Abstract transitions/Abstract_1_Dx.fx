// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Abstraction1_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Abstraction1.mp4

/**
 Abstraction #1 uses a pattern that developed from my attempt to create a series of
 radiating or collapsing circles to transition between two sources.  Initially I
 rather unexpectedly produced a simple X wipe and while plugging in different values
 to try and track down the error, stumbled across this.  I liked it so I kept it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Abstract_1_Dx.fx
//
// This is a rebuild of an earlier effect, Abstraction1_Dx.fx, to meet the needs of
// Lightworks version 2021.1 and higher.  From a user's standpoint it's functionally
// identical to that earlier effect.  I have absolutely no idea how it works.  It's
// something that I accidentally came across while trying to do something else.
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
   string Description = "Abstraction #1";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "An abstract geometric transition between two opaque sources";
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

#define XY_SCALE 0.25

#define PROGRESS 0.35
#define P_OFFSET 0.3125         // 5/16
#define P_SCALE  4

#define LOOP     50

#define TWO_PI   6.2831853072
#define HALF_PI  1.5707963268

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

int SetTechnique
<
   string Description = "Wipe direction";
   string Enum = "Forward,Reverse";
> = 0;

float CentreX
<
   string Description = "Mid position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CentreY
<
   string Description = "Mid position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_RawBg, uv); }

float4 ps_forward (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy1 = lerp (0.5.xx, float2 (CentreX, 1.0 - CentreY), saturate (Amount * 2.0));
   float2 xy2 = abs (uv - xy1) * XY_SCALE;

   float progress = pow ((Amount * PROGRESS) + P_OFFSET, P_SCALE);
   float ctime, stime;

   sincos (progress, stime, ctime);
   xy1 = 0.4.xx;

   for (int i = 0; i < LOOP; ++i) {
      xy2  = abs (xy2 - xy1);
      xy2  = xy2 * ctime - xy2.yx * stime;
      xy1 *= 0.95;
   }

   progress = abs ((frac (length (xy2) * LOOP) - 0.5) * 2.0 + 0.5);

   float4 Fgnd = tex2D (s_Foreground, uv);
   float4 Bgnd = tex2D (s_Background, uv);
   float4 blnd = lerp (Fgnd, Bgnd, progress);

   progress = Amount * 2.0;

   blnd = lerp (Fgnd, blnd, saturate (progress));

   return lerp (blnd, Bgnd, saturate (progress - 1.0));
}

float4 ps_reverse (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy1 = lerp (0.5.xx, float2 (CentreX, 1.0 - CentreY), saturate ((1.0 - Amount) * 2.0));
   float2 xy2 = abs (uv - xy1) * XY_SCALE;

   float progress = pow (((1.0 - Amount) * PROGRESS) + P_OFFSET, P_SCALE);
   float ctime, stime;

   sincos (progress, stime, ctime);
   xy1 = 0.4.xx;

   for (int i = 0; i < LOOP; ++i) {
      xy2  = abs (xy2 - xy1);
      xy2  = xy2 * ctime - xy2.yx * stime;
      xy1 *= 0.95;
   }

   progress = abs ((frac (length (xy2) * LOOP) - 0.5) * 2.0 + 0.5);

   float4 Fgnd = tex2D (s_Foreground, uv);
   float4 Bgnd = tex2D (s_Background, uv);
   float4 blnd = lerp (Fgnd, Bgnd, progress);

   progress = Amount * 3.0;

   blnd = lerp (Fgnd, blnd, saturate (progress));

   return lerp (blnd, Bgnd, saturate (progress - 2.0));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Abstract_1_Dx_1 
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_forward)
}

technique Abstract_1_Dx_2
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_reverse)
}

