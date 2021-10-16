// @Maintainer jwrl
// @Released 2021-10-16
// @Author jwrl
// @Created 2021-10-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdKitA_640.png

/**
 This is a general purpose toolkit designed to build lower thirds.  It can optionally be
 fed with a graphics layer or other external image or effect.  It's designed to produce
 a flat coloured ribbon with two overlaid floating flat colour boxes.  They can be used
 to generate borders, other graphical components, or even be completely hidden.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rdToolkitA.fx
//
// Version history:
//
// Rewrite 2021-10-16 jwrl.
// Rewrite of the original user lower 3rds effect to support resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower 3rd toolkit A";
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

#define inRange(XY,MIN,MAX) !(any (XY < MIN) || any (XY > MAX))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (In_1, s_Input_1);
DefineInput (In_2, s_Input_2);

DefineTarget (Video, s_Video);
DefineTarget (Ribn, s_Ribbon);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int InpMode
<
   string Group = "Text settings";
   string Description = "Text source";
   string Enum = "Before - uses In_1 for text / In_2 as background,After - uses In_1 as background with external text";
> = 0;

int TxtAlpha
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
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float TxtPosY
<
   string Group = "Text settings";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

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

float Ribbon_Y
<
   string Group = "Ribbon";
   string Description = "Vertical position";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

float4 RibbonColour
<
   string Group = "Ribbon";
   string Description = "Left colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float BoxA_Width
<
   string Group = "Box A";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float BoxA_L
<
   string Group = "Box A";
   string Description = "Crop left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float BoxA_R
<
   string Group = "Box A";
   string Description = "Crop right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

float BoxA_Y
<
   string Group = "Box A";
   string Description = "Vertical position";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.212;

float4 BoxAcolour
<
   string Group = "Box A";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 0.0, 1.0 };

float BoxB_Width
<
   string Group = "Box B";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

float BoxB_L
<
   string Group = "Box B";
   string Description = "Crop left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.35;

float BoxB_R
<
   string Group = "Box B";
   string Description = "Crop right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float BoxB_Y
<
   string Group = "Box B";
   string Description = "Vertical position";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.085;

float4 BoxBcolour
<
   string Group = "Box B";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

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

float4 ps_input (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   return (InpMode == 1) ? GetPixel (s_Input_1, uv1) : GetPixel (s_Input_2, uv2);
}

float4 ps_ribbon (float2 uv0 : TEXCOORD0, float2 uv1 : TEXCOORD1) : COLOR
{
   float y0 = max (RibbonWidth, 0.000001) * 0.142;
   float y1 = 1.0 - Ribbon_Y;

   float2 xy1 = float2 (RibbonL, y1 - y0);
   float2 xy2 = float2 (RibbonR, y1 + y0);

   float4 retval = inRange (uv0, xy1, xy2) ? RibbonColour : EMPTY;

   y0  = max (BoxA_Width, 0.000001) * 0.142;
   y1  = 1.0 - BoxA_Y;
   xy1 = float2 (BoxA_L, y1 - y0);
   xy2 = float2 (BoxA_R, y1 + y0);

   if (inRange (uv0, xy1, xy2)) retval = BoxAcolour;

   y0  = max (BoxB_Width, 0.000001) * 0.142;
   y1  = 1.0 - BoxB_Y;
   xy1 = float2 (BoxB_L, y1 - y0);
   xy2 = float2 (BoxB_R, y1 + y0);

   if (inRange (uv0, xy1, xy2)) retval = BoxBcolour;

   if (!InpMode) {
      float4 Fgnd = GetPixel (s_Input_1, uv1 + float2 (0.5 - TxtPosX, TxtPosY - 0.5));

      if (TxtAlpha == 1) {
         Fgnd.a = pow (Fgnd.a, 0.5);
         Fgnd.rgb /= Fgnd.a;
      }

      retval = lerp (retval, Fgnd, Fgnd.a);
   }

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy = (uv - float2 (0.5, 0.5)) / max (0.000001, MasterScale * 2.0);

   xy += float2 (0.5 - Master_X, 0.5 + Master_Y);

   float4 Fgnd = GetPixel (s_Ribbon, xy);

   return lerp (GetPixel (s_Video, uv), Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Lower3rdToolkitA
{
   pass P_1 < string Script = "RenderColorTarget0 = Video;"; > ExecuteShader (ps_input)
   pass P_2 < string Script = "RenderColorTarget0 = Ribn;"; > ExecuteShader (ps_ribbon)
   pass P_3 ExecuteShader (ps_main)
}

