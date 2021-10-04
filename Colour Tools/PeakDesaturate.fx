// @Maintainer jwrl
// @Released 2021-08-18
// @Author jwrl
// @Created 2021-08-18
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
// Rewrite 2021-08-18 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Peak desaturate";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "Quickly and easily desaturate whites and blacks contaminated during other grading operations";
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

// Magic numbers for Y matrix calculation

#define Rmatrix   1.0191
#define Bmatrix   0.3904
#define matScale  3.4095
#define pSc       1.5

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 RGBval = saturate (GetPixel (s_Input, xy));

   // This oversamples the luma value so that we don't get hard contouring.
   // We also get some colour noise reduction without the expense of a blur routine.

   float Blevel = (RGBval.g * RGBval.g) + (Rmatrix * RGBval.r) + (Bmatrix * RGBval.b);

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
   pass P_1 ExecuteShader (ps_main)
}

