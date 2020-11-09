// @Maintainer jwrl
// @Released 2020-11-09
// @Author Renaud Bédard
// @Author Tanner Helland
// @Author Ian Taylor
// @Created 2019-06-15
// @see https://www.lwks.com/media/kunena/attachments/6375/ALE_SmoothChroma_640.png

/**
 This effect adjusts the colour balance of the input in degrees Kelvin.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourTemp.fx
//
// Ported by Renaud Bédard (@renaudbedard) from original code from Tanner Helland
// http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/
//
// Colour space functions translated from HLSL versions on Chilli Ant (by Ian Taylor)
// http://www.chilliant.com/rgb2hsv.html
//
// licensed and released under Creative Commons 3.0 Attribution
// https://creativecommons.org/licenses/by/3.0/
//
// Version history:
//
// Update 2020-11-09 jwrl:
// Added CanSize switch for LW 2021 support.
//
// Modified jwrl 2020-08-05
// Clamped video levels on entry to and exit from the effect.  Floating point processing
// can result in video level overrun which can impact exports poorly.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Colour temp K";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "This trims the colour temperature in degrees Kelvin";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float ColourTemp
<
   string Description = "Temp Kelvin";
   float MinVal = 1500;
   float MaxVal = 15000;
> = 6500;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LUMINANCE_PRESERVATION 0.75

#define EPSILON 1e-10

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tempRGB (float col_temp)         // ColorTemperatureToRGB
{
   float4 retval = 1.0.xxxx;
	
   col_temp = clamp (col_temp, 1500.0, 15000.0) / 100.0;
    
   if (col_temp <= 66.0) {
      retval.g = saturate (0.39008157876901960784 * log (col_temp) - 0.63184144378862745098);
   }
   else {
      float t = col_temp - 60.0;

      retval.r = saturate (1.29293618606274509804 * pow (t, -0.1332047592));
      retval.g = saturate (1.12989086089529411765 * pow (t, -0.0755148492));
   }
    
   if (col_temp <= 19.0) { retval.b = 0.0; }
   else if (col_temp < 66.0) {
      retval.b = saturate (0.54320678911019607843 * log (col_temp - 10.0) - 1.19625408914);
   }

   return retval;
}

float fn_luma (float4 colour)       // Luminance
{
   float fmin = min (min (colour.r, colour.g), colour.b);
   float fmax = max (max (colour.r, colour.g), colour.b);

   return (fmax + fmin) / 2.0;
}

float4 fn_HUEtoRGB (float H)        // HUEtoRGB
{
   float4 retval = 1.0.xxxx;

   retval.r = abs (H * 6.0 - 3.0) - 1.0;
   retval.g = 2.0 - abs (H * 6.0 - 2.0);
   retval.b = 2.0 - abs (H * 6.0 - 4.0);

   return saturate (retval);
}

float4 fn_HSLtoRGB (float4 HSL)     // HSLtoRGB
{
   float4 retval = fn_HUEtoRGB (HSL.x);

   float C = (1.0 - abs (2.0 * HSL.z - 1.0)) * HSL.y;

   retval.rgb = (retval.rgb - 0.5.xxx) * C + HSL.zzz;

   return retval;
}
 
float4 fn_RGBtoHCV (float4 RGB)     // RGBtoHCV
{
   // Based on work by Sam Hocevar and Emil Persson

   float4 P = (RGB.g < RGB.b) ? float4 (RGB.bg, -1.0, 2.0 / 3.0) : float4 (RGB.gb, 0.0, -1.0 / 3.0);
   float4 Q = (RGB.r < P.x) ? float4 (P.xyw, RGB.r) : float4 (RGB.r, P.yzx);

   float C = Q.x - min (Q.w, Q.y);
   float H = abs ((Q.w - Q.y) / (6.0 * C + EPSILON) + Q.z);

   return float4 (H, C, Q.x, 1.0);
}

float4 fn_RGBtoHSL (float4 RGB)     // RGBtoHSL
{
   float4 HCV = fn_RGBtoHCV (RGB);

   float L = HCV.z - HCV.y * 0.5;
   float S = HCV.y / (1.0 - abs (L * 2.0 - 1.0) + EPSILON);

   return float4 (HCV.x, S, L, 1.0);
}

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 image = saturate (tex2D (s_Input, uv));
   float4 blend = lerp (image, image * fn_tempRGB (ColourTemp), Amount);
   float4 resultHSL = fn_RGBtoHSL (blend);
   float4 luma_RGB = fn_HSLtoRGB (float4 (resultHSL.xy, fn_luma (image), resultHSL.w));        

   return saturate (lerp (blend, luma_RGB, LUMINANCE_PRESERVATION));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ColourTemp_1
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}

