// @Maintainer jwrl
// @Released 2021-08-01
// @Author jwrl
// @Created 2021-08-01
// @see https://www.lwks.com/media/kunena/attachments/6375/MaskedMix_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/MaskedMixRoute.png

/**
 This is a variant of Lightworks' masked blend that allows the mask to be mixed with
 the foreground.  There are some major differences.  The first is that instead of
 putting the mask input on the bottom layer it is placed on the top.  This just appears
 to make more sense to me.  The next layer is the fill layer, then the bottom is the
 background.  The next difference is that the blend can be enhanced to better handle
 title effects.  Third, when used with title effects drop shadows will be preserved.
 This has implications if you choose to use coloured drop shadows, because they will
 be affected by the fill layer.

 To circumvent issues like that, this effect also has the ability to derive the mask
 using a colour match process.  This also helps where the mask doesn't have at least
 one of red, green or blue at maximum level.  It adds two controls to do this: one for
 enabling and disabling colour matching, and the other for selecting the colour to
 match.  The simplest way to match the colours is to apply the effect, disable it so
 that the foreground layer is displayed, and use the eyedropper on the colour wheel
 to select the colour to match.  Once you have the match, enable the effect and
 continue with the rest of the setup process.

 Finally, blending treats the foreground/fill mix as a single layer over the background.
 While every attempt has been made to match the standard blend modes used in graphic
 arts software, hue blending has been modified to give a cleaner fill mix.  Also, because
 of the reorganisation and renaming of the mask layers compared to the Lightworks masked
 blend effect, bypassing the effect will show the foreground layer, and not the fill layer.
 This was considered to be a reasonable change.
*/

//-----------------------------------------------------------------------------------------//
// User effect MaskedMix.fx
//
// Version history:
//
// Rewrite 2021-08-01 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Added extra mode to allow preservation of unmatched mask colours.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Masked mix";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "This is a variant of masked blend that allows the fill to be mixed with the mask colour.";
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
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define HALF_PI 1.5707963268

#define CrR      0.439
#define CrG      0.368
#define CrB      0.071

#define CbR      0.148
#define CbG      0.291
#define CbB      0.439

#define Rr_R     1.596
#define Rg_R     0.813
#define Rg_B     0.391
#define Rb_B     2.018

#define WHITErgb 1.0.xxx
#define BLACKrgb 0.0.xxx
#define WHITE    1.0.xxxx

