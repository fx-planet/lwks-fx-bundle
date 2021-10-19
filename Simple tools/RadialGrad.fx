// @Maintainer jwrl
// @Released 2021-10-19
// @Author jwrl
// @Created 2020-04-03
// @see https://www.lwks.com/media/kunena/attachments/6375/RadialGrad_640.png

/**
 This generates a radial colour gradient, the radius of which can be adjusted.  The position
 can also be adjusted and the aspect ratio can also be altered.  This allows the geometry to
 be changed from circular to a vertical or horizontal ellipse.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RadialGrad.fx
//
// Version history:
//
// Update 2021-10-19 jwrl.
// Corrected CanSize switch to false.
//
// Updated 2020-11-14 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 2020-05-15 - jwrl.
// Simplified code generally.
// Added a limited range diameter control.
// Relabelled "Centre colour" to "Inner colour".
// Changed aspect ratio correction so that it tracks the output aspect ratio.
//
// Modified 2020-04-04 - jwrl.
// Added aspect ratio correction and a means of varying the amount of correction applied.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Radial gradiant";
   string Category    = "Mattes";
   string SubCategory = "Simple tools";
   string Notes       = "Creates a colour field with a radial gradiant";
   bool CanSize       = false;
> = 0;

//-----------------------------------------------------------------------------------------//
// Declarations and definitons
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

#define EMPTY  0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define PI    3.141592654

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float4 Colour_1
<
   string Group = "Colour range";
   string Description = "Outer colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float4 Colour_2
<
   string Group = "Colour range";
   string Description = "Inner colour";
   bool SupportsAlpha = true;
> = { 0.314, 0.784, 1.0, 1.0 };

float Radius
<
   string Group = "Colour range";
   string Description = "Diameter";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.5;
   float MaxVal = 1.5;
> = 1.0;

float Aspect
<
   string Group = "Colour range";
   string Description = "Aspect ratio 1:x";
   float MinVal = 0.25;
   float MaxVal = 4.0;
> = 1.0;

float Offs_X
<
   string Description = "Gradient centre";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.5;

float Offs_Y
<
   string Description = "Gradient centre";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv0 : TEXCOORD0, float2 uv1 : TEXCOORD1) : COLOR
{
   float2 xy = uv0 - 0.5.xx;

   float ratio = max (Aspect, 0.0001) * _OutputAspectRatio;

   if (ratio < 1.0) xy.x *= ratio;
   else xy.y /= ratio;

   xy /= Radius;
   xy += float2 (1.0 - Offs_X, ((Offs_Y - 0.5) / _OutputAspectRatio) + 0.5);

   float2 mask = sin (saturate (xy) * PI);

   float4 retval = lerp (Colour_1, lerp (Colour_1, Colour_2, mask.x), mask.y);

   return lerp (GetPixel (s_Input, uv1), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique RadialGrad
{
   pass P_1 ExecuteShader (ps_main)
}

