// @Maintainer jwrl
// @Released 2021-10-07
// @Author windsturm
// @Created 2012-06-16
// @OriginalAuthor "Evan Wallace"
// @see https://www.lwks.com/media/kunena/attachments/6375/FxDotScreen_640.png

/**
 This effect is a version of the dot pattern of a black and white half-tone print image.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DotScreen.fx
//
// Original effect "FxDotScreen" (FxDotScreen.fx) by windsturm.
//-----------------------------------------------------------------------------------------//

/*
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

//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Update 2021-10-07 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//
// Modified 26 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 5 December 2018 jwrl.
// Added creation date.
// Renamed effect.
// Changed subcategory.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Cross platform compatibility check 3 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Rewrote the body of the code to improve efficiency.
// Removed two variables that had been declared but never used.
// Removed an unnecessary const declaration.
// Removed a function used to perform an operation that would more efficently be
// executed as in-line code.
// Minimum dotSize value has been constrained to 3.0, to protect against divide by
// zero errors. 
// Several instances of implicit casting of float types which would have failed in
// Mac/Linux environments have now been explicitly defined.
// In the process of doing all of the above, the original 20 lines of code have been
// reduced to 10 with no loss of functionality.
//
// Bug fix 26 February 2017 by jwrl:
// Added workaround for the interlaced media height bug in all Lightworks effects.
//
// Version 14 update 18 Feb 2017 jwrl - added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dot screen";
   string Category    = "Stylize";
   string SubCategory = "Print Effects";
   string Notes       = "This effect is a version of the dot pattern of a black and white half-tone print image";
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

#define PI 3.14159265358979323846264

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, InputSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
    float4 color = tex2D (InputSampler, uv2);

    float2 center = float2 (centerX, 1.0 - centerY);
    
    float luma = (skipGS == 1) ? (color.r + color.g + color.b) / 3.0
                               : dot (color.rgb, float3 (0.299, 0.587, 0.114));
    float s, c;

    sincos (radians (angle), s, c);

    float2 xy1 = (uv2 - center) * float2 (1.0, 1.0 / _OutputAspectRatio) * _OutputWidth;
    float2 xy2 = (xy1 * c - float2 (xy1.y, -xy1.x) * s) * PI / max (3.0, dotSize);

    float pattern = sin (xy2.x) * sin (xy2.y) * Strength;

    color.rgb = ((luma * 10.0) + pattern - 5.0).xxx;

    return Overflow (uv1) ? EMPTY : color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FxTechnique
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main)
}

