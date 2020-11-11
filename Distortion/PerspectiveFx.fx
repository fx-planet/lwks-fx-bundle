// @Maintainer jwrl
// @Released 2020-11-11
// @Author windsturm
// @OriginalAuthor "Evan Wallace"
// @Created 2017-05-03
// @see https://www.lwks.com/media/kunena/attachments/6375/FxPerspective_640.png

/**
 This effect warps one rectanglur area to another with a perspective transform.  It can be
 used to make a 2D image look 3D or to flatten a 2D image captured in a 3D environment.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PerspectiveFx.fx
//-----------------------------------------------------------------------------------------//
/**
  * FxPerspective.
  * @description  Warps one quadrangle to another with a perspective transform. This can be used to
  *               make a 2D image look 3D or to recover a 2D image captured in a 3D environment.
  * 
  * @forked Windsturm
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
//-----------------------------------------------------------------------------------------//
// FxPerspective
//
// Version history:
//
// Update 2020-11-11 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 23 December 2018 jwrl.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Added subcategory and category changed to DVE by jwrl for version 14, 31 July 2017.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Perspective Fx";
   string Category    = "DVE";
   string SubCategory = "Distortion";
   string Notes       = "Warps one rectangle to another using a perspective transform";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and samplers
//-----------------------------------------------------------------------------------------//

texture Input;

sampler s0 = sampler_state
{
    Texture   = <Input>;
    AddressU  = Border;
    AddressV  = Border;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};

sampler s1 = sampler_state
{
    Texture   = <Input>;
    AddressU  = Wrap;
    AddressV  = Wrap;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool viewSsource
<
	string Description = "View source";
> = false;

bool modeWrap
<
	string Description = "Image Wrap";
> = false;

float bTLX
<
    string Group       = "Before";
    string Description = "Top Left";
    string Flags       = "SpecifiesPointX";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.1;

float bTLY
<
    string Group       = "Before";
    string Description = "Top Left";
    string Flags       = "SpecifiesPointY";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.9;

float bTRX
<
    string Group       = "Before";
    string Description = "Top Right";
    string Flags       = "SpecifiesPointX";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.9;

float bTRY
<
    string Group       = "Before";
    string Description = "Top Right";
    string Flags       = "SpecifiesPointY";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.9;

float bBLX
<
    string Group       = "Before";
    string Description = "Bottom Left";
    string Flags       = "SpecifiesPointX";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.1;

float bBLY
<
    string Group       = "Before";
    string Description = "Bottom Left";
    string Flags       = "SpecifiesPointY";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.1;

float bBRX
<
    string Group       = "Before";
    string Description = "Bottom Right";
    string Flags       = "SpecifiesPointX";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.9;

float bBRY
<
    string Group       = "Before";
    string Description = "Bottom Right";
    string Flags       = "SpecifiesPointY";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.1;

float aTLX
<
    string Group       = "After";
    string Description = "Top Left";
    string Flags       = "SpecifiesPointX";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.2;

float aTLY
<
    string Group       = "After";
    string Description = "Top Left";
    string Flags       = "SpecifiesPointY";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.8;

float aTRX
<
    string Group       = "After";
    string Description = "Top Right";
    string Flags       = "SpecifiesPointX";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.8;

float aTRY
<
    string Group       = "After";
    string Description = "Top Right";
    string Flags       = "SpecifiesPointY";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.8;

float aBLX
<
    string Group       = "After";
    string Description = "Bottom Left";
    string Flags       = "SpecifiesPointX";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.2;

float aBLY
<
    string Group       = "After";
    string Description = "Bottom Left";
    string Flags       = "SpecifiesPointY";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.2;

float aBRX
<
    string Group       = "After";
    string Description = "Bottom Right";
    string Flags       = "SpecifiesPointX";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.8;

float aBRY
<
    string Group       = "After";
    string Description = "Bottom Right";
    string Flags       = "SpecifiesPointY";
    float MinVal = 0.00;
    float MaxVal = 1.00;
> = 0.2;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3x3 getSquareToQuad (float x0, float y0, float x1, float y1, float x2, float y2, float x3, float y3)
{
    float dx1 = x1 - x2;
    float dy1 = y1 - y2;
    float dx2 = x3 - x2;
    float dy2 = y3 - y2;
    float dx3 = x0 - x1 + x2 - x3;
    float dy3 = y0 - y1 + y2 - y3;
    float det = dx1*dy2 - dx2*dy1;
    float a = (dx3*dy2 - dx2*dy3) / det;
    float b = (dx1*dy3 - dx3*dy1) / det;

    return float3x3(
        x1 - x0 + a*x1, y1 - y0 + a*y1, a,
        x3 - x0 + b*x3, y3 - y0 + b*y3, b,
        x0, y0, 1
    );
}

float3x3 getInverse (float3x3 m)
{
    float a = m[0].x, b = m[0].y, c = m[0].z;
    float d = m[1].x, e = m[1].y, f = m[1].z;
    float g = m[2].x, h = m[2].y, i = m[2].z;
    float det = a*e*i - a*f*h - b*d*i + b*f*g + c*d*h - c*e*g;

    return float3x3(
        (e*i - f*h) / det, (c*h - b*i) / det, (b*f - c*e) / det,
        (f*g - d*i) / det, (a*i - c*g) / det, (c*d - a*f) / det,
        (d*h - e*g) / det, (b*g - a*h) / det, (a*e - b*d) / det
    );
}

float3x3 multiply (float3x3 a, float3x3 b)
{
    return float3x3(
        a[0].x*b[0].x + a[0].y*b[1].x + a[0].z*b[2].x,
        a[0].x*b[0].y + a[0].y*b[1].y + a[0].z*b[2].y,
        a[0].x*b[0].z + a[0].y*b[1].z + a[0].z*b[2].z,
        a[1].x*b[0].x + a[1].y*b[1].x + a[1].z*b[2].x,
        a[1].x*b[0].y + a[1].y*b[1].y + a[1].z*b[2].y,
        a[1].x*b[0].z + a[1].y*b[1].z + a[1].z*b[2].z,
        a[2].x*b[0].x + a[2].y*b[1].x + a[2].z*b[2].x,
        a[2].x*b[0].y + a[2].y*b[1].y + a[2].z*b[2].y,
        a[2].x*b[0].z + a[2].y*b[1].z + a[2].z*b[2].z
    );
}

float2 matrixWarp (float3x3 m, float2 coord)
{
    float3 warp = mul (float3 (coord, 1.0), m);

    return warp.xy / warp.z;
}

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 FxPerspective (float2 xy : TEXCOORD1 ) : COLOR
{
    if (viewSsource) {
        return tex2D(s0, xy);
    }

    float3x3 a = getSquareToQuad(aTLX, 1-aTLY, aTRX, 1-aTRY, aBLX, 1-aBLY, aBRX, 1-aBRY);    // after
    float3x3 b = getSquareToQuad(bTLX, 1-bTLY, bTRX, 1-bTRY, bBLX, 1-bBLY, bBRX, 1-bBRY);    // before
    float3x3 c = multiply(getInverse(a), b);
    float2 coord = matrixWarp(c, xy);

    if (modeWrap) return tex2D (s1, coord);     // Wrap mode

    // Border mode

    if (any (coord > 1.0.xx) || any (coord < 0.0.xx)) return 0.0.xxxx;

    return tex2D (s0, coord);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Perspective
{
   pass SinglePass
   {
      PixelShader = compile PROFILE FxPerspective ();
   }
}
