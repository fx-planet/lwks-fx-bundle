// @ReleaseDate: 2018-03-31
// @Author: baopao
//SkinSmooth by baopao

//Based on:

//http://www.blosser.org/d9/dlAviShader042.rar

//Graphic card that support at least pixel shader 2.a

//--------------------------------------------------------------//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  THE BUG WAS NOT IN THE WAY THIS EFFECT
// WAS ORIGINALLY IMPLEMENTED.
//
// It appears that when a height parameter is needed one can
// not reliably use _OutputHeight.  It returns only half the
// actual frame height when interlaced media is playing and
// only when it is playing.  For that reason the output height
// should always be obtained by dividing _OutputWidth by
// _OutputAspectRatio until such time as the bug in the
// Lightworks code can be fixed.  It seems that after contact
// with the developers that is very unlikely to be soon.
//
// Note: This fix has been fully tested, and appears to be a
// reliable solution regardless of the pixel aspect ratio.
//
// Version 14 update 18 Feb 2017 jwrl.
//
// Added subcategory to effect header.
//
// Cross platform compatibility check 1 August 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Considerable code cleanup and redundancy removal also done.
// In the process changed TEXCOORD0 declaration to TEXCOORD1
// to fix the half texel shift.  Removed redundant constants
// that did nothing except take up space and force needless
// mathematical operations.  Preserved the alpha channel of
// the input, and reworded several parameter strings to make
// more sense.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Skin smooth";
   string Category    = "Colour";
   string SubCategory = "Preset Looks";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture IMG;
texture MSK;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler2D frameSampler = sampler_state {
   Texture   = <IMG>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler2D MaskSampler = sampler_state {
   Texture   = <MSK>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2;

float FrameSize
<
   string Description = "Sample size";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

bool RedMSK
<
   string Description = "Red mask";
> = true;

float MskBrightness
<
   string Description = "Mask brightness";
   float MinVal = 0.0;
   float MaxVal = 10.00;
> = 1.0;

float MskGamma
<
   string Description = "Mask gamma";
   float MinVal = 0.0;
   float MaxVal = 2.00;
> = 1.0;

bool ShowRedMSK
<
   string Description = "Show red mask";
> = false;


bool InputMSK
<
   string Description = "Use external mask";
> = false;

bool ShowMSK
<
   string Description = "Show external mask";
> = false;

float4 ShowMskColour
<
   string Description = "Ext mask colour";
> = { 0.0, 1.0, 0.0, 1.0 };

float ShowMSKAmount
<
   string Description = "Ext mask mix";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 fold_bilateral (float2 tTex : TEXCOORD1) : COLOR
{
   float stepX = _OutputWidth * (1.0 - (min (1.0, FrameSize) * 0.75));
   float stepY = stepX / _OutputAspectRatio;
   float w2t = stepX * stepX / 8.0;
   float h2t = stepY * stepY / 8.0;

   stepX = 1.0 / stepX;
   stepY = 1.0 / stepY;

   float4 Color = tex2D (frameSampler, tTex);

   float3 normalizer = 1.0.xxx;
   float3 tempC0 = Color.rgb;
   float3 tempC1, tempC2, tempW;

   float2 position;

   float startX = -stepX * 2.0;
   float startY = -stepY * 2.0;
   float p = 0.5 / (Amount * Amount);
   float x = stepX;
   float optX, optY, y;

   for (int i = 0; i < 2; i++) {
      y = stepY;
      optX = x * x * w2t;

      position = tTex + float2 (0.0, y);
      tempC1 = tex2D (frameSampler, position).rgb;
      tempC2 = tempC0 - tempC1;
      tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
      Color.rgb += tempC1 * tempW;
      normalizer += tempW;

      position = tTex - float2 (0.0, y);
      tempC1 = tex2D (frameSampler, position).rgb;
      tempC2 = tempC0 - tempC1;
      tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
      Color.rgb += tempC1 * tempW;
      normalizer += tempW;

      position = tTex + float2 (x, 0.0);
      tempC1 = tex2D (frameSampler, position).rgb;
      tempC2 = tempC0 - tempC1;
      tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
      Color.rgb += tempC1 * tempW;
      normalizer += tempW;

      position = tTex - float2 (x, 0.0);
      tempC1 = tex2D (frameSampler, position).rgb;
      tempC2 = tempC0 - tempC1;
      tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
      Color.rgb += tempC1 * tempW;
      normalizer += tempW;

      for (int j = 0; j < 2; j++) {
         optX += y * y * h2t;

         position = tTex + float2 (x, y);
         tempC1 = tex2D (frameSampler, position).rgb;
         tempC2 = tempC0 - tempC1;
         tempW = exp(-(tempC2 * tempC2 * p) - optX.xxx);
         Color.rgb += tempC1 * tempW;
         normalizer += tempW;

         position = tTex - float2 (x, -y);
         tempC1 = tex2D (frameSampler, position).rgb;
         tempC2 = tempC0 - tempC1;
         tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
         Color.rgb += tempC1 * tempW;
         normalizer += tempW;

         position = tTex + float2 (x, -y);
         tempC1 = tex2D (frameSampler, position).rgb;
         tempC2 = tempC0 - tempC1;
         tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
         Color.rgb += (tempC1 * tempW);
         normalizer += (tempW);

         position = tTex - float2 (x, y);
         tempC1 = tex2D (frameSampler, position).rgb;
         tempC2 = tempC0 - tempC1;
         tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
         Color.rgb += tempC1 * tempW;
         normalizer += tempW;

         y += stepY;
      }

      x += stepX;
   }

   Color.rgb /= normalizer;

   float4 bgPix = tex2D (frameSampler, tTex.xy);

   float R_MSK = (lerp (bgPix.r, bgPix.g, 0.5) - bgPix.b);

   R_MSK = saturate (pow (R_MSK, 1.0 / MskGamma) * MskBrightness);

   if (RedMSK) Color = lerp (bgPix, Color, R_MSK);

   if (ShowRedMSK) Color = R_MSK.xxxx;
   
   float4 Mask = tex2D (MaskSampler, tTex);

   if (InputMSK) Color = lerp (bgPix, Color, Mask); 

   if (ShowMSK) Color = lerp (bgPix, ShowMskColour, ShowMSKAmount * Mask);

   return float4 (Color.rgb, bgPix.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique BilateralFilter
{
   pass Single_Pass { PixelShader = compile PROFILE fold_bilateral (); }
}

