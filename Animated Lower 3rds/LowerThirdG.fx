// @Maintainer jwrl
// @Released 2021-10-16
// @Author jwrl
// @Created 2021-10-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdG_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdG.mp4

/**
 This uses a clock wipe to wipe on a box around text.  The box can wipe on clockwise or
 anticlockwise, and start from the top or the bottom.  Once the box is almost complete a
 fill colour dissolves in, along with the text.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LowerThirdG.fx
//
// Version history:
//
// Rewrite 2021-10-16 jwrl.
// Rewrite of the original user lower 3rds effect to support resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third G";
   string Category    = "Text";
   string SubCategory = "Animated Lower 3rds";
   string Notes       = "This uses a clock wipe to wipe on a box which then reveals the text";
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

#define TWO_PI  6.2831853072
#define HALF_PI 1.5707963268

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (In_1, s_Raw_1);
DefineInput (In_2, s_Raw_2);

DefineTarget (Inp_1, s_Input_1);
DefineTarget (Inp_2, s_Input_2);

DefineTarget (Wipe, s_Wipe);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Transition
<
   string Description = "Transition";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int Direction
<
   string Description = "Transition direction";
   string Enum = "Clockwise top,Anticlockwise top,Clockwise bottom,Anticlockwise bottom";
> = 0;

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

Float BoxWidth
<
   string Group = "Surround";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

Float BoxHeight
<
   string Group = "Surround";
   string Description = "Height";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

Float LineWidth
<
   string Group = "Surround";
   string Description = "Line weight";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float CentreX
<
   string Group = "Surround";
   string Description = "Origin";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreY
<
   string Group = "Surround";
   string Description = "Origin";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreZ
<
   string Group = "Surround";
   string Description = "Origin";
   string Flags = "SpecifiesPointZ";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float4 LineColour
<
   string Group = "Surround";
   string Description = "Line colour";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 1.0, 1.0 };

float4 FillColour
<
   string Group = "Surround";
   string Description = "Fill colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.2, 0.8, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initIn1 (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Raw_1, uv); }
float4 ps_initIn2 (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_Raw_2, uv); }

float4 ps_prelim (float2 uv : TEXCOORD0) : COLOR
{
   float2 xy = (uv - 0.5.xx);
   float2 az = abs (xy);
   float2 cz = float2 (BoxWidth, BoxHeight) * 0.5;

   float trans = max ((Transition - 0.75) * 4.0, 0.0);

   float4 out_ln = (cz.x < az.x) || (cz.y < az.y) ? LineColour : EMPTY;
   float4 retval = (az.x < cz.x) && (az.y < cz.y) ? lerp (EMPTY, FillColour, trans) : EMPTY;

   cz += float2 (1.0, _OutputAspectRatio) * LineWidth * 0.025;

   if ((az.x > cz.x) || (az.y > cz.y)) out_ln = EMPTY;

   float x, y;
   float scale = distance (xy, 0.0);

   trans = sin ((1.0 - min (Transition * 1.25, 1.0)) * HALF_PI);
   sincos (trans * TWO_PI, x, y);

   xy  = float2 (x, y) * scale;
   xy += 0.5.xx;

   if (trans < 0.25) {
      if ((uv.x > 0.5) && (uv.x < xy.x) && (uv.y < xy.y)) out_ln = EMPTY;
   }
   else if (trans < 0.5) {
      if ((uv.x > 0.5) && (uv.y < 0.5)) out_ln = EMPTY;
      if ((uv.x > xy.x) && (uv.y > xy.y)) out_ln = EMPTY;
   }
   else if (trans < 0.75) {
      if ((uv.x > 0.5) || ((uv.x > xy.x) && (uv.y > xy.y))) out_ln = EMPTY;
   }
   else if ((uv.x > 0.5) || (uv.y > 0.5) || ((uv.x < xy.x) && (uv.y < xy.y))) out_ln = EMPTY;

   return lerp (retval, out_ln, out_ln.a);
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float scale = pow (max ((CentreZ + 1.0) * 0.5, 0.0001) + 0.5, 4.0);
   float trans = max ((Transition - 0.75) * 4.0, 0.0);

   float4 Text = GetPixel (s_Input_1, uv - float2 (ArtPosX, -ArtPosY));
   float4 Bgnd = GetPixel (s_Input_2, uv);

   if (ArtAlpha == 1) {
      Text.a = pow (Text.a, 0.5);
      Text.rgb *= Text.a;
   }

   float2 xy, pos;

   if (Direction < 2) {
      xy = uv - 0.5.xx;
      pos = float2 (-CentreX, CentreY);
   }
   else {
      xy = 0.5.xx - uv;
      pos = float2 (CentreX, -CentreY);
   }

   if ((Direction == 0) || (Direction == 2)) {
      xy.x = -xy.x;
      pos.x = -pos.x;
   }

   xy = (xy / scale) + pos + 0.5.xx;

   float4 Mask = lerp (GetPixel (s_Wipe, xy), Text, Text.a * trans);

   return lerp (Bgnd, Mask, Mask.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LowerThirdG
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 < string Script = "RenderColorTarget0 = Wipe;"; > ExecuteShader (ps_prelim)
   pass P_4 ExecuteShader (ps_main)
}

