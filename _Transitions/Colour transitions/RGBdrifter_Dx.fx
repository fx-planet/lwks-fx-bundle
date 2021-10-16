// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_RGBdrift_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_RGBdrifter.mp4

/**
 This transitions between the two images using different curves for each of red, green
 and blue.  One colour and alpha is always linear, and the other two can be set using
 the colour profile selection.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBdrifter_Dx.fx
//
// Version history:
//
// Rewrite 2021-07-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RGB drifter";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Dissolves between the two images using different curves for each of red, green and blue";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define HALF_PI 1.5707963268

#define CURVE   4.0

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

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

int SetTechnique
<
   string Description = "Select colour profile";
   string Enum = "Red to blue,Blue to red,Red to green,Green to red,Green to blue,Blue to green"; 
> = 0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_R_B (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidOut = GetPixel (s_Foreground, xy1);
   float4 vidIn  = GetPixel (s_Background, xy2);
   float4 retval;

   float amt_R = pow (1.0 - Amount, CURVE);
   float amt_B = pow (Amount, CURVE);

   retval.ga = lerp (vidOut.ga, vidIn.ga, Amount);
   retval.r  = lerp (vidIn.r, vidOut.r, amt_R);
   retval.b  = lerp (vidOut.b, vidIn.b, amt_B);

   return retval;
}

float4 ps_main_B_R (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 vidOut = GetPixel (s_Foreground, uv1);
   float4 vidIn  = GetPixel (s_Background, uv2);
   float4 retval;

   float amt_R = pow (Amount, CURVE);
   float amt_B = pow (1.0 - Amount, CURVE);

   retval.ga = lerp (vidOut.ga, vidIn.ga, Amount);
   retval.r  = lerp (vidOut.r, vidIn.r, amt_R);
   retval.b  = lerp (vidIn.b, vidOut.b, amt_B);

   return retval;
}

float4 ps_main_R_G (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 vidOut = GetPixel (s_Foreground, uv1);
   float4 vidIn  = GetPixel (s_Background, uv2);
   float4 retval;

   float amt_R = pow (1.0 - Amount, CURVE);
   float amt_G = pow (Amount, CURVE);

   retval.ba = lerp (vidOut.ba, vidIn.ba, Amount);
   retval.r  = lerp (vidIn.r, vidOut.r, amt_R);
   retval.g  = lerp (vidOut.g, vidIn.g, amt_G);

   return retval;
}

float4 ps_main_G_R (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 vidOut = GetPixel (s_Foreground, uv1);
   float4 vidIn  = GetPixel (s_Background, uv2);
   float4 retval;

   float amt_R = pow (Amount, CURVE);
   float amt_G = pow (1.0 - Amount, CURVE);

   retval.ba = lerp (vidOut.ba, vidIn.ba, Amount);
   retval.r  = lerp (vidOut.r, vidIn.r, amt_R);
   retval.g  = lerp (vidIn.g, vidOut.g, amt_G);

   return retval;
}

float4 ps_main_G_B (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 vidOut = GetPixel (s_Foreground, uv1);
   float4 vidIn  = GetPixel (s_Background, uv2);
   float4 retval;

   float amt_G = pow (1.0 - Amount, CURVE);
   float amt_B = pow (Amount, CURVE);

   retval.ra = lerp (vidOut.ra, vidIn.ra, Amount);
   retval.g  = lerp (vidIn.g, vidOut.g, amt_G);
   retval.b  = lerp (vidOut.b, vidIn.b, amt_B);

   return retval;
}

float4 ps_main_B_G (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 vidOut = GetPixel (s_Foreground, uv1);
   float4 vidIn  = GetPixel (s_Background, uv2);
   float4 retval;

   float amt_G = pow (Amount, CURVE);
   float amt_B = pow (1.0 - Amount, CURVE);

   retval.ra = lerp (vidOut.ra, vidIn.ra, Amount);
   retval.g  = lerp (vidOut.g, vidIn.g, amt_G);
   retval.b  = lerp (vidIn.b, vidOut.b, amt_B);

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique RGBdrifter_Dx_R_B { pass P_1 ExecuteShader (ps_main_R_B) }
technique RGBdrifter_Dx_B_R { pass P_1 ExecuteShader (ps_main_B_R) }
technique RGBdrifter_Dx_R_G { pass P_1 ExecuteShader (ps_main_R_G) }
technique RGBdrifter_Dx_G_R { pass P_1 ExecuteShader (ps_main_G_R) }
technique RGBdrifter_Dx_G_B { pass P_1 ExecuteShader (ps_main_G_B) }
technique RGBdrifter_Dx_B_G { pass P_1 ExecuteShader (ps_main_B_G) }

