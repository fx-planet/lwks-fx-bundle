// @Maintainer jwrl
// @Released 2021-08-31
// @Author Evan Wallace (evanw/glfx.js https://github.com/evanw/glfx.js)
// @Created 2012-07-30
// @see https://www.lwks.com/media/kunena/attachments/6375/FxTiltShift_640.png

/**
 ORIGINAL AUTHOR'S DESCRIPTION
 Simulates the shallow depth of field normally encountered in close-up photography,
 which makes the scene seem much smaller than it actually is. This filter assumes the
 scene is relatively planar, in which case the part of the scene that is completely
 in focus can be described by a line (the intersection of the focal plane and the
 scene). An example of a planar scene might be looking at a road from above at a
 downward angle. The image is then blurred with a blur radius that starts at zero
 on the line and increases further from the line.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TiltShift.fx
//
// Ported by windsturm
//
// ORIGINAL AUTHOR'S PERMISSION:
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
// Version history:
//
// Updated 2021-08-31 jwrl:
// Partial rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 2020-11-09:
// Various updates mainly to improve cross-platform performance.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Tilt shift";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "Simulates the shallow depth of field normally encountered in close-up photography";
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

#define SetInputMode(TEX, SMPL, MODE) \
                                      \
 texture TEX;                         \
                                      \
 sampler SMPL = sampler_state         \
 {                                    \
   Texture   = <TEX>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
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
#define ExecuteParam(SHD,PRM) { PixelShader = compile PROFILE SHD (PRM); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

SetInputMode (Input, s_RawInp, Mirror);

SetTargetMode (FixInp, s0, Mirror);
SetTargetMode (Pass1, s1, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float startX
<
   string Description = "Start";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float startY
<
   string Description = "Start";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float endX
<
   string Description = "End";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float endY
<
   string Description = "End";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
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

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_RawInp, uv); }

float4 FxTiltShift (float2 uv : TEXCOORD1, float2 texCoord : TEXCOORD2, uniform int mode) : COLOR
{
   if (Overflow (uv)) return EMPTY;

   float4 color = 0.0;
   float2 start = float2 (_OutputWidth * startX, (_OutputHeight) * (1.0 - startY));
   float2 end   = float2 (_OutputWidth * endX,   (_OutputHeight) * (1.0 - endY));

   float dx = end.x - start.x;
   float dy = end.y - start.y;
   float d  = sqrt (dx * dx + dy * dy);

   float2 texSize = float2 (_OutputWidth, _OutputHeight);

   if (mode == 0) color = tiltShift (s0, start, end, float2 ( dx / d, dy / d), texSize, texCoord);
   if (mode == 1) color = tiltShift (s1, start, end, float2 (-dy / d, dx / d), texSize, texCoord);

   return color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FxTechnique
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass PassA < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (FxTiltShift, 0)
   pass PassB ExecuteParam (FxTiltShift, 1)
}

