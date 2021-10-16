// @Maintainer jwrl
// @Released 2021-10-16
// @Author jwrl
// @Created 2021-10-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdF_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdF.mp4

/**
 This effect does a twist of a text overlay over a standard ribbon with adjustable opacity.
 The direction of the twist can be set to wipe on or wipe off.  "Wipe on" gives a left to
 right transition on, and "Wipe off" gives a left to right transition off.  As a result
 when setting the transition range in "Wipe off" it's necessary to set the transition to
 zero, unlike the usual 100%.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LowerThirdF.fx
//
// Version history:
//
// Rewrite 2021-10-16 jwrl.
// Rewrite of the original user lower 3rds effect to support resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third F";
   string Category    = "Text";
   string SubCategory = "Animated Lower 3rds";
   string Notes       = "Twists a text overlay to reveal it over a ribbon background";
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

#define inRange(XY,MIN,MAX) (all (XY >= MIN) && all (XY <= MAX))

#define TWISTS   4.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define MODULATE 10.0

#define R_WIDTH  0.125
#define R_LIMIT  0.005

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (In_1, s_Raw_1);
DefineInput (In_2, s_Raw_2);

DefineTarget (Inp_1, s_Input_1);
DefineTarget (Inp_2, s_Input_2);

DefineTarget (Text, s_Text);

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

float TransRange
<
   string Group = "Set this so the effect just ends when Transition reaches 100%";
   string Description = "Transition range";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int ArtAlpha
<
   string Group = "Text settings";
   string Description = "Text type";
   string Enum = "Video/External image,Crawl/Roll/Title/Image key";
> = 1;

float TxtPosX
<
   string Group = "Text settings";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float TxtPosY
<
   string Group = "Text settings";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

int SetTechnique
<
   string Group = "Twist settings";
   string Description = "Direction";
   string Enum = "Wipe on,Wipe off";
> = 0;

float TwistAmount
<
   string Group = "Twist settings";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float TwistSoft
<
   string Group = "Twist settings";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float RibbonWidth
<
   string Group = "Ribbon settings";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.33333333;

float RibbonL
<
   string Group = "Ribbon settings";
   string Description = "Crop left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float RibbonR
<
   string Group = "Ribbon settings";
   string Description = "Crop right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float RibbonY
<
   string Group = "Ribbon settings";
   string Description = "Vertical position";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

float4 RibbonColour
<
   string Group = "Ribbon settings";
   string Description = "Colour";
> = { 0.0, 0.0, 1.0, 0.0 };

float RibbonOpacity_TL
<
   string Group = "Ribbon opacity";
   string Description = "Upper left";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.75;

float RibbonOpacity_BL
<
   string Group = "Ribbon opacity";
   string Description = "Lower left";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

float RibbonOpacity_TR
<
   string Group = "Ribbon opacity";
   string Description = "Upper right";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float RibbonOpacity_BR
<
   string Group = "Ribbon opacity";
   string Description = "Lower right";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.25;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initIn1 (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Raw_1, uv); }
float4 ps_initIn2 (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_Raw_2, uv); }

float4 ps_text_pos (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = GetPixel (s_Input_1, uv - float2 (TxtPosX, -TxtPosY));

   if (ArtAlpha == 1) {
      retval.a = pow (retval.a, 0.5);
      retval.rgb *= retval.a;
   }

   return retval;
}

float4 ps_main_0 (float2 uv : TEXCOORD3) : COLOR
{
   float ribbon = 1.0 - RibbonY;
   float range  = max (0.0, TwistSoft * SOFTNESS) + OFFSET;
   float maxVis = (Transition * (range + 1.0) * TransRange) - uv.x;
   float T_Axis = uv.y - ribbon;

   float amount = saturate (maxVis / range);
   float modltn = max (0.0, MODULATE * (range - maxVis));
   float twists = cos (modltn * TwistAmount * TWISTS);

   float2 xy = float2 (uv.x, ribbon + (T_Axis / twists));

   float4 Bgd = GetPixel (s_Input_2, uv);
   float4 Txt = lerp (EMPTY, GetPixel (s_Text, xy), amount);

   float width = max (RibbonWidth * R_WIDTH, R_LIMIT);

   float2 xy1 = float2 (RibbonL, ribbon - width);
   float2 xy2 = float2 (RibbonR, ribbon + width);

   if (inRange (uv, xy1, xy2)) {
      float length = max (0.0, RibbonR - RibbonL);
      float grad_H = max (uv.x - RibbonL, 0.0) / length;
      float grad_V = (uv.y - xy1.y) / (width * 2.0);

      float alpha   = lerp (RibbonOpacity_TL, RibbonOpacity_TR, grad_H);
      float alpha_1 = lerp (RibbonOpacity_BL, RibbonOpacity_BR, grad_H);

      alpha = max (0.0, lerp (alpha, alpha_1, grad_V));

      float4 Fgd = lerp (float4 (RibbonColour.rgb, alpha), Txt, Txt.a);

      return lerp (Bgd, Fgd, Fgd.a * Opacity);
   }
   else return lerp (Bgd, Txt, Txt.a * Opacity);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float ribbon = 1.0 - RibbonY;
   float range  = max (0.0, TwistSoft * SOFTNESS) + OFFSET;
   float maxVis = uv.x + range + ((Transition - 1.0) * (range + 1.0) * TransRange);
   float T_Axis = uv.y - ribbon;

   float amount = saturate (maxVis / range);
   float modltn = max (0.0, MODULATE * (range - maxVis));
   float twists = cos (modltn * TwistAmount * TWISTS);

   float2 xy = float2 (uv.x, ribbon + (T_Axis / twists));

   float4 Bgd = GetPixel (s_Input_2, uv);
   float4 Txt = lerp (EMPTY, GetPixel (s_Text, xy), amount);

   float width = max (RibbonWidth * R_WIDTH, R_LIMIT);

   float2 xy1 = float2 (RibbonL, ribbon - width);
   float2 xy2 = float2 (RibbonR, ribbon + width);

   if (inRange (uv, xy1, xy2)) {
      float length = max (0.0, RibbonR - RibbonL);
      float grad_H = max (uv.x - RibbonL, 0.0) / length;
      float grad_V = (uv.y - xy1.y) / (width * 2.0);

      float alpha   = lerp (RibbonOpacity_TL, RibbonOpacity_TR, grad_H);
      float alpha_1 = lerp (RibbonOpacity_BL, RibbonOpacity_BR, grad_H);

      alpha = max (0.0, lerp (alpha, alpha_1, grad_V));

      float4 Fgd = lerp (float4 (RibbonColour.rgb, alpha), Txt, Txt.a);

      return lerp (Bgd, Fgd, Fgd.a * Opacity);
   }
   else return lerp (Bgd, Txt, Txt.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LowerThirdF_0
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 < string Script = "RenderColorTarget0 = Text;"; > ExecuteShader (ps_text_pos)
   pass P_4 ExecuteShader (ps_main_0)
}

technique LowerThirdF_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 < string Script = "RenderColorTarget0 = Text;"; > ExecuteShader (ps_text_pos)
   pass P_4 ExecuteShader (ps_main_1)
}

