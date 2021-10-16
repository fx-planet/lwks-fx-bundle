// @Maintainer jwrl
// @Released 2021-10-16
// @Author jwrl
// @Created 2021-10-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdE_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdE.mp4

/**
 This effect does a page turn type of text overlay over a standard ribbon with adjustable
 opacity.  The direction of the page turn can be set to wipe on or wipe off.  "Wipe on"
 gives a left > right transition, and "Wipe off" reverses it. 
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LowerThirdE.fx
//
// Version history:
//
// Rewrite 2021-10-16 jwrl.
// Rewrite of the original user lower 3rds effect to support resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third E";
   string Category    = "Text";
   string SubCategory = "Animated Lower 3rds";
   string Notes       = "Page turns a text overlay over a ribbon background";
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

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05

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
> = 0;

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

float TxtDistort
<
   string Group = "Text settings";
   string Description = "Distortion";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float TxtRipple
<
   string Group = "Text settings";
   string Description = "Ripple amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

int SetTechnique
<
   string Group = "Text settings";
   string Description = "Effect direction";
   string Enum = "Wipe on,Wipe off";
> = 0;

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
   float range  = max (0.0, TxtDistort * SOFTNESS) + OFFSET;
   float T_Axis = uv.y - RibbonY;
   float maxVis = range + uv.x - (TransRange * Transition * (1.0 + range));

   float amount = saturate (maxVis / range);
   float ripple = max (0.0, RIPPLES * maxVis);
   float width  = (0.01 + (RibbonWidth * 0.25));

   float modulate = pow (max (0.0, TxtRipple), 5.0) * ripple;

   float offset = sin (modulate) * ripple * width;
   float twists = cos (modulate * 4.0);

   float2 xy = float2 (uv.x, RibbonY + (T_Axis / twists) - offset);

   float4 Txt = lerp (GetPixel (s_Text, xy), EMPTY, amount);
   float4 Bgd = GetPixel (s_Input_2, uv);

   float2 xy1 = float2 (RibbonL, 1.0 - RibbonY - (width * 0.5));
   float2 xy2 = float2 (RibbonR, xy1.y + width);

   if (inRange (uv, xy1, xy2)) {
      float length = max (0.0, RibbonR - RibbonL);
      float grad   = max (uv.x - RibbonL, 0.0) / length;

      float alpha_1 = lerp (RibbonOpacity_TL, RibbonOpacity_TR, grad);
      float alpha_2 = lerp (RibbonOpacity_BL, RibbonOpacity_BR, grad);

      grad = (uv.y - xy1.y) / width;

      float alpha = max (0.0, lerp (alpha_1, alpha_2, grad));

      float4 Fgd = lerp (float4 (RibbonColour.rgb, alpha), Txt, Txt.a);

      return lerp (Bgd, Fgd, Fgd.a * Opacity);
   }
   else return lerp (Bgd, Txt, Txt.a * Opacity);
}

float4 ps_main_1 (float2 uv : TEXCOORD3) : COLOR
{
   float range  = max (0.0, TxtDistort * SOFTNESS) + OFFSET;
   float minVis = TransRange * (1.0 - Transition) * (1.0 + range) - uv.x;
   float T_Axis = uv.y - RibbonY;
   float maxVis = range - minVis;

   float amount = saturate (maxVis / range);
   float ripple = max (0.0, RIPPLES * minVis);
   float width  = (0.01 + (RibbonWidth * 0.25));

   float modulate = pow (max (0.0, TxtRipple), 5.0) * ripple;

   float offset = sin (modulate) * ripple * width;
   float twists = cos (modulate * 4.0);

   float2 xy = float2 (uv.x, RibbonY + (T_Axis / twists) - offset);

   float4 Txt = lerp (EMPTY, GetPixel (s_Text, xy), amount);
   float4 Bgd = GetPixel (s_Input_2, uv);

   float2 xy1 = float2 (RibbonL, 1.0 - RibbonY - (width * 0.5));
   float2 xy2 = float2 (RibbonR, xy1.y + width);

   if (inRange (uv, xy1, xy2)) {
      float length = max (0.0, RibbonR - RibbonL);
      float grad   = max (uv.x - RibbonL, 0.0) / length;

      float alpha_1 = lerp (RibbonOpacity_TL, RibbonOpacity_TR, grad);
      float alpha_2 = lerp (RibbonOpacity_BL, RibbonOpacity_BR, grad);

      grad = (uv.y - xy1.y) / width;

      float alpha = max (0.0, lerp (alpha_1, alpha_2, grad));

      float4 Fgd = lerp (float4 (RibbonColour.rgb, alpha), Txt, Txt.a);

      return lerp (Bgd, Fgd, Fgd.a * Opacity);
   }
   else return lerp (Bgd, Txt, Txt.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LowerThirdE_0
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 < string Script = "RenderColorTarget0 = Text;"; > ExecuteShader (ps_text_pos)
   pass P_4 ExecuteShader (ps_main_0)
}

technique LowerThirdE_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 < string Script = "RenderColorTarget0 = Text;"; > ExecuteShader (ps_text_pos)
   pass P_4 ExecuteShader (ps_main_1)
}

