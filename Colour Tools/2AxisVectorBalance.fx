// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2016-06-05
// @see https://www.lwks.com/media/kunena/attachments/6375/Two_Axis_Vector_640.png

/**
This effect was written at the request of David Rasberry.  It's designed for fast efficient
two-axis YUV-based colour grading.  For comprehensive RGB-based grading there are better tools
supplied with Lightworks which supply a wide range of colour grading tools.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 2AxisVectorBalance.fx
//
// Modified 16 June 2016 by jwrl.
// Reinstated hue adjustment.  Taken out of the original effect because of code "bloat",
// a side effect of the other changes here was that the code became more compact and
// efficient allowing its return, still with a total overall size reduction.
//
// Added U/V gain to the existing U/V offset functions and changed the algorithm used to
// implement the offset.
//
// Signal clipping that could distort colour levels in whites and blacks under adverse
// conditions has been addressed as far as is currently possible.  By its very nature
// there will always be the potential to clip individual RGB levels.
//
// Execution order is now changed.  Gain and pedestal happen prior to anything else.
// Then comes U/V gain and offset, master saturation, white and black desaturation,
// then finally hue.
//
// Since the range of gain adjustment available more than compensates for it, automatic
// luminance tracking has been removed.  It wasn't doing what it was designed to do very
// well and had the potential to add significant distortion.
//
// Cross platform compatibility check 29 July 2017 jwrl.
// Explicitly defined samplers to compensate for cross platform default sampler state
// differences.  Some extra code cleanup to improve efficiency has also been done.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 21 May 2018 jwrl.
// Corrected spurious display of _Crgb and _C_uv arrays as user parameters.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
//
// Modified by LW user jwrl 23 December 2018.
// Changed category and subcategory.
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "2 axis vector balance";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "Designed for fast efficient two-axis colour cast removal";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state {
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Gain
<
   string Group = "Luminance";
   string Description = "Gain";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Gamma
<
   string Group = "Luminance";
   string Description = "Gamma";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Ped
<
   string Group = "Luminance";
   string Description = "Pedestal";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Hue
<
   string Group = "Colour";
   string Description = "Hue";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Sat
<
   string Group = "Colour";
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float wDesat
<
   string Group = "Colour";
   string Description = "White saturate";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float bDesat
<
   string Group = "Colour";
   string Description = "Black saturate";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int BT_ver
<
   string Group = "Vectors";
   string Description = "Colour space";
   string Enum = "BT-601 (SD),BT-709 (HD),Legacy YUV";
> = 1;

float U_gain
<
   string Group = "Vectors";
   string Description = "U/Pb/Cb gain";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float U_offs
<
   string Group = "Vectors";
   string Description = "U/Pb/Cb offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float V_gain
<
   string Group = "Vectors";
   string Description = "V/Pr/Cr gain";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float V_offs
<
   string Group = "Vectors";
   string Description = "V/Pr/Cr offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define UV_SCALE 0.175

#define SAT_RNG  5.0
#define SAT_BRK  4.0
#define SAT_SCL  2.5

#define HALF_PI  1.570796
#define PI       3.141593

#define BLACK    float2(0.0, 1.0).xxxy

float3 _Crgb [] = { { 0.299, 0.587, 0.114 }, { 0.2126, 0.7152, 0.0722 }, { 0.299, 0.587, 0.114 } };

float2 _C_uv [] = { { 0.564, 0.713 }, { 0.539, 0.635 }, { 0.492, 0.877 } };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float  cosHue, sinHue;
   float  _gamma = (Gamma > 0.0) ? 1.0 - Gamma * 0.8 : 1.0 - Gamma * 4.0;

   float2 UVval   = _C_uv [BT_ver];

   float3 RGBluma = _Crgb [BT_ver];

   float4 Image  = tex2D (InputSampler, xy);
   float4 retval = saturate ((pow (Image, _gamma) * (1.0 + Gain)) + (Ped / 3.0));

   float luma = dot (retval.rgb, RGBluma);
   float Cb = (((retval.b - luma) * (1.0 + U_gain) * UVval.x) + (U_offs * UV_SCALE)) * (1.0 + Sat);
   float Cr = (((retval.r - luma) * (1.0 + V_gain) * UVval.y) + (V_offs * UV_SCALE)) * (1.0 + Sat);

   retval.r = luma + (Cr / UVval.y);
   retval.b = luma + (Cb / UVval.x);
   retval.g = (luma - dot (retval.rb, RGBluma.rb)) / RGBluma.g;

   float bBreak = saturate (luma * SAT_RNG);
   float wBreak = 1.0 - saturate ((luma * SAT_RNG) - SAT_BRK);

   bBreak = saturate (SAT_SCL * (1.0 - sin (bBreak * HALF_PI)));
   wBreak = saturate (SAT_SCL * (1.0 - sin (wBreak * HALF_PI)));

   retval = lerp (retval, luma.xxxx, bBreak * (1.0 - bDesat));
   retval = lerp (retval, luma.xxxx, wBreak * (1.0 - wDesat));

   sincos ((-Hue * PI), sinHue, cosHue);

   float3 _H = (1.0 - cosHue) / 3.0;

   _H.y  = sqrt (1.0 / 3.0) * sinHue;
   _H.z -= _H.y;
   _H.y += _H.x;
   _H.x += cosHue;

   Image.rgb = saturate ((retval.r * _H) + (retval.g * _H.zxy) + (retval.b * _H.yzx));

   return Image;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique TwoAxisVector
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
