// @Maintainer jwrl
// @Released 2021-10-18
// @Author khaver
// @Created 2011-12-08
// @see https://www.lwks.com/media/kunena/attachments/6375/Polymask_640.png

/**
 This a user adjustable mask with four sides.  The edges of the mask can be feathered, and
 a background colour can also be applied.  Zoom, aspect ratio and position adjustments
 are available, but using any them will disconnect the on-screen pin display from the
 corners to which they are connected.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PolyMask04.fx
//
// Version history.
//
// Update 2021-10-18 jwrl.
// As well as compensating for resolution independence, this update also performed some
// code optimisations to cut the number of passes of the main code from three to one.
// Improvements to the mask generation functions also increased the efficiency somewhat.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "PolyMask 4";
   string Category    = "DVE";
   string SubCategory = "Polymasks";
   string Notes       = "A four sided adjustable mask with feathered edges and optional background colour";
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define P_SIZE 4

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (fg, s_RawFg);
DefineInput (bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool ColourMask
<
   string Description = "Color Mask";
> = false;

float4 MaskColour
<
   string Description = "Color";
> = {0.0, 0.5, 0.0, 1.0};

bool Invert
<
   string Description = "Invert";
> = true;

float Feather
<
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.0;

float ZoomIt
<
   string Description = "Zoom";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float PanX
<
   string Description = "Move";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float PanY
<
   string Description = "Move";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

bool AspectRatio
<
   string Description = "Aspect Compensation";
> = false;

bool ShowMask
<
   string Description = "Show mask";
> = false;

float P1X
<
   string Group = "Coordinates";
   string Description = "P 1";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

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
> = 0.2;

float P2Y
<
   string Group = "Coordinates";
   string Description = "P 2";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float P3X
<
   string Group = "Coordinates";
   string Description = "P 3";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float P3Y
<
   string Group = "Coordinates";
   string Description = "P 3";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float P4X
<
   string Group = "Coordinates";
   string Description = "P 4";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float P4Y
<
   string Group = "Coordinates";
   string Description = "P 4";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_LineDistance (float2 xy, float2 l1, float2 l2)
{
   float2 Delta = l2 - l1;
   float2 D_sqr = Delta * Delta;
   float2 uv = (xy - l1) * Delta;

   float u = (uv.x + uv.y) / (D_sqr.x + D_sqr.y);

   float2 closestPointOnLine = (u < 0.0) ? l1 : (u > 1.0) ? l2 : l1 + (u * Delta);

   return distance (xy, closestPointOnLine);
}

float fn_PolyDistance (float2 xy, float2 poly [P_SIZE])
{
   float result = 100.0;

   for (int i = 0; i < P_SIZE; i++) {
      int j = (i < 1) ? P_SIZE - 1 : i - 1;

      float2 currentPoint  = poly [i];
      float2 previousPoint = poly [j];

      float segmentDistance = fn_LineDistance (xy, previousPoint, currentPoint);

      if (segmentDistance < result) result = segmentDistance;
   }

   return result;
}

float fn_makePoly (float2 xy, float2 poly [P_SIZE])
{
   float retval = 0.0;

   for (int i = 0; i < P_SIZE; i++) {
      int j = (i < 1) ? P_SIZE - 1 : i - 1;

      if (((poly [j].y > xy.y ) != (poly [i].y > xy.y)) &&
          (xy.x < (poly [i].x - poly [j].x) * (xy.y - poly [j].y) / (poly [i].y - poly [j].y) + poly [j].x))
      retval = abs (retval - 1.0);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return BdrPixel (s_RawBg, uv); }

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float2 poly [P_SIZE] = { { P1X, 1.0 - P1Y }, { P2X, 1.0 - P2Y }, { P3X, 1.0 - P3Y },
                            { P4X, 1.0 - P4Y } };

   float aspect = AspectRatio ? _OutputAspectRatio : 1.0;

   float2 xy = float2 ((uv.x - PanX) * aspect, uv.y + PanY - 1.0) / max (ZoomIt, 1.0e-6) + 0.5.xx;

   float mask  = fn_makePoly (xy, poly);
   float range = fn_PolyDistance (xy, poly);

   if (range < Feather) {
      range *= 0.5 / Feather;
      mask   = (mask > 0.5) ? 0.5 + range : 0.5 - range;
   }

   float4 Mask = (Invert) ? (1.0 - mask).xxxx : mask.xxxx;
   float4 Bgnd = (ColourMask) ? MaskColour : GetPixel (s_Background, uv);

   return (ShowMask) ? Mask : lerp (GetPixel (s_Foreground, uv), Bgnd, Mask.a);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique PolyMask04
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 ExecuteShader (ps_main)
}

