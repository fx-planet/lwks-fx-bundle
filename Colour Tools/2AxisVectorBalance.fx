// @Maintainer jwrl
// @Released 2021-08-18
// @Author jwrl
// @Created 2021-08-18
// @see https://www.lwks.com/media/kunena/attachments/6375/Two_Axis_Vector_640.png

/**
 This effect was written at the request of David Rasberry.  It's designed for fast efficient
 two-axis YUV-based colour grading.  For comprehensive RGB-based grading there are better
 effects supplied with Lightworks which provide a wide range of colour grading tools.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 2AxisVectorBalance.fx
//
// Version history:
//
// Rewrite 2021-08-18 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "2 axis vector balance";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "Designed for fast efficient two-axis colour cast removal";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

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
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float  cosHue, sinHue;
   float  _gamma = (Gamma > 0.0) ? 1.0 - Gamma * 0.8 : 1.0 - Gamma * 4.0;

   float2 UVval = _C_uv [BT_ver];

   float3 RGBluma = _Crgb [BT_ver];

   float4 Image  = saturate (GetPixel (s_Input, xy));
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
   pass P_1 ExecuteShader (ps_main)
}

