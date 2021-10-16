// @Maintainer jwrl
// @Released 2021-10-16
// @Author jwrl
// @Created 2021-10-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdKitB_640.png

/**
 This is a general purpose toolkit designed to build lower thirds.  It's designed to create
 an edged, coloured ribbon gradient with an overlaid floating bordered flat colour box.  Any
 component can be completely hidden if required and all are fully adjustable.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rdToolkitB.fx
//
// This is a three input effect.  It uses In1 for an optional logo or other graphical
// component, In2 for optional text and Bgd as a background-only layer.
//
// Rewrite 2021-10-16 jwrl.
// Rewrite of the original user lower 3rds effect to support resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower 3rd toolkit B";
   string Category    = "Text";
   string SubCategory = "Animated Lower 3rds";
   string Notes       = "A general purpose toolkit designed to help build custom lower thirds";
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

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (In_1, s_Raw_1);
DefineInput (In_2, s_Raw_2);
DefineInput (Bgd, s_RawBg);

DefineTarget (Inp_1, s_Input_1);
DefineTarget (Inp_2, s_Input_2);
DefineTarget (RawBg, s_Background);

DefineTarget (Video, s_Video);
DefineTarget (Ribn, s_Ribbon);
DefineTarget (Comp, s_Composite);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int SetTechnique
<
   string Group = "Text settings";
   string Description = "Text source";
   string Enum = "Before / Using In1 for logo and In2 for text,Before / Using In1 for text and In2 for background,After / Using In1 for logo and In2 for background,After this effect - use In1 as only source";
> = 0;

int TxtAlpha
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

float LogoSize
<
   string Group = "Logo settings";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float LogoPosX
<
   string Group = "Logo settings";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float LogoPosY
<
   string Group = "Logo settings";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float RibbonWidth
<
   string Group = "Ribbon";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.33333333;

float RibbonL
<
   string Group = "Ribbon";
   string Description = "Crop left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float RibbonR
<
   string Group = "Ribbon";
   string Description = "Crop right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float RibbonY
<
   string Group = "Ribbon";
   string Description = "Vertical position";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

float4 RibbonColourA
<
   string Group = "Ribbon";
   string Description = "Left colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float4 RibbonColourB
<
   string Group = "Ribbon";
   string Description = "Right colour";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 1.0, 0.0 };

float TbarWidth
<
   string Group = "Upper line";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.33333333;

float TbarL
<
   string Group = "Upper line";
   string Description = "Crop left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float TbarR
<
   string Group = "Upper line";
   string Description = "Crop right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float4 TbarColour
<
   string Group = "Upper line";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.11, 0.11, 0.52, 1.0 };

float BbarWidth
<
   string Group = "Lower line";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.33333333;

float BbarL
<
   string Group = "Lower line";
   string Description = "Crop left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float BbarR
<
   string Group = "Lower line";
   string Description = "Crop right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float4 BbarColour
<
   string Group = "Lower line";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.07, 0.33, 0.33, 1.0 };

bool BarGrad
<
   string Group = "Lower line";
   string Description = "Use line colours as gradients for both lines";
> = false;

float BoxWidth
<
   string Group = "Inset box";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float BoxHeight
<
   string Group = "Inset box";
   string Description = "Height";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float BoxLine
<
   string Group = "Inset box";
   string Description = "Border width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Box_X
<
   string Group = "Inset box";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Box_Y
<
   string Group = "Inset box";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float4 BoxColourA
<
   string Group = "Inset box";
   string Description = "Line colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

float4 BoxColourB
<
   string Group = "Inset box";
   string Description = "Fill colour";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 0.0, 1.0 };

float MasterScale
<
   string Group = "Master size and position";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Master_X
<
   string Group = "Master size and position";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Master_Y
<
   string Group = "Master size and position";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initIn1 (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Raw_1, uv); }
float4 ps_initIn2 (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_Raw_2, uv); }
float4 ps_initBg  (float2 uv : TEXCOORD3) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_ribbon (float2 uv : TEXCOORD0) : COLOR
{
   float4 retval = EMPTY;

   float colour_grad, length;
   float width  = 0.01 + (RibbonWidth * 0.25);

   float2 xy1 = float2 (RibbonL, 1.0 - RibbonY - (width * 0.5));
   float2 xy2 = float2 (RibbonR, xy1.y + width);

   if (inRange (uv, xy1, xy2)) {
      length = max (0.0, RibbonR - RibbonL);
      colour_grad = max (uv.x - RibbonL, 0.0) / length;
      retval = lerp (RibbonColourA, RibbonColourB, colour_grad);
   }

   float y = xy1.y - (TbarWidth * 0.02);

   if (inRange (uv, float2 (TbarL, y), float2 (TbarR, xy1.y))) {
      if (BarGrad) {
         length = max (0.0, TbarR - TbarL);
         colour_grad = max (uv.x - TbarL, 0.0) / length;
         retval = lerp (TbarColour, BbarColour, colour_grad);
      }
      else retval = TbarColour;
   }

   y = xy2.y + (BbarWidth * 0.02);

   if (inRange (uv, float2 (BbarL, xy2.y), float2 (BbarR, y))) {
      if (BarGrad) {
         length = max (0.0, BbarR - BbarL);
         colour_grad = max (uv.x - BbarL, 0.0) / length;
         retval = lerp (TbarColour, BbarColour, colour_grad);
      }
      else retval = BbarColour;
   }

   float2 xy3 = float2 (BoxWidth, BoxHeight * _OutputAspectRatio) * 0.1;

   xy2  = float2 (Box_X, 1.0 - Box_Y);
   xy1  = xy2 - xy3;
   xy2 += xy3;

   if (inRange (uv, xy1, xy2)) retval = BoxColourA;

   xy3  = float2 (1.0, _OutputAspectRatio) * BoxLine * 0.012;
   xy1 += xy3;
   xy2 -= xy3;

   if (inRange (uv, xy1, xy2)) retval = BoxColourB;

   return retval;
}

float4 ps_comp_0 (float2 uv : TEXCOORD4) : COLOR
{
   float2 xy = ((uv - 0.5.xx) / max (0.00001, LogoSize)) - float2 (LogoPosX, -LogoPosY) + 0.5.xx;

   float4 Logo = GetPixel (s_Input_1, xy);
   float4 Text = GetPixel (s_Input_2, uv - float2 (TxtPosX, -TxtPosY));

   if (TxtAlpha == 1) {
      Text.a = pow (Text.a, 0.5);
      Text.rgb *= Text.a;
   }

   float4 Fgnd = lerp (GetPixel (s_Ribbon, uv), Text, Text.a);

   return lerp (Fgnd, Logo, Logo.a);
}

float4 ps_comp_1 (float2 uv : TEXCOORD4) : COLOR
{
   float4 Text = GetPixel (s_Input_1, uv - float2 (TxtPosX, -TxtPosY));

   if (TxtAlpha == 1) {
      Text.a = pow (Text.a, 0.5);
      Text.rgb *= Text.a;
   }

   return lerp (GetPixel (s_Ribbon, uv), Text, Text.a);
}

float4 ps_comp_2 (float2 uv : TEXCOORD4) : COLOR
{
   float2 xy = ((uv - 0.5.xx) / max (0.001, LogoSize)) - float2 (LogoPosX, -LogoPosY) + 0.5.xx;

   float4 Logo = GetPixel (s_Input_1, xy);

   return lerp (GetPixel (s_Ribbon, uv), Logo, Logo.a);
}

float4 ps_main_0 (float2 uv : TEXCOORD4) : COLOR
{
   float2 xy = (uv - 0.5.xx) / max (0.000001, MasterScale * 2.0);

   float4 Fgnd = GetPixel (s_Composite, xy + float2 (0.5 - Master_X, 0.5 + Master_Y));

   return lerp (GetPixel (s_Background, uv), Fgnd, Fgnd.a * Opacity);
}

float4 ps_main_3 (float2 uv : TEXCOORD4) : COLOR
{
   float2 xy = (uv - 0.5.xx) / max (0.000001, MasterScale * 2.0);

   float4 Fgnd = GetPixel (s_Ribbon, xy + float2 (0.5 - Master_X, 0.5 + Master_Y));

   return lerp (GetPixel (s_Input_1, uv), Fgnd, Fgnd.a * Opacity);
}

float4 ps_main (float2 uv : TEXCOORD4) : COLOR
{
   float2 xy = (uv - 0.5.xx) / max (0.000001, MasterScale * 2.0);

   float4 Fgnd = GetPixel (s_Composite, xy + float2 (0.5 - Master_X, 0.5 + Master_Y));

   return lerp (GetPixel (s_Input_2, uv), Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Lower3rdToolkitB_0
{
   pass In1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass In2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = Ribn;"; > ExecuteShader (ps_ribbon)
   pass P_2 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_comp_0)
   pass P_3 ExecuteShader (ps_main_0)
}

technique Lower3rdToolkitB_1
{
   pass In1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass In2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = Ribn;"; > ExecuteShader (ps_ribbon)
   pass P_2 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_comp_1)
   pass P_3 ExecuteShader (ps_main)
}

technique Lower3rdToolkitB_2
{
   pass In1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass In2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = Ribn;"; > ExecuteShader (ps_ribbon)
   pass P_2 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_comp_2)
   pass P_3 ExecuteShader (ps_main)
}

technique Lower3rdToolkitB_3
{
   pass In1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass In2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = Ribn;"; > ExecuteShader (ps_ribbon)
   pass P_2 ExecuteShader (ps_main_3)
}