#define LUMA    float4(0.2989, 0.5866, 0.1145, 0.0)

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Fill, s_Fill);
DefineInput (Bg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Source
<
   string Description = "Lightworks effects: Disconnect the input and select";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image";
> = 1;

int SetTechnique
<
   string Description = "Blend mode";
   string Enum = "Normal,____________________,Darken,Multiply,Colour Burn,Linear Burn,Darker Colour,____________________,Lighten,Screen,Colour Dodge,Linear Dodge (Add),Lighter Colour,____________________,Overlay,Soft Light,Hard Light,Vivid Light,Linear Light,Pin Light,Hard Mix,____________________,Difference,Exclusion,Subtract,Divide,____________________,Hue,Saturation,Colour,Luminosity";
> = 0;

float Mix
<
   string Description = "Fill mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int Mode
<
   string Description = "Use as mask:";
   string Enum = "Foreground,Matching foreground colour,Matching colour + alpha";
> = 0;

float4 MatchColour
<
   string Description = "Colour to match";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 1.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_rgb2hsv (float4 rgb)
{
   float4 K = float4 (0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
   float4 p = lerp (float4 (rgb.bg, K.wz), float4 (rgb.gb, K.xy), step (rgb.b, rgb.g));
   float4 q = lerp (float4 (p.xyw, rgb.r), float4 (rgb.r, p.yzx), step (p.x, rgb.r));

   float d = q.x - min (q.w, q.y);
   float e = 1.0e-10;

   return float4 (abs (q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x, rgb.a);
}

float4 fn_hsv2rgb (float4 hsv)
{
   float3 hue = float3 (1.0, 2.0 / 3.0, 1.0 / 3.0);
   float3 rgb = saturate (abs (frac (hsv.xxx + hue) * 6.0 - 3.0) - 1.0.xxx);

   return float4 (hsv.z * lerp (1.0.xxx, rgb, hsv.y), hsv.w);
}

float4 fn_textr (sampler s_Mask, float2 xy1, sampler s_Texture, float2 xy2)
{
   float4 Fgd = GetPixel (s_Mask, xy1);
   float4 Tex = GetPixel (s_Texture, xy2);

   float alpha = (Mode == 0) ? max (Fgd.r, max (Fgd.g, Fgd.b))
                             : smoothstep (1.0, 0.0, distance (MatchColour, Fgd));

   if (Mode == 2) { Fgd.rgb = lerp (Fgd.rgb, Tex.rgb, alpha * Mix); }
   else {
      Tex.rgb *= min (alpha, Tex.a);
      Fgd.rgb  = lerp (Fgd.rgb, Tex.rgb, Mix);
   }

   if (Source == 0) {
      Fgd.a    = pow (Fgd.a, 0.5);
      Fgd.rgb /= Fgd.a;
   }

   return Fgd;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_null (float2 uv : TEXCOORD1) : COLOR
{
   return GetPixel (s_Background, uv);
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return float4 (Fgnd.rgb, max (Fgnd.a, Bgnd.a));
}

//--------------------------------------- GROUP 1 -----------------------------------------//

float4 ps_darken (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = min (Fgnd.rgb, Bgnd.rgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_multiply (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb *= Bgnd.rgb;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_colourBurn (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   if (Fgnd.r > 0.0) Fgnd.r = 1.0 - ((1.0 - Bgnd.r) / Fgnd.r);
   if (Fgnd.g > 0.0) Fgnd.g = 1.0 - ((1.0 - Bgnd.g) / Fgnd.g);
   if (Fgnd.b > 0.0) Fgnd.b = 1.0 - ((1.0 - Bgnd.b) / Fgnd.b);

   return lerp (Bgnd, min (Fgnd, WHITE), Fgnd.a * Amount);
}

float4 ps_linearBurn (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = max (Fgnd.rgb + Bgnd.rgb - WHITErgb, BLACKrgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_darkerColour (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float luma = dot (Bgnd, LUMA);

   if (dot (Fgnd, LUMA) > luma) Fgnd.rgb = Bgnd.rgb;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 2 -----------------------------------------//

float4 ps_lighten (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = max (Fgnd.rgb, Bgnd.rgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_screen (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_colourDodge (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (1.0 - Fgnd.r);
   Fgnd.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (1.0 - Fgnd.g);
   Fgnd.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (1.0 - Fgnd.b);

   return lerp (Bgnd, min (Fgnd, WHITE), Fgnd.a * Amount);
}

float4 ps_linearDodge (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = min (Fgnd.rgb + Bgnd.rgb, WHITErgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_lighterColour (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float  luma = dot (Bgnd, LUMA);

   if (dot (Fgnd, LUMA) < luma) Fgnd.rgb = Bgnd.rgb;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 3 -----------------------------------------//

float4 ps_overlay (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 retMin = 2.0 * Bgnd.rgb * Fgnd.rgb;
   float3 retMax = WHITErgb - 2.0 * (WHITErgb - Fgnd.rgb) * (WHITErgb - Bgnd.rgb);

   Fgnd.r = (Bgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Bgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Bgnd.b <= 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_softLight (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 retMax = (2.0 * Fgnd.rgb) - WHITErgb;
   float3 retMin = Bgnd.rgb * (retMax * (WHITErgb - Bgnd.rgb) + WHITErgb);

   retMax *= sqrt (Bgnd.rgb) - Bgnd.rgb;
   retMax += Bgnd.rgb;

   Fgnd.r = (Fgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b <= 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_hardLight (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 retMin = saturate (2.0 * Bgnd.rgb * Fgnd.rgb);
   float3 retMax = saturate (WHITErgb - 2.0 * (WHITErgb - Bgnd.rgb) * (WHITErgb - Fgnd.rgb));

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_vividLight (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 retMax, retMin;

   retMin.r = (Fgnd.r == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.r) / (2.0 * Fgnd.r)), 0.0);
   retMin.g = (Fgnd.g == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.g) / (2.0 * Fgnd.g)), 0.0);
   retMin.b = (Fgnd.b == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.b) / (2.0 * Fgnd.b)), 0.0);

   retMax.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (2.0 * (1.0 - Fgnd.r));
   retMax.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (2.0 * (1.0 - Fgnd.g));
   retMax.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (2.0 * (1.0 - Fgnd.b));

   retMin = min (retMin, WHITErgb);
   retMax = min (retMax, WHITErgb);

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_linearLight (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 retMin = max ((2.0 * Fgnd.rgb) + Bgnd.rgb - WHITErgb, BLACKrgb);
   float3 retMax = min ((2.0 * Fgnd.rgb) + Bgnd.rgb - WHITErgb, WHITErgb);

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_pinLight (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 retMax = 2.0 * Fgnd.rgb;
   float3 retMin = retMax - WHITErgb;

   Fgnd.r = (Bgnd.r > retMax.r) ? retMax.r : (Bgnd.r < retMin.r) ? retMin.r : Bgnd.r;
   Fgnd.g = (Bgnd.g > retMax.g) ? retMax.g : (Bgnd.g < retMin.g) ? retMin.g : Bgnd.g;
   Fgnd.b = (Bgnd.b > retMax.b) ? retMax.b : (Bgnd.b < retMin.b) ? retMin.b : Bgnd.b;

   return lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_hardMix (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 ref = WHITErgb - Bgnd.rgb;

   Fgnd.r = (Fgnd.r < ref.r) ? 0.0 : 1.0;
   Fgnd.g = (Fgnd.g < ref.g) ? 0.0 : 1.0;
   Fgnd.b = (Fgnd.b < ref.b) ? 0.0 : 1.0;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 4 -----------------------------------------//

float4 ps_difference (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = abs (Fgnd.rgb - Bgnd.rgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_exclusion (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb * (WHITErgb - (2.0 * Fgnd.rgb)));

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_subtract (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = max (Bgnd.rgb - Fgnd.rgb, BLACKrgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_divide (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.r = (Fgnd.r == 0.0) ? 1.0 : min (Bgnd.r / Fgnd.r, 1.0);
   Fgnd.g = (Fgnd.g == 0.0) ? 1.0 : min (Bgnd.g / Fgnd.g, 1.0);
   Fgnd.b = (Fgnd.b == 0.0) ? 1.0 : min (Bgnd.b / Fgnd.b, 1.0);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 5 -----------------------------------------//

float4 ps_hue (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);
   float4 blnd = fn_rgb2hsv (Bgnd);
   float4 ref  = fn_rgb2hsv (Fgnd);

   blnd.xw = ref.xw;
   blnd.y *= sin (min (1.0, ref.y * 2.0) * HALF_PI);

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_saturation (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.yw = fn_rgb2hsv (Fgnd).yw;

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_colour (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);
   float4 blnd = fn_rgb2hsv (Fgnd);

   blnd.x = (fn_rgb2hsv (Bgnd)).x;

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_luminosity (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_textr (s_Foreground, uv1, s_Fill, uv2);
   float4 Bgnd = GetPixel (s_Background, uv3);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.zw = (fn_rgb2hsv (Fgnd)).zw;

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//;
// Techniques;
//-----------------------------------------------------------------------------------------//;

technique Normal        { pass P_1 ExecuteShader (ps_main) }

//--------------------------------------- GROUP 1 -----------------------------------------//

technique Group_1       { pass P_1 ExecuteShader (ps_null) }
technique Darken        { pass P_1 ExecuteShader (ps_darken) }
technique Multiply      { pass P_1 ExecuteShader (ps_multiply) }
technique ColourBurn    { pass P_1 ExecuteShader (ps_colourBurn) }
technique LinearBurn    { pass P_1 ExecuteShader (ps_linearBurn) }
technique DarkerColour  { pass P_1 ExecuteShader (ps_darkerColour) }

//--------------------------------------- GROUP 2 -----------------------------------------//

technique Group_2       { pass P_1 ExecuteShader (ps_null) }
technique Lighten       { pass P_1 ExecuteShader (ps_lighten) }
technique Screen        { pass P_1 ExecuteShader (ps_screen) }
technique ColourDodge   { pass P_1 ExecuteShader (ps_colourDodge) }
technique LinearDodge   { pass P_1 ExecuteShader (ps_linearDodge) }
technique LighterColour { pass P_1 ExecuteShader (ps_lighterColour) }

//--------------------------------------- GROUP 3 -----------------------------------------//

technique Group_3       { pass P_1 ExecuteShader (ps_null) }
technique Overlay       { pass P_1 ExecuteShader (ps_overlay) }
technique SoftLight     { pass P_1 ExecuteShader (ps_softLight) }
technique Hardlight     { pass P_1 ExecuteShader (ps_hardLight) }
technique Vividlight    { pass P_1 ExecuteShader (ps_vividLight) }
technique Linearlight   { pass P_1 ExecuteShader (ps_linearLight) }
technique Pinlight      { pass P_1 ExecuteShader (ps_pinLight) }
technique HardMix       { pass P_1 ExecuteShader (ps_hardMix) }

//--------------------------------------- GROUP 4 -----------------------------------------//

technique Group_4       { pass P_1 ExecuteShader (ps_null) }
technique Difference    { pass P_1 ExecuteShader (ps_difference) }
technique Exclusion     { pass P_1 ExecuteShader (ps_exclusion) }
technique Subtract      { pass P_1 ExecuteShader (ps_subtract) }
technique Divide        { pass P_1 ExecuteShader (ps_divide) }

//--------------------------------------- GROUP 5 -----------------------------------------//

technique Group_5       { pass P_1 ExecuteShader (ps_null) }
technique Hue           { pass P_1 ExecuteShader (ps_hue) }
technique Saturation    { pass P_1 ExecuteShader (ps_saturation) }
technique Colour        { pass P_1 ExecuteShader (ps_colour) }
technique Luminosity    { pass P_1 ExecuteShader (ps_luminosity) }

