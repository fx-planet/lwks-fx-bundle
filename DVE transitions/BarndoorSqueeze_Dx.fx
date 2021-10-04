// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_SplitSqueeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_SplitSqueeze.mp4

/**
 This is based on the barn door split effect, modified to squeeze or expand the divided
 section of the frame.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BarndoorSqueeze_Dx.fx
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
   string Description = "Barn door squeeze";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "A barn door effect that squeezes the outgoing video to the edges of frame to reveal the incoming video";
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

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Outw, s_Outgoing);
DefineTarget (Inw, s_Incoming);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Squeeze horizontal,Expand horizontal,Squeeze vertical,Expand vertical";
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

float4 ps_out (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_Foreground, uv); }
float4 ps_in (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_Background, uv); }

float4 ps_sqz_horiz (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 ((uv3.x - Amount) / negAmt, uv3.y);
   float2 xy2 = float2 (uv3.x / negAmt, uv3.y);

   negAmt /= 2.0;

   return (uv3.x > posAmt) ? tex2D (s_Outgoing, xy1) :
          (uv3.x < negAmt) ? tex2D (s_Outgoing, xy2) : GetPixel (s_Background, uv2);
}

float4 ps_exp_horiz (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 ((uv3.x + Amount - 1.0) / Amount, uv3.y);
   float2 xy2 = float2 (uv3.x / Amount, uv3.y);

   return (uv3.x > posAmt) ? tex2D (s_Incoming, xy1) :
          (uv3.x < negAmt) ? tex2D (s_Incoming, xy2) : GetPixel (s_Foreground, uv1);
}

float4 ps_sqz_vert (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv3.x, (uv3.y - Amount) / negAmt);
   float2 xy2 = float2 (uv3.x, uv3.y / negAmt);

   negAmt /= 2.0;

   return (uv3.y > posAmt) ? tex2D (s_Outgoing, xy1) :
          (uv3.y < negAmt) ? tex2D (s_Outgoing, xy2) : GetPixel (s_Background, uv2);
}

float4 ps_exp_vert (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv3.x, (uv3.y + Amount - 1.0) / Amount);
   float2 xy2 = float2 (uv3.x, uv3.y / Amount);

   return (uv3.y > posAmt) ? tex2D (s_Incoming, xy1)
        : (uv3.y < negAmt) ? tex2D (s_Incoming, xy2) : GetPixel (s_Foreground, uv1);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique squeezeHoriz
{
   pass P_1 < string Script = "RenderColorTarget0 = Outw;"; > ExecuteShader (ps_out)
   pass P_2 ExecuteShader (ps_sqz_horiz)
}

technique expandHoriz
{
   pass P_1 < string Script = "RenderColorTarget0 = Inw;"; > ExecuteShader (ps_in)
   pass P_2 ExecuteShader (ps_exp_horiz)
}

technique squeezeVert
{
   pass P_1 < string Script = "RenderColorTarget0 = Outw;"; > ExecuteShader (ps_out)
   pass P_2 ExecuteShader (ps_sqz_vert)
}

technique expandVert
{
   pass P_1 < string Script = "RenderColorTarget0 = Inw;"; > ExecuteShader (ps_in)
   pass P_2 ExecuteShader (ps_exp_vert)
}
