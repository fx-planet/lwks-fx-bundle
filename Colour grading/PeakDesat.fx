//--------------------------------------------------------------//
// Lightworks user effect PeakDesat.fx
//
// Created by LW user jwrl 6 April 2016.
// @Author: jwrl
// @CreationDate: "6 April 2016"
//
// This is a tool designed to quickly and easily desaturate
// whites and blacks, which can easily become contaminated
// during other grading operations.  The turnover point and
// blend smoothness are also adjustable.
//
// Cross platform compatibility check 30 July 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Peak desaturate";
   string Category    = "Colour";
   string SubCategory = "Technical";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

// Magic numbers for Y matrix calculation

#define Rmatrix   1.0191
#define Bmatrix   0.3904
#define matScale  3.4095
#define pSc       1.5

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 main (float2 xy : TEXCOORD1) : COLOR
{
   float4 RGBval = tex2D (FgSampler, xy);

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

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique deSat
{
   pass Single_Pass
   {
      PixelShader = compile PROFILE main ();
   }
}

