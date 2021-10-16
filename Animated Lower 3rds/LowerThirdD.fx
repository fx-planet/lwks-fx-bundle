// @Maintainer jwrl
// @Released 2021-10-16
// @Author jwrl
// @Created 2021-10-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdD_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdD_1.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdD_2.mp4

/**
 This effect pushes a text block on from the edge of frame to reveal the lower third text.
 The block has a coloured edge which can be adjusted in width, and which vanishes as the
 block reaches its final position.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LowerThirdD.fx
//
// Version history:
//
// Rewrite 2021-10-16 jwrl.
// Rewrite of the original user lower 3rds effect to support resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third D";
   string Category    = "Text";
   string SubCategory = "Animated Lower 3rds";
   string Notes       = "Pushes a text block on from the edge of frame to reveal the lower third text";
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

#define HALF_PI 1.5707963268

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

int SetTechnique
<
   string Description = "Direction";
   string Enum = "Bottom up,Top down,Left to right,Right to left";
> = 0;

int Masking
<
   string Description = "Masking";
   string Enum = "Show text and edge for setup,Mask controlled by transition";
> = 0;

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

float BlockLimit
<
   string Group = "Block setting";
   string Description = "Limit of travel";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float BlockCrop_A
<
   string Group = "Block setting";
   string Description = "Crop A";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.08;

float BlockCrop_B
<
   string Group = "Block setting";
   string Description = "Crop B";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.35;

float4 BlockColour
<
   string Group = "Block setting";
   string Description = "Fill colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.98, 0.9, 1.0 };

float EdgeWidth
<
   string Group = "Edge setting";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 EdgeColour
<
   string Group = "Edge setting";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.73, 0.51, 0.84, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initIn1 (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Raw_1, uv); }
float4 ps_initIn2 (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_Raw_2, uv); }

float4 ps_block (float2 uv : TEXCOORD0) : COLOR
{
   float limit = 1.0 - (BlockLimit * 0.32);
   float width = limit - (EdgeWidth * 0.125);

   if ((uv.x < BlockCrop_A) || (uv.x > BlockCrop_B) || (uv.y < width)) return EMPTY;

   return uv.y < limit ? EdgeColour : BlockColour;
}

float4 ps_main_V1 (float2 uv : TEXCOORD3) : COLOR
{
   float trans = 0.995 - sin (Transition * HALF_PI);
   float mask  = BlockLimit * 0.32;
   float range = ((EdgeWidth * 0.125) + mask) * trans;

   mask  = (Masking == 0) ? 0.0 : 1.0 - mask;

   float2 xy1 = float2 (uv.x, uv.y - range);
   float2 xy2 = uv - float2 (TxtPosX, range - TxtPosY);

   float4 L3rd = (uv.y < mask) || Overflow (xy1) ? EMPTY : tex2D (s_Ribbon, xy1);
   float4 Fgnd = GetPixel (s_Input_1, xy2);

   if (ArtAlpha == 1) {
      Fgnd.a = pow (Fgnd.a, 0.5);
      Fgnd.rgb *= Fgnd.a;
   }

   Fgnd = lerp (L3rd, Fgnd, Fgnd.a);

   return lerp (GetPixel (s_Input_2, uv), Fgnd, Fgnd.a * Opacity);
}

float4 ps_main_V2 (float2 uv : TEXCOORD3) : COLOR
{
   float trans = 0.995 - sin (Transition * HALF_PI);
   float mask  = BlockLimit * 0.32;
   float range = ((EdgeWidth * 0.125) + mask) * trans;

   mask = (Masking == 0) ? 1.0 : mask - 0.001;

   float2 xy1 = float2 (uv.x, 1.0 - uv.y - range);
   float2 xy2 = uv + float2 (-TxtPosX, TxtPosY + range);

   float4 L3rd = (uv.y > mask) || Overflow (xy1) ? EMPTY : tex2D (s_Ribbon, xy1);
   float4 Fgnd = GetPixel (s_Input_1, xy2);

   if (ArtAlpha == 1) {
      Fgnd.a = pow (Fgnd.a, 0.5);
      Fgnd.rgb *= Fgnd.a;
   }

   Fgnd = lerp (L3rd, Fgnd, Fgnd.a);

   return lerp (GetPixel (s_Input_2, uv), Fgnd, Fgnd.a * Opacity);
}

float4 ps_main_H1 (float2 uv : TEXCOORD3) : COLOR
{
   float trans = 0.995 - sin (Transition * HALF_PI);
   float mask  = BlockLimit * 0.32;
   float range = ((EdgeWidth * 0.125) + mask) * trans;

   mask = (Masking == 0) ? 1.0 : mask - 0.001;

   float2 xy1 = float2 (uv.y, 1.0 - uv.x - range);
   float2 xy2 = uv + float2 (range - TxtPosX, TxtPosY);

   float4 L3rd = (uv.x > mask) || Overflow (xy1) ? EMPTY : tex2D (s_Ribbon, xy1);
   float4 Fgnd = (uv.x > mask) || Overflow (xy2) ? EMPTY : tex2D (s_Input_1, xy2);

   if (ArtAlpha == 1) {
      Fgnd.a = pow (Fgnd.a, 0.5);
      Fgnd.rgb *= Fgnd.a;
   }

   Fgnd = lerp (L3rd, Fgnd, Fgnd.a);

   return lerp (GetPixel (s_Input_2, uv), Fgnd, Fgnd.a * Opacity);
}

float4 ps_main_H2 (float2 uv : TEXCOORD3) : COLOR
{
   float trans = 0.995 - sin (Transition * HALF_PI);
   float mask  = BlockLimit * 0.32;
   float range = ((EdgeWidth * 0.125) + mask) * trans;

   mask  = (Masking == 0) ? 0.0 : 1.0 - mask;

   float2 xy1 = float2 (uv.y, uv.x - range);
   float2 xy2 = uv - float2 (TxtPosX + range, -TxtPosY);

   float4 L3rd = (uv.x < mask) || Overflow (xy1) ? EMPTY : tex2D (s_Ribbon, xy1);
   float4 Fgnd = (uv.x < mask) || Overflow (xy2) ? EMPTY : tex2D (s_Input_1, xy2);

   if (ArtAlpha == 1) {
      Fgnd.a = pow (Fgnd.a, 0.5);
      Fgnd.rgb *= Fgnd.a;
   }

   Fgnd = lerp (L3rd, Fgnd, Fgnd.a);

   return lerp (GetPixel (s_Input_2, uv), Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LowerThirdD_V1
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 < string Script = "RenderColorTarget0 = Ribn;"; > ExecuteShader (ps_block)
   pass P_4 ExecuteShader (ps_main_V1)
}

technique LowerThirdD_V2
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 < string Script = "RenderColorTarget0 = Ribn;"; > ExecuteShader (ps_block)
   pass P_4 ExecuteShader (ps_main_V2)
}

technique LowerThirdD_H1
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 < string Script = "RenderColorTarget0 = Ribn;"; > ExecuteShader (ps_block)
   pass P_4 ExecuteShader (ps_main_H1)
}

technique LowerThirdD_H2
{
   pass P_1 < string Script = "RenderColorTarget0 = Inp_1;"; > ExecuteShader (ps_initIn1)
   pass P_2 < string Script = "RenderColorTarget0 = Inp_2;"; > ExecuteShader (ps_initIn2)
   pass P_3 < string Script = "RenderColorTarget0 = Ribn;"; > ExecuteShader (ps_block)
   pass P_4 ExecuteShader (ps_main_H2)
}

