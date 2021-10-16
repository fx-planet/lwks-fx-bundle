// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_CnrSqueeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_CnrSqueeze.mp4

/**
 This is based on the corner wipe effect, modified to squeeze or expand the divided
 section of the frame.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CornerSqueeze_Dx.fx
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
   string Description = "Corner squeeze";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "A corner wipe effect that squeezes or expands the divided section of the frame";
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
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Vid1, s_Video_1);
DefineTarget (Vid2, s_Video_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Squeeze to corners,Expand from corners";
> = 0;

float Amount
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_in (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_Background, uv); }
float4 ps_out (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_Foreground, uv); }

float4 ps_sqz_horiz (float2 uv : TEXCOORD3) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 ((uv.x - Amount) / negAmt, uv.y);
   float2 xy2 = float2 (uv.x / negAmt, uv.y);

   negAmt /= 2.0;

   return (uv.x > posAmt) ? tex2D (s_Video_1, xy1) : (uv.x < negAmt)
                          ? tex2D (s_Video_1, xy2) : EMPTY;
}

float4 ps_sqz_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv3.x, (uv3.y - Amount) / negAmt);
   float2 xy2 = float2 (uv3.x, uv3.y / negAmt);

   negAmt /= 2.0;

   float4 retval = (uv3.y > posAmt) ? tex2D (s_Video_2, xy1) : (uv3.y < negAmt)
                                    ? tex2D (s_Video_2, xy2) : EMPTY;

   return lerp (GetPixel (s_Background, uv2), retval, retval.a);
}

float4 ps_exp_horiz (float2 uv : TEXCOORD3) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 ((uv.x + Amount - 1.0) / Amount, uv.y);
   float2 xy2 = float2 (uv.x / Amount, uv.y);

   return (uv.x > posAmt) ? tex2D (s_Video_1, xy1) : (uv.x < negAmt)
                          ? tex2D (s_Video_1, xy2) : EMPTY;
}

float4 ps_exp_main (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv3.x, (uv3.y + Amount - 1.0) / Amount);
   float2 xy2 = float2 (uv3.x, uv3.y / Amount);

   float4 retval = (uv3.y > posAmt) ? tex2D (s_Video_2, xy1) : (uv3.y < negAmt)
                                    ? tex2D (s_Video_2, xy2) : EMPTY;

   return lerp (GetPixel (s_Foreground, uv1), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique CornerSqueeze_Dx_0
{
   pass P_1 < string Script = "RenderColorTarget0 = Vid1;"; > ExecuteShader (ps_out)
   pass P_2 < string Script = "RenderColorTarget0 = Vid2;"; > ExecuteShader (ps_sqz_horiz)
   pass P_3 ExecuteShader (ps_sqz_main)
}

technique CornerSqueeze_Dx_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Vid1;"; > ExecuteShader (ps_in)
   pass P_2 < string Script = "RenderColorTarget0 = Vid2;"; > ExecuteShader (ps_exp_horiz)
   pass P_3 ExecuteShader (ps_exp_main)
}
