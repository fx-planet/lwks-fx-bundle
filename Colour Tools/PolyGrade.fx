// @Maintainer jwrl
// @Released 2021-08-18
// @Author khaver
// @Created 2014-11-22
// @see https://www.lwks.com/media/kunena/attachments/6375/PolyGrad_640.png

/**
 PolyGrade emulates to a degree the operation of power windows.  This maskable grading
 tool can add that little extra polish to your colourgrade.

 To use it, apply the effect and turn on "Show Guides".  This will allow you to position
 the corners of the polygon mask.  The red area shows where the colourgrade effect will
 be at 100%, and the green area is where the effect influence will be at 0%.  Increasing
 the feather amount will increase the area between the red and green zones.  When a
 corner node gets near the edge of frame it will snap to that edge.

 Once the areas are set turn off "Show Guides" and adjust the other parameters as you
 would any other colourgrading tool.

 NOTE:  Because this effect relies on the ability to drag the corner pins on screen it
 has been found necessary to disable resolution independence.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PolyGrade.fx
//
// Version history:
//
// Update 2021-08-18 jwrl:
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Poly grade";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "Emulates to a degree the operation of power windows";
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

float _OutputAspectRatio;
float _OutputWidth;
float _OutputHeight;

#define _psize 8

#define W 1.0.xxx

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (bg, BGround);

DefineTarget (Tex1, Samp1);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float4 MaskColor
<
   string Description = "Grad Color";
> = { 0.0, 0.0, 0.0, 0.0 };

int Mode
<
   string Description = "Blend mode";
   string Enum = "Add,Subtract,Multiply,Screen,Overlay,Soft Light,Hard Light,Exclusion,Lighten,Darken,Difference,Burn";
> = 2;

float feather
<
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool invert
<
   string Description = "Flip";
> = false;

bool show
<
   string Description = "Show Guides";
> = false;

float P1X
<
   string Group = "Coordinates";
   string Description = "P 1";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float P1Y
<
   string Group = "Coordinates";
   string Description = "P 1";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float P2X
<
   string Group = "Coordinates";
   string Description = "P 2";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2879;

float P2Y
<
   string Group = "Coordinates";
   string Description = "P 2";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2879;

float P3X
<
   string Group = "Coordinates";
   string Description = "P 3";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float P3Y
<
   string Group = "Coordinates";
   string Description = "P 3";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float P4X
<
   string Group = "Coordinates";
   string Description = "P 4";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2879;

float P4Y
<
   string Group = "Coordinates";
   string Description = "P 4";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.7121;

float P5X
<
   string Group = "Coordinates";
   string Description = "P 5";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float P5Y
<
   string Group = "Coordinates";
   string Description = "P 5";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float P6X
<
   string Group = "Coordinates";
   string Description = "P 6";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.7121;

float P6Y
<
   string Group = "Coordinates";
   string Description = "P 6";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.7121;

float P7X
<
   string Group = "Coordinates";
   string Description = "P 7";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float P7Y
<
   string Group = "Coordinates";
   string Description = "P 7";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float P8X
<
   string Group = "Coordinates";
   string Description = "P 8";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.7121;

float P8Y
<
   string Group = "Coordinates";
   string Description = "P 8";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2879;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_LineDistance (float2 p, float2 l1, float2 l2)
{
   float2 Delta = l2 - l1;
   float2 D_sqr = Delta * Delta;
   float2 uv = (p - l1) * Delta;

   float u = (uv.x + uv.y) / (D_sqr.x + D_sqr.y);

   float2 closestPointOnLine = (u < 0.0) ? l1 : (u > 1.0) ? l2 : l1 + (u * Delta);

   return distance (p, closestPointOnLine);
}

float fn_PolyDistance (float2 p, float2 poly [_psize])
{
   float result = 100.0;

   for (int i = 0; i < _psize; i++) {
      int j = (i < 1) ? _psize - 1 : i - 1;

      float2 currentPoint  = poly [i];
      float2 previousPoint = poly [j];

      float segmentDistance = fn_LineDistance (p, previousPoint, currentPoint);

      if (segmentDistance < result) result = segmentDistance;
   }

   return result;
}

float3 fn_method (float3 fg, float3 bg)
{
   if (Mode == 0) return saturate (bg + fg);                // Add
   if (Mode == 1) return saturate (bg - fg);                // Subtract
   if (Mode == 2) return bg * fg;                           // Multiply
   if (Mode == 3) return W - ((W - fg) * (W - bg));         // Screen

   if (Mode == 5) return (W - bg) * (fg * bg) + (bg * (W - ((W - bg) * (W - fg)))); // Soft Light

   if (Mode == 7) return fg + bg - (2.0 * fg * bg);         // Exclusion
   if (Mode == 8) return max (fg, bg);                      // Lighten
   if (Mode == 9) return min (fg, bg);                      // Darken
   if (Mode == 10) return abs (fg - bg);                    // Difference
   if (Mode == 11) return saturate (W - ((W - fg) / bg));   // Burn

   float3 newc;

   if (Mode == 4) {                                         // Overlay
      newc.r = (bg.r < 0.5) ? 2.0 * fg.r * bg.r : 1.0 - (2.0 * (1.0 - fg.r) * (1.0 - bg.r));
      newc.g = (bg.g < 0.5) ? 2.0 * fg.g * bg.g : 1.0 - (2.0 * (1.0 - fg.g) * (1.0 - bg.g));
      newc.b = (bg.b < 0.5) ? 2.0 * fg.b * bg.b : 1.0 - (2.0 * (1.0 - fg.b) * (1.0 - bg.b));
   }
   else {                                                   // Hard Light
      newc.r = (fg.r < 0.5) ? 2.0 * fg.r * bg.r : 1.0 - (2.0 * (1.0 - fg.r) * (1.0 - bg.r));
      newc.g = (fg.g < 0.5) ? 2.0 * fg.g * bg.g : 1.0 - (2.0 * (1.0 - fg.g) * (1.0 - bg.g));
      newc.b = (fg.b < 0.5) ? 2.0 * fg.b * bg.b : 1.0 - (2.0 * (1.0 - fg.b) * (1.0 - bg.b));
   }

   return newc;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_poly (float2 xy : TEXCOORD1) : COLOR
{
   float pixelsx = 0.04; //20.0 / _OutputWidth;
   float pixelsy = 0.04; //20.0 / _OutputHeight;

   float2 poly [_psize];

   poly[0] = float2 (P1X, 1.0 - P1Y);
   poly[1] = float2 (P2X, 1.0 - P2Y);
   poly[2] = float2 (P3X, 1.0 - P3Y);
   poly[3] = float2 (P4X, 1.0 - P4Y);
   poly[4] = float2 (P5X, 1.0 - P5Y);
   poly[5] = float2 (P6X, 1.0 - P6Y);
   poly[6] = float2 (P7X, 1.0 - P7Y);
   poly[7] = float2 (P8X, 1.0 - P8Y);

   for (int i = 0; i < _psize; i++) {
      if (poly [i].x < pixelsx) poly [i].x = 0.0;
      if (poly [i].x > 1.0 - pixelsx) poly [i].x = 1.0;
      if (poly [i].y < pixelsy) poly [i].y = 0.0;
      if (poly [i].y > 1.0 - pixelsy) poly [i].y = 1.0;
   }

   float ret = 0.0;

   for (int i = 0; i < _psize; i++) {
      int j = (i < 1) ? _psize - 1 : i - 1;

      if ((xy.x < (poly [i].x - poly [j].x) * (xy.y - poly [j].y) / (poly [i].y - poly [j].y) + poly [j].x)
          && ((poly [j].y > xy.y ) != (poly [i].y > xy.y))) ret = abs (ret - 1.0);
   }

   return ret.xxxx;
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float pixelsx = 0.04; //20.0 / _OutputWidth;
   float pixelsy = 0.04; //20.0 / _OutputHeight;

   float2 poly [_psize];

   poly[0] = float2 (P1X, 1.0 - P1Y);
   poly[1] = float2 (P2X, 1.0 - P2Y);
   poly[2] = float2 (P3X, 1.0 - P3Y);
   poly[3] = float2 (P4X, 1.0 - P4Y);
   poly[4] = float2 (P5X, 1.0 - P5Y);
   poly[5] = float2 (P6X, 1.0 - P6Y);
   poly[6] = float2 (P7X, 1.0 - P7Y);
   poly[7] = float2 (P8X, 1.0 - P8Y);

   for (int i = 0; i < _psize; i++) {
      if (poly [i].x < pixelsx) poly [i].x = 0.0;
      if (poly [i].x > 1.0 - pixelsx) poly [i].x = 1.0;
      if (poly [i].y < pixelsy) poly [i].y = 0.0;
      if (poly [i].y > 1.0 - pixelsy) poly [i].y = 1.0;
   }

   float4 orig = saturate (GetPixel (BGround, xy));

   float Mask = GetPixel (Samp1, xy).a;
   float polyDistance = fn_PolyDistance (xy, poly);

   if (polyDistance < feather) {
      if (Mask > 0.5) Mask = 1.0;
      if (Mask <= 0.5) Mask = 1.0 - (polyDistance / feather);
   }

   if (invert) Mask = 1.0 - Mask;

   if (show) {
      return (Mask < 0.01) ? lerp (orig, float4 (0.0, 1.0, 0.0, Mask), 0.5) :
             (Mask > 0.99) ? lerp (orig, float4 (1.0, 0.0, 0.0, Mask), 0.5) : orig;
   }

   float3 newc = fn_method (MaskColor.rgb, orig.rgb);

   float4 color = lerp (orig, float4 (newc, orig.a), Mask * strength);

   return saturate (color);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique PolyGrade
{
   pass Pass1 < string Script = "RenderColorTarget0 = Tex1;"; > ExecuteShader (ps_poly)
   pass Pass2 ExecuteShader (ps_main)
}

