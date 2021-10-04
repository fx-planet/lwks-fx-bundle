// @Maintainer jwrl
// @Released 2021-08-18
// @Author khaver
// @Created 2016-06-05
// @see https://www.lwks.com/media/kunena/attachments/6375/3AxisColTemp_640.png

/**
 3 axis colour balance is a simple axis-based colourgrade tool, originally written for
 David Rasberry.  It can adjust Red<>Cyan, Green<>Magenta, Blue<>Yellow, all of which
 match the vector scope, as well as luminance.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 3AxisColourBalance.fx
//
// Version history:
//
// Update 2021-08-18 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "3 axis colour balance";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "A three axis-based RGB-CMY colourgrade tool";
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

float4 _BlueColor = float4 (0.0, 0.0, 1.0, 1.0);
float4 _RedColor = float4 (1.0, 0.0, 0.0, 1.0);
float4 _GreenColor = float4 (0.0, 1.0, 0.0, 1.0);
float4 _MagColor = float4 (1.0, 0.0, 1.0, 1.0);
float4 _CyanColor = float4 (0.0, 1.0, 1.0, 1.0);
float4 _YellowColor = float4 (1.0, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 main( float2 xy1 : TEXCOORD1 ) : COLOR
{
   float4 src = saturate (GetPixel (s_Input, xy1));
   float4 ret, chrom;

   float Lmin = min (src.r, min (src.g, src.b));
   float Red = src.r - Lmin;
   float Green = src.g - Lmin;
   float Blue = src.b - Lmin;

   float4 color = float4 (Red, Green, Blue, Lmin) + 0.5;

   chrom  = (AmountRC > 0.0) ? (_CyanColor * (AmountRC / 5.0)) : (_RedColor * abs (AmountRC / 5.0));
   chrom += (AmountGM > 0.0) ? (_MagColor * (AmountGM / 5.0)) : (_GreenColor * abs (AmountGM / 5.0));
   chrom += (AmountBY > 0.0) ? (_YellowColor * (AmountBY / 5.0)) : (_BlueColor * abs (AmountBY / 5.0));

   float L2min = min(chrom.r, min(chrom.g, chrom.b));
   float NRed = chrom.r - L2min;
   float NGreen = chrom.g - L2min;
   float NBlue = chrom.b - L2min;

   float4 ncolor = float4 (NRed, NGreen, NBlue, L2min);

   ret = color + ncolor;
   Lmin += (Luma / 2.0);
   ret = float4 (ret.r + Lmin - 0.5, ret.g + Lmin - 0.5, ret.b + Lmin - 0.5, src.a);

   return saturate (ret);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ColorTemp { pass Single_Pass ExecuteShader (main) }

