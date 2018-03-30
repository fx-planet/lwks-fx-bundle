#define WINDOWS

//--------------------------------------------------------------//
// Based on: http://glslsandbox.com/e#9996.0
//
// Conversion for Lightworks Linux/Mac by baopao
//
// Windows conversion of baopao's code by jwrl
//
// This revision for version 14 by jwrl 6 February 2017.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "SineLight";
   string Category    = "Mattes";
   string SubCategory = "Patterns";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler Image = sampler_state { Texture = <Input>; };

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Num
<
   string Description = "Num";
   float MinVal = 0.0;
   float MaxVal = 400;
> = 200;

float Speed
<
   string Description = "Speed";
   float MinVal = 0.00;
   float MaxVal = 10.00;
> = 5.0;

float Scale
<
   string Description = "Scale";
   float MinVal = 0.00;
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
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float CentreY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.00;
   float MaxVal = 1.00;
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

//--------------------------------------------------------------//
// Declarations and definitions
//--------------------------------------------------------------//

float _Progress;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD) : COLOR
{
   float2 position;
   float2 vidPoint = uv + float2 (CentreX, CentreY);

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

   return min (sum, 1.0).xxxx;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

#ifdef WINDOWS

#define PROFILE ps_3_0

#endif

technique SinglePass
{
   pass Single_Pass 
   { 
      PixelShader = compile PROFILE ps_main (); 
   }
}

