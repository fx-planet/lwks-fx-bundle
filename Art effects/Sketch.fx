// @Maintainer jwrl
// @ReleaseDate 2018-03-31
// @Author khaver
// @CreationDate "August 2012"
//--------------------------------------------------------------//
// Sketch.fx created by Gary Hango (khaver) August 2012.
//
// Cross platform conversion by jwrl May 2 2016.
//
// Bug fix 26 February 2017 by jwrl:
//
// Added workaround for the interlaced media height bug in
// Lightworks effects.
//
// Cross platform compatibility check 27 July 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Explicitly defined float2 and float4 variables to address
// behavioural difference between the D3D and Cg compilers.
//
// Removed the statements "static const", "CULL_MODE" and the
// VertexShader declaration.  They broke the effect in Linux
// and appeared to do nothing in Windows.
//
// Removed the arguments being passed to the RenderColorTarget
// declarations.  They seemed to do nothing in either OS.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Sketch";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";         // Added for LW14 - jwrl
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture ThresholdTexture : RenderColorTarget;
texture Blur1 : RenderColorTarget;
texture Blur2 : RenderColorTarget;
texture Target : RenderColorTarget;

sampler SourceTextureSampler = sampler_state
{
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler ThresholdSampler = sampler_state
{
   Texture = <ThresholdTexture>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BlurSampler = sampler_state
{
   Texture = <Blur1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BlurSampler2 = sampler_state
{
   Texture = <Blur2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler TarSamp = sampler_state {
   Texture = <Target>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
 };

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

bool Invert
<
   string Description = "Invert All";
> = false;

float4 BorderLineColor
<
   string Description = "Color";
   string Group = "Lines";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 0.0, 1.0 };

float Strength
<
   string Description = "Strength";
   string Group = "Lines";
   float MinVal = 0.0;
   float MaxVal = 20.0;
> = 1.0;

bool InvLines
<
   string Description = "Invert";
   string Group = "Lines";
> = false;

float RLevel
<
   string Description = "Red Threshold";
   string Group = "Background";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.3;

float GLevel
<
   string Description = "Green Threshold";
   string Group = "Background";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.59;

float BLevel
<
   string Description = "Blue Threshold";
   string Group = "Background";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.11;

float Level
<
   string Description = "Shadow Amount";
   string Group = "Background";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float4 DarkColor
<
   string Description = "Shadow Color";
   string Group = "Background";
   bool SupportsAlpha = true;
> = { 0.5, 0.5, 0.5, 1.0 };

float4 LightColor
<
   string Description = "Highlight Color";
   string Group = "Background";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 1.0, 1.0 };

bool Swap
<
   string Description = "Swap";
   string Group = "Background";
> = false;

bool InvBack
<
   string Description = "Invert";
   string Group = "Background";
> = false;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

int GX [3][3] =
{
    { -1, +0, +1 },
    { -2, +0, +2 },
    { -1, +0, +1 },
};

int GY [3][3] =
{
    { +1, +2, +1 },
    { +0, +0, +0 },
    { -1, -2, -1 },
};

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 threshold_main (float2 xy1 : TEXCOORD1) : COLOR
{
   float4 src1 = tex2D (SourceTextureSampler, xy1);
   float srcLum = saturate ((src1.r * RLevel) + (src1.g * GLevel) + (src1.b * BLevel));

   if (Swap) src1.rgb = (srcLum <= Level) ? LightColor.rgb : DarkColor.rgb;
   else src1.rgb = (srcLum > Level) ? LightColor.rgb : DarkColor.rgb;
      
   if (InvBack) src1 = 1.0.xxxx - src1;

   return src1;
}

float4 blurX_main (float2 xy1 : TEXCOORD1) : COLOR
{
   float one   = 1.0 / _OutputWidth;
   float tap1  = xy1.x + one;
   float ntap1 = xy1.x - one;

   float4 blurred = tex2D (ThresholdSampler, xy1);

   blurred += tex2D (ThresholdSampler, float2 (tap1,  xy1.y));
   blurred += tex2D (ThresholdSampler, float2 (ntap1, xy1.y));

   return blurred / 3.0;
}

float4 blurY_main (float2 xy1 : TEXCOORD1) : COLOR
{
   float one  = _OutputAspectRatio / _OutputWidth;
   float tap1 = xy1.y + one;
   float ntap1 = xy1.y - one;

   float4 ret = tex2D (BlurSampler, xy1);

   ret += tex2D (BlurSampler, float2 (xy1.x, tap1));
   ret += tex2D (BlurSampler, float2 (xy1.x, ntap1));

   return ret / 3.0;
}

float4 EdgedetectGrayscaleFunc (float2 tex : TEXCOORD1) : COLOR
{
   float4 bl = BorderLineColor;

   float2 PIXEL_SIZE = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 HALF_PIX = PIXEL_SIZE / 2.0;
   float2 xy = 0.0.xx;

   float sumX = 0.0;
   float sumY = 0.0;

   for (int i = -1; i <= 1; i++) {

      for (int j = -1; j <= 1; j++) {
         float2 ntex = float2 (i * PIXEL_SIZE.x, j * PIXEL_SIZE.y);
         float val = dot (tex2D (SourceTextureSampler, tex + ntex).rgb, float3 (0.3, 0.59, 0.11));

         sumX += val * GX [i + 1][j + 1] * Strength;
         sumY += val * GY [i + 1][j + 1] * Strength;
      }
   }

   float4 color = 1.0.xxxx - (saturate (abs (sumX) + abs (sumY)) * (1.0.xxxx - bl));
   color.a = (color.r + color.g + color.b) / 3.0;

   if (InvLines) color.rgb = 1.0.xxx - color.rgb;

   return color;
}

float4 Fix (float2 tex : TEXCOORD1) : COLOR
{
   float2 PIXEL_SIZE = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 HALF_PIX = PIXEL_SIZE / 2.0;

   float4 lines = tex2D (TarSamp, tex - (PIXEL_SIZE * 2.0));
   float4 back = tex2D (BlurSampler2, tex - (PIXEL_SIZE * 1.5));

   if (Invert) return 1.0.xxxx - lerp (lines, back, lines.a);

   return lerp (lines, back, lines.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique EdgeDetect
{
   pass ThresholdPass
   <
      string Script = "RenderColorTarget0 = ThresholdTexture;";
   >
   {
      PixelShader = compile PROFILE threshold_main ();
   }

   pass BlurX
   <
      string Script = "RenderColorTarget0 = Blur1;";
   >
   {
      PixelShader = compile PROFILE blurX_main ();
   }

   pass BlurY
   <
      string Script = "RenderColorTarget0 = Blur2;";
   >
   {
      PixelShader = compile PROFILE blurY_main ();
   }

   pass one
   <
      string Script = "RenderColorTarget0 = Target;";
   >
   {
      PixelShader = compile PROFILE EdgedetectGrayscaleFunc ();
   }

   pass two
   {
      PixelShader = compile PROFILE Fix ();
   }
}

