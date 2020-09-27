// @Maintainer jwrl
// @Released 2020-09-27
// @Author windsturm
// @Created 2012-06-16
// @see https://www.lwks.com/media/kunena/attachments/6375/FxColorHalftone2_640.png

/**
 This effect emulates the dot pattern of a colour half-tone print image.  The colours used
 for background and dots are user adjustable.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourHalftone.fx
//
// Original effect "FxColorHalftone2" (FxColorHalftone2.fx) by windsturm.
//
// Version history:
//
// Update 2020-09-27 jwrl.
// Revised header block.
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
// Cross platform compatibility check 3 August 2017 jwrl.
// Explicitly defined float3 and float4 variables to address the behaviour differences
// between the D3D and Cg compilers.
//
// Version 14 update 18 Feb 2017 jwrl - added subcategory to effect header.
//
// This conversion for ps_2_b compliance by Lightworks user jwrl, 4 February 2016.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Colour halftone";
   string Category    = "Stylize";
   string SubCategory = "Print Effects";
   string Notes       = "Emulates the dot pattern of a colour half-tone print image";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
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

float angleC
<
   string Description = "Cyan";
   string Group       = "Angle";
   float MinVal = 0.0;
   float MaxVal = 90.0;
> = 15.0;

float angleM
<
   string Description = "Magenta";
   string Group       = "Angle";
   float MinVal = 0.0;
   float MaxVal = 90.0;
> = 75.0;

float angleY
<
   string Description = "Yellow";
   string Group       = "Angle";
   float MinVal = 0.0;
   float MaxVal = 90.0;
> = 0.0;

float angleK
<
   string Description = "blacK";
   string Group       = "Angle";
   float MinVal = 0.0;
   float MaxVal = 90.0;
> = 40.0;

float4 colorC
<
   string Description = "Cyan";
   string Group       = "Color";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 1.0, 1.0 };

float4 colorM
<
   string Description = "Magenta";
   string Group       = "Color";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 1.0, 1.0 };

float4 colorY
<
   string Description = "Yellow";
   string Group       = "Color";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 0.0, 1.0 };

float4 colorK
<
   string Description = "blacK";
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

#define SQRT_2 1.414214

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2x2 RotationMatrix (float rotation)  
{
   float c, s;

   sincos (rotation, s, c);

   return float2x2 (c, -s, s, c);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 half_tone (float2 uv, float i, float s, float angle, float a)
{
   float2 xy = uv;
   float2 asp = float2 (1.0, _OutputAspectRatio);
   float2 centerXY = float2 (centerX, 1.0 - centerY);

   float2 pointXY = mul ((xy - centerXY) / asp, RotationMatrix (radians (angle)));

   pointXY = pointXY + (s / 2.0);
   pointXY = round (pointXY / dotSize) * dotSize;
   pointXY = mul (pointXY, RotationMatrix (radians (-angle)));
   pointXY = pointXY * asp + centerXY;

   float3 cmyColor = (1.0.xxx - tex2D (s0, pointXY).rgb);           // simplest conversion

   float k = min (min (min (1.0, cmyColor.x), cmyColor.y), cmyColor.z);

   float4 cmykColor = float4 ((cmyColor - k.xxx) / (1.0 - k), k);

   //xy slide

   float2 slideXY = mul (float2 ((s) / SQRT_2, 0.0), RotationMatrix (radians ((angle + a) * -1.0)));
   slideXY *= asp;

   float cmykluma [4] = { cmykColor.w, cmykColor.x, cmykColor.y, cmykColor.z };
   float4 cmykcol [4] = { colorK, colorC, colorM, colorY };

   xy += slideXY;
   asp *= (dotSize * cmykluma [i]);

   float2 aspectAdjustedpos = ((xy - pointXY) / asp) + pointXY;

   float dist = distance (aspectAdjustedpos, pointXY);

   if (dist < 0.5) return cmykcol [i];

   return (-1.0).xxxx;
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 source = tex2D (s0, xy);

   if (dotSize <= 0.0) { return source; }

   float cmykang [4] = {angleK, angleC, angleM, angleY};

   float4 ret = colorBG;

   float4 ret1 = half_tone (xy, 0, 0.0, cmykang [0], 0.0);
   float4 ret2 = half_tone (xy, 0, dotSize, cmykang [0], 45.0);

   if (ret1.a > -1.0 || ret2.a > -1.0) { ret *=  max (ret1, ret2); }

   ret1 = half_tone (xy, 1, 0.0, cmykang [1], 0.0);
   ret2 = half_tone (xy, 1, dotSize, cmykang [1], 45.0);

   if (ret1.a > -1.0 || ret2.a > -1.0) { ret *=  max (ret1, ret2); }

   ret1 = half_tone (xy, 2, 0.0, cmykang [2], 0.0);
   ret2 = half_tone (xy, 2, dotSize, cmykang [2], 45.0);

   if (ret1.a > -1.0 || ret2.a > -1.0) { ret *=  max (ret1, ret2); }

   ret1 = half_tone (xy, 3, 0.0, cmykang [3], 0.0);
   ret2 = half_tone (xy, 3, dotSize, cmykang [3], 45.0);

   if (ret1.a > -1.0 || ret2.a > -1.0) { ret *=  max (ret1, ret2); }

   return ret;
}


technique ColourHalftone
{
   pass pass1
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
