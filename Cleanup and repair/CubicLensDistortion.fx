// CubicLensDistortion.fx 
// ----------------------
// (Ported & ripped by Brdloush,  based on "ft-CubicLensDistortion" effect by François Tarlier)
//
//
// Nice effect that can be used for getting rid of heavy fish-eye effect of GoPro HD Hero2 cam.
//
// Following settings worked nicely:
// - Comp Size - X: 100%
// - Comp Size - Y: 100%
// - Scale: 0.88
// - Distortion: -18%
// - Cubic Distortion: 5.75%
//
// Feel free to share/modify or even implement all the functions of original "ft-CubicLensDistortion".
//
// --------------------------------------------------------------------------------------------------------
 
// This Lightworks FX script is based on "ft-CubicLensDistortion" effect by François Tarlier.
//
//
//     
//     Pixel Bender shader written by François Tarlier
//     http://www.francois-tarlier.com/blog/index.php/2010/03/update-cubic-lens-distortion-pixel-bender-shader-for-ae-with-scale-chroamtic-aberration/
//     
//     
//     ------------------------------------------------------------
//     Original Lens Distortion Algorithm from SSontech (Syntheyes)
//     http://www.ssontech.com/content/lensalg.htm
// 
//     r2 = image_aspect*image_aspect*u*u + v*v
//     f = 1 + r2*(k + kcube*sqrt(r2))
//     u' = f*u
//     v' = f*v
//     ------------------------------------------------------------
//
//
//
//
//    Copyright (c) 2010 François Tarlier
//    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//    documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
//    the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
//    to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//    INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//    PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
//    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
//    OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
//    OTHER DEALINGS IN THE SOFTWARE.
//
// Cross platform compatibility check 29 July 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.


//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Cubic lens distortion";       // The title
   string Category    = "Stylize";                  // Governs the category that the effect appears in in Lightworks
   string SubCategory = "Repair";        // Subcategory added by jwrl for version 14 and up 10 Feb 2017
> = 0;


float scale
<
   string Description = "Scale";
   float MinVal = 0.25f;
   float MaxVal = 4.0f;
> = 1.0f;

float distortion
<
   string Description = "Distortion";
   float MinVal = -1.0f;
   float MaxVal = 1.0f;
> = 0.0f;

float cubicDistortion
<
   string Description = "Cubic Distortion";
   float MinVal = -1.0f;
   float MaxVal = 1.0f;
> = 0.0f;



//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

texture Input;

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
// Define parameters here.
//
// The Lightworks application will automatically generate
// sliders/controls for all parameters which do not start
// with a a leading '_' character
//--------------------------------------------------------------//


float _OutputAspectRatio;


#pragma warning ( disable : 3571 )




//--------------------------------------------------------------
// Pixel Shader
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//
// Note that pixels are processed out of order, in parallel.
// Using shader model 2.0, so there's a 64 instruction limit -
// use multple passes if you need more.
//--------------------------------------------------------------
float4 CubicLensDistorsion( float2 xy : TEXCOORD1 ) : COLOR
{

  float ratio = _OutputAspectRatio;

  float scaleFactor = 1.0/scale;
        
        float4 inputDistord;
        float2 tex = xy;


        tex.x = 2.0*(tex.x - 0.5);
        tex.y = 2.0*(tex.y - 0.5);
        
        // lens distortion coefficient
        float k = distortion;
        // cubic distortion value
        float kcube = cubicDistortion;
        float f = 0.0;
        
        //APPLY DISTORTION
        float r2 = ratio * ratio * (tex.x) * (tex.x) + (tex.y) * (tex.y);
        //only compute the cubic distortion if necessary
        if( kcube == 0.0){
                f = 1.0 + r2 * k;
        }else{
                f = 1.0 + r2 * (k + kcube * sqrt(r2));
        };

        
        float x = f*scaleFactor*(tex.x*0.5)+0.5;
        float y = f*scaleFactor*(tex.y*0.5)+0.5;
        inputDistord = tex2D(FgSampler,float2(x,y));

	if (x < 0.0f || x > 1.0f) inputDistord = float4(0,0,0,0);
	if (y < 0.0f || y > 1.0f) inputDistord = float4(0,0,0,0);

	return inputDistord;
}

//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE CubicLensDistorsion();
   }
}

