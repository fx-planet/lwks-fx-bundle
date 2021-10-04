// @Maintainer jwrl
// @Released 2021-08-31
// @Author jwrl
// @Created 2021-08-31
// @see https://www.lwks.com/media/kunena/attachments/6375/3Dbevel_640.png

/**
 This is a crop tool that provides a 3D bevelled border.  The lighting of the bevel can
 be adjusted in intensity, and the lighting angle can be changed.  Fill lighting is also
 included to soften the shaded areas of the bevel.  A hard-edged outer border is also
 included which simply shades the background by an adjustable amount.

 X-Y positioning of the border and its contents has been included, and simple scaling has
 been provided.  This is not intended as a comprehensive DVE replacement so no X-Y scale
 factors nor rotation has been provided.

 NOTE:  Any alpha information in the foreground is discarded by this effect.  It would
 be hard to maintain in a way that would make sense for all possible needs in any case.
 This means that wherever the foreground and bevelled border appears will be completely
 opaque.  The background alpha is preserved.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 3Dbevel.fx
//
// Version history:
//
// Update 2021-08-31 jwrl:
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "3D bevelled crop";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "This provides a simple crop with an inner 3D bevelled edge and a flat coloured outer border";
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

#define EMPTY  0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define BEVEL  0.1
#define BORDER 0.0125

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);
DefineTarget (Bvl, s_Bevel);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Scale
<
   string Group = "Foreground size and position";
   string Description = "Size";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.1;
   float MaxVal = 5.0;
> = 1.0;

float PosX
<
   string Group = "Foreground size and position";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosY
<
   string Group = "Foreground size and position";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CropLeft
<
   string Group = "Foreground crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float CropTop
<
   string Group = "Foreground crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropRight
<
   string Group = "Foreground crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropBottom
<
   string Group = "Foreground crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Border
<
   string Group = "Border settings";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float4 Colour
<
   string Group = "Border settings";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.375, 0.125, 0.0, 1.0 };

float Bevel
<
   string Group = "Bevel settings";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.125;

float Bstrength
<
   string Group = "Bevel settings";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Intensity
<
   string Group = "Bevel settings";
   string Description = "Light level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.45;

float Angle
<
   string Group = "Bevel settings";
   string Description = "Light angle";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 80.0;

float4 Light
<
   string Group = "Bevel settings";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 1.0, 0.66666667, 0.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 fn_rgb2hsv (float3 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float3 hsv  = float3 (0.0.xx, Cmax);

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float3 fn_hsv2rgb (float3 hsv)
{
   if (hsv.y == 0.0) return hsv.zzz;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (2.0 - hsv.y) - q;

   if (i == 0) return float3 (hsv.z, r, p);
   if (i == 1) return float3 (q, hsv.z, p);
   if (i == 2) return float3 (p, hsv.z, r);
   if (i == 3) return float3 (p, q, hsv.z);
   if (i == 4) return float3 (r, p, hsv.z);

   return float3 (hsv.z, p, q);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These two passes map the foreground and background clips to TEXCOORD3, so that
// variations in clip geometry and rotation are handled without too much effort.

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_crop (float2 uv : TEXCOORD3) : COLOR
{
   float3 retval = GetPixel (s_Foreground, uv).rgb;

   float2 cropAspect = float2 (1.0, _OutputAspectRatio);
   float2 centreCrop = float2 (abs (CropRight - CropLeft), abs (CropTop - CropBottom));
   float2 cropBevel  = centreCrop - (cropAspect * Bevel * BEVEL);
   float2 cropBorder = centreCrop + (cropAspect * Border * BORDER);

   float2 xy1 = uv - float2 (CropRight + CropLeft, 2.0 - CropTop - CropBottom) / 2.0;
   float2 xy2 = abs (xy1) * 2.0;
   float2 xy3 = saturate (xy2 - cropBevel);

   xy3.x *= _OutputAspectRatio;

   if ((xy2.x > cropBevel.x) || (xy2.y > cropBevel.y)) {
      float3 hsv = fn_rgb2hsv (Light.rgb);

      hsv.y *= 0.25;
      hsv.z *= 0.375;

      float2 lit;

      sincos (radians (Angle), lit.x, lit.y);
      lit = (lit + 1.0.xx) * 0.5;

      float amt = (xy1.y > 0.0) ? 1.0 - lit.y : lit.y;

      if (xy3.x > xy3.y) { amt = (xy1.x > 0.0) ? lit.x : 1.0 - lit.x; }

      amt = saturate (0.95 - (amt * Intensity * 2.0)) * 6.0;
      amt = (amt >= 3.0) ? amt - 2.0 : 1.0 / (4.0 - amt);
      hsv.z = pow (hsv.z, amt);

      if (hsv.z > 0.5) hsv.y = saturate (hsv.y - hsv.z + 0.5);

      hsv.z = saturate (hsv.z * 2.0);

      retval = lerp (retval, fn_hsv2rgb (hsv), (Bstrength * 0.5) + 0.25);
   }

   if ((xy2.x > centreCrop.x) || (xy2.y > centreCrop.y)) { retval = Colour.rgb; }

   return ((xy2.x > cropBorder.x) || (xy2.y > cropBorder.y)) ? EMPTY : float4 (retval, 1.0);
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy = ((uv - float2 (PosX, 1.0 - PosY)) / max (1e-6, Scale)) + 0.5.xx;

   float4 Fgnd = GetPixel (s_Bevel, xy);

   return lerp (GetPixel (s_Background, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Bevel3D
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = Bvl;"; > ExecuteShader (ps_crop)
   pass P_2 ExecuteShader (ps_main)
}

