// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This "dissolve" simulates the chinagraph marks used by film editors to mark up optical
 effects on film rushes.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks effect Chinagraph_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Chinagraph pencil", "Mix", "Fades and non mixes", "Simulates the chinagraph marks used by film editors to mark up optical effects on film rushes", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (MarkType, "Overlay type", kNoGroup, 0, "Left to right|Right to left|Crossover");

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Tilt, "Angle", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (Texture, "Amount", "Texture", kNoFlags, 0.125, 0.0, 1.0);
DeclareFloatParam (Depth, "Depth", "Texture", kNoFlags, 0.125, 0.0, 1.0);
DeclareFloatParam (Radius, "Softness", "Texture", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SIZE    0.00436
#define RAND_1  12.9898
#define RAND_2  78.233
#define RAND_3  43758.5453

#define TEX     0.5
#define WIDTH   0.0109
#define DISP    0.00218
#define TILT    0.1

#define L_R     0
#define R_L     1

#define LOOP    12
#define RADIUS  0.003333
#define ANGLE   0.261799
#define DIVISOR 25

#define OFFSET  0.002

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Target)
{ return Amount < 0.5 ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (Overlay)
{ return Amount < 0.5 ? ReadPixel (Bg, uv2) : ReadPixel (Fg, uv1); }

DeclarePass (Markup)
{
   float2 grain = float2 (1.0, _OutputAspectRatio) * SIZE;
   float2 xy1 = round ((uv3 - 0.5) / grain) * grain;
   float2 xy2 = frac (sin (dot (xy1, float2 (RAND_1, RAND_2)) + _Progress) * RAND_3);

   float4 china = float2 (frac (sin (dot (xy1, float2 (RAND_1, RAND_2)) + xy2.x) * RAND_3), 1.0).xxxy;
   float4 retval = 0.0.xxxx;

   china = lerp (retval, china, Texture * TEX);
   china = min (china + Depth, 1.0.xxxx);

   xy1 = ((uv3 - 0.5) / 4.0) + 0.5; xy2 = 1.0 - xy1;

   xy1.x  = uv3.x + uv3.y + WIDTH;
   xy2.x  = uv3.x + uv3.y - WIDTH;

   float4 offs_1 = tex2D (Target, xy1);
   float4 offs_2 = tex2D (Target, xy2);
   float4 offs_3 = tex2D (Overlay, 1.0 - xy1);
   float4 offs_4 = tex2D (Overlay, 1.0 - xy2);

   float slope  = Amount + (uv3.y * Tilt * TILT);
   float prog_0 = uv3.x;
   float prog_1 = ((offs_1.r + offs_1.g + offs_1.b + offs_3.r + offs_3.g + offs_3.b) * DISP) + WIDTH;
   float prog_2 = ((offs_2.r + offs_2.g + offs_2.b + offs_4.r + offs_4.g + offs_4.b) * DISP) + WIDTH;

   prog_1 = max (slope - prog_1, 0.0);
   prog_2 = min (slope + prog_2, 1.0);

   if ((MarkType != R_L) && (prog_0 > prog_1) && (prog_0 < prog_2))
      retval = float4 (china.rgb, 1.0);

   if ((MarkType != L_R) && (prog_0 > 1.0 - prog_2) && (prog_0 < 1.0 - prog_1))
      retval = float4 (china.rgb, 1.0);

   return retval;
}

DeclareEntryPoint (Chinagraph_Dx)
{
   float4 retval = tex2D (Target, uv3);
   float4 china  = tex2D (Markup, uv3);

   if ((Amount != 0.0) && (Radius != 0.0)) {

      float angle = 0.0;

      float2 xy, radius = float2 (1.0 - china.b, china.r + china.g) * Radius * RADIUS;

      for (int i = 0; i < LOOP; i++) {
         sincos (angle, xy.x, xy.y);
         xy *= radius;
         china += tex2D (Markup, uv3 + xy);
         china += tex2D (Markup, uv3 - xy);
         angle += ANGLE;
      }

      china /= DIVISOR;
   }

   return lerp (retval, china, china.a);
}

