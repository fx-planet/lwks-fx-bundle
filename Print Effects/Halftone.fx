// @Maintainer jwrl
// @Released 2021-10-07
// @Author windsturm
// @Created 2012-12-11
// @see https://www.lwks.com/media/kunena/attachments/6375/FxHalfTone2_640.png

/**
 This effect simulates the dot pattern used in a black and white half-tone print image.
 The colours used for background and dots are user adjustable.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Halftone.fx
//
// Version history:
//
// Update 2021-10-07 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//
// Modified 26 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 5 December 2018 jwrl.
// Added creation date.
// Renamed effect.
// Changed subcategory.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14 update 18 Feb 2017 jwrl - added subcategory to effect header.
//
// Conversion for ps_2_b compliance by Lightworks user jwrl, 4 February 2016.
//
// Original effect "FxHalftone2" (FxHalftone2.fx) by windsturm 2012-12-11.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Halftone";
   string Category    = "Stylize";
   string SubCategory = "Print Effects";
   string Notes       = "Simulates the dot pattern used in a black and white half-tone print image";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
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

#define SQRT_2 1.414214

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, s0);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int toneMode
<
    string Description = "Tone Mode";
    string Enum = "Darkness,Brightness,SourceColor";
> = 0;

int lumaMode
<
    string Description = "Luma Mode";
    string Enum = "BT709,BT470,BT601";
> = 0;

float centerX
<
    string Description = "Center";
    string Flags = "SpecifiesPointX";
    float MinVal = 0.0;
    float MaxVal = 1.0;
> = 0.5;

float centerY
<
    string Description = "Center";
    string Flags = "SpecifiesPointY";
    float MinVal = 0.0;
    float MaxVal = 1.0;
> = 0.5;

float dotSize
<
    string Description = "Size";
    float MinVal = 0.0;
    float MaxVal = 1.0;
> = 0.01;

float Angle
<
    string Description = "Angle";
    float MinVal = 0.0;
    float MaxVal = 360.0;
> = 0.0;

float4 colorFG
<
    string Description = "Foreground";
    string Group       = "Color";
    bool SupportsAlpha = true;
> = { 0.0, 0.0, 0.0, 1.0 };

float4 colorBG
<
    string Description = "Background";
    string Group       = "Color";
    bool SupportsAlpha = true;
> = { 1.0, 1.0, 1.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2x2 RotationMatrix (float rotation)
{
   float c, s;

   sincos (rotation, s, c);

   return float2x2 (c, -s, s ,c);
}

float4 half_tone (float2 uv, float s, float angle, float a)
{
   float2 xy  = uv;
   float2 asp = float2 (1.0, _OutputAspectRatio);

   float2 centerXY = float2 (centerX, 1.0 - centerY);
   float2 pointXY  = mul ((xy - centerXY) / asp, RotationMatrix (radians (angle)));

   pointXY += (s / 2.0);
   pointXY = round (pointXY / dotSize) * dotSize;
   pointXY = mul (pointXY, RotationMatrix (radians (-angle)));
   pointXY = pointXY * asp + centerXY;

   float4 pointCol = tex2D (s0, pointXY);

   // xy slide

   float2 slideXY = mul (float2 ((s) / SQRT_2, 0.0), RotationMatrix (radians ((angle + a) * -1.0)));
   slideXY *= asp;

   float luma;

   if (lumaMode == 0) { luma = dot (float3 (0.212649, 0.715169, 0.072182), pointCol.rgb); }
   else if (lumaMode == 1) { luma = dot (float3 (0.222015, 0.706655, 0.071330), pointCol.rgb); }
   else luma = dot (float3 (0.298912, 0.586611, 0.114478), pointCol.rgb);
    
   float4 fgColor = colorFG;

   if (toneMode == 2) fgColor = pointCol;

   xy += slideXY;
   asp *= dotSize * ((toneMode == 0) ? 1.0 - luma : luma);

   float2 aspectAdjustedpos = ((xy - pointXY) / asp) + pointXY;

   return (distance (aspectAdjustedpos, pointXY) < 0.5) ? fgColor : (-1.0).xxxx;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   if (dotSize <= 0.0) return tex2D (s0, uv2);

   float4 ret1 = half_tone (uv2, 0.0, Angle, 0.0);
   float4 ret2 = half_tone (uv2, dotSize, Angle, 45.0);

   float4 retval = (ret1.a > -1.0 || ret2.a > -1.0) ? max (ret1, ret2) : colorBG;

   return Overflow (uv1) ? EMPTY : retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Halftone
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main)
}

