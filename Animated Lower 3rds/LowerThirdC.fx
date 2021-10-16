// @Maintainer jwrl
// @Released 2021-10-16
// @Author jwrl
// @Created 2021-10-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdC_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdC.mp4

/**
 This effect opens a text ribbon in a lower third position to reveal the lower third text.
 That's all there is to it really.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LowerThirdC.fx
//
// Version history:
//
// Rewrite 2021-10-16 jwrl.
// Rewrite of the original user lower 3rds effect to support resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third C";
   string Category    = "Text";
   string SubCategory = "Animated Lower 3rds";
   string Notes       = "Opens a text ribbon to reveal the lower third text";
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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
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

DefineInput (In_1, s_Raw_1);
DefineInput (In_2, s_Raw_2);

DefineTarget (Inp_1, s_Input_1);
DefineTarget (Inp_2, s_Input_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Transition
<
   string Description = "Transition";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int ArtAlpha
<
   string Group = "Text settings";
   string Description = "Text type";
   string Enum = "Video/External image,Crawl/Roll/Title/Image key";
> = 1;

bool SetupText
<
   string Group = "Text settings";
   string Description = "Setup text position";
> = true;

float ArtPosX
<
   string Group = "Text settings";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ArtPosY
<
   string Group = "Text settings";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float RibbonWidth
<
   string Group = "Ribbon setting";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.3;

float RibbonLength
<
   string Group = "Ribbon setting";
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float4 RibbonColourA
<
   string Group = "Ribbon setting";
   string Description = "Left colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float4 RibbonColourB
<
   string Group = "Ribbon setting";
   string Description = "Right colour";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 1.0, 1.0 };

float Ribbon_X
<
   string Group = "Ribbon setting";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Ribbon_Y
<
   string Group = "Ribbon setting";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

float LineWidth
<
   string Group = "Line setting";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1 ;

float4 LineColourA
<
   string Group = "Line setting";
   string Description = "Left colour";
   bool SupportsAlpha = true;
> = { 0.07, 0.07, 0.49, 1.0 };

float4 LineColourB
<
   string Group = "Line setting";
   string Description = "Right colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.27, 0.47, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initIn1 (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Raw_1, uv); }
float4 ps_initIn2 (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_Raw_2, uv); }

float4 ps_main (float2 uv0 : TEXCOORD0, float2 uv3 : TEXCOORD3) : COLOR
{
   float lWidth  = LineWidth * 0.0625;
   float rWidth = max (0.0, lerp (-lWidth, (RibbonWidth + 0.02) * 0.25, Transition));

   lWidth = max (0.0, lWidth + min (0.0, rWidth));

   float2 xy1 = uv3 - float2 (ArtPosX, -ArtPosY);
   float2 xy2 = float2 (Ribbon_X, 1.0 - Ribbon_Y - (rWidth * 0.5));
   float2 xy3 = xy2 + float2 (RibbonLength, rWidth);

   float colour_grad = max (uv0.x - Ribbon_X, 0.0) / RibbonLength;

   float4 lColour = lerp (LineColourA, LineColourB, colour_grad);
   float4 retval  = lerp (RibbonColourA, RibbonColourB, colour_grad);
   float4 artwork = GetPixel (s_Input_1, xy1);

   if (ArtAlpha == 1) {
      artwork.a = pow (artwork.a, 0.5);
      artwork.rgb *= artwork.a;
   }

   retval = (uv0.y < xy2.y) || (uv0.y > xy3.y) ? EMPTY : lerp (retval, artwork, artwork.a);

   xy1 = float2 (xy2.y - lWidth, xy3.y + lWidth);

   if (((uv0.y >= xy1.x) && (uv0.y <= xy2.y)) || ((uv0.y >= xy3.y) && (uv0.y <= xy1.y)))
      retval = lColour;

   if ((uv0.x < xy2.x) || (uv0.x > xy3.x)) retval = EMPTY;

   if (SetupText) retval = lerp (retval, artwork, artwork.a);

   return lerp (GetPixel (s_Input_2, uv3), retval, retval.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LowerThirdC
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 ExecuteShader (ps_main)
}

