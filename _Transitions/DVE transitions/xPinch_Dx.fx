// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_xPinch_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_xPinch.mp4

/**
 This effect pinches the outgoing video to a user-defined point to reveal the incoming
 shot, while zooming out of the pinched image.  It can also reverse the process to bring
 in the incoming video.

 The direction swap has been deliberately made asymmetric.  Subjectively it looked better
 to have the pinch established before the zoom out started, but to run the zoom in through
 the entire un-pinch process.  Trig functions are used on the effect progress to make the
 acceleration smoother.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect xPinch_Dx.fx
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
   string Description = "X-pinch";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Pinches the outgoing video to an X-shape then a user-defined point to reveal the incoming shot";
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define MID_PT  (0.5).xx
#define HALF_PI 1.5707963

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Video, s_Video);
DefineTarget (Pinch, s_Pinch);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Pinch to reveal,Expand to reveal";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_in (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_Background, uv); }
float4 ps_out (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_Foreground, uv); }

float4 ps_pinch_1 (float2 uv : TEXCOORD3) : COLOR
{
   float progress = sin (Amount * HALF_PI);

   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return GetPixel (s_Video, xy);
}

float4 ps_main_1 (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float progress = 1.0 - cos (max (0.0, Amount - 0.25) * HALF_PI);
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv3 - MID_PT) * scale) + MID_PT;

   float4 retval = tex2D (s_Pinch, xy);

   return lerp (GetPixel (s_Background, uv2), retval, retval.a);
}

float4 ps_pinch_2 (float2 uv : TEXCOORD3) : COLOR
{
   float progress = cos (Amount * HALF_PI);

   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return GetPixel (s_Video, xy);
}

float4 ps_main_2 (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float progress = 1.0 - sin (Amount * HALF_PI);
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv3 - MID_PT) * scale) + MID_PT;

   float4 retval = tex2D (s_Pinch, xy);

   return lerp (GetPixel (s_Foreground, uv1), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique xPinch_Dx_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Video;"; > ExecuteShader (ps_out)
   pass P_2 < string Script = "RenderColorTarget0 = Pinch;"; > ExecuteShader (ps_pinch_1)
   pass P_3 ExecuteShader (ps_main_1)
}

technique xPinch_Dx_2
{
   pass P_1 < string Script = "RenderColorTarget0 = Video;"; > ExecuteShader (ps_in)
   pass P_2 < string Script = "RenderColorTarget0 = Pinch;"; > ExecuteShader (ps_pinch_2)
   pass P_3 ExecuteShader (ps_main_2)
}
