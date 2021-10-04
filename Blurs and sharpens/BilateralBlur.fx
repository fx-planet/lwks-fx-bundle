// @Maintainer jwrl
// @Released 2021-08-31
// @Author baopao
// @Created 2013-10-23
// @see https://www.lwks.com/media/kunena/attachments/6375/BilateralBlur_640.png

/**
 A strong bilateral blur created by baopao with a little help from his friends.  In this
 version for Lightworks 2021 and higher the alpha channel is preserved, unlike in the
 earlier one where it was discarded.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BilateralBlur.fx
//
// bilateral based on:
// Antitorgo's avishader 0.42 filter
// http://www.blosser.org/d9/dlAviShader042.rar
//
// Version history:
//
// Updated 2021-08-31 jwrl:
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 2020-11-09:
// Various updates mainly to improve cross-platform performance.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bilateral blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "A strong bilateral blur created by baopao with a little help from his friends";
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

#define SetInputMode(TEX, SMPL, MODE) \
                                      \
 texture TEX;                         \
                                      \
 sampler SMPL = sampler_state         \
 {                                    \
   Texture   = <TEX>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define SetTargetMode(TGT, SMP, MODE) \
                                      \
 texture TGT : RenderColorTarget;     \
                                      \
 sampler SMP = sampler_state          \
 {                                    \
   Texture   = <TGT>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

SetInputMode (Input, s_Input, Mirror);

SetTargetMode (FixInp, InpSampler, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float FrameSize
<
   string Description = "Blur window";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_Input, uv); }

float4 fold_bilateral (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 tempC0 = tex2D (InpSampler, uv2);
   float4 Colour = tempC0;
   float4 normalizer = 1.0.xxxx;
   float4 tempC1, tempC2, tempW;

   float2 position;

   float width  = max (0.002, 1.0 - max (0.0, FrameSize));
   float height = _OutputHeight * width;

   width *= _OutputWidth;

   float stepX = 1.0 / width;
   float stepY = 1.0 / height;

   float p = 1.0 / max (0.000001, 2.0 * Amount * Amount);

   float x = stepX;
   float y, optX, optY, tempG;

   for (int i = 0; i < 2; i++) {
      y = stepY;
      optX = x * x * width * width * 0.125;
      position = float2 (uv2.x, uv2.y + y);

      tempC1 = tex2D (InpSampler, position);
      tempC2 = tempC0 - tempC1;
      tempW  = exp (-(tempC2 * tempC2 * p) - optX);
      Colour += (tempC1 * tempW);

      normalizer += tempW;

      position = float2 (uv2.x, uv2.y - y);

      tempC1 = tex2D (InpSampler, position);
      tempC2 = tempC0 - tempC1;
      tempW  = exp (-(tempC2 * tempC2 * p) - optX);
      Colour += (tempC1 * tempW);

      normalizer += tempW;

      position = float2 (uv2.x + x, uv2.y);

      tempC1 = tex2D (InpSampler, position);
      tempC2 = tempC0 - tempC1;
      tempW  = exp (-(tempC2 * tempC2 * p) - optX);
      Colour += (tempC1 * tempW);

      normalizer += tempW;

      position = float2 (uv2.x - x, uv2.y);

      tempC1 = tex2D (InpSampler, position);
      tempC2 = tempC0 - tempC1;
      tempW  = exp (-(tempC2 * tempC2 * p) - optX);
      Colour += (tempC1 * tempW);

      normalizer += tempW;

      for (int j = 0; j < 2; j++) {
         optX += y * y * height * height * 0.125;

         position = float2 (uv2.x + x, uv2.y + y);

         tempC1 = tex2D (InpSampler, position);
         tempC2 = tempC0 - tempC1;
         tempW  = exp (-(tempC2 * tempC2 * p) - optX);
         Colour += (tempC1 * tempW);

         normalizer += tempW;

         position = float2 (uv2.x - x, uv2.y + y);

         tempC1 = tex2D (InpSampler, position);
         tempC2 = tempC0 - tempC1;
         tempW  = exp (-(tempC2 * tempC2 * p) - optX);
         Colour += (tempC1 * tempW);

         normalizer += tempW;

         position = float2 (uv2.x + x, uv2.y - y);

         tempC1 = tex2D (InpSampler, position);
         tempC2 = tempC0 - tempC1;
         tempW  = exp (-(tempC2 * tempC2 * p) - optX);
         Colour += (tempC1 * tempW);

         normalizer += tempW;

         position = float2 (uv2.x - x, uv2.y - y);

         tempC1 = tex2D (InpSampler, position);
         tempC2 = tempC0 - tempC1;
         tempW  = exp (-(tempC2 * tempC2 * p) - optX);
         Colour += (tempC1 * tempW);

         normalizer += tempW;

         y += stepY;
      }

      x += stepX;
   }

   return Overflow (uv1) ? EMPTY : Colour / normalizer;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique BilateralFilter
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Single_Pass ExecuteShader (fold_bilateral)
}

