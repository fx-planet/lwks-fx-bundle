// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24

/**
 Transitions between two sources by rotating them horizontally or vertically.  The maths
 used is quite different to that used in the keyed version because of non-linearities that
 were acceptable for that use were not for this.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rotating_Dx.fx
//
// Revision history:
//
// Built jwrl 2021-07-24
// Build date does not reflect upload date because of forum upload problems
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Rotating transition";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "X or Y axis rotating transition";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define PI      3.1415926536
#define TWO_PI  6.2831853072
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Inputs and Samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Amount axis";
   string Enum = "Vertical,Horizontal";
> = 0;

bool Reverse
<
   string Description = "Reverse rotation";
> = false;

float Offset
<
   string Description = "Z offset";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_3Drotate (float2 tl, float2 tr, float2 bl, float2 br, float2 uv)
{
   float2 c1 = tr - bl;
   float2 c2 = br - bl;
   float2 c3 = tl - br - c1;

   float d = (c1.x * c2.y) - (c2.x * c1.y);

   float a = ((c3.x * c2.y) - (c2.x * c3.y)) / d;
   float b = ((c1.x * c3.y) - (c3.x * c1.y)) / d;

   c1 += bl - tl + (a * tr);
   c2 += bl - tl + (b * br);
   d   = (c1.x * (c2.y - (b * tl.y))) - (c1.y * (c2.x + (b * tl.x)))
       + (a * ((c2.x * tl.y) - (c2.y * tl.x)));

   float3x3 m = float3x3 (c2.y - (b * tl.y), (a * tl.y) - c1.y, (c1.y * b) - (a * c2.y),
                          (b * tl.x) - c2.x, c1.x - (a * tl.x), (a * c2.x) - (c1.x * b),
                          (c2.x * tl.y) - (c2.y * tl.x), (c1.y * tl.x) - (c1.x * tl.y),
                          (c1.x * c2.y)  - (c1.y * c2.x)) / d;

   float3 xyz = mul (float3 (uv, 1.0), mul (m, float3x3 (1.0, 0.0.xx, -1.0.xx, -2.0, 0.0.xx, 1.0)));

   return xyz.xy / xyz.z;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_V (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float scale = lerp (0.1, 0.025, Offset);
   float L = (1.0 - cos (Amount * PI)) * 0.5;
   float R = 1.0 - L;
   float X = sin (Amount * TWO_PI) * scale;
   float Y = sin (Amount * PI) * (scale + scale);
   float Z = 1.0 - (tan ((0.5 - abs (Amount - 0.5)) * HALF_PI) * lerp (0.2, 0.0125, Offset));

   float2 xy;

   if (Amount < 0.5) { xy = uv1; }
   else {
      L = 1.0 - L;
      R = 1.0 - R;
      Y = -Y;
      xy = uv2;
   }

   if (Reverse) {
      Y = -Y;
      xy -= float2 (X * 0.5, 0.5);
   }
   else xy -= float2 (-X, 0.5);

   float2 topLeft  = float2 (L, -Y);
   float2 topRight = float2 (R, Y);
   float2 botLeft  = float2 (L, 1.0 + Y);
   float2 botRight = float2 (R, 1.0 - Y);

   xy.y = (xy.y * Z) + 0.5;
   xy   = fn_3Drotate (topLeft, topRight, botLeft, botRight, xy);

   return (Amount < 0.5) ? GetPixel (s_Foreground, xy) : GetPixel (s_Background, xy);
}

float4 ps_main_H (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float scale = lerp (0.1, 0.025, Offset);
   float B = (cos (Amount * PI) + 1.0) * 0.5;
   float T = 1.0 - B;
   float X = sin (Amount * PI) * (scale + scale);
   float Y = sin (Amount * TWO_PI) * scale;
   float Z = 1.0 - (tan ((0.5 - abs (Amount - 0.5)) * HALF_PI) * lerp (0.2, 0.0125, Offset));

   float2 xy;

   if (Amount < 0.5) { xy = uv1; }
   else {
      B = 1.0 - B;
      T = 1.0 - T;
      X = -X;
      xy = uv2;
   }

   if (Reverse) {
      X = -X;
      xy -= float2 (0.5, Y * 0.5);
   }
   else xy -= float2 (0.5, -Y);

   float2 topLeft  = float2 (-X, T);
   float2 topRight = float2 (1.0 + X, T);
   float2 botLeft  = float2 (X, B);
   float2 botRight = float2 (1.0 - X, B);

   xy.x = (xy.x * Z) + 0.5;
   xy   = fn_3Drotate (topLeft, topRight, botLeft, botRight, xy);

   return (Amount < 0.5) ? GetPixel (s_Foreground, xy) : GetPixel (s_Background, xy);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Rotating_Dx_V { pass P_1 ExecuteShader (ps_main_V) }
technique Rotating_Dx_H { pass P_1 ExecuteShader (ps_main_H) }

