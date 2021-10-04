// @Maintainer jwrl
// @Released 2021-08-01
// @Author jwrl
// @Created 2021-08-01
// @see https://www.lwks.com/media/kunena/attachments/6375/TwistIt_Dx_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/TwistIt_Dx.mp4

/**
 This is a wipe that uses a trig distortion to perform a single simple twist to transition
 between two images, either horizontally or vertically.  It does not have any of the bells
 and whistles such as adjustable blending and softness.  If you need that have a look at
 Twister_Dx.fx instead.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TwistIt_Dx.fx
//
// Version history:
//
// Built 2021-08-01 jwrl.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Twist it";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Twists one image to another vertically or horizontally";
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

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define PI 3.1415926536

float _OutputHeight;

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
   string Description = "Transition profile";
   string Enum = "Left > right,Right > left,Top > bottom,Bottom > top"; 
> = 0;

float Spread
<
   string Description = "Twist width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_main_0 (float2 uv : TEXCOORD3) : COLOR
{
   float twist = (9.0 * Spread) + 3.0;
   float pos_n = ((1.0 - Amount) / twist) - Amount;

   twist *= pos_n + uv.x;
   twist  = cos (saturate (twist) * PI);

   float2 xy = float2 (uv.x, ((uv.y - 0.5) / twist) + 0.5);

   if (twist > 0.0) return GetPixel (s_Background, xy);

   return GetPixel (s_Foreground, float2 (xy.x, 1.0 - xy.y));
}

float4 ps_main_1 (float2 uv : TEXCOORD3) : COLOR
{
   float twist = (9.0 * Spread) + 3.0;
   float pos_n = ((1.0 - Amount) / twist) - Amount;

   twist *= pos_n - uv.x + 1.0;
   twist  = cos (saturate (twist) * PI);

   float2 xy = float2 (uv.x, ((uv.y - 0.5) / twist) + 0.5);

   if (twist > 0.0) return GetPixel (s_Background, xy);

   return GetPixel (s_Foreground, float2 (xy.x, 1.0 - xy.y));
}

float4 ps_main_2 (float2 uv : TEXCOORD3) : COLOR
{
   float twist = (9.0 * Spread) + 3.0;
   float pos_n = ((1.0 - Amount) / twist) - Amount;

   twist *= pos_n + uv.y;
   twist  = cos (saturate (twist) * PI);

   float2 xy = float2 (((uv.x - 0.5) / twist) + 0.5, uv.y);

   if (twist > 0.0) return GetPixel (s_Background, xy);

   return GetPixel (s_Foreground, float2 (1.0 - xy.x, xy.y));
}

float4 ps_main_3 (float2 uv : TEXCOORD3) : COLOR
{
   float twist = (9.0 * Spread) + 3.0;
   float pos_n = ((1.0 - Amount) / twist) - Amount;

   twist *= pos_n - uv.y + 1.0;
   twist  = cos (saturate (twist) * PI);

   float2 xy = float2 (((uv.x - 0.5) / twist) + 0.5, uv.y);

   if (twist > 0.0) return GetPixel (s_Background, xy);

   return GetPixel (s_Foreground, float2 (1.0 - xy.x, xy.y));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Twistit_LR
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_main_0)
}

technique Twistit_RL
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_main_1)
}

technique Twistit_TB
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_main_2)
}

technique Twistit_BT
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_main_3)
}

