// @Maintainer jwrl
// @Released 2021-08-07
// @Author khaver
// @Author Daniel Taylor
// @Created 2018-05-24
// @see https://www.lwks.com/media/kunena/attachments/6375/PencilSketch_640.png

/**
 Pencil Sketch (PencilSketchFx.fx) is a really nice effect that creates a pencil sketch
 from your image.  As well as the ability to adjust saturation, gamma, brightness and
 gain, it's possible to overlay the result over a background layer.  What isn't possible
 is to compile this version under versions of Windows Lightworks earlier than 14.5.
 There is a legacy version available for users in that position.
*/

//-----------------------------------------------------------------------------------------//
// Original Shadertoy author:
// Daniel Taylor (culdevu) (2017-06-09) https://www.shadertoy.com/view/ldXfRj
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------------------------------------------//
// PencilSketchFx.fx for Lightworks was adapted by user khaver 24 May 2018 from original
// code by the above author taken from the Shadertoy website:
// https://www.shadertoy.com/view/ldXfRj
//
// This adaptation retains the same Creative Commons license shown above.  It cannot be
// used for commercial purposes.
//
// note: code comments are from the original author(s).
//
// Version history:
//
// Update 2021-08-07 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Pencil Sketch";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "Pencil sketch effect with sat/gamma/cont/bright/gain/overlay/alpha controls";
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
   AddressU  = Wrap;                  \
   AddressV  = Wrap;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define EMPTY      0.0.xxxx
#define BLACK      float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputWidth;
float _OutputHeight;

#define PI2      6.28318530717959
#define RANGE    16.0
#define STEP     2.0
#define ANGLENUM 4.0

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);
DefineTarget (Inp, InputSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float AMOUNT
<
   string Description = "Color";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Saturation
<
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;


float MasterGamma
<
   string Description = "Gamma";
   float MinVal = 0.1;
   float MaxVal = 4.0;
> = 1.00;

float MasterContrast
<
   string Description = "Contrast";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float MasterBrightness
<
   string Description = "Brightness";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float MasterGain
<
   string Description = "Gain";
   float MinVal = 0.0;
   float MaxVal = 4.0;
> = 1.0;

float Range
<
   string Description = "Range";
   float MinVal = 0.0;
   float MaxVal = 20.0;
> = 10.0;

float EPS
<
   string Description = "Stroke";
   float MinVal = 1e-10;
   float MaxVal = 5.0;
> = 1.0;

float MAGIC_GRAD_THRESH
<
   string Description = "Gradient Threshold";
   float MinVal = 0.0;
   float MaxVal = 0.1;
> = 0.01;

float MAGIC_SENSITIVITY
<
   string Description = "Sensitivity";
   float MinVal = 0.0;
   float MaxVal = 50.0;
> = 1.0;

bool ALPHA
<
   string Description = "Add Alpha";
> = false;

float MAGIC_COLOR
<
   string Description = "Overlay Amount";
   string Group = "Source Video";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

bool GREY
<
   string Description = "Greyscale";
   string Group = "Source Video";
> = false;

//-----------------------------------------------------------------------------------------//
// Your usual image functions and utility stuff
//-----------------------------------------------------------------------------------------//

float4 getCol (float2 pos)
{
   float2 uv = pos / float2 (_OutputWidth, _OutputHeight);

   return tex2D (InputSampler, uv);
}

float getVal (float2 pos)
{
   return dot (getCol (pos).xyz, float3 (0.2126, 0.7152, 0.0722));
}

float2 getGrad (float2 pos, float eps)
{
   float2 d = float2 (eps, 0.0);

   return float2 (getVal (pos + d.xy) - getVal (pos - d.xy),
                  getVal (pos + d.yx) - getVal (pos - d.yx)) / eps / 2.0;
}

void pR (inout float2 p, float a)
{
   p = (cos (a) * p) + (sin (a) * p.yx);
}

//-----------------------------------------------------------------------------------------//
// Let's do this!
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 mainImage (float2 uv : TEXCOORD1, float2 fragCoord : TEXCOORD2) : COLOR
{
   float2 iResolution = float2 (_OutputWidth, _OutputHeight);
   float2 pos = fragCoord * iResolution;

   float4 fragColor;

   float weight = 1.0;

   for (float j = 0.0; j < ANGLENUM; j += 1.0) {
      float2 dir = float2 (1.0, 0.0);

      pR (dir, j * PI2 / (EPS * ANGLENUM));           // NOTE: dir is changed by this!!!!!

      float2 grad = float2 (-dir.y, dir.x);

      for (float i = -RANGE; i <= RANGE; i += STEP) {
         float2 pos2 = pos + (normalize (dir) * i);

         // video texture wrap can't be set to anything other than clamp  (-_-)

         if ((pos2.y < 0.0) || (pos2.x < 0.0) || (pos2.x > iResolution.x) || (pos2.y > iResolution.y)) continue;

         float2 g = getGrad (pos2, 1.0);

         if (length(g) < MAGIC_GRAD_THRESH) continue;

         weight -= pow (abs (dot (normalize (grad), normalize (g))), MAGIC_SENSITIVITY) / floor ((2.0 * ceil (Range) + 1.0) / STEP) / ANGLENUM;
      }
   }

   float4 col = (!GREY) ? getCol (pos) : getVal (pos).xxxx;

   float4 background = lerp (col, 1.0.xxxx, 1.0 - MAGIC_COLOR);

   fragColor = lerp (0.0.xxxx, background, weight);
   fragColor = ((((pow (fragColor, 1.0 / MasterGamma) * MasterGain) + MasterBrightness) - 0.5) * MasterContrast) + 0.5;

   float4 fg = tex2D (InputSampler, fragCoord);
   float4 bg = fragColor;
   float4 result;

   result.r = (bg.r < 0.5) ? 2.0 * fg.r * bg.r : 1.0 - (2.0 * (1.0 - fg.r) * (1.0 - bg.r));
   result.g = (bg.g < 0.5) ? 2.0 * fg.g * bg.g : 1.0 - (2.0 * (1.0 - fg.g) * (1.0 - bg.g));
   result.b = (bg.b < 0.5) ? 2.0 * fg.b * bg.b : 1.0 - (2.0 * (1.0 - fg.b) * (1.0 - bg.b));

   result.rgb = lerp (result.rgb, BLACK, 1.0 - fg.a); // This cleans up any overshoot if the frame boundaries are too small.

   result.rgb = lerp (bg.rgb, result.rgb, fg.a * AMOUNT);

   result.a = (!ALPHA) ? 1.0 : 1.0 - dot (result.rgb, 0.33333.xxx);

   float3 avg = (result.r + result.g + result.b) / 3.0;

   result.rgb = avg + ((result.rgb - avg) * Saturation);

   return (Overflow (uv)) ? EMPTY : result;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Pencil
{
   pass Pfg < string Script = "RenderColorTarget0 = Inp;"; > ExecuteShader (ps_initInp)
   pass Pass1 ExecuteShader (mainImage)
}

