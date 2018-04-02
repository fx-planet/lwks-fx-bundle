// @ReleaseDate: 2018-03-31
/**
  * FxSpinBlur.
  * SpinBlur effect.
  * 
  * @param <threshold>  Blur length parameters
  * @param <CX> Center point of the spin, the X coordinate
  * @param <CY> Center point of the spin, the Y coordinate
  * @param <AR> AspectRatio 1:x
  * @author Windsturm
  * @version 1.0
 */

//--------------------------------------------------------------//
// FxSpinBlur
//
// original code by rakusan.
// http://kuramo.ch/webgl/videoeffects/
//
// Translated by Windsturm.
//
// This Lightworks cross-platform version ported by Lightworks
// forum moderator jwrl May 3 2016.
//
// An arithmetic bug which arose during the cross platform
// conversion was detected and fixed by jwrl on June 28 2017.
// The bug resulted in a noticeable drop in video levels and
// severe highlight compression.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "FxSpinBlur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";   // Added for v14 compatibility - jwrl.
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture prelim : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InputSampler = sampler_state
{
   Texture = <Input>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler partSampler = sampler_state
{
   Texture = <prelim>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float threshold
<
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 20.0;

float CX
<
   string Description = "Center";
   string Flags = "SpecifiesPointX";
   float MinVal = -0.50;
   float MaxVal = 1.50;
> = 0.5;

float CY
<
   string Description = "Center";
   string Flags = "SpecifiesPointY";
   float MinVal = -0.50;
   float MaxVal = 1.50;
> = 0.5;

float AR
<
   string Description = "AspectRatio 1:x";
   float MinVal = 0.01;
   float MaxVal = 10.00;
> = 1.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define BLUR_PART 15
#define BLUR_SAMP 30
#define BLUR_DIV  11.6

#define WAIT_1    1.0
#define WAIT_2    0.5

#define INTERVAL  0.033333

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 FxSpinBlur (float2 xy : TEXCOORD1, uniform bool pass2) : COLOR
{
   if (threshold == 0.0) return tex2D (InputSampler, xy);

   float2 angXY;
   float Tcos, Tsin;

   float4 color = 0.0.xxxx;

   float2 outputAspect = float2 (1.0, _OutputAspectRatio);
   float2 blueAspect = float2 (1.0, AR);
   float2 center = float2 (CX, 1.0 - CY );
   float2 uv = (xy - center) / outputAspect / blueAspect;

   float amount = radians (threshold) / BLUR_SAMP;
   float wait = pass2 ? WAIT_2 : WAIT_1;

   int start_count = pass2 ? BLUR_PART : 0;
   int end_count = pass2 ? BLUR_SAMP : BLUR_PART;

   float ang = amount * start_count;

   for (int i = start_count; i < end_count; i++) {
      sincos (ang, Tsin, Tcos);
      angXY = center + float2 ((uv.x * Tcos - uv.y * Tsin),
              (uv.x * Tsin + uv.y * Tcos) * outputAspect.y) * blueAspect;

      color += (tex2D (InputSampler, angXY) * wait);

      wait -= INTERVAL;
      ang += amount;
   }

   color /= BLUR_DIV;

   if (pass2) color = (color + tex2D (partSampler, xy)) * 0.75;

   return color;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique SampleFxTechnique
{
   pass Pass_1
   <
      string Script = "RenderColorTarget0 = prelim;";
   >
   {
      PixelShader = compile PROFILE FxSpinBlur (false);
   }

   pass Pass_2
   {
      PixelShader = compile PROFILE FxSpinBlur (true);
   }
}

