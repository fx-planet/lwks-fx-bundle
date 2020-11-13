// @Maintainer jwrl
// @Released 2020-11-13
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
// Update 2020-11-13 jwrl.
// Added Cansize switch for LW 2021 support.
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
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

sampler2D s0 = sampler_state
{
    Texture = <Input>;
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};

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
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.5;

float centerY
<
    string Description = "Center";
    string Flags = "SpecifiesPointY";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.5;

float dotSize
<
    string Description = "Size";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.01;

float Angle
<
    string Description = "Angle";
    float MinVal = 0.00;
    float MaxVal = 360.00;
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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

#define SQRT_2 1.414214

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2x2 RotationMatrix (float rotation)
{
   float c, s;

   sincos (rotation, s, c);

   return float2x2 (c, -s, s ,c);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

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

   float Width = dotSize * ((toneMode == 0) ? 1.0f - luma : luma);

   asp *= Width;
   xy += slideXY;

   float2 aspectAdjustedpos = ((xy - pointXY) / asp) + pointXY;

   if (distance (aspectAdjustedpos, pointXY) < 0.5) return fgColor;

   return (-1.0).xxxx;
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 source = tex2D (s0, xy);

   if (dotSize <= 0.0) return source;

   float4 ret1 = half_tone (xy, 0.0, Angle, 0.0);
   float4 ret2 = half_tone (xy, dotSize, Angle, 45.0);

   if (ret1.a > -1.0 || ret2.a > -1.0) return max (ret1, ret2);

   return colorBG;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Halftone
{
   pass pass1
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
