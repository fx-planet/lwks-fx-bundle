// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2016-06-05
// @see https://www.lwks.com/media/kunena/attachments/6375/TwoAxis_640.png

/**
This effect was written at the request of David Rasberry.  It's designed for fast efficient
two-axis colour cast removal.  For more sophisticated grading there are better tools supplied
with Lightworks which give precise colour correction.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 2AxisColourBalance.fx
//
// The basic idea is from Editshare's colour temperature tool, but this implementation
// is my own.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
//
// Modified by LW user jwrl 23 December 2018.
// Changed subcategory.
// Changed name from TwoAxis.fx
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "2 axis colour balance";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "Designed for fast efficient red-blue and green-magenta colour cast removal";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state
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

float redBlue
<
   string Description = "Red-blue";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float greenMagenta
<
   string Description = "Green-magenta";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float whiteDesat
<
   string Description = "White desaturate";
   float MinVal = -1.0;
   float MaxVal = 0.0;
> = 0.0;

float blackDesat
<
   string Description = "Black desaturate";
   float MinVal = -1.0;
   float MaxVal = 0.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define R_VALUE   0.2989
#define G_VALUE   0.5866
#define B_VALUE   0.1145

#define RB_SCALE  0.25
#define GM_SCALE  0.1333

#define SAT_RANGE 5.0
#define SAT_BREAK 4.0
#define SAT_SCALE 2.5

#define HALF_PI   1.570796

float4 _RedCorrect = float4 (0.93, 0.38, 0.0, 1.0);
float4 _GrnCorrect = float4 (0.0, 1.0, 0.0, 1.0);
float4 _BluCorrect = float4 (0.0, 0.38, 0.93, 1.0);
float4 _MagCorrect = float4 (1.0, 0.0, 1.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 Image  = tex2D (InputSampler, xy);
   float4 retval = (redBlue > 0.0) ? lerp (Image, _BluCorrect, redBlue * RB_SCALE)
                                   : lerp (_RedCorrect, Image, 1.0 + (redBlue * RB_SCALE));

   retval = (greenMagenta > 0.0) ? lerp (retval, _MagCorrect, greenMagenta * GM_SCALE)
                                 : lerp (_GrnCorrect, retval, 1.0 + (greenMagenta * GM_SCALE));

   float rawLuma  = (Image.r * R_VALUE) + (Image.g * G_VALUE) + (Image.b * B_VALUE);
   float procLuma = (retval.r * R_VALUE) + (retval.g * G_VALUE) + (retval.b * B_VALUE);

   float whtBreak = 1.0 - saturate (rawLuma * SAT_RANGE - SAT_BREAK);
   float blkBreak = saturate (rawLuma * SAT_RANGE);

   whtBreak = saturate (SAT_SCALE * (1.0 - sin (whtBreak * HALF_PI)));
   blkBreak = saturate (SAT_SCALE * (1.0 - sin (blkBreak * HALF_PI)));

   retval -= (procLuma - rawLuma);
   retval = lerp (retval, rawLuma.xxxx, whtBreak * abs (whiteDesat));
   retval = lerp (retval, rawLuma.xxxx, blkBreak * abs (blackDesat));

   retval.a = Image.a;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique TwoAxisColourBalance
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
