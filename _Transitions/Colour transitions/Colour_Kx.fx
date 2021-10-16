// @Maintainer jwrl
// @Released 2021-07-17
// @Author jwrl
// @Created 2021-07-17
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Colour_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Colour.mp4

/**
 This effect fades a blended foreground such as a title or image key in or out through
 a user-selected colour gradient.  The gradient can be a single flat colour, a vertical
 gradient, a horizontal gradient or a four corner gradient.  The colour is at its
 maximum strength half way through the transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Colour_Kx.fx
//
// This effect is a combination of two previous effects, Colour_Ax and Colour_Adx.
//
// Version history:
//
// Built 2021-07-17 jwrl.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dissolve thru colour (keyed)";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Fades the blended foreground in or out through a colour gradient";
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
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Super, s_Super);
DefineTarget (Color, s_Color);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Source
<
   string Description = "Source";
   string Enum = "Extracted foreground (delta key),Crawl/Roll/Title/Image key,Video/External image";
> = 0;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start if delta key folded,At start of clip,At end of clip";
> = 1;

float cAmount
<
   string Group = "Colour setup";
   string Description = "Colour mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool gradSetup
<
   string Group = "Colour setup";
   string Description = "Show gradient full screen";
> = false;

int cGradient
<
   string Group = "Colour setup";
   string Description = "Gradient";
   string Enum = "Flat (uses only the top left colour),Horizontal blend (top left > top right),Horizontal blend to centre (TL > TR > TL),Vertical blend (top left > bottom left),Vertical blend to centre (TL > BL > TL),Four way gradient,Four way gradient to centre,Four way gradient to centre (horizontal),Four way gradient to centre (vertical),Radial (TL outer > TR centre)";
> = 5;

float OffsX
<
   string Group = "Colour setup";
   string Description = "Colour gradient midpoint";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.5;

float OffsY
<
   string Group = "Colour setup";
   string Description = "Colour gradient midpoint";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.5;

float4 topLeft
<
   string Description = "Top Left";
   string Group = "Colour setup";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 1.0, 1.0 };

float4 topRight
<
   string Description = "Top Right";
   string Group = "Colour setup";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 0.0, 1.0 };

float4 botLeft
<
   string Description = "Bottom Left";
   string Group = "Colour setup";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float4 botRight
<
   string Description = "Bottom Right";
   string Group = "Colour setup";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 1.0, 1.0 };

float KeyGain
<
   string Description = "Key trim";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_keygen (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_colour (float2 uv0 : TEXCOORD0) : COLOR
{
   if (cGradient == 0) return topLeft;

   float4 retval;

   float buff_1, buff_2, horiz, vert = 1.0 - OffsY;
   float buff_0 = (OffsX <= 0.0)  ? (uv0.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv0.x / 2.0 :
                  (OffsX > uv0.x) ? uv0.x / (2.0 * OffsX) : ((uv0.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   if ((cGradient == 2) || (cGradient == 6) || (cGradient == 8) || (cGradient == 9)) horiz = sin (PI * buff_0);
   else {
      sincos (HALF_PI * buff_0, buff_1, buff_2);
      buff_2 = 1.0 - buff_2;
      horiz = lerp (buff_1, buff_2, buff_0);
   }

   buff_0 = (vert <= 0.0) ? (uv0.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv0.y / 2.0 :
            (vert > uv0.y) ? uv0.y / (2.0 * vert) : ((uv0.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   if ((cGradient == 4) || (cGradient == 6) || (cGradient == 7) || (cGradient == 9)) vert = sin (PI * buff_0);
   else {
      sincos (HALF_PI * buff_0, buff_1, buff_2);
      buff_2 = 1.0 - buff_2;
      vert = lerp (buff_1, buff_2, buff_0);
   }

   if ((cGradient == 3) || (cGradient == 4)) { retval = lerp (topLeft, botLeft, vert); }
   else {
      retval = lerp (topLeft, topRight, horiz);
   
      if (cGradient == 9) retval = lerp (topLeft, retval, vert);
      else if (cGradient > 4) {
         float4 botRow = lerp (botLeft, botRight, horiz);
         retval = lerp (retval, botRow, vert);
      }
   }

   return retval;
}

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 gradient = GetPixel (s_Color, uv3);

   if (gradSetup) return gradient;

   float4 Bgnd = GetPixel (s_Foreground, uv1);
   float4 Fgnd = GetPixel (s_Super, uv3);

   float level = min (1.0, cAmount * 2.0);
   float c_Amt = cos (saturate (level * Amount) * HALF_PI);

   level = sin (Amount * HALF_PI);
   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (Bgnd, Fgnd, Fgnd.a * level);
}

float4 ps_main_I (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 gradient = GetPixel (s_Color, uv3);

   if (gradSetup) return gradient;

   float4 Bgnd = GetPixel (s_Background, uv2);
   float4 Fgnd = GetPixel (s_Super, uv3);

   float level = min (1.0, cAmount * 2.0);
   float c_Amt = cos (saturate (level * Amount) * HALF_PI);

   level = sin (Amount * HALF_PI);
   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (Bgnd, Fgnd, Fgnd.a * level);
}

float4 ps_main_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 gradient = GetPixel (s_Color, uv3);

   if (gradSetup) return gradient;

   float4 Bgnd = GetPixel (s_Background, uv2);
   float4 Fgnd = GetPixel (s_Super, uv3);

   float level = min (1.0, cAmount * 2.0);
   float c_Amt = sin (saturate (level * Amount) * HALF_PI);

   level = cos (Amount * HALF_PI);
   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (Bgnd, Fgnd, Fgnd.a * level);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Colour_Kx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 < string Script = "RenderColorTarget0 = Color;"; > ExecuteShader (ps_colour)
   pass P_3 ExecuteShader (ps_main_F)
}

technique Colour_Kx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Color;"; > ExecuteShader (ps_colour)
   pass P_3 ExecuteShader (ps_main_I)
}

technique Colour_Kx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Color;"; > ExecuteShader (ps_colour)
   pass P_3 ExecuteShader (ps_main_O)
}

