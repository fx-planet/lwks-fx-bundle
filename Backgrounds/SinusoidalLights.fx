// @Maintainer jwrl
// @Released 2021-09-04
// @Author baopao
// @Created 2020-11-28
// @see https://www.lwks.com/media/kunena/attachments/6375/SineLights_640.png

/**
 Sinusoidal lights is a semi-abstract pattern generator created for Mac and Linux systems
 by Lightworks user baopao.  This version has been converted for cross-platform use by
 Lightworks user jwrl.  Because this backgrounds is newly created media it is be produced
 at the sequence resolution. This means that any background video will also be locked to
 that resolution.

 NOTE: Backgrounds are newly created media and are produced at the sequence resolution.
 They are then cropped to the background resolution.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SinusoidalLights.fx
//
// Based on: http://glslsandbox.com/e#9996.0, conversion for Lightworks Linux/Mac by
// baopao.  Windows conversion of baopao's code by jwrl.
//
// Version history:
//
// Update 2021-09-04 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Sinusoidal lights";
   string Category    = "Matte";
   string SubCategory = "Backgrounds";
   string Notes       = "A pattern generator that creates stars in Lissajou curves";
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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
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

float _Progress;

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

DefineTarget (Img,  Image);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Num
<
   string Description = "Num";
   float MinVal = 0.0;
   float MaxVal = 400;
> = 200;

float Speed
<
   string Description = "Speed";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 5.0;

float Scale
<
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.0;
> = 1;

float Size
<
   string Description = "Size";
   float MinVal = 1;
   float MaxVal = 20;
> = 8;

float CentreX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ResX
<
   string Description = "ResX";
   float MinVal = 0.01;
   float MaxVal = 2.0;
> = 0.2;

float ResY
<
   string Description = "ResY";
   float MinVal = 0.01;
   float MaxVal = 2.0;
> = 0.48;

float Sine
<
   string Description = "Sine";
   float MinVal = 0.01;
   float MaxVal = 12.0;
> = 8.00;

float Curve
<
   string Description = "Curve";
   float MinVal = 0.0;
   float MaxVal = 150.0;
> = 4.00;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 range_adjust (float2 uv)
{
   float2 xy = uv;

   if (_OutputAspectRatio <= 1.0) {
      xy.x = (xy.x - CentreX - 0.5) * _OutputAspectRatio;
      xy.y +=  CentreY;

      if (_OutputAspectRatio < 1.0) {
         xy.y -= 0.5;
         xy   *= _OutputAspectRatio;
         xy.y += 0.5;
      }

      xy.x += 0.5;
   }
   else {
      xy.x -= CentreX;
      xy.y = (xy.y + CentreY - 0.5) / _OutputAspectRatio;

      if (_OutputAspectRatio < 1.0) {
         xy.x -= 0.5;
         xy   /= _OutputAspectRatio;
         xy.x += 0.5;
      }

      xy.y += 0.5;
   }

   return xy;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This preamble pass means that we handle rotated video correctly.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Input, uv); }

float4 ps_main (float2 uv0 : TEXCOORD, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 retval = tex2D (Image, uv2);

   float2 position;
   float2 vidPoint = range_adjust (uv0);

   float crv  = 0.0;
   float size = Scale / ((20.0 - Size) * 100.0);
   float sum  = 0.0;
   float time = _Progress * Speed;

   for (int i = 0; i < Num; ++i) {
      position.x = (sin ((Sine * time) + crv) * ResX * Scale) + 0.5;
      position.y = (sin (time) * ResY * Scale) + 0.5;

      sum  += size / length (vidPoint - position);
      crv  += Curve;
      time += 0.2;
    }

   return lerp (retval, min (sum, 1.0).xxxx, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SinglePass
{
   pass Pin < string Script = "RenderColorTarget0 = Img;"; > ExecuteShader (ps_initInp)
   pass Single_Pass ExecuteShader (ps_main)
}

