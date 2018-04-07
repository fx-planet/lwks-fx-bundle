// @Maintainer jwrl
// @Released 2018-04-05
// @Author "Evan Wallace (evanw/glfx.js https://github.com/evanw/glfx.js)"
// 
// @see https://www.lwks.com/media/kunena/attachments/6375/TiltShift.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect FxTiltShift.fx
//
// Ported by windsturm
//
// ORIGINAL AUTHOR'S DESCRIPTION AND PERMISSION:
// Simulates the shallow depth of field normally encountered in close-up photography,
// which makes the scene seem much smaller than it actually is. This filter assumes the
// scene is relatively planar, in which case the part of the scene that is completely
// in focus can be described by a line (the intersection of the focal plane and the
// scene). An example of a planar scene might be looking at a road from above at a
// downward angle. The image is then blurred with a blur radius that starts at zero
// on the line and increases further from the line.
//
// Copyright (C) 2011 by Evan Wallace
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify,
// merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following
// conditions:
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
// Conversion for ps_2_0 compliance by Lightworks user jwrl, 5 February 2016.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Bug fix June 28 2017 by jwrl.
// An arithmetic bug which arose during the cross platform conversion was detected and
// fixed.  The bug resulted in a noticeable drop in video levels and severe highlight
// compression.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "FxTiltShift";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Pass1 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s0 = sampler_state
{
	Texture = <Input>;
	AddressU = Mirror;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s1 = sampler_state {
	Texture = <Pass1>;
	AddressU = Mirror;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float startX
<
   string Description = "Start";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2;

float startY
<
   string Description = "Start";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float endX
<
   string Description = "End";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.8;

float endY
<
   string Description = "End";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float blurRadius
<
   string Description = "Blur Radius";
   float MinVal = 0.0;
   float MaxVal = 50.0;
> = 15.0;

float gradientRadius
<
   string Description = "Gradient Radius";
   float MinVal = 0.0;
   float MaxVal = 500.0;
> = 200.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float random (float3 scale, float seed, float2 texCoord)
{
   /* use the fragment position for a different seed per-pixel */

   float3 Coord = float3 (texCoord.x, texCoord.y, 0.0);

   return frac (sin (dot (Coord.xyz + seed, scale)) * 43758.5453 + seed);
}

float4 tiltShift (sampler tSource, float2 start, float2 end, float2 delta, float2 texSize, float2 texCoord)
{
   float4 gl_FragColor = 0.0;

   //' + randomShaderFunc + '

   float4 color = 0.0;
   float total = 0.0;

   /* randomize the lookup values to hide the fixed number of samples */

   float offset = 1.0;

   float2 normal = normalize (float2 (start.y - end.y, end.x - start.x));
   float radius = smoothstep (0.0, 1.0, abs (dot (texCoord * texSize - start, normal)) / gradientRadius) * blurRadius;

   for (float t = -30.0; t <= 30.0; t++) {
      float percent = (t + offset - 0.5) / 30.0;
      float weight = 1.0 - abs(percent);
      float4 sample = tex2D(tSource, texCoord + delta / texSize * percent * radius);

      /* switch to pre-multiplied alpha to correctly blur transparent images */

      sample.rgb *= sample.a;

      color += sample * weight;
      total += weight;
   }

   gl_FragColor = color / total;

   /* switch back from pre-multiplied alpha */

   gl_FragColor.rgb /= gl_FragColor.a + 0.00001;

   return gl_FragColor;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 FxTiltShift (float2 texCoord : TEXCOORD1, uniform int mode) : COLOR
{
   float4 color = 0.0;
   float2 start = float2 (_OutputWidth * startX, (_OutputWidth/_OutputAspectRatio) * (1.0 - startY));
   float2 end   = float2 (_OutputWidth * endX,   (_OutputWidth/_OutputAspectRatio) * (1.0 - endY));

   float dx = end.x - start.x;
   float dy = end.y - start.y;
   float d  = sqrt (dx * dx + dy * dy);

   float2 texSize = float2 (_OutputWidth, _OutputWidth / _OutputAspectRatio);

   if (mode == 0) color = tiltShift (s0, start, end, float2 ( dx / d, dy / d), texSize, texCoord);
   if (mode == 1) color = tiltShift (s1, start, end, float2 (-dy / d, dx / d), texSize, texCoord);

   return color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FxTechnique
{
   pass PassA
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE FxTiltShift (0);
   }

   pass PassB
   {
      PixelShader = compile PROFILE FxTiltShift (1);
   }
}
