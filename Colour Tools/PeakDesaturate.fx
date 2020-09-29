// @Maintainer jwrl
// @Released 2020-09-29
// @Author jwrl
// @Created 2016-04-06
// @see https://www.lwks.com/media/kunena/attachments/6375/PeakDesat_640.png

/**
 This is a tool designed to quickly and easily desaturate whites and blacks, which can
 easily become contaminated during other grading operations.  The turnover point and
 blend smoothness of both black and white desaturation are adjustable.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PeakDesaturate.fx
//
// Version history:
//
// Update 2020-09-29 jwrl.
// Revised header block.
//
// Modified jwrl 2020-08-05
// Clamped video levels on entry to the effect.  Floating point processing can result in
// video level overrun which can impact exports poorly.
//
// Modified by LW user jwrl 23 December 2018.
// Changed subcategory.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Cross platform compatibility check 30 July 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Peak desaturate";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "Quickly and easily desaturate whites and blacks contaminated during other grading operations";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state
{
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

float WhtPnt
<
   string Group = "White";
   string Description = "Turnover";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.5;

float WhtRng
<
   string Group = "White";
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.5;

float WhtDesat
<
   string Group = "White";
   string Description = "Desaturate";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.0;

float BlkPnt
<
   string Group = "Black";
   string Description = "Turnover";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.5;

float BlkRng
<
   string Group = "Black";
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.5;

float BlkDesat
<
   string Group = "Black";
   string Description = "Desaturate";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

// Magic numbers for Y matrix calculation

#define Rmatrix   1.0191
#define Bmatrix   0.3904
#define matScale  3.4095
#define pSc       1.5

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 RGBval = saturate (tex2D (FgSampler, xy));

   // This oversamples the luma value so that we don't get hard contouring.
   // We also get some colour noise reduction without the expense of a blur routine.

   float Blevel = RGBval.g + RGBval.g + Rmatrix * RGBval.r + Bmatrix * RGBval.b;

   float4 LumaValue = float2 (saturate (Blevel / matScale), 1.0).xxxy;

   // Get the turnover point for white desaturation and set the level.

   float Wpoint = (1.0 - WhtPnt) * pSc;
   float Wlevel = clamp (Blevel * Wpoint, 0.0, matScale) - matScale + 1.0;

   Wlevel *= 2.0 - WhtRng;                                  // Expand the range
   Wlevel  = saturate (Wlevel - WhtRng);                    // Legalise it
   Wlevel *= WhtDesat;                                      // Quit with luma level set

   float Bpoint = (1.0 - BlkPnt) * pSc;                     // Turnover point for blacks

   Blevel  = clamp (Blevel * Bpoint, 0.0, matScale);
   Blevel *= 2.0 - BlkRng;
   Blevel  = 1.0 - saturate (Blevel - BlkRng);
   Blevel *= BlkDesat;

   // Desaturate the blacks, then the whites.

   float4 retval = lerp (RGBval, LumaValue, Blevel);
   retval = lerp (retval, LumaValue, Wlevel);

   retval.a = RGBval.a;                                     // Preserve original alpha

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique PeakDesaturate
{
   pass P_1
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
