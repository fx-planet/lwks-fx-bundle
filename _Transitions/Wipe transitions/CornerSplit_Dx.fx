// @Maintainer jwrl
// @Released 2021-07-27
// @Author jwrl
// @Created 2021-07-27
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_Corners_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_Corners.mp4

/**
 This is a four-way split which moves the image to or from the corners of the frame.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CornerSplit_Dx.fx
//
// Version history:
//
// Rewrite 2021-07-27 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Corner split";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Splits an image four ways to or from the corners of the frame";
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

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Overlay, s_Overlay);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Corner open,Corner close";
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

// These two shaders are used to convert the sampler texture coordinates to sequence
// texture coordinates.  This ensures that the wipe calculations aren't affected by
// varying input sizes.

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Foreground, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_Background, uv); }

float4 ps_open (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv3.x - posAmt + 0.5, uv3.y - posAmt + 0.5);
   float2 xy2 = float2 (uv3.x - negAmt + 0.5, xy1.y);
   float2 xy3 = float2 (xy1.x, uv3.y - negAmt + 0.5);
   float2 xy4 = float2 (xy2.x, xy3.y);

   return (uv3.x > posAmt) && (uv3.y > posAmt) ? tex2D (s_Overlay, xy1) :
          (uv3.x < negAmt) && (uv3.y > posAmt) ? tex2D (s_Overlay, xy2) :
          (uv3.x > posAmt) && (uv3.y < negAmt) ? tex2D (s_Overlay, xy3) :
          (uv3.x < negAmt) && (uv3.y < negAmt) ? tex2D (s_Overlay, xy4) :
                                                 GetPixel (s_Background, uv2);
}

float4 ps_shut (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv3.x - posAmt + 0.5, uv3.y - posAmt + 0.5);
   float2 xy2 = float2 (uv3.x - negAmt + 0.5, xy1.y);
   float2 xy3 = float2 (xy1.x, uv3.y - negAmt + 0.5);
   float2 xy4 = float2 (xy2.x, xy3.y);

   return (uv3.x > posAmt) && (uv3.y > posAmt) ? tex2D (s_Overlay, xy1) :
          (uv3.x < negAmt) && (uv3.y > posAmt) ? tex2D (s_Overlay, xy2) :
          (uv3.x > posAmt) && (uv3.y < negAmt) ? tex2D (s_Overlay, xy3) :
          (uv3.x < negAmt) && (uv3.y < negAmt) ? tex2D (s_Overlay, xy4) :
                                                 GetPixel (s_Foreground, uv1);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique openCorner
{
   pass Pfg < string Script = "RenderColorTarget0 = Overlay;"; > ExecuteShader (ps_initFg)
   pass P_1 ExecuteShader (ps_open)
}

technique shutCorner
{
   pass Pbg < string Script = "RenderColorTarget0 = Overlay;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_shut)
}

