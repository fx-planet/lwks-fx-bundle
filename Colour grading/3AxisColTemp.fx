// @Maintainer jwrl
// @Released 2018-12-04
// @Author khaver
// @Created 2016-06-05
// @see https://www.lwks.com/media/kunena/attachments/6375/3AxisColTemp_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect 3AxisColTemp.fx
//
// 3 Axis Colour Temperature is a simple axis-based colourgrade tool, originally written
// for David Rasberry.  It can adjust Red<>Cyan, Green<>Magenta, Blue<>Yellow (matches
// the vector scope), plus luminance.
//
// Subcategory added by jwrl for version 14 and up 10 Feb 2017
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified by LW user jwrl 4 December 2018.
// Added creation date.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "3 Axis Colour Temperature";
   string Category    = "Colour";
   string SubCategory = "Technical";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Input;

sampler InputSampler = sampler_state { Texture = <Input>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float AmountRC
<
   string Description = "R<>C Amount";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float AmountGM
<
   string Description = "G<>M Amount";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float AmountBY
<
   string Description = "B<>Y Amount";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Luma
<
   string Description = "Luma Adjust";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Descriptions and declarations
//-----------------------------------------------------------------------------------------//

float4 _BlueColour = float4( 0.0, 0.0, 1.0, 1.0 );
float4 _RedColour = float4( 1.0, 0.0, 0.0, 1.0 );
float4 _GreenColour  = float4( 0.0, 1.0, 0.0, 1.0 );
float4 _MagColour  = float4( 1.0, 0.0, 1.0, 1.0 );
float4 _CyanColour  = float4( 0.0, 1.0, 1.0, 1.0 );
float4 _YellowColour  = float4( 1.0, 1.0, 0.0, 1.0 );

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 main( float2 xy1 : TEXCOORD1 ) : COLOR
{
   float4 src = tex2D( InputSampler, xy1 );
   float4 ret;
   float4 chrom = float4(0,0,0,0);
   float Lmin = min(src.r, min(src.g, src.b));
   float Red = src.r - Lmin;
   float Green = src.g - Lmin;
   float Blue = src.b - Lmin;
   float4 color = float4(Red, Green, Blue, Lmin) + 0.5;

   if ( AmountRC > 0.0 )
   {
      chrom +=  (_CyanColour * (AmountRC / 5.0 ));
   }
   else
   {
      chrom += (_RedColour * abs( AmountRC / 5.0 ) );
   }

   if ( AmountGM > 0.0 )
   {
      chrom += (_MagColour * (AmountGM / 5.0 ));
   }
   else
   {
      chrom += (_GreenColour * abs( AmountGM / 5.0 ) );
   }
   if ( AmountBY > 0.0 )
   {
      chrom += (_YellowColour * (AmountBY / 5.0 ));
   }
   else
   {
      chrom += (_BlueColour * abs( AmountBY / 5.0 ) );
   }

   float L2min = min(chrom.r, min(chrom.g, chrom.b));
   float NRed = chrom.r - L2min;
   float NGreen = chrom.g - L2min;
   float NBlue = chrom.b - L2min;
   float4 ncolor = float4(NRed, NGreen, NBlue, L2min);
   ret = color + ncolor;
   Lmin += (Luma / 2.0);
   ret = float4(ret.r + Lmin - 0.5, ret.g + Lmin - 0.5, ret.b + Lmin - 0.5, src.a);

   return ret;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ColourTemp { pass Single_Pass { PixelShader = compile PROFILE main(); } }
