// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// GreyscaleTest.fx written by jwrl 1 April 2017.
// @Author jwrl
// @Created "1 April 2017"
//
// Inspired by an earlier version, this is a complete rewrite
// from the ground up.  There are a total of ten unique
// patterns which can be generated.  They are three versions
// of simple ten step bars, three of a compound bar pattern,
// two simple grey scales, and two compound grey scales.
// Although it's possible to select both full gamut decimal
// and full gamut hexadecimal versions of both gradients they
// are identical.
//
// The multiple conditional statements of the original version
// have been replaced with a worst case of four.  The bar test
// signals are now produced by indexing into arrays where
// possible.  This has the advantages of speed and simplicity,
// but ps_2.0 constraints mean that the full gamut versions
// are produced by scaling the array indeces.
//
// Bugfix by jwrl 14 July 2017 to correct an issue with Linux/
// Mac versions of the Lightworks effects compiler that caused
// the two bar patterns not to display.  The fix is to change
// TEXCOORD1 declarations to TEXCOORD0.
//
// A second known bug correction addresses another issue with
// the compiler.  It doesn't like const declarations outside
// shaders on the Mac/Linux platforms.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Test greyscale";
   string Category    = "User";
   string SubCategory = "Broadcast";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int TestType
<
   string Description = "Bar scale";
   string Enum = "BT 709 percentage scale,Full gamut decimal,Full gamut hexadecimal";
> = 0;

int SetTechnique
<
   string Description = "Display type";
   string Enum = "Bars,Composite bars,Gradient,Composite gradient";
> = 1;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

// TestType enumeration indexing

#define BT_709   0
#define FULL     1

// Number of rows possible

#define ROWS     12

// BT.709 black (16) and white (235) definitions

#define BT709_B  0.0627451
#define BT709_W  0.92156863

// BT.709 scale factor to convert 0-255 to 0-219.  This is then offset by 16 to produce 16-235.

#define SCALE709 0.85882353

float _binary [11] = { 0.0, BT709_B, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, BT709_W, 1.0 };
float _BT_709 [11] = { BT709_B, 0.14862745, 0.2345098, 0.32039216, 0.40627451, 0.49215686,
                       0.57803922, 0.66392157, 0.74980392, 0.83568628, BT709_W };

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_bars (float2 uv : TEXCOORD0) : COLOR
{
   float x = uv.x;

   int barIdx = min (floor (x * 11.0), 10);

   if (TestType == BT_709) return float2 (_BT_709 [barIdx], 1.0).xxxy;

   if (TestType == FULL) return float2 (barIdx / 10.0, 1.0).xxxy;

   return float2 (_binary [barIdx], 1.0).xxxy;
}

float4 ps_bars_main (float2 uv : TEXCOORD0) : COLOR
{
   float x = uv.x, y = uv.y;

   int barIdx = abs ((floor (y + 0.5) * 10.0) - min (floor (x * 11.0), 10.0));
   int z = int (floor (min (y, 1.0 - y) * ROWS));

   if (z == 0) return float2 (abs (floor (y + 0.5) - floor (x + 0.5)), 1.0).xxxy;

   if (z == 1) return float2 ((abs (floor (y + 0.5) - floor (x + 0.5)) * SCALE709) + BT709_B, 1.0).xxxy;

   if (TestType == BT_709) return float2 (_BT_709 [barIdx], 1.0).xxxy;

   if (TestType == FULL) return float2 (barIdx / 10.0, 1.0).xxxy;

   return float2 (_binary [barIdx], 1.0).xxxy;
}

float4 ps_grad (float2 uv : TEXCOORD0) : COLOR
{
   float x = uv.x;

   if (TestType == BT_709) return float2 ((x * SCALE709) + BT709_B, 1.0).xxxy;

   return float2 (x, 1.0).xxxy;
}

float4 ps_grad_main (float2 uv : TEXCOORD0) : COLOR
{
   float x = uv.x;
   float y = uv.y;

   int z = int (floor (min (y, 1.0 - y) * ROWS));

   if (z == 0) return float2 (abs (floor (y + 0.5) - floor (x + 0.5)), 1.0).xxxy;

   if (z == 1) return float2 ((abs (floor (y + 0.5) - floor (x + 0.5)) * SCALE709) + BT709_B, 1.0).xxxy;

   if (TestType == BT_709) return float2 ((abs (floor (y + 0.5) - x) * SCALE709) + BT709_B, 1.0).xxxy;

   return float2 (abs (floor (y + 0.5) - x), 1.0).xxxy;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Bars
{
   pass P_1
   { PixelShader = compile PROFILE ps_bars (); }
}

technique CompositeBars
{
   pass P_1
   { PixelShader = compile PROFILE ps_bars_main (); }
}

technique Grad
{
   pass P_1
   { PixelShader = compile PROFILE ps_grad (); }
}

technique CompositeGrad
{
   pass P_1
   { PixelShader = compile PROFILE ps_grad_main (); }
}

