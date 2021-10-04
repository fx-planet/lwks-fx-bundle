// @Maintainer jwrl
// @Released 2021-08-30
// @Author schrauber
// @Created 2017-01-05
// @see https://www.lwks.com/media/kunena/attachments/6375/magnifying_glass_640.png

/**
 This is similar in operation to the regional zoom effect, but instead of non-linear
 distortion a linear zoom is performed.  It can be used as-is, or fed into another
 effect to generate borders and/or generate shadows or blend with another background.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MagnifyingGlass.fx
//
// Version history:
//
// Update 2021-08-30 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Magnifying glass";
   string Category    = "DVE";
   string SubCategory = "Distortion";
   string Notes       = "Similar in operation to a bulge effect, but performs a flat linear zoom";
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

#define SetTargetMode(TGT, SMP, MODE) \
                                      \
 texture TGT : RenderColorTarget;     \
                                      \
 sampler SMP = sampler_state          \
 {                                    \
   Texture   = <TGT>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _InputWidthNormalised;
float _OutputAspectRatio; 

//-----------------------------------------------------------------------------------------//
// Standard input preamble for dealing with input compatability issues
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

SetTargetMode (Fg, FgSampler, Mirror);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Parameters, which can be changed by the user in the effects settings.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


int lens
<
   string Description = "Shape";
   string Enum = "Round or elliptical lens,Rectangular lens";
> = 0;


float zoom
<
   string Description = "zoom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;


float Dimension
<
   string Group ="Glass size";
   string Description = "Dimensions";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float AspectRatio
<
   string Group ="Glass size";
   string Description = "Aspect Ratio";
   float MinVal = 0.1;
   float MaxVal = 10.0;
> = 1;


float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//--------------------------------------------------------------
// Pixel Shader
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//--------------------------------------------------------------

// This preamble pass means that we handle rotated video correctly.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Input, uv); }

float4 Zoom (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   if (Overflow (uv1)) return EMPTY;

   float2 xydist = float2 (Xcentre, 1.0 - Ycentre) - uv2; 									// XY Distance between the current position to the adjusted effect centering

   float dimensions = Dimension * _InputWidthNormalised;    // Corrects Dimension scale - jwrl
   float distance = length (float2 (xydist.x / AspectRatio, (xydist.y / _OutputAspectRatio) * AspectRatio)); 		// Hypotenuse of xydistance, the shortest distance between the currently processed pixels to the center of the distortion.
 
   distance /= _InputWidthNormalised;    // Corrects distance scale - jwrl

   if ((distance > dimensions) && (lens == 0)) return float4 (tex2D (FgSampler, uv2).rgb, 0.0);						// Background, round lens
 
   if (((abs(xydist.x) / AspectRatio > dimensions)
      || (abs(xydist.y) * AspectRatio > dimensions))
      && (lens == 1))
      return float4 (tex2D (FgSampler, uv2).rgb, 0.0);											// Background, rectangular lens

 return tex2D (FgSampler, zoom * xydist + uv2);										// Zoom  (lens)
} 



//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------

technique SampleFxTechnique
{
   pass Pin < string Script = "RenderColorTarget0 = Fg;"; > ExecuteShader (ps_initInp)
   pass SinglePass ExecuteShader (Zoom)
}

