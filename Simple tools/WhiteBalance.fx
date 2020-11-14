// @Maintainer jwrl
// @Released 2020-11-14
// @Author jwrl
// @Created 2020-04-23
// @see https://www.lwks.com/media/kunena/attachments/6375/WhiteBalance_640.png

/**
 This is a simple black and white balance utility.  To use it, first sample the point that
 you want to use as a white reference with the eyedropper, then get the black reference
 point.  Switch off "Select white and black reference points" and set up the white and
 black levels.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhiteBalance.fx
//
// Version history:
//
// Updated 2020-11-14 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified jwrl 2020-09-29
// Clamped video levels on exit from the effect.  Floating point processing can result
// in video level overrun which can impact exports poorly.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "White and black balance";
   string Category    = "Colour";
   string SubCategory = "Simple tools";
   string Notes       = "A simple black and white balance utility";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool Reference
<
   string Description = "Select white and black reference points";
> = true;

float4 WhitePoint
<
   string Group = "Reference points";
   string Description = "White";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 1.0, -1.0 };

float4 BlackPoint
<
   string Group = "Reference points";
   string Description = "Black";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.0, -1.0 };

float WhiteLevel
<
   string Group = "Target levels";
   string Description = "White";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.5;
   float MaxVal = 1.5;
> = 1.0;

float BlackLevel
<
   string Group = "Target levels";
   string Description = "Black";
   string Flags = "DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 0.5;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   if (!Reference) {
      float alpha = retval.a;

      // Get the black and white reference points

      retval = ((retval - BlackPoint) / WhitePoint);

      // Convert the black and white reference values to the target values

      retval = ((retval * WhiteLevel) + BlackLevel.xxxx);

      retval.a = alpha;
   }

   return saturate (retval);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WhiteBalance
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
