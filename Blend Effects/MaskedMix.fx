// @Maintainer jwrl
// @Released 2020-05-26
// @Author jwrl
// @Created 2020-05-23
// @see https://www.lwks.com/media/kunena/attachments/6375/MaskedMix_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/MaskedMixRoute.png

/**
 This is a variant of Editshare's masked blend that allows the mask to be mixed with
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
// Modified 2020-05-25 jwrl:
// Added the ability to derive the mask by colour matching.
//
// Modified 2020-05-26 jwrl:
// Reworked the fill masking to clean up the edges.  Previously there was a visible hard
// edge between the masked fill and the foreground.  That has now been fixed.
// From here on are cosmetic changes only!
// Descriptive header completely rewritten.
// Notes string reworded to hopefully be clearer.
// Parameter Mode changed from "Mask mode" to "Use as mask:".
// First Mode enumerator now reads "Foreground" and not "Foreground luminance".
// Second Mode enumerator is now "Matching foreground colour" not "Foreground colour match".
// Parameter MatchColour changed from "Colour match" to read "Colour to match".
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Masked mix";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "This is a variant of masked blend that allows the masked fill to be mixed with the mask colour.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Fill;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Fill = sampler_state { Texture = <Fill>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Source
<
   string Description = "Source selection (disconnect input to text effects first)";
   string Enum = "Crawl / roll / titles,Video / external image";
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
   string Enum = "Foreground,Matching foreground colour";
> = 0;

float4 MatchColour
<
   string Description = "Colour to match";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 1.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI 1.5707963268

#define CrR     0.439
#define CrG     0.368
#define CrB     0.071

#define CbR     0.148
#define CbG     0.291
#define CbB     0.439

#define Rr_R    1.596
#define Rg_R    0.813
#define Rg_B    0.391
#define Rb_B    2.018

#define WHITE   1.0.xxx
#define BLACK   0.0.xxx
#define PEAK    1.0.xxxx

#define LUMA    float4(0.2989, 0.5866, 0.1145, 0.0)

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

float4 fn_tx (sampler s_Mask, float2 xy1, sampler s_Texture, float2 xy2)
{
   float4 Fgd = tex2D (s_Mask, xy1);
   float4 Tex = tex2D (s_Texture, xy2);

   float alpha = (Mode == 0) ? max (Fgd.r, max (Fgd.g, Fgd.b))
                             : smoothstep (1.0, 0.0, distance (MatchColour, Fgd));

   Tex.rgb *= min (alpha, Tex.a);
   Fgd.rgb  = lerp (Fgd.rgb, Tex.rgb, Mix);

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
   return tex2D (s_Background, uv);
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   Fgnd = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return float4 (Fgnd.rgb, max (Fgnd.a, Bgnd.a));
}

//--------------------------------------- GROUP 1 -----------------------------------------//

float4 ps_darken (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   Fgnd.rgb = min (Fgnd.rgb, Bgnd.rgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_multiply (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   Fgnd.rgb *= Bgnd.rgb;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_colourBurn (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   if (Fgnd.r > 0.0) Fgnd.r = 1.0 - ((1.0 - Bgnd.r) / Fgnd.r);
   if (Fgnd.g > 0.0) Fgnd.g = 1.0 - ((1.0 - Bgnd.g) / Fgnd.g);
   if (Fgnd.b > 0.0) Fgnd.b = 1.0 - ((1.0 - Bgnd.b) / Fgnd.b);

   return lerp (Bgnd, min (Fgnd, PEAK), Fgnd.a * Amount);
}

float4 ps_linearBurn (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   Fgnd.rgb = max (Fgnd.rgb + Bgnd.rgb - WHITE, BLACK);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_darkerColour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   float luma = dot (Bgnd, LUMA);

   if (dot (Fgnd, LUMA) > luma) Fgnd.rgb = Bgnd.rgb;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 2 -----------------------------------------//

float4 ps_lighten (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   Fgnd.rgb = max (Fgnd.rgb, Bgnd.rgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_screen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_colourDodge (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   Fgnd.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (1.0 - Fgnd.r);
   Fgnd.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (1.0 - Fgnd.g);
   Fgnd.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (1.0 - Fgnd.b);

   return lerp (Bgnd, min (Fgnd, PEAK), Fgnd.a * Amount);
}

float4 ps_linearDodge (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   Fgnd.rgb = min (Fgnd.rgb + Bgnd.rgb, WHITE);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_lighterColour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   float  luma = dot (Bgnd, LUMA);

   if (dot (Fgnd, LUMA) < luma) Fgnd.rgb = Bgnd.rgb;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 3 -----------------------------------------//

float4 ps_overlay (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   float3 retMin = 2.0 * Bgnd.rgb * Fgnd.rgb;
   float3 retMax = WHITE - 2.0 * (WHITE - Fgnd.rgb) * (WHITE - Bgnd.rgb);

   Fgnd.r = (Bgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Bgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Bgnd.b <= 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_softLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   float3 retMax = (2.0 * Fgnd.rgb) - WHITE;
   float3 retMin = Bgnd.rgb * (retMax * (WHITE - Bgnd.rgb) + WHITE);

   retMax *= sqrt (Bgnd.rgb) - Bgnd.rgb;
   retMax += Bgnd.rgb;

   Fgnd.r = (Fgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b <= 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_hardLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   float3 retMin = saturate (2.0 * Bgnd.rgb * Fgnd.rgb);
   float3 retMax = saturate (WHITE - 2.0 * (WHITE - Bgnd.rgb) * (WHITE - Fgnd.rgb));

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_vividLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   float3 retMax, retMin;

   retMin.r = (Fgnd.r == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.r) / (2.0 * Fgnd.r)), 0.0);
   retMin.g = (Fgnd.g == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.g) / (2.0 * Fgnd.g)), 0.0);
   retMin.b = (Fgnd.b == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.b) / (2.0 * Fgnd.b)), 0.0);

   retMax.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (2.0 * (1.0 - Fgnd.r));
   retMax.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (2.0 * (1.0 - Fgnd.g));
   retMax.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (2.0 * (1.0 - Fgnd.b));

   retMin = min (retMin, WHITE);
   retMax = min (retMax, WHITE);

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_linearLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   float3 retMin = max ((2.0 * Fgnd.rgb) + Bgnd.rgb - WHITE, BLACK);
   float3 retMax = min ((2.0 * Fgnd.rgb) + Bgnd.rgb - WHITE, WHITE);

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_pinLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   float3 retMax = 2.0 * Fgnd.rgb;
   float3 retMin = retMax - WHITE;

   Fgnd.r = (Bgnd.r > retMax.r) ? retMax.r : (Bgnd.r < retMin.r) ? retMin.r : Bgnd.r;
   Fgnd.g = (Bgnd.g > retMax.g) ? retMax.g : (Bgnd.g < retMin.g) ? retMin.g : Bgnd.g;
   Fgnd.b = (Bgnd.b > retMax.b) ? retMax.b : (Bgnd.b < retMin.b) ? retMin.b : Bgnd.b;

   return lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_hardMix (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   float3 ref = WHITE - Bgnd.rgb;

   Fgnd.r = (Fgnd.r < ref.r) ? 0.0 : 1.0;
   Fgnd.g = (Fgnd.g < ref.g) ? 0.0 : 1.0;
   Fgnd.b = (Fgnd.b < ref.b) ? 0.0 : 1.0;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 4 -----------------------------------------//

float4 ps_difference (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   Fgnd.rgb = abs (Fgnd.rgb - Bgnd.rgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_exclusion (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb * (WHITE - (2.0 * Fgnd.rgb)));

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_subtract (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   Fgnd.rgb = max (Bgnd.rgb - Fgnd.rgb, BLACK);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_divide (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);

   Fgnd.r = (Fgnd.r == 0.0) ? 1.0 : min (Bgnd.r / Fgnd.r, 1.0);
   Fgnd.g = (Fgnd.g == 0.0) ? 1.0 : min (Bgnd.g / Fgnd.g, 1.0);
   Fgnd.b = (Fgnd.b == 0.0) ? 1.0 : min (Bgnd.b / Fgnd.b, 1.0);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 5 -----------------------------------------//

float4 ps_hue (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);
   float4 blnd = fn_rgb2hsv (Bgnd);
   float4 ref  = fn_rgb2hsv (Fgnd);

   blnd.xw = ref.xw;
   blnd.y *= sin (min (1.0, ref.y * 2.0) * HALF_PI);

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_saturation (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.yw = fn_rgb2hsv (Fgnd).yw;

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_colour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);
   float4 blnd = fn_rgb2hsv (Fgnd);

   blnd.x = (fn_rgb2hsv (Bgnd)).x;

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_luminosity (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = fn_tx (s_Foreground, xy1, s_Fill, xy2);
   float4 Bgnd = tex2D (s_Background, xy3);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.zw = (fn_rgb2hsv (Fgnd)).zw;

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//;
// Techniques;
//-----------------------------------------------------------------------------------------//;

technique Normal        { pass P_1 { PixelShader = compile PROFILE ps_main (); } }

//--------------------------------------- GROUP 1 -----------------------------------------//

technique Group_1       { pass P_1 { PixelShader = compile PROFILE ps_null (); } }
technique Darken        { pass P_1 { PixelShader = compile PROFILE ps_darken (); } }
technique Multiply      { pass P_1 { PixelShader = compile PROFILE ps_multiply (); } }
technique ColourBurn    { pass P_1 { PixelShader = compile PROFILE ps_colourBurn (); } }
technique LinearBurn    { pass P_1 { PixelShader = compile PROFILE ps_linearBurn (); } }
technique DarkerColour  { pass P_1 { PixelShader = compile PROFILE ps_darkerColour (); } }

//--------------------------------------- GROUP 2 -----------------------------------------//

technique Group_2       { pass P_1 { PixelShader = compile PROFILE ps_null (); } }
technique Lighten       { pass P_1 { PixelShader = compile PROFILE ps_lighten (); } }
technique Screen        { pass P_1 { PixelShader = compile PROFILE ps_screen (); } }
technique ColourDodge   { pass P_1 { PixelShader = compile PROFILE ps_colourDodge (); } }
technique LinearDodge   { pass P_1 { PixelShader = compile PROFILE ps_linearDodge (); } }
technique LighterColour { pass P_1 { PixelShader = compile PROFILE ps_lighterColour (); } }

//--------------------------------------- GROUP 3 -----------------------------------------//

technique Group_3       { pass P_1 { PixelShader = compile PROFILE ps_null (); } }
technique Overlay       { pass P_1 { PixelShader = compile PROFILE ps_overlay (); } }
technique SoftLight     { pass P_1 { PixelShader = compile PROFILE ps_softLight (); } }
technique Hardlight     { pass P_1 { PixelShader = compile PROFILE ps_hardLight (); } }
technique Vividlight    { pass P_1 { PixelShader = compile PROFILE ps_vividLight (); } }
technique Linearlight   { pass P_1 { PixelShader = compile PROFILE ps_linearLight (); } }
technique Pinlight      { pass P_1 { PixelShader = compile PROFILE ps_pinLight (); } }
technique HardMix       { pass P_1 { PixelShader = compile PROFILE ps_hardMix (); } }

//--------------------------------------- GROUP 4 -----------------------------------------//

technique Group_4       { pass P_1 { PixelShader = compile PROFILE ps_null (); } }
technique Difference    { pass P_1 { PixelShader = compile PROFILE ps_difference (); } }
technique Exclusion     { pass P_1 { PixelShader = compile PROFILE ps_exclusion (); } }
technique Subtract      { pass P_1 { PixelShader = compile PROFILE ps_subtract (); } }
technique Divide        { pass P_1 { PixelShader = compile PROFILE ps_divide (); } }

//--------------------------------------- GROUP 5 -----------------------------------------//

technique Group_5       { pass P_1 { PixelShader = compile PROFILE ps_null (); } }
technique Hue           { pass P_1 { PixelShader = compile PROFILE ps_hue (); } }
technique Saturation    { pass P_1 { PixelShader = compile PROFILE ps_saturation (); } }
technique Colour        { pass P_1 { PixelShader = compile PROFILE ps_colour (); } }
technique Luminosity    { pass P_1 { PixelShader = compile PROFILE ps_luminosity (); } }
