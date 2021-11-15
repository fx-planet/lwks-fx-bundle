// @Maintainer jwrl
// @Released 2021-11-15
// @Author khaver
// @Created 2014-11-19
// @see https://www.lwks.com/media/kunena/attachments/6375/VHSv2_640.png

/**
 This effect simulates a damaged VHS tape.  Use the Source X pos slider to locate the
 vertical strip down the frame that affects the distortion.  The horizontal distortion
 uses the luminance value along this vertical strip.  The threshold adjusts the value
 that triggers the distortion and white, red and blue noise can be added.  There's also
 a Roll control to roll the image up or down at different speeds.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VHSsimulator.fx
//
// VHS by khaver (cross-platform V2 mod by jwrl)
//
// Version history:
//
// Update 2021-11-15 jwrl.
// Corrected video wrap around.  Because I was uncertain whether khaver intended this
// or whether I had previously broken the effect I have added a switch to disable wrap.
//
// Update 2021-11-01 jwrl.
// Updated the original effect to better support LW v2021 and higher.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "VHS simulator";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Simulates a damaged VHS tape";
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
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

SetTargetMode (Tex1, Samp1, Wrap);
SetTargetMode (Tex2, Samp2, Wrap);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Lines
<
   string Description = "Vertical Resolution";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float ORGX
<
   string Group = "Distortion";
   string Description = "Source X pos";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.02;

bool Invert
<
   string Group = "Distortion";
   string Description = "Negate Source";
> = false;

float Strength
<
   string Group = "Distortion";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Threshold
<
   string Group = "Distortion";
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Bias
<
   string Group = "Distortion";
   string Description = "Bias";
   float MinVal = -0.5;
   float MaxVal = 0.5;
> = 0.0;

float WNoise
<
   string Group = "Noise";
   string Description = "White Noise";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float RNoise
<
   string Group = "Noise";
   string Description = "Red Noise";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float BNoise
<
   string Group = "Noise";
   string Description = "Blue Noise";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

int RMult
<
   string Group = "Roll";
   string Description = "Speed Multiplier";
   string Enum = "x1,x10,x100";
> = 0;

float Roll
<
   string Group = "Roll";
   string Description = "Speed";
   float MinVal = -10.0;
   float MaxVal = 10.0;
> = 0.0;

bool Wrap
<
   string Description = "Allow video wrap around";
> = false;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float random (float2 p)
{
   float2 r = float2 (23.140692632779269,  // e^pi (Gelfond's constant)
                      2.6651441426902251); // 2^sqrt(2) (Gelfond/Schneider constant)

   return frac (cos (fmod (123456789.0, 1e-7 + 256.0 * dot (p, r))));  
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 main (float2 uv : TEXCOORD1) : COLOR
{
   float4 source = float4 (0.0.xxx, 1.0);
   float4 ret = source;
   float4 strip = GetPixel (s_Input, float2 (ORGX, uv.y));

   float luma = (strip.r + strip.g + strip.b) / 3.0;

   luma = Invert ? 1.0 - ((abs (luma - (0.5 + Bias))) * 2.0)
                 : abs (luma - (0.5 + Bias)) * 2.0;

   if (luma >= Threshold) {

      float noiseW = WNoise / 5.0;
      float noiseR = RNoise / 10.0;
      float noiseB = BNoise / 10.0;

      if (random (float2 ((uv.x + 0.5) * luma, (_Progress + 0.5) * uv.y)) / Strength < noiseW)
         ret = 1.0.xxxx;

      if (random (float2 ((uv.y + 0.5) * luma, (_Progress + 0.4) * uv.x)) / Strength < noiseR)
         ret = float4 (0.75, 0.0.xx, 1.0) * (1.0 - luma - Threshold);

      if (random (float2 ((uv.x + 0.5) * luma, (_Progress + 0.3) * uv.x)) / Strength < noiseB)
         ret = float4 (0.0.xx, 0.75, 1.0) * (1.0 - luma - Threshold);
   }

   return (min (WNoise, Strength) == 0.0) && (min (RNoise, Strength) == 0.0) &&
          (min (BNoise, Strength) == 0.0) ? source : ret;
}

float4 main0 (float2 uv : TEXCOORD1) : COLOR
{
   float4 source = GetPixel (s_Input,uv);

   float xSize = 5.0 / (Lines * _OutputWidth);
   float ySize = _OutputAspectRatio / (Lines * _OutputWidth);

   float2 xy = float2 (uv.x - 0.5, round (( uv.y - 0.5) / ySize ) * ySize) + 0.5;

   return GetPixel (s_Input, xy);
}

float4 main1 (float2 uv : TEXCOORD1) : COLOR
{
   float xSize = 5.0 / (Lines * _OutputWidth);
   float ySize = _OutputAspectRatio / (Lines * _OutputWidth);
   float rmult = ceil (pow (10.0, (float) RMult));
   float flip = _Progress * Roll * rmult;

   float2 xy1 = float2 (uv.x, uv.y + flip);

   float4 orig, strip;

   if (Wrap) {
      orig = tex2D (Samp2, xy1);
      strip = tex2D (Samp2, float2 (ORGX, xy1.y));
   }
   else {
      orig = GetPixel (Samp2, xy1);
      strip = GetPixel (Samp2, float2 (ORGX, xy1.y));
   }

   float luma = (strip.r + strip.g + strip.b) / 3.0;

   luma = Invert ? 1.0 - ((abs (luma - (0.5 + Bias))) * 2.0) : abs (luma - (0.5 + Bias)) * 2.0;

   if (luma >= Threshold) {
      float2 xy2 = float2 (xy1.x - ((luma - Threshold) * Strength), xy1.y);
      float2 xy3 = float2 (round ((xy1.x - 0.5) / xSize ) * xSize,
                           round ((xy1.y - 0.5) / ySize) * ySize) + 0.5.xx;

      xy3.x -= (luma - Threshold) * Strength;

      float4 noise;

      if (Wrap) {
         orig.r = tex2D (Samp2, float2 (xy2.x + (xSize * (luma - Threshold) * Strength * 33.0), xy2.y)).r;
         orig.g = tex2D (Samp2, xy2).g;
         orig.b = tex2D (Samp2, float2 (xy2.x - (xSize * (luma - Threshold) * Strength * 33.0), xy2.y)).b;

         noise = tex2D (Samp1, xy3);
      }
      else {
         orig.r = GetPixel (Samp2, float2 (xy2.x + (xSize * (luma - Threshold) * Strength * 33.0), xy2.y)).r;
         orig.g = GetPixel (Samp2, xy2).g;
         orig.b = GetPixel (Samp2, float2 (xy2.x - (xSize * (luma - Threshold) * Strength * 33.0), xy2.y)).b;

         noise = GetPixel (Samp1, xy3);
      }

      orig = max (orig, noise);
   }

   return orig;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass Pass1 < string Script = "RenderColorTarget0 = Tex1;"; > ExecuteShader (main)
   pass Pass2 < string Script = "RenderColorTarget0 = Tex2;"; > ExecuteShader (main0)
   pass Pass3 ExecuteShader (main1)
}

