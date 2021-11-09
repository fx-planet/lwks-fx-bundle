// @Maintainer jwrl
// @Released 2021-11-09
// @Author jwrl
// @Created 2021-11-05
// @see https://forum.lwks.com/attachments/highlightwidgets_640-png.39542/

/**
 This is an effect that is used to highlight sections of the input video, using circles,
 squares or arrows.  This effect will break resolution independence.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect HighlightWidgets.fx
//
// Version history:
//
// Update 2021-11-09 jwrl.
// Removed aspect ratio adjustment from the circle widget.
// Changed arrow generation to improve geometry and prevent border overflow.
//
// Built 2021-11-05 jwrl.
// Not completely comfortable with arrow widget at the moment.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Highlight widgets";
   string Category    = "Key";
   string SubCategory = "Simple tools";
   string Notes       = "Used to highlight sections of video that you want to emphasize";
   bool CanSize       = false;
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define LessThan(XY,REF) (all (XY <= REF))

float _OutputWidth;
float _OutputHeight;

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and Samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

DefineTarget (Shape, s_Shape);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Choose widget";
   string Enum = "Circle,Square,Arrow"; 
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Size
<
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Aspect
<
   string Description = "Ratio (not circle)";
   float MinVal = 0.1;
   float MaxVal = 10.0;
> = 1.0;

float LineWeight
<
   string Description = "Line weight";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Border
<
   string Description = "Border";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Rotation
<
   string Description = "Rotate arrow";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

float CentreX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CentreY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 Colour
<
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_circle (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = GetPixel (s_Input, uv);
   float4 retval = Bgnd;

   float2 xy = float2 (uv.x - 0.5, (uv.y - 0.5) / _OutputAspectRatio) + 0.5.xx;

   float radius = distance (xy, float2 (CentreX, 1.0 - CentreY));
   float size_1 = 0.01 + (Size * 0.49);
   float size_2 = size_1 + (LineWeight * 0.1);
   float brdr_1 = Border * 0.05;
   float brdr_2 = size_2 + brdr_1;

   brdr_1 = max (0.0, size_1 - brdr_1);

   float alias = 2.0 / min (_OutputWidth, _OutputHeight);
   float level = smoothstep (brdr_1 - alias, brdr_1, radius);

   level *= smoothstep (brdr_2 + alias, brdr_2, radius);

   retval = lerp (retval, BLACK, level);

   level  = smoothstep (size_1 - alias, size_1, radius);
   level *= smoothstep (size_2 + alias, size_2, radius);

   retval = lerp (retval, Colour, level);

   return lerp (Bgnd, retval, Amount);
}

float4 ps_square (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = GetPixel (s_Input, uv);
   float4 retval = Bgnd;

   float2 asp = float2 (1.0 / _OutputAspectRatio, 1.0);
   float2 xy1 = abs (float2 (uv.x - CentreX, uv.y + CentreY - 1.0));
   float2 xy2 = (0.01 + (Size * 0.74)) * asp;

   if (Aspect > 1.0) xy2.x *= Aspect;
   else xy2.y /= Aspect;

   float2 xy3 = xy2 + (asp * LineWeight * 0.15);
   float2 xy4 = (asp * Border * 0.075);
   float2 xy5 = xy3 + xy4;

   xy4 = xy2 - xy4;

   if (LessThan (xy1, xy5) && !LessThan (xy1, xy4)) retval = BLACK;
   if (LessThan (xy1, xy3) && !LessThan (xy1, xy2)) retval = Colour;

   return lerp (Bgnd, retval, Amount);
}

float4 ps_arrow (float2 uv : TEXCOORD0) : COLOR
{
   float4 retval = EMPTY;

   float scale = lerp (0.075, 0.2, Aspect / 10.0);       // max = 0.2,   min = 0.077
   float range = lerp (0.375, 0.695, LineWeight - 0.1);  // max = 0.625, min = 0.375
   float brdr  = Border * 0.05625;
   float Lmin  = 0.1;
   float Lrng  = 0.375;
   float Lmax  = Lmin + Lrng;
   float Hmin  = Lmax - brdr;
   float Hmax  = 0.7;
   float c, s;

   Lrng /= 2.0;

   float2 asp = float2 (1.0, _OutputAspectRatio);
   float2 ofs = float2 (0.5 - Lrng - Lmin, 0.0);
   float2 xy0 = 0.5.xx;
   float2 xy1 = abs (uv - xy0 + ofs);                 // This is the reference for the line
   float2 xy2 = float2 (Lrng, range * scale) * asp;   // Coordinates for arrow stem
   float2 xy3 = xy2 + (brdr * asp);                   // Coordinates for stem border

   sincos (atan2 (scale, 0.3), s, c);

   c = brdr / c;
   s = brdr / s;
   Hmax += s;

   float2 xy4 = float2 (Hmin, scale + c) * asp;    // Arrow head border base
   float2 xy5 = float2 (Hmax, 0.0);                // Arrow head border tip

   xy5 = lerp (xy4, xy5, saturate ((uv.x - Hmin) / (Hmax - Hmin)));
   xy4 = uv - xy0;
   xy4.x += 0.5;
   xy4.y = abs (xy4.y);

   if (LessThan (xy1, xy2)) retval.wx = 1.0.xx;
   if (LessThan (xy1, xy3)) retval.wy = 1.0.xx;

   if ((xy4.x >= Hmin) && (xy4.x <= Hmax)) {
      if (xy4.y < xy5.y) retval.wy = 1.0.xx;
      if (xy4.x >= Lmax) {
         xy5.y -= c * _OutputAspectRatio;
         xy5.y  = max (0.0, xy5.y);

         if (xy4.y < xy5.y) retval.wx = 1.0.xx;
      }
   }

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - float2 (CentreX, 1.0 - CentreY);

   float scale = (Size * 1.0667) + 0.0667;
   float c, s, angle = radians (Rotation);

   sincos (angle, s, c);

   xy.x *= _OutputAspectRatio;
   xy    = mul (float2x2 (c, s, -s, c), xy);
   xy.x /= _OutputAspectRatio;
   xy    = (xy / scale) + 0.5.xx;

   float4 Bgnd = GetPixel (s_Input, uv);
   float4 Fgnd = GetPixel (s_Shape, xy);

   float2 xy1, xy2 = 2.0 / float2 (_OutputWidth, _OutputHeight);

   angle = 0.0;

   for (int i = 0; i < 12; i++) {
      sincos (angle, xy1.y, xy1.x);
      Fgnd  += tex2D (s_Shape, xy + (xy1 * xy2));
      angle += 0.523599;
   }

   Fgnd /= 13.0;

   float4 retval = lerp (Bgnd, BLACK, Fgnd.y);

   retval = lerp (retval, Colour, Fgnd.x);

   return lerp (Bgnd, retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique HighlightWidgets_1
{
   pass P_1 ExecuteShader (ps_circle)
}

technique HighlightWidgets_2
{
   pass P_1 ExecuteShader (ps_square)
}

technique HighlightWidgets_3
{
   pass P_1 < string Script = "RenderColorTarget0 = Shape;"; > ExecuteShader (ps_arrow)
   pass P_2 ExecuteShader (ps_main)
}

