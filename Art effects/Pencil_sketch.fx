// @Maintainer jwrl
// @Released 2018-12-23
// @Author khaver
// @Author Daniel Taylor
// @Created 2018-05-24
// @see https://www.lwks.com/media/kunena/attachments/6375/PencilSketch_640.png

/**
Pencil Sketch (PencilSketchFx.fx) is a really nice effect that creates a pencil sketch
from your image.  As well as the ability to adjust saturation, gamma, brightness and
gain, it's possible to overlay the result over a background layer.  What isn't possible
is to compile this version under versions of Windows Lightworks earlier than 14.5.
There is a legacy version available for users in that position.
*/

//-----------------------------------------------------------------------------------------//
// Original Shadertoy author:
// Daniel Taylor (culdevu) (2017-06-09) https://www.shadertoy.com/view/ldXfRj
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------------------------------------------//
// PencilSketchFx.fx for Lightworks was adapted by user khaver 24 May 2018 from original
// code by the above author taken from the Shadertoy website:
// https://www.shadertoy.com/view/ldXfRj
//
// This adaptation retains the same Creative Commons license shown above.  It cannot be
// used for commercial purposes.
//
// note: code comments are from the original author(s).
//
// Modified 23 December 2018 jwrl.
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Pencil Sketch";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "Pencil sketch effect with sat/gamma/cont/bright/gain/overlay/alpha controls";
> = 0;

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

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
	AddressU = Wrap;
	AddressV = Wrap;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float AMOUNT
<
   string Description = "Color";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Saturation
<
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;


float MasterGamma
<
   string Description = "Gamma";
   float MinVal = 0.10;
   float MaxVal = 4.00;
> = 1.00;

float MasterContrast
<
   string Description = "Contrast";
   float MinVal = 0.00;
   float MaxVal = 5.00;
> = 1.0;

float MasterBrightness
<
   string Description = "Brightness";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float MasterGain
<
   string Description = "Gain";
   float MinVal = 0.00;
   float MaxVal = 4.00;
> = 1.0;

float Range
<
   string Description = "Range";
   float MinVal = 0.00;
   float MaxVal = 20.00;
> = 10.0;

float EPS
<
   string Description = "Stroke";
   float MinVal = 1e-10;
   float MaxVal = 5.0;
> = 1.0;

float MAGIC_GRAD_THRESH
<
   string Description = "Gradient Threshold";
   float MinVal = 0.0;
   float MaxVal = 0.1;
> = 0.01;

float MAGIC_SENSITIVITY
<
   string Description = "Sensitivity";
   float MinVal = 0.0;
   float MaxVal = 50.0;
> = 1.0;

bool ALPHA
<
   string Description = "Add Alpha";
> = false;

float MAGIC_COLOR
<
   string Description = "Overlay Amount";
   string Group = "Source Video";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

bool GREY
<
   string Description = "Greyscale";
   string Group = "Source Video";
> = false;

//-----------------------------------------------------------------------------------------//

float _OutputWidth = 1;
float _OutputHeight = 1;

//-----------------------------------------------------------------------------------------//

#define PI2 6.28318530717959
#define RANGE 16.
#define STEP 2.
#define ANGLENUM 4.

//---------------------------------------------------------
// Your usual image functions and utility stuff
//---------------------------------------------------------
float4 getCol(float2 pos)
{
    float2 uv = pos / float2(_OutputWidth,_OutputHeight);
    return tex2D(InputSampler, uv);
}

float getVal(float2 pos)
{
    float4 c=getCol(pos);
    return dot(c.xyz, float3(0.2126, 0.7152, 0.0722));
}

float2 getGrad(float2 pos, float eps)
{
   	float2 d=float2(eps,0);
    return float2(
        getVal(pos+d.xy)-getVal(pos-d.xy),
        getVal(pos+d.yx)-getVal(pos-d.yx)
    )/eps/2.;
}

void pR(inout float2 p, float a) {
	p = cos(a)*p + sin(a)*float2(p.y, -p.x);
}

//---------------------------------------------------------
// Let's do this!
//---------------------------------------------------------
float4 mainImage( float2 fragCoord : TEXCOORD1 ) : COLOR
{
	float2 iResolution = float2(_OutputWidth,_OutputHeight);
	float4 fragColor;
    float2 pos = fragCoord * iResolution;
    float weight = 1.0;

    for (float j = 0.; j < ANGLENUM; j += 1.)
    {
        float2 dir = float2(1, 0);
        pR(dir, j * PI2 / (EPS * ANGLENUM));

        float2 grad = float2(-dir.y, dir.x);

        for (float i = -RANGE; i <= RANGE; i += STEP)
        {
            float2 pos2 = pos + normalize(dir)*i;

            // video texture wrap can't be set to anything other than clamp  (-_-)
            if (pos2.y < 0. || pos2.x < 0. || pos2.x > iResolution.x || pos2.y > iResolution.y)
                continue;

            float2 g = getGrad(pos2, 1.);
            if (length(g) < MAGIC_GRAD_THRESH)
                continue;

            weight -= pow(abs(dot(normalize(grad), normalize(g))), MAGIC_SENSITIVITY) / floor((2. * ceil(Range) + 1.) / STEP) / ANGLENUM;
        }
    }
	float4 col;
	if (!GREY) col = getCol(pos);

	else {float grey = getVal(pos); col = float4(grey,grey,grey,grey);}

    float4 background = lerp(col, float4(1,1,1,1), 1.0 - MAGIC_COLOR);

    fragColor = lerp(float4(0,0,0,0), background, weight);
	fragColor = ( ( ( ( pow( fragColor, 1 / MasterGamma ) * MasterGain ) + MasterBrightness ) - 0.5 ) * MasterContrast ) + 0.5;

	float4 fg = tex2D( InputSampler, fragCoord );
	float4 bg = fragColor;

   float4 result;

   if ( bg.r < 0.5 )
      result.r = 2.0 * fg.r * bg.r;
   else
      result.r = 1.0 - ( 2.0 * ( 1.0 - fg.r ) * ( 1.0 - bg.r ) );

   if ( bg.g < 0.5 )
      result.g = 2.0 * fg.g * bg.g;
   else
      result.g = 1.0 - ( 2.0 * ( 1.0 - fg.g ) * ( 1.0 - bg.g ) );

   if ( bg.b < 0.5 )
      result.b = 2.0 * fg.b * bg.b;
   else
      result.b = 1.0 - ( 2.0 * ( 1.0 - fg.b ) * ( 1.0 - bg.b ) );

   result.rgb = lerp( bg.rgb, result.rgb, fg.a * AMOUNT );
   if (!ALPHA) result.a   = 1.0;
   else result.a = 1.0 - dot(result.rgb, float3(0.33333,0.33334,0.33333));

   float3 avg = ( result.r + result.g + result.b ) / 3.0;
   result.rgb = avg + ( ( result.rgb - avg ) * Saturation );

   return result;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Pencil
{
   pass Pass1
   {
      PixelShader = compile PROFILE mainImage ();
   }
}
