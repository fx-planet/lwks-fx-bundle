// @Maintainer jwrl
// @Released 2021-10-16
// @Author jwrl
// @Created 2021-10-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdB_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdB_1.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdB_2.mp4

/**
 This effect consists of a line with an attached bar.  The bar can be locked at either end
 of the line or made to move from right to left or left to right as the transition is
 adjusted.  It can also be locked to either end of the line.

 External text can be input to In_1, and can wipe on or off in sync with, or against the
 moving block.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LowerThirdB.fx
//
// Version history:
//
// Rewrite 2021-10-16 jwrl.
// Rewrite of the original user lower 3rds effect to support resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third B";
   string Category    = "Text";
   string SubCategory = "Animated Lower 3rds";
   string Notes       = "Moves a bar along a coloured line to reveal the text";
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

DefineTarget (Ribn, s_Ribbon);

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

int ArtWipe
<
   string Group = "Text settings";
   string Description = "Visibility";
   string Enum = "Always visible,Wipe at left edge of block,Wipe at right edge of block"; 
> = 1;

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

float LineWidth
<
   string Group = "Line setting";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float LineLength
<
   string Group = "Line setting";
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float Line_X
<
   string Group = "Line setting";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.05;

float Line_Y
<
   string Group = "Line setting";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float4 LineColour
<
   string Group = "Line setting";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

int BlockMode
<
   string Group = "Block setting";
   string Description = "Movement";
   string Enum = "Move from left to right,Move from right to left,Anchor to left end of line,Anchor to right end of line"; 
> = 0;

float BlockWidth
<
   string Group = "Block setting";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float BlockLength
<
   string Group = "Block setting";
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float4 BlockColour
<
   string Group = "Block setting";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initIn1 (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Raw_1, uv); }
float4 ps_initIn2 (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_Raw_2, uv); }

float4 ps_bar (float2 uv : TEXCOORD0) : COLOR
{
   float lWidth  = 0.005 + (LineWidth * 0.01);
   float bLength = BlockLength * LineLength;
   float bWidth  = BlockWidth * 0.2;
   float bTrans  = BlockMode == 0 ? Transition : BlockMode == 1
                                  ? 1.0 - Transition : BlockMode == 2
                                  ? 0.0 : 1.0;
   float bOffset = (LineLength - bLength) * bTrans;

   float2 xy1 = float2 (Line_X, 1.0 - Line_Y - (lWidth * 0.5));
   float2 xy2 = xy1 + float2 (LineLength, lWidth);
   float2 xy3 = float2 (xy1.x + bOffset, xy2.y);
   float2 xy4 = xy3 + float2 (bLength, bWidth);

   float4 retval = inRange (uv, xy1, xy2) ? LineColour : EMPTY;

   if (inRange (uv, xy3, xy4)) retval = BlockColour;

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float aTrans = ArtWipe == 0 ? LineLength : LineLength * (1.0 - BlockLength);

   float2 xy = uv - float2 (ArtPosX, -ArtPosY);

   float4 Fgnd = GetPixel (s_Ribbon, uv);
   float4 Text = GetPixel (s_Input_1, xy);

   if (ArtAlpha == 1) {
      Text.a = pow (Text.a, 0.5);
      Text.rgb *= Text.a;
   }

   if ((ArtWipe >= 1) && !SetupText) {
      if (BlockMode == 0) {
         aTrans *= Transition;
         aTrans += ArtWipe == 1 ? Line_X : LineLength * BlockLength + Line_X;

         if (uv.x > aTrans) Text = EMPTY;
      }
      else if (BlockMode == 1) {
         aTrans *= 1.0 - Transition;
         aTrans += ArtWipe == 1 ? Line_X : LineLength * BlockLength + Line_X;

         if (uv.x < aTrans) Text = EMPTY;
      }
   }

   Text = lerp (Fgnd, Text, Text.a);

   return lerp (GetPixel (s_Input_2, uv), Text, Text.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LowerThirdB
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 < string Script = "RenderColorTarget0 = Ribn;"; > ExecuteShader (ps_bar)
   pass P_4 ExecuteShader (ps_main)
}

