//--------------------------------------------------------------//
// Lightworks user effect FractalMagic3.fx
//
// Created by LW user jwrl 22 May 2016.
// @Author: jwrl
// @CreationDate: "22 May 2016"
//  LW 14+ version by jwrl 12 February 2017
//  SubCategory "Patterns" added.
//
// The fractal component is a conversion of a GLSL sandbox
// effect (http://glslsandbox.com/e#308888.0) created by
// Robert Schütze (trirop) 07.12.2015.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fractal magic 3";
   string Category    = "Mattes";
   string SubCategory = "Patterns";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture FracOut : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InputSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Frac_Sampler = sampler_state
{
   Texture   = <FracOut>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float FracOffs
<
   string Description = "Fractal offset";   
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.0;

float FracRate
<
   string Description = "Fractal rate";   
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float4 Colour
<
   string Description = "Mix colour";
   string Group = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.77, 0.19, 1.0 };

float ColourMix
<
   string Description = "Mix level";
   string Group = "Colour";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float HueParam
<
   string Description = "Hue";
   string Group = "Colour";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float SatParam
<
   string Description = "Saturation";
   string Group = "Colour";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Gain
<
   string Description = "Gain";
   string Group = "Luminance";
   float MinVal = 0.00;
   float MaxVal = 4.00;
> = 1.0;

float Gamma
<
   string Description = "Gamma";
   string Group = "Luminance";
   float MinVal = 0.0;
   float MaxVal = 4.00;
> = 1.00;

float Brightness
<
   string Description = "Brightness";
   string Group = "Luminance";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float Contrast
<
   string Description = "Contrast";
   string Group = "Luminance";
   float MinVal = 0.00;
   float MaxVal = 4.00;
> = 1.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define PI_2     6.283185

#define INVSQRT3 0.57735

#define R_WEIGHT 0.2989
#define G_WEIGHT 0.5866
#define B_WEIGHT 0.1145

float _Progress;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_fractal (float2 xy : TEXCOORD1) : COLOR
{
   float speed = _Progress * FracRate;
   float4 retval = 1.0.xxxx;
   float3 f = float3 (xy, FracOffs);

   for (int i = 0; i < 75; i++) {
      f.xzy = float3 (1.3, 0.999, 0.7) * (abs ((abs (f) / dot (f, f) - float3 (1.0, 1.0, speed * 0.5))));
   }

   retval.rgb = f;

   return retval;
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 Fgd    = tex2D (InputSampler, xy);
   float4 retval = tex2D (Frac_Sampler, xy);

   float luma   = dot (retval.rgb, float3 (R_WEIGHT, G_WEIGHT, B_WEIGHT));
   float buffer = dot (Colour.rgb, float3 (R_WEIGHT, G_WEIGHT, B_WEIGHT));

   buffer = saturate (buffer - 0.5);
   buffer = 1 / (buffer + 0.5);

   float4 temp = Colour * luma * buffer;

   retval = lerp (retval, temp, ColourMix);
   luma = (retval.r + retval.g + retval.b) / 3.0;

   float RminusG = retval.r - retval.g;
   float RminusB = retval.r - retval.b;
   float GammVal = (Gamma > 1.0) ? Gamma : Gamma * 0.9 + 0.1;
   float Hue_Val = acos ((RminusG + RminusB) / (2.0 * sqrt (RminusG * RminusG + RminusB * (retval.g - retval.b)))) / PI_2;
   float Sat_Val = 1.0 - min (min (retval.r, retval.g), retval.b) / luma;

   if (retval.b > retval.g) Hue_Val = 1.0 - Hue_Val;

   Hue_Val = frac (Hue_Val + (HueParam * 0.5));
   Sat_Val = saturate (Sat_Val * (SatParam + 1.0));

   float Hrange = Hue_Val * 3.0;
   float Hoffst = (2.0 * floor (Hrange) + 1.0) / 6.0;

   buffer = INVSQRT3 * tan ((Hue_Val - Hoffst) * PI_2);
   temp.x = (1.0 - Sat_Val) * luma;
   temp.y = ((3.0 * (buffer + 1.0)) * luma - (3.0 * buffer + 1.0) * temp.x) / 2.0;
   temp.z = 3.0 * luma - temp.y - temp.x;

   retval = (Hrange < 1.0) ? temp.zyxw : (Hrange < 2.0) ? temp.xzyw : temp.yxzw;
   temp   = (((pow (retval, 1.0 / GammVal) * Gain) + Brightness.xxxx - 0.5.xxxx) * Contrast) + 0.5.xxxx;
   retval = lerp (Fgd, temp, Opacity);

   retval.a = Fgd.a;

   return retval;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique doMain
{
   pass P_1
   < string Script = "RenderColorTarget0 = FracOut;"; >
   { PixelShader = compile PROFILE ps_fractal (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

