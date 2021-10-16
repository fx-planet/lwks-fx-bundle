// @Maintainer jwrl
// @Released 2021-10-16
// @Author jwrl
// @Created 2021-10-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdA_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdA_1.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdA_2.mp4

/**
 This moves a coloured bar on from one side of the screen then lowers or raises it to reveal
 an alpha image connected to the input In_1.  To remove the effect, the bar can be moved up
 to hide the text again and then moved off.  This combination move is all done with one
 operation using the Transition parameter.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LowerThirdA.fx
//
// Version history:
//
// Rewrite 2021-10-16 jwrl.
// Rewrite of the original user lower 3rds effect to support resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third A";
   string Category    = "Text";
   string SubCategory = "Animated Lower 3rds";
   string Notes       = "Moves a coloured bar from the edge of screen and lowers or raises it to reveal text";
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

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (In_1, s_Raw_1);
DefineInput (In_2, s_Raw_2);

DefineTarget (Inp_1, s_Input_1);
DefineTarget (Inp_2, s_Input_2);

DefineTarget (Bar, s_Bar);

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

int SetTechnique
<
   string Group = "Text settings";
   string Description = "Direction";
   string Enum = "Visible above bar,Visible below bar"; 
> = 0;

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

float BarWidth
<
   string Group = "Line settings";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float BarLength
<
   string Group = "Line settings";
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float Bar_X
<
   string Group = "Line settings";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float Bar_Y
<
   string Group = "Line settings";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float4 BarColour
<
   string Group = "Line settings";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

float BarPosX
<
   string Group = "Line start position";
   string Description = "Displacement";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float BarPosY
<
   string Group = "Line start position";
   string Description = "Displacement";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initIn1 (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Raw_1, uv); }
float4 ps_initIn2 (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_Raw_2, uv); }

float4 ps_bar (float2 uv : TEXCOORD0) : COLOR
{
   float _width = 0.005 + (BarWidth * 0.1);

   float2 xy1 = float2 (Bar_X, 1.0 - Bar_Y - (_width * 0.5));
   float2 xy2 = xy1 + float2 (BarLength, _width);

   return inRange (uv, xy1, xy2) ? BarColour : EMPTY;
}

float4 ps_main_0 (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy1 = float2 (BarPosX, -BarPosY) * (1.0 - min (1.0, Transition));
   float2 xy2 = float2 (TxtPosX, -TxtPosY);

   float y = 1.0 - Bar_Y + xy1.y;

   xy1 = uv - xy1;

   float4 bar = GetPixel (s_Bar, xy1);
   float4 Fgd = (uv.y >= y) && !SetupText ? EMPTY : GetPixel (s_Input_1, uv - xy2);

   if (ArtAlpha == 1) {
      Fgd.a = pow (Fgd.a, 0.5);
      Fgd.rgb *= Fgd.a;
   }

   Fgd = lerp (Fgd, bar, bar.a);

   return lerp (GetPixel (s_Input_2, uv), Fgd, Fgd.a * Opacity);
}

float4 ps_main_1 (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy1 = float2 (BarPosX, -BarPosY) * (1.0 - min (1.0, Transition));
   float2 xy2 = float2 (TxtPosX, -TxtPosY);

   float y = 1.0 - Bar_Y + xy1.y;

   xy1 = uv - xy1;

   float4 bar = GetPixel (s_Bar, xy1);
   float4 Fgd = (uv.y <= y) && !SetupText ? EMPTY : GetPixel (s_Input_1, uv - xy2);

   if (ArtAlpha == 1) {
      Fgd.a = pow (Fgd.a, 0.5);
      Fgd.rgb *= Fgd.a;
   }

   Fgd = lerp (Fgd, bar, bar.a);

   return lerp (GetPixel (s_Input_2, uv), Fgd, Fgd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LowerThirdA_0
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 < string Script = "RenderColorTarget0 = Bar;"; > ExecuteShader (ps_bar)
   pass P_4 ExecuteShader (ps_main_0)
}

technique LowerThirdA_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 < string Script = "RenderColorTarget0 = Bar;"; > ExecuteShader (ps_bar)
   pass P_4 ExecuteShader (ps_main_1)
}

