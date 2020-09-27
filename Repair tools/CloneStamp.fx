// @Maintainer jwrl
// @Released 2020-09-27
// @Author nouanda
// @Created 2014-10-20
// @see https://www.lwks.com/media/kunena/attachments/6375/CloneStamp_640.png

/**
 A means of cloning sections of the image into other sections, in a similar way to the art
 tool.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CloneStamp.fx
//
// Collective effort from Lightworks Forum members nouanda // brdloush // jwrl
// Ok, we're amateurs, but we managed to do it!
//
// Absolutely no copyright - none - zero - nietchevo - rien - it's no rocket science,
// why should we claim a copyright?  Feel free to use at your envy!
//
// Function aspectAdjustedpos from Lwks' shapes2.fx shader
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Update 2020-09-27 jwrl.
// Amended header block.
//
// Modified 26 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 2018-12-05 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// MAJOR update 2017-07-29 jwrl.
// Cross platform compatibility check and fix.
// Explicitly defined samplers to correct for platform default sampler state differences.
// Taking nouanda's "feel free" above at face value, I have rewritten the rectangle code
// to correct a bug in the clone positioning.  In the process considerable code cleanup
// and optimisation of both modules has been done.
//
// Rewrote the aspect ratio adjustment to take into account _OutputAspectRatio.  The code
// is no longer the Lightworks version which has meant some changes to the aspect ratio
// parameter.  The default setting of 1.78:1 is now 1:1 and the range now swings between
// 1:3.33 to 3.33:1.
//
// Fixed an aspect ratio bug in the ellipse code.  This means that the ellipse now
// defaults to a circle at an aspect ratio of 1:1.  This matches the behaviour of the
// rectangle, which defaults to square.
//
// Scaled the Size parameter in the ellipse code so that it matches the area covered by
// the rectangle at the same settings.
//
// Rewrote the rectangle softness so the corners of the linear and sinusoidal curves
// are smooth and are no longer cut off.
//
// FINAL COMMENT: There are still too many conditionals for my liking and I know that
// I can work out a technique without using them for the rectangular linear softness.
// Unfortunately it doesn't translate for the square or sinusoidal softness, so at the
// moment I don't want to use it.  There has to be a way.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Clone Stamp";
   string Category    = "Stylize";
   string SubCategory = "Repair tools";
   string Notes       = "A means of cloning sections of the image into other sections similarly to art software";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler SourceSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Shape";
   string Enum = "Ellipse, Rectangle";
> = 0;

float Size
<
   string Description = "Size";
   string Group = "Parameters";
   float  MinVal = 0.0;
   float  MaxVal = 1.0;
> = 0.33;

float Softness
<
   string Description = "Softness";
   string Group = "Parameters";
   float  MinVal = 0.0;
   float  MaxVal = 1.0;
> = 0.5;

int Interpolation
<
   string Description = "Interpolation";
   string Group = "Parameters";
   string Enum = "Linear, Square, Sinusoidal";
> = 0;

float SrcPosX
<
   string Description = "Source Position";
   string Group = "Parameters";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float SrcPosY
<
   string Description = "Source Position";
   string Group = "Parameters";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float AspectRatio
<
   string Description = "Aspect ratio x:1";
   string Group = "Parameters";
   float MinVal = 0.3;
   float MaxVal = 3.3333333;
> = 1.0;

float DestPosX
<
   string Description = "Destination Position";
   string Group = "Parameters";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.7;

float DestPosY
<
   string Description = "Destination Position";
   string Group = "Parameters";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.7;

float BlendOpacity
<
   string Description = "Blend Opacity";
   string Group       = "Overlay";
   float MinVal       = 0.00;
   float MaxVal       = 1.00;
> = 1.0;

float DestRed
<
   string Description = "Red correction";
   string Group = "Color Correction";
   string Flags = "Red";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float DestGreen
<
   string Description = "Green correction";
   string Group = "Color Correction";
   string Flags = "Green";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float DestBlue
<
   string Description = "Blue correction";
   string Group = "Color Correction";
   string Flags = "Blue";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.14159265
#define PI_AREA 1.27323954

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_ellipse (float2 uv : TEXCOORD1): COLOR
{
   float4 Src = tex2D (SourceSampler, uv);            // get background texture for edge softness

   //Adjust size for circle
   float CircleSize = Size * PI_AREA;

   //Adjust aspect ratio
   float2 DestPos = float2 (DestPosX, 1.0 - DestPosY);
   float2 DestAspectAdjustedPos = ((uv - DestPos) / (float2 (AspectRatio, _OutputAspectRatio) * CircleSize)) + DestPos;

   float DestDelta = distance (DestAspectAdjustedPos, DestPos);

   //apply effect only in the effect radius
   if (CircleSize <= DestDelta) return Src;

   //correct Softness radius (cannot be greater than the Effect radius)
   float SoftRadius = CircleSize * (1.0 - Softness);

   // distance between the softness radius and the pixel position
   float SoftRing = DestDelta - SoftRadius;

   // initiate Softness to set Transparency (0 - fully solid by default)
   float Soft = 0.0;

   // if the pixel is in the soft area, interpolate softness as per Interpolation parameter
   if (SoftRing >= 0.0) {
      SoftRing /= (CircleSize - SoftRadius);

      Soft = (Interpolation == 0) ? SoftRing
           : (Interpolation == 1) ? 1.0 - pow (1.0 - pow (SoftRing, 2.0), 0.5)
                                  : 0.5 - (cos (SoftRing * PI) / 2.0);
   }

   //Offset Source and Destination
   float2 xy = uv + float2 (SrcPosX, DestPosY) - float2 (DestPosX, SrcPosY);

   // get texture for Destination replacement
   float4 Dest = tex2D (SourceSampler, xy);

   //applies color correction
   Dest.rgb += float3 (DestRed, DestGreen, DestBlue);

   // apply softness by merging with the background
   Dest = lerp (Dest, Src, Soft);

   // Apply opacity the same way
   return float4 (lerp (Src.rgb, Dest.rgb, BlendOpacity), Src.a);
}

float4 ps_rectangle (float2 uv : TEXCOORD1): COLOR
{
   float4 Src = tex2D (SourceSampler, uv);            // get sampler of the backgroung for edge softness

   //get Destination Position - so it can be modified (parameters are constant, not variables)
   float2 DestPos  = float2 (DestPosX, 1.0 - DestPosY);
   float2 DestSize = float2 (AspectRatio, _OutputAspectRatio) * Size;
   float2 SoftSize = DestSize * (1.0 - Softness);

   //define box effect limits
   float2 BoxMin = DestPos - DestSize / 2.0;
   float2 BoxMax = BoxMin + DestSize;

   //apply effect only in the effect radius
   if (any ((uv - BoxMin) < 0.0.xx) || any ((uv - BoxMax) > 0.0.xx)) return Src;

   //define softness effect limits
   float2 SoftMin = DestPos - SoftSize / 2.00;
   float2 SoftMax = SoftMin + SoftSize;

   //define softness range
   float2 RangeMin = (uv - SoftMin) / (BoxMin - SoftMin);
   float2 RangeMax = (uv - SoftMax) / (BoxMax - SoftMax);

   // if the pixel is in the soft area, interpolate softness as per Interpolation parameter

   if (Interpolation == 1) {
      RangeMin = 1.0.xx - pow ((1.0.xx - pow (RangeMin, 2.0.xx)), 0.5.xx);
      RangeMax = 1.0.xx - pow ((1.0.xx - pow (RangeMax, 2.0.xx)), 0.5.xx);
   }
   else if (Interpolation == 2) {
      RangeMin = 0.5.xx - (cos (RangeMin * PI) / 2.0);
      RangeMax = 0.5.xx - (cos (RangeMax * PI) / 2.0);
   }

   RangeMin = 1.0.xx - RangeMin;
   RangeMax = 1.0.xx - RangeMax;

   float Soft_1 = ((uv.x >= BoxMin.x) && (uv.x <= SoftMin.x)) ? RangeMin.x : 1.0;
   float Soft_2 = ((uv.y >= BoxMin.y) && (uv.y <= SoftMin.y)) ? RangeMin.y : 1.0;

   if ((uv.x <= BoxMax.x) && (uv.x >= SoftMax.x)) Soft_1 = min (Soft_1, RangeMax.x);
   if ((uv.y <= BoxMax.y) && (uv.y >= SoftMax.y)) Soft_2 = min (Soft_2, RangeMax.y);

   float Soft = saturate (min (Soft_1, Soft_2) * Soft_1 * Soft_2);

   //Offset Source and Destination
   float2 xy = uv + float2 (SrcPosX, DestPosY) - float2 (DestPosX, SrcPosY);

   // get texture for Destination replacement
   float4 Dest = tex2D (SourceSampler, xy);

   //applies color correction
   Dest.rgb += float3 (DestRed, DestGreen, DestBlue);

   // apply softness by merging with the background
   Dest = lerp (Src, Dest, Soft);

   // Apply opacity the same way
   return float4 (lerp (Src.rgb, Dest.rgb, BlendOpacity), Src.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ellipse
{
   pass P_1
   { PixelShader = compile PROFILE ps_ellipse (); }
}

technique Rectangle
{
   pass P_1
   { PixelShader = compile PROFILE ps_rectangle (); }
}
