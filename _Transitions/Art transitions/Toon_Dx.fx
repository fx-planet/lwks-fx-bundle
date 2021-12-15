// @Maintainer jwrl
// @Released 2021-12-15
// @Author jwrl
// @Created 2021-12-15
// @see https://forum.lwks.com/data/video/40/40022-ea57525bdd87344d53a514c3ec0f937c.mp4

/**
 This transition posterizes the outgoing image then develops outlines from the image edges
 while dissolving to the incoming image.  With the incoming image the process is reversed.
 The intention is to mimic khaver's Toon effect, but apply it to a transition.  While it's
 similar, there's an extra parameter provided that allows adjustment of the white levels of
 the posterised colours.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Toon_Dx.fx
//
// Version history:
//
// First built 2021-11-25 jwrl.
// Originally built as proof of concept only.  This version is considerably improved.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Toon transition";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "A stylised cartoon transition between the two images";
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
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define ONE_THIRD  0.3333333333
#define PI         3.1415926536

float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Mix_1, s_Mix_1);
DefineTarget (Mix_2, s_Mix_2);
DefineTarget (Pre, s_PreBlur);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0 = 0.0;
   float KF1 = 1.0;
> = 0.5;

float Threshold
<
   string Group = "Edge detection";
   string Description = "Threshold";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 0.3;

float LineWeightX
<
   string Group = "Edge detection";
   string Description = "Line weight X";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float LineWeightY
<
   string Group = "Edge detection";
   string Description = "Line weight Y";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int PosterizeDepth
<
   string Group = "Posterize preprocess";
   string Description = "Posterize depth";
   string Enum = "2,3,4,5,6,7,8";
> = 3;

float Preblur
<
   string Group = "Posterize preprocess";
   string Description = "Preblur";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Saturation
<
   string Group = "Posterize preprocess";
   string Flags = "DisplayAsPercentage";
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 4.0;
> = 2.5;

float Gamma
<
   string Group = "Posterize preprocess";
   string Description = "Gamma";
   float MinVal = 0.1;
   float MaxVal = 4.0;
> = 0.6;

float Brightness
<
   string Group = "Posterize postprocess";
   string Flags = "DisplayAsPercentage";
   string Description = "Brightness";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Contrast
<
   string Group = "Posterize postprocess";
   string Flags = "DisplayAsPercentage";
   string Description = "Contrast";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float Gain
<
   string Group = "Posterize postprocess";
   string Flags = "DisplayAsPercentage";
   string Description = "Gain";
   float MinVal = 0.0;
   float MaxVal = 4.0;
> = 1.0;

float HueAngle
<
   string Group = "Posterize postprocess";
   string Description = "Hue (degrees)";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 fn_HSLtoRGB (float3 HSL)
{
   float3 RGB;

   float dif = HSL.y - HSL.z;

   RGB.r = HSL.x + ONE_THIRD;
   RGB.b = HSL.x - ONE_THIRD;

   RGB.r = (RGB.r < 0.0) ? RGB.r + 1.0 : (RGB.r > 1.0) ? RGB.r - 1.0 : RGB.r;
   RGB.g = (HSL.x < 0.0) ? HSL.x + 1.0 : (HSL.x > 1.0) ? HSL.x - 1.0 : HSL.x;
   RGB.b = (RGB.b < 0.0) ? RGB.b + 1.0 : (RGB.b > 1.0) ? RGB.b - 1.0 : RGB.b;

   RGB *= 6.0;

   RGB.r = (RGB.r < 1.0) ? (RGB.r * dif) + HSL.z :
           (RGB.r < 3.0) ? HSL.y :
           (RGB.r < 4.0) ? ((4.0 - RGB.r) * dif) + HSL.z : HSL.z;

   RGB.g = (RGB.g < 1.0) ? (RGB.g * dif) + HSL.z :
           (RGB.g < 3.0) ? HSL.y :
           (RGB.g < 4.0) ? ((4.0 - RGB.g) * dif) + HSL.z : HSL.z;

   RGB.b = (RGB.b < 1.0) ? (RGB.b * dif) + HSL.z :
           (RGB.b < 3.0) ? HSL.y :
           (RGB.b < 4.0) ? ((4.0 - RGB.b) * dif) + HSL.z : HSL.z;

   return RGB;
}

float3 fn_RGBtoHSL (float3 RGB)
{
   float high  = max (RGB.r, max (RGB.g, RGB.b));
   float lows  = min (RGB.r, min (RGB.g, RGB.b));
   float range = high - lows;
   float Lraw  = high + lows;

   float Luma  = Lraw * 0.5;
   float Hue   = 0.0;
   float Satn  = 0.0;

   if (range != 0.0) {
      Satn = (Lraw < 1.0) ? range / Lraw : range / (2.0 - Lraw);

      if (RGB.r == high) { Hue = (RGB.g - RGB.b) / range; }
      else if (RGB.g == high) { Hue = 2.0 + (RGB.b - RGB.r) / range; }
      else { Hue = 4.0 + (RGB.r - RGB.g) / range; }

      Hue /= 6.0;
   }

   return float3 (Hue, Satn, Luma);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mix (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float Amt = saturate ((Amount - 0.25) * 2.0);

   return lerp (GetPixel (s_Foreground, uv1), GetPixel (s_Background, uv2), Amt);
}

float4 ps_blurX (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_Mix_1, uv);

   // What follows is the horizontal component of a standard box blur.  The maths used
   // takes advantage of the fact that the shader language can do float2 operations as
   // efficiently as floats.  This way we save on having to manufacture a new float2
   // every time that we need a new address for the next tap.

   float2 xy0 = float2 (Preblur / _OutputWidth, 0.0);
   float2 xy1 = uv + xy0;
   float2 xy2 = uv - xy0;

   retval += tex2D (s_Mix_1, xy1); xy1 += xy0;
   retval += tex2D (s_Mix_1, xy1); xy1 += xy0;
   retval += tex2D (s_Mix_1, xy1); xy1 += xy0;
   retval += tex2D (s_Mix_1, xy1); xy1 += xy0;
   retval += tex2D (s_Mix_1, xy1); xy1 += xy0;
   retval += tex2D (s_Mix_1, xy1);
   retval += tex2D (s_Mix_1, xy2); xy2 -= xy0;
   retval += tex2D (s_Mix_1, xy2); xy2 -= xy0;
   retval += tex2D (s_Mix_1, xy2); xy2 -= xy0;
   retval += tex2D (s_Mix_1, xy2); xy2 -= xy0;
   retval += tex2D (s_Mix_1, xy2); xy2 -= xy0;
   retval += tex2D (s_Mix_1, xy2);

   // Divide retval by 13 because there are 12 sampling taps plus the original image

   return retval / 13.0;
}

float4 ps_blurY (float2 uv : TEXCOORD3) : COLOR
{
   float4 RGB = tex2D (s_PreBlur, uv);

   float alpha = RGB.a;

   // This is the vertical component of the box blur.

   float2 xy0 = float2 (0.0, Preblur / _OutputHeight);
   float2 xy1 = uv + xy0;
   float2 xy2 = uv - xy0;

   RGB += tex2D (s_PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (s_PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (s_PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (s_PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (s_PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (s_PreBlur, xy1);
   RGB += tex2D (s_PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (s_PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (s_PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (s_PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (s_PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (s_PreBlur, xy2);

   RGB /= 13.0;

   float posterize = PosterizeDepth + 2.0;

   // We now adjust the brightness, contrast, gamma and gain of the blurred image.

   float3 proc = (((pow (RGB.rgb, 1.0 / Gamma) * Gain * 0.5) + (Brightness - 0.5).xxx) * Contrast) + 0.5.xxx;
   float3 HSL = fn_RGBtoHSL (proc);

   HSL.y = saturate (HSL.y * Saturation);
   HSL.x = HSL.x + frac (HueAngle / 360.0);

   if (HSL.x < 0.0) HSL.x += 1.0;
   if (HSL.x > 1.0) HSL.x -= 1.0;

   HSL.yz = saturate (round (HSL.yz * posterize) / posterize);

   if (HSL.y == 0.0) return float4 (HSL.zzz, RGB.a);

   posterize *= 6.0;
   HSL.x = round (HSL.x * posterize) / posterize;

   if (HSL.x < 0.0) HSL.x += 1.0;
   if (HSL.x > 1.0) HSL.x -= 1.0;

   float S = HSL.y * HSL.z * (1.0 + (sin (Amount * PI) * 2.0));

   HSL.y = (HSL.z < 0.5) ? HSL.z + S : (HSL.y + HSL.z) - S;
   HSL.z = (2.0 * HSL.z) - HSL.y;

   return float4 (fn_HSLtoRGB (HSL), 1.0);
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float Amt = max ((abs (Amount - 0.5) * 2.0) - 0.5, 0.0) * 2.0;
   float Thr = Threshold * Threshold;
   float W_X = 100.0 + ((1.0 - LineWeightX) * 2048.0);
   float W_Y = 100.0 + ((1.0 - LineWeightY) * 2048.0);

   Thr *= Thr;

   float2 LwX = float2 (1.0 / W_X, 0.0);
   float2 LwY = float2 (0.0, 1.0 / W_Y);
   float2 xy1 = uv - LwY;
   float2 xy2 = uv + LwY;

   // Convolution

   float4 vidX = GetPixel (s_Mix_1, xy1 - LwX);
   float4 vidY = vidX;
   float4 conv = GetPixel (s_Mix_1, xy1 + LwX);

   vidX += conv - (GetPixel (s_Mix_1, xy1));
   vidY -= (conv - GetPixel (s_Mix_1, uv - LwX) + GetPixel (s_Mix_1, uv + LwX));

   conv  = GetPixel (s_Mix_1, xy2 - LwX);
   vidX -= (conv - GetPixel (s_Mix_1, xy2));
   vidY += conv;
   conv  = GetPixel (s_Mix_1, xy2 + LwX);
   vidX -= conv;
   vidY -= conv;
   conv  = (vidX * vidX) + (vidY * vidY);

   // Add and apply threshold

   float outlines = ((conv.x <= Thr) + (conv.y <= Thr) + (conv.z <= Thr)) / 3.0;
   float sinAmt = sin (Amount * PI);

   float4 Bgnd = GetPixel (s_Mix_1, uv);
   float4 retval = lerp (float4 (outlines.xxx, 1.0), Bgnd, Amt);
   float4 Fgnd = GetPixel (s_Mix_2, uv);

   float3 pp = fn_RGBtoHSL (Fgnd.rgb);

   float alpha = saturate (Bgnd.a * 3.0);

   pp.x  = pp.x > 0.5 ? pp.x - 0.5 : pp.x + 0.5;
   pp.yz = 1.0.xx - pp.yz;
   pp    = lerp (fn_HSLtoRGB (pp), 1.0.xxx, sinAmt * 0.5);
   Fgnd  = lerp (Fgnd, float4 (pp, Fgnd.a), sinAmt);

   Amt = 1.0 - max ((Amt - 0.5) * 2.0, 0.0);
   Bgnd = lerp (Bgnd, saturate (Fgnd), Amt);

   retval.rgb = min (retval.rgb, Bgnd.rgb) * alpha;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Toon_Dx
{
   pass P_1 < string Script = "RenderColorTarget0 = Mix_1;"; > ExecuteShader (ps_mix)
   pass P_2 < string Script = "RenderColorTarget0 = Pre;"; > ExecuteShader (ps_blurX)
   pass P_3 < string Script = "RenderColorTarget0 = Mix_2;"; > ExecuteShader (ps_blurY)
   pass P_4 ExecuteShader (ps_main)
}

