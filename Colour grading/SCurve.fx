//--------------------------------------------------------------//
// By JMovie for Lightworks
//
// Lightworks version 14+ update by jwrl 21 January 2017.
//
// The code has been optimised to reduce the number of passes
// required from six to two.  The number of function calls has
// also been reduced to minimise the significant function call
// overhead in the original.  The number of variables required
// has been reduced and the alpha channel has been preserved.
//
// The user interface has been improved to change the cryptic
// parameter labels to something more meaningful.  Parameters
// have been logically grouped, and their ranges have been
// altered to run from 0-100% instead of 0-255, consistent
// with Lightworks effects useage.
//
// This version has been compared against the original jMovie
// version to confirm functional equivalence.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "S-Curve";
   string Category    = "Colour";
   string SubCategory = "Technical";        // Subcategory added by jwrl for version 14 and up 10 Feb 2017
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture HSVin : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InpSampler = sampler_state
{
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler HSVsampler = sampler_state
{
   Texture   = <HSVin>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float InY
<
   string Group = "Curves";
   string Description = "Black (InY)";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float LowY
<
   string Group = "Curves";
   string Description = "Low mid (LowY)";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.3333;

float HighY
<
   string Group = "Curves";
   string Description = "High mid (HighY)";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.6667;

float OutY
<
   string Group = "Curves";
   string Description = "White (OutY)";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float InX
<
   string Group = "Break points";
   string Description = "Black (InX)";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float LowX
<
   string Group = "Break points";
   string Description = "Low mid (LowX)";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float HighX
<
   string Group = "Break points";
   string Description = "High mid (HighX)";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float OutX
<
   string Group = "Break points";
   string Description = "White (OutX)";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool Visualize
<
   string Description = "Visualize";
> = false;

bool RChannel
<
   string Description = "Channel R";
> = true;

bool GChannel
<
   string Description = "Channel G";
> = true;

bool BChannel
<
   string Description = "Channel B";
> = true;

bool ValueChannel
<
   string Description = "Channel (HS)V Overrides RGB";
> = false;

//--------------------------------------------------------------//
// Declarations and definitions
//--------------------------------------------------------------//

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

float fn_curve_magic (float valueIn, float indexFraction)
// _CurveMagic derived from http://www.codeproject.com/KB/graphics/Spline_ImageCurve.aspx
// and modifed by jMovie.  This fn_curve_magic version very much simplifed and optimised
// by removing redundant code and variables - jwrl
{
   float2 controlPoint [4];
   float2 points [4] = { float2 (InX * 0.2745, InY),
                         float2 (LowX * 0.6275, LowY),
                         float2 ((HighX * 0.6667) + 0.3333, HighY),
                         float2 ((OutX * 0.3333) + 0.6667, OutY) };

   int fromXIdx = (indexFraction < 0.25) ? 0 : (indexFraction < 0.35) ? 1 : 2;

   controlPoint [0] = points [0];
   controlPoint [1] = points [1] * 6.0 - points [0];
   controlPoint [2] = points [2] * 6.0 - points [3];
   controlPoint [3] = points [3];

   controlPoint [2] = (controlPoint [2] - controlPoint [1] * 0.25) / 3.75;
   controlPoint [1] = (controlPoint [1] - controlPoint [2]) / 4.0;

   float t = (valueIn - points [fromXIdx].x) / (points [fromXIdx + 1].x - points [fromXIdx].x);
   float T = 1.0 - t;

   float2 b = T * (controlPoint [fromXIdx] * 2.0 + controlPoint [fromXIdx + 1]);

   b += t * (controlPoint [fromXIdx] + controlPoint [fromXIdx + 1] * 2.0);
   b *= t;
   b += T * T * points [fromXIdx];
   b *= T;
   b += t * t * t * points [fromXIdx + 1];

   return b.y;
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_input (float2 xy : TEXCOORD1) : COLOR
// Original Pass0_Input converted by changing _RGBtoHSV function to in-line code.
// All float3 variables converted to float4 to preserve alpha channel - jwrl
{
   if (Visualize) return float4 (xy.x, 0.0, 0.0, 1.0);

   float4 src_rgba = tex2D (InpSampler, xy);

   if (!ValueChannel) return src_rgba;

   float4 HSV = float4 (0.0.xx, max (src_rgba.r, max (src_rgba.g, src_rgba.b)), src_rgba.a);

   float M = min (src_rgba.r, min (src_rgba.g, src_rgba.b));
   float C = HSV.z - M;

   if (C != 0.0) {
      HSV.y = C / HSV.z;

      float4 D = (((HSV.z - src_rgba) / 6.0) + (C / 2.0)) / C;

      if (src_rgba.r == HSV.z) HSV.x = D.b - D.g;
      else if (src_rgba.g == HSV.z) HSV.x = (1.0 / 3.0) + D.r - D.b;
      else if (src_rgba.b == HSV.z) HSV.x = (2.0 / 3.0) + D.g - D.r;

      if (HSV.x < 0.0) HSV.x += 1.0;

      if (HSV.x > 1.0) HSV.x -= 1.0;
   }

   return HSV;
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
// Original Pass1_IndexInput altered to change the _FromIndexes function to in-line
// code.  That and the seperate curve and output passes rolled into this one pass.
// Original _HSVtoRGB function has been converted to in-line code to reduce overhead.
// All float3 variables converted to float4 to preserve alpha channel - jwrl
{
   float points [6] = { 0.0, InX * 0.2745, LowX * 0.6275, (HighX * 0.6667) + 0.3333, (OutX * 0.3333) + 0.6667, 1.0 };

   float4 src_rgba = tex2D (InpSampler, xy);
   float4 p2 = tex2D (HSVsampler, xy);
   float4 src_hsv = p2, src_idx = 0.0;

   for (int i = 0; i < 6; ++i) {
      if (points [i] < p2.x) src_idx.x += 0.1;
      if (points [i] < p2.y) src_idx.y += 0.1;
      if (points [i] < p2.z) src_idx.z += 0.1;
   }

   p2.x = fn_curve_magic (p2.x, src_idx.x);

   if (Visualize) { if ((1.0 - xy.y) < (p2.x)) src_rgba = 0.0; }
   else {
      src_hsv.z = fn_curve_magic (p2.z, src_idx.z);

      if (ValueChannel) {
         p2 = 0.0;

         float C = src_hsv.z * src_hsv.y;
         float H = src_hsv.x * 6.0;
         float X = C * (1.0 - abs (fmod (H, 2.0) - 1.0));

         if (src_hsv.y != 0.0) {
            int I = floor (H);

            if (I == 0) p2.xy = float2 (C, X);
            else if (I == 1) p2.xy = float2 (X, C);
            else if (I == 2) p2.yz = float2 (C, X);
            else if (I == 3) p2.yz = float2 (X, C);
            else if (I == 4) p2.xz = float2 (X, C);
            else p2.xz = float2 (C, X);
         }

         p2 += src_hsv.z - C;
         src_rgba.rgb = p2.xyz;
      }
      else {
         if (RChannel) src_rgba.r = p2.x;
         if (GChannel) src_rgba.g = fn_curve_magic (p2.y, src_idx.y);
         if (BChannel) src_rgba.b = src_hsv.z;
      }
   }

   return src_rgba;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique ScurveTechnique
{
   pass P_1
   < string Script = "RenderColorTarget0 = HSVin;"; >
   { PixelShader = compile PROFILE ps_input (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

