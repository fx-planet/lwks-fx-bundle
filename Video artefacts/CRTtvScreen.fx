// @Maintainer jwrl
// @Released 2021-11-01
// @Author jwrl
// @Created 2021-11-01
// @see https://www.lwks.com/media/kunena/attachments/6375/CRTscreen_640.png

/**
 This effect simulates a close-up look at an analogue colour TV screen.  Three options
 are available: Trinitron (Sony), Diamondtron (Mitusbishi/NEC) and Linitron.  For
 copyright reasons they are identified as type 1, type 2 and type 3 respectively in
 this effect.  No attempt has been made to emulate a dot matrix shadow mask tube,
 because in early tests we just lost too much luminance for the effect to be useful.
 That's pretty much why the manufacturers stopped using the real shadowmask too.

 The stabilising wires have not been emulated in the type 1 tube for anything other
 than the lowest two pixel sizes.  They just looked absurd with the larger settings.

 The glow/halation effect is just a simple box blur, slightly modified to give a
 reasonable simulation of the burnout that could be obtained by overdriving a CRT.

 NOTE:  Because this effect needs to be able to precisely set pixel widths no matter
 what the original clip size or aspect ratio is it has not been possible to make it
 truly resolution independent.  What it does is lock the clip resolution to sequence
 resolution instead.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user CRTtvScreen.fx
//
// Version history:
//
// Rewrite 2021-11-01 jwrl.
// Rewrite of the original effect to better support LW 2021 and higher.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "CRT TV screen";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Simulates a close-up look at an analogue colour TV screen.  Three options are available.";
   bool CanSize       = false;
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

#define R_ON   0.00
#define R_OFF  0.25
#define G_ON   0.33
#define G_OFF  0.58
#define B_ON   0.66
#define B_OFF  0.91

#define V_MAX  0.8

#define SONY   0
#define DMD    2

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

DefineTarget (Fgd, s_Foreground);
DefineTarget (prelim, s_prelim);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Size
<
   string Description = "Pixel scale";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

int Style
<
   string Description = "Screen mask";
   string Enum = "Type 1,Type 2,Type 3";
> = 0;

float Radius
<
   string Description = "Glow radius";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Opacity
<
   string Description = "Glow amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_raster (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   int scale = 1.0 + (10.0 * max (Size, 0.0));

   float H_pixels = float (int (uv.x * _OutputWidth * 3.0 / scale) / 12.0);
   float V_pixels = frac (int (uv.y * _OutputWidth / (_OutputAspectRatio + scale)) / 8.0);
   float P_pixels;

   H_pixels = modf (H_pixels, P_pixels);
   P_pixels = round (frac (P_pixels / 2.0) + 0.25);

   if ((P_pixels == 1.0) && (Style == DMD))
      V_pixels = (V_pixels >= 0.5) ? V_pixels - 0.5 : V_pixels + 0.5;

   if ((H_pixels < R_ON) || (H_pixels > R_OFF)) retval.r = 0.0;

   if ((H_pixels < G_ON) || (H_pixels > G_OFF)) retval.g = 0.0;

   if ((H_pixels < B_ON) || (H_pixels > B_OFF)) retval.b = 0.0;

   if (Style == SONY) {                // New code for Sony Trinitron stabilising wires

      if (scale <= 2) {
         V_pixels = abs (uv.y - 0.5);
         P_pixels = (scale == 1) ? (V_pixels) * 2.0 : V_pixels;
         P_pixels = (P_pixels < 0.4) ? 1.0 : P_pixels - 0.4;

         if (P_pixels < 0.002) return float4 (0.0.xxx, retval.a);
      }
   }
   else if (V_pixels > V_MAX) return float4 (0.0.xxx, retval.a);

   return retval;
}

float4 ps_prelim (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   float Pixel_1 = Radius / _OutputWidth;
   float Pixel_2 = Pixel_1 + Pixel_1 + Pixel_1;

   xy.x    += Pixel_1;
   Pixel_1 += Pixel_2;

   float4 retval = tex2D (s_Foreground, xy);

   xy.x += Pixel_1; retval += tex2D (s_Foreground, xy);
   xy.x += Pixel_1; retval += tex2D (s_Foreground, xy);
   xy.x += Pixel_1; retval += tex2D (s_Foreground, xy);
   xy.x += Pixel_1; retval += tex2D (s_Foreground, xy);

   xy.x = uv.x - Pixel_2;
   retval += tex2D (s_Foreground, xy);

   xy.x -= Pixel_1; retval += tex2D (s_Foreground, xy);
   xy.x -= Pixel_1; retval += tex2D (s_Foreground, xy);
   xy.x -= Pixel_1; retval += tex2D (s_Foreground, xy);
   xy.x -= Pixel_1; retval += tex2D (s_Foreground, xy);

   return retval / 10.0;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   float Pixel_1 = Radius * _OutputAspectRatio / _OutputWidth;
   float Pixel_2 = Pixel_1 + Pixel_1 + Pixel_1;

   xy.y    += Pixel_1;
   Pixel_1 += Pixel_2;

   float4 retval = tex2D (s_prelim, xy);

   xy.y += Pixel_1; retval += tex2D (s_prelim, xy);
   xy.y += Pixel_1; retval += tex2D (s_prelim, xy);
   xy.y += Pixel_1; retval += tex2D (s_prelim, xy);
   xy.y += Pixel_1; retval += tex2D (s_prelim, xy);

   xy.y = uv.y - Pixel_2;
   retval += tex2D (s_prelim, xy);

   xy.y -= Pixel_1; retval += tex2D (s_prelim, xy);
   xy.y -= Pixel_1; retval += tex2D (s_prelim, xy);
   xy.y -= Pixel_1; retval += tex2D (s_prelim, xy);
   xy.y -= Pixel_1; retval += tex2D (s_prelim, xy);

   retval /= 10.0;
   retval = lerp (retval, 0.0.xxxx, 1.0 - Opacity);

   float4 Inp = tex2D (s_Foreground, uv);

   retval = min (max (retval, Inp), 1.0.xxxx);
   retval = pow (retval, 0.4);

   float luma = dot (retval.rgb, float3 (0.2989, 0.5866, 0.1145));

   retval.a = Inp.a;
   Inp = saturate (retval + retval - luma);
   Inp.a = retval.a;

   luma = sqrt (Radius * Opacity);

   return Overflow (uv) ? EMPTY : lerp (retval, Inp, luma);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique colourscreen
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; > ExecuteShader (ps_raster)
   pass P_2 < string Script = "RenderColorTarget0 = prelim;"; > ExecuteShader (ps_prelim)
   pass P_3 ExecuteShader (ps_main)
}

