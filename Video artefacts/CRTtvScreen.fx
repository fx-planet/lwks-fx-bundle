// @Maintainer jwrl
// @Released 2020-11-15
// @Author jwrl
// @Created 2017-02-22
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
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user CRTtvScreen.fx
//
// Version history:
//
// Update 2020-11-15 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 7 December 2018 jwrl.
// Changed subcategory.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Cross platform compatibility check 3 August 2017 jwrl.
// Explicitly defined InpSampler{} to reduce the risk of cross platform default
// sampler state differences.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "CRT TV screen";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Simulates a close-up look at an analogue colour TV screen.  Three options are available.";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Fgd    : RenderColorTarget;
texture prelim : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InpSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FgdSampler = sampler_state {
   Texture   = <Fgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler preSampler = sampler_state {
   Texture   = <prelim>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float Opacity
<
   string Description = "Glow amount";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_raster (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (InpSampler, uv);

   int scale = 1.0 + (10.0 * max (Size, 0.0));

   float H_pixels = float (int (uv.x * _OutputWidth * 3.0 / scale) / 12.0);
   float V_pixels = frac (int (uv.y * _OutputWidth / (_OutputAspectRatio + scale)) / 8.0);
   float P_pixels;

   H_pixels = modf (H_pixels, P_pixels);
   P_pixels = round (frac (P_pixels / 2.0) + 0.25);

   if ((P_pixels == 1.0) && (Style == DMD)) V_pixels = (V_pixels >= 0.5) ? V_pixels - 0.5 : V_pixels + 0.5;

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

   float4 retval = tex2D (FgdSampler, xy);

   xy.x += Pixel_1; retval += tex2D (FgdSampler, xy);
   xy.x += Pixel_1; retval += tex2D (FgdSampler, xy);
   xy.x += Pixel_1; retval += tex2D (FgdSampler, xy);
   xy.x += Pixel_1; retval += tex2D (FgdSampler, xy);

   xy.x = uv.x - Pixel_2;
   retval += tex2D (FgdSampler, xy);

   xy.x -= Pixel_1; retval += tex2D (FgdSampler, xy);
   xy.x -= Pixel_1; retval += tex2D (FgdSampler, xy);
   xy.x -= Pixel_1; retval += tex2D (FgdSampler, xy);
   xy.x -= Pixel_1; retval += tex2D (FgdSampler, xy);

   return retval / 10.0;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   float Pixel_1 = Radius * _OutputAspectRatio / _OutputWidth;
   float Pixel_2 = Pixel_1 + Pixel_1 + Pixel_1;

   xy.y    += Pixel_1;
   Pixel_1 += Pixel_2;

   float4 retval = tex2D (preSampler, xy);

   xy.y += Pixel_1; retval += tex2D (preSampler, xy);
   xy.y += Pixel_1; retval += tex2D (preSampler, xy);
   xy.y += Pixel_1; retval += tex2D (preSampler, xy);
   xy.y += Pixel_1; retval += tex2D (preSampler, xy);

   xy.y = uv.y - Pixel_2;
   retval += tex2D (preSampler, xy);

   xy.y -= Pixel_1; retval += tex2D (preSampler, xy);
   xy.y -= Pixel_1; retval += tex2D (preSampler, xy);
   xy.y -= Pixel_1; retval += tex2D (preSampler, xy);
   xy.y -= Pixel_1; retval += tex2D (preSampler, xy);

   retval /= 10.0;
   retval = lerp (retval, 0.0.xxxx, 1.0 - Opacity);

   float4 Inp = tex2D (FgdSampler, uv);

   retval = min (max (retval, Inp), 1.0.xxxx);
   retval = pow (retval, 0.4);

   float luma = dot (retval.rgb, float3 (0.2989, 0.5866, 0.1145));

   retval.a = Inp.a;
   Inp = saturate (retval + retval - luma);
   Inp.a = retval.a;

   luma = sqrt (Radius * Opacity);

   return lerp (retval, Inp, luma);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique colourscreen
{
   pass Pass_one
   <
      string Script = "RenderColorTarget0 = Fgd;";
   >
   {
      PixelShader = compile PROFILE ps_raster ();
   }

   pass Pass_two
   <
      string Script = "RenderColorTarget0 = prelim;";
   >
   {
      PixelShader = compile PROFILE ps_prelim ();
   }

   pass Pass_three
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
