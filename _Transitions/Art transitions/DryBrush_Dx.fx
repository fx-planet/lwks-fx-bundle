// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_DryBrush_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_DryBrush.mp4

/**
 This mimics the Photoshop angled brush stroke effect to transition between two shots.
 The stroke length and angle can be independently adjusted, and can be keyframed while
 the transition happens to make the effect more dynamic.  To minimise edge of frame
 problems mirror addressing has been used for processing.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DryBrush_Dx.fx
//
// Version history:
//
// Rebuilt 2021-07-25 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dry brush mix";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "Uses an angled brush stroke effect to transition between two shots";
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

float Length
<
   string Description = "Stroke length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Angle
<
   string Description = "Stroke angle";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 45.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_rnd (float2 uv)
{
   return frac (sin (dot (uv, float2 (12.9898, 78.233))) * 43758.5453);
}

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_RawBg, uv); }

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float stroke = (Length * 0.1) + 0.02;
   float angle  = radians (Angle + 135.0);

   float2 xy0 = fn_rnd (uv - 0.5.xx) * stroke * Amount;
   float2 xy1, xy2, xy3;

   sincos (angle, xy3.x, xy3.y);

   xy1.x = xy0.x * xy3.x + xy0.y * xy3.y;
   xy1.y = xy0.y * xy3.x - xy0.x * xy3.y;

   xy0 = fn_rnd (uv - 0.5.xx) * stroke * (1.0 - Amount);

   xy2.x = xy0.x * xy3.x + xy0.y * xy3.y;
   xy2.y = xy0.y * xy3.x - xy0.x * xy3.y;

   float4 Fgnd = tex2D (s_Foreground, uv + xy1);
   float4 Bgnd = tex2D (s_Background, uv + xy2);

   return lerp (Fgnd, Bgnd, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DryBrush_Dx
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_main)
}
