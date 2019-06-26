// @Maintainer jwrl
// @Released 2018-12-26
// @Author brdloush
// @Created 2013-02-08
// @see https://www.lwks.com/media/kunena/attachments/6375/CubicLensDistortion_640.png

/**
Nice effect that can be used for getting rid of heavy fish-eye distortion with GoPro HD
Hero2 and similar cameras.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CubicLensDistortion.fx 
//
// Ported & ripped by Brdloush, based on ft-CubicLensDistortion effect by François Tarlier
//
// Following settings worked nicely:
// - Comp Size - X: 100%
// - Comp Size - Y: 100%
// - Scale: 0.88
// - Distortion: -18%
// - Cubic Distortion: 5.75%
//
// Feel free to share/modify or implement all the functions of original
// "ft-CubicLensDistortion".
//
// Pixel Bender shader written by François Tarlier
// http://www.francois-tarlier.com/blog/index.php/2010/03/update-cubic-lens-distortion-pixel-bender-shader-for-ae-with-scale-chroamtic-aberration/
//     
// Original Lens Distortion Algorithm from SSontech (Syntheyes)
// http://www.ssontech.com/content/lensalg.htm
//     r2 = image_aspect*image_aspect*u*u + v*v
//     f = 1 + r2*(k + kcube*sqrt(r2))
//     u' = f*u
//     v' = f*v
//
// Copyright (c) 2010 François Tarlier
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies
// or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
// OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// Cross platform compatibility check 29 July 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.  This effect should now function correctly when used with
// all current and previous Lightworks versions.  When doing that I have also substantially
// restructured the code so that it is both more readable and will run more efficiently
// in Lightworks.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 2018-12-05 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified 26 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Cubic lens distortion";
   string Category    = "Stylize";
   string SubCategory = "Repair tools";
   string Notes       = "Can be used for reducing fish-eye distortion with wide angle lenses";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float scale
<
   string Description = "Scale";
   float MinVal = 0.25;
   float MaxVal = 4.0;
> = 1.0;

float distortion
<
   string Description = "Distortion";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float cubicDistortion
<
   string Description = "Cubic Distortion";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

#define EMPTY    (0.0).xxxx

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float2 uv = (xy - (0.5).xx) * 2.0;

   float scaleFactor = 1.0 / scale;
   float r2 = dot (uv, float2 (_OutputAspectRatio * _OutputAspectRatio * uv.x, uv.y));
   float f = cubicDistortion == 0.0 ? 1.0 + (r2 * distortion)
                                    : 1.0 + (r2 * (distortion + cubicDistortion * sqrt (r2)));

   uv = (uv * f * scaleFactor * 0.5) + (0.5).xx;

   return fn_illegal (uv) ? EMPTY : tex2D (FgSampler, uv);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique CubicLensDistortion
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
