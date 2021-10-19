// @Maintainer jwrl
// @Released 2021-10-19
// @Author jwrl
// @Created 2021-10-19
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
// Rewrite 2021-10-19 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

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
   if (Overflow (uv)) return EMPTY;

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

technique WhiteBalance { pass P_1 ExecuteShader (ps_main) }

