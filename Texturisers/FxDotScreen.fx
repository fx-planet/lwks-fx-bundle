/*
  * FxDotScreen.
  * Dot Screen effect.
  * 
  * @Auther Windsturm
  * @version 1.0.0

forked from evanw/glfx.js https://github.com/evanw/glfx.js

Copyright (C) 2011 by Evan Wallace

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/
//--------------------------------------------------------------//
// FxDotScreen
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Bug fix 26 February 2017 by jwrl:
// Added workaround for the interlaced media height bug in all
// Lightworks effects.
//
// Cross platform compatibility check 3 August 2017 jwrl.
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Rewrote the body of the code to improve efficiency.  In the
// process found two variables that had been declared but never
// used, an unnecessary const declaration, and the use of a
// function to perform an operation that could more efficently
// be executed as in-line code.
//
// The minimum dotSize value has been constrained to 3.0, to
// protect against divide by zero errors.  Previously it was
// possible to manually enter values lower than that.  There
// were several instances of implicit casting of float types
// which would have failed in Mac/Linux environments.  They
// have now all been explicitly defined.
//
// In the process of the above, the original 20 lines of code
// have been reduced to 10 with no loss of functionality.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
    string EffectGroup = "GenericPixelShader";
    string Description = "FxDotScreen";       // The title
    string Category    = "Stylize";      // Governs the category that the effect appears in in Lightworks
    string SubCategory = "Textures";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InputSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int skipGS
<
   string Description = "Greyscale derived from:";
   string Enum = "Luminance,RGB average";
> = 0;

float centerX
<
    string Description = "Center Position";
    string Flags = "SpecifiesPointX";
    float MinVal = 0.0;
    float MaxVal = 1.0;
> = 0.5;

float centerY
<
    string Description = "Center Position";
    string Flags = "SpecifiesPointY";
    float MinVal = 0.0;
    float MaxVal = 1.0;
> = 0.5;

float angle
<
    string Description = "Angle";
    float MinVal = 0.0;
    float MaxVal = 90.0;
> = 15.0;

float dotSize
<
    string Description = "Size";
    float MinVal = 3.0;
    float MaxVal = 1000.0;
> = 3.0;

float Strength
<
    string Description = "Strength";
    float MinVal = 0.0;
    float MaxVal = 200.0;
> = 4.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define PI 3.14159265358979323846264

float _OutputAspectRatio;
float _OutputWidth;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 FxDotScreen (float2 xy : TEXCOORD1) : COLOR
{
    float4 color = tex2D (InputSampler, xy);

    float2 center = float2 (centerX, 1.0 - centerY);
    
    float luma = (skipGS == 1) ? (color.r + color.g + color.b) / 3.0
                               : dot (color.rgb, float3 (0.299, 0.587, 0.114));
    float s, c;

    sincos (radians (angle), s, c);

    float2 uv1 = (xy - center) * float2 (1.0, 1.0 / _OutputAspectRatio) * _OutputWidth;
    float2 uv2 = (uv1 * c - float2 (uv1.y, -uv1.x) * s) * PI / max (3.0, dotSize);

    float pattern = sin (uv2.x) * sin (uv2.y) * Strength;

    color.rgb = ((luma * 10.0) + pattern - 5.0).xxx;

    return color;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique FxTechnique
{
    pass P_1
    { PixelShader = compile PROFILE FxDotScreen (); }
}
