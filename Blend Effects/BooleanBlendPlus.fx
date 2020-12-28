// @Maintainer jwrl
// @Released 2020-12-28
// @Author jwrl
// @Created 2020-02-29
// @see https://www.lwks.com/media/kunena/attachments/6375/BooleanBlendPlus_640.png

/**
 This is an extension of Boolean blend, which is the analogue equivalent of a digital
 logic gate.  AND, OR, NAND, NOR and XOR have been implemented while the analogue
 levels of the alpha channel have been maintained.  The video is always just OR-ed
 while the logic is fully implemented only in the alpha channel.  Also included is a
 means of masking B with A.  In that case the same operation as with AND is performed
 on the alpha channels, but the video is taken only from the B channel.

 In all modes the default is to premultiply the RGB by the alpha channel.  This is
 done to ensure that transparency displays as black as far as the gating is concerned.
 However in this effect RGB can also be simply set to zero when alpha is zero.  This
 can be done independently for each channel.

 The levels of the A and B inputs can also be adjusted independently.  In mask mode
 reducing the A level to zero will fade the mask, revealing the background video in
 its entirety.  In that mode reducing the B level to zero fades the effect to black.

 There is also a means of using the highest value of A and B video's RGB components
 to create an artificial alpha channel for each channel.  The alpha value, however it
 is produced, is output for possible use by the blending logic.  Where the final output
 alpha channel is zero the video is blanked to allow for the boolean result to be used
 in external blend and DVE effects.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BooleanBlendPlus.fx
//
// Only the logic shader is fully commented.  The blend shaders aren't because they are
// simple implementations of standard widely available algorithms.
//
// Version history:
//
// Rewrite 2020-12-28 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Boolean blend plus";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Combines two images using an analogue equivalent of boolean logic then blends the result over background video.";
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

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define CrR    0.439
#define CrG    0.368
#define CrB    0.071

#define CbR    0.148
#define CbG    0.291
#define CbB    0.439

#define Rr_R   1.596
#define Rg_R   0.813
#define Rg_B   0.391
#define Rb_B   2.018

#define WHITE  1.0.xxxx
#define EMPTY  0.0.xxxx

#define AND    0
#define OR     1
#define NAND   2
#define NOR    3
#define XOR    4
#define MASK   5

#define LUMA    float4(0.2989, 0.5866, 0.1145, 0.0)

#define EMPTY    (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (A, Sampler_A);
DefineInput (B, Sampler_B);
DefineInput (Bg, s_Background);

DefineTarget (Fg, s_Foreground);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Logic
<
   string Description = "Boolean function";
   string Enum = "AND,OR,NAND,NOR,XOR,Mask B with A";
> = 0;

int SetTechnique
<
   string Description = "Blend mode";
   string Enum = "Normal,Export boolean only,____________________,Darken,Multiply,Colour Burn,Linear Burn,Darker Colour,____________________,Lighten,Screen,Colour Dodge,Linear Dodge (Add),Lighter Colour,____________________,Overlay,Soft Light,Hard Light,Vivid Light,Linear Light,Pin Light,Hard Mix,____________________,Difference,Exclusion,Subtract,Divide,____________________,Hue,Saturation,Colour,Luminosity";
> = 0;

float Amount
<
   string Description = "Blend opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amount_A
<
   string Group = "A video";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int Alpha_A
<
   string Group = "A video";
   string Description = "Transparency";
   string Enum = "Standard,Premultiply,Alpha from RGB";
> = 1;

float Amount_B
<
   string Group = "B video";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int Alpha_B
<
   string Group = "B video";
   string Description = "Transparency";
   string Enum = "Standard,Premultiply,Alpha from RGB";
> = 1;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_rgb2hsv (float4 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float4 hsv  = float3 (0.0, Cmax, rgb.a).xxyz;

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float4 fn_hsv2rgb (float4 hsv)
{
   if (hsv.y == 0.0) return hsv.zzzw;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (1.0 - hsv.y * (1.0 - f));

   if (i == 0) return float4 (hsv.z, r, p, hsv.w);
   if (i == 1) return float4 (q, hsv.z, p, hsv.w);
   if (i == 2) return float4 (p, hsv.z, r, hsv.w);
   if (i == 3) return float4 (p, q, hsv.zw);
   if (i == 4) return float4 (r, p, hsv.zw);

   return float4 (hsv.z, p, q, hsv.w);
}

float4 fn_tex2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   return (max (xy.x, xy.y) > 0.5) ? EMPTY : tex2D (s, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_logic (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = fn_tex2D (Sampler_A, xy1);
   float4 vidB = fn_tex2D (Sampler_B, xy2);
   float4 retval;

   // If premultiply is not set, alpha at zero causes the RGB values to be replaced
   // with zero (absolute black).  If alpha is not available, RGB values can be used
   // instead but premutliply is not available in that mode.

   if (Alpha_A == 1) { vidA.rgb *= vidA.a; }
   else if (Alpha_A == 2) {
      vidA.a  = max (vidA.r, max (vidA.g, vidA.b));
      vidA.a *= vidA.a;
   }
   else if (vidA.a == 0.0) vidA = EMPTY;

   if (Logic == MASK) {
      // The mask operation differs slightly from a simple boolean, in that only
      // the B video will be displayed after it's masked and not a mix of A and B.

      if (Alpha_B == 2) {
         vidB.a  = max (vidB.r, max (vidB.g, vidB.b));
         vidB.a *= vidB.a;
      }

      vidB *= Amount_B;

      retval = float4 (vidB.rgb, min (vidA.a, vidB.a));

      // The premultiply for B is done now to clean up the video after masking.

      if (Alpha_B == 1) { retval.rgb *= retval.a; }
      else if (retval.a == 0.0) retval = EMPTY;

      return lerp (vidB, retval, Amount_A);
   }

   if (Alpha_B == 1) { vidB.rgb *= vidB.a; }
   else if (Alpha_B == 2) {
      vidB.a  = max (vidB.r, max (vidB.g, vidB.b));
      vidB.a *= vidB.a;
   }
   else if (vidB.a == 0.0) vidB = EMPTY;

   vidA *= Amount_A;
   vidB *= Amount_B;

   // In all boolean modes the video is initially OR-ed.  This is so that whatever is
   // subsequently done to the alpha channel, appropriate video will be output.

   retval = max (vidA, vidB);

   // The boolean logic is now applied to the alpha channel only.  Nothing needs to be
   // done if the logic setting is OR, because we already have that result.

   if (Logic == AND) retval.a = min (vidA.a, vidB.a);
   if (Logic == NAND) retval.a = 1.0 - min (vidA.a, vidB.a);
   if (Logic == NOR) retval.a = 1.0 - retval.a;
   if (Logic == XOR) retval.a *= 1.0 - min (vidA.a, vidB.a);

   if (retval.a == 0.0) retval = EMPTY;         // Blanks the video if alpha is zero

   return retval;
}

//--------------------------------------- GROUP 0 -----------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);

   return lerp (fn_tex2D (s_Background, xy2), Fgnd, Fgnd.a * Amount);
}

float4 ps_export (float2 uv : TEXCOORD1) : COLOR
{
   return fn_tex2D (s_Foreground, uv);
}

float4 ps_dummy (float2 uv : TEXCOORD1) : COLOR
{
   return fn_tex2D (s_Background, uv);
}

//--------------------------------------- GROUP 1 -----------------------------------------//

float4 ps_darken (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   Fgnd.rgb = min (Fgnd.rgb, Bgnd.rgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_multiply (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   Fgnd.rgb *= Bgnd.rgb;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_colourBurn (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   if (Fgnd.r > 0.0) Fgnd.r = 1.0 - ((1.0 - Bgnd.r) / Fgnd.r);
   if (Fgnd.g > 0.0) Fgnd.g = 1.0 - ((1.0 - Bgnd.g) / Fgnd.g);
   if (Fgnd.b > 0.0) Fgnd.b = 1.0 - ((1.0 - Bgnd.b) / Fgnd.b);

   return lerp (Bgnd, min (Fgnd, WHITE), Fgnd.a * Amount);
}

float4 ps_linearBurn (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   Fgnd.rgb = max (Fgnd.rgb + Bgnd.rgb - 1.0.xxx, 0.0.xxx);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_darkerColour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   float luma = dot (Bgnd, LUMA);

   if (dot (Fgnd, LUMA) > luma) Fgnd.rgb = Bgnd.rgb;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 2 -----------------------------------------//

float4 ps_lighten (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   Fgnd.rgb = max (Fgnd.rgb, Bgnd.rgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_screen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_colourDodge (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   Fgnd.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (1.0 - Fgnd.r);
   Fgnd.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (1.0 - Fgnd.g);
   Fgnd.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (1.0 - Fgnd.b);

   return lerp (Bgnd, min (Fgnd, WHITE), Fgnd.a * Amount);
}

float4 ps_linearDodge (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   Fgnd.rgb = min (Fgnd.rgb + Bgnd.rgb, 1.0.xxx);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_lighterColour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   float  luma = dot (Bgnd, LUMA);

   if (dot (Fgnd, LUMA) < luma) Fgnd.rgb = Bgnd.rgb;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 3 -----------------------------------------//

float4 ps_overlay (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   float3 retMin = 2.0 * Bgnd.rgb * Fgnd.rgb;
   float3 retMax = 1.0.xxx - 2.0 * (1.0.xxx - Fgnd.rgb) * (1.0.xxx - Bgnd.rgb);

   Fgnd.r = (Bgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Bgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Bgnd.b <= 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_softLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   float3 retMax = (2.0 * Fgnd.rgb) - 1.0.xxx;
   float3 retMin = Bgnd.rgb * (retMax * (1.0.xxx - Bgnd.rgb) + 1.0.xxx);

   retMax *= sqrt (Bgnd.rgb) - Bgnd.rgb;
   retMax += Bgnd.rgb;

   Fgnd.r = (Fgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b <= 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_hardLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   float3 retMin = saturate (2.0 * Bgnd.rgb * Fgnd.rgb);
   float3 retMax = saturate (1.0.xxx - 2.0 * (1.0.xxx - Bgnd.rgb) * (1.0.xxx - Fgnd.rgb));

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_vividLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   float3 retMax, retMin;

   retMin.r = (Fgnd.r == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.r) / (2.0 * Fgnd.r)), 0.0);
   retMin.g = (Fgnd.g == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.g) / (2.0 * Fgnd.g)), 0.0);
   retMin.b = (Fgnd.b == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.b) / (2.0 * Fgnd.b)), 0.0);

   retMax.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (2.0 * (1.0 - Fgnd.r));
   retMax.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (2.0 * (1.0 - Fgnd.g));
   retMax.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (2.0 * (1.0 - Fgnd.b));

   retMin = min (retMin, (1.0).xxx);
   retMax = min (retMax, (1.0).xxx);

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_linearLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);
   float4 retMin = max ((2.0 * Fgnd) + Bgnd - WHITE, EMPTY);
   float4 retMax = min ((2.0 * Fgnd) + Bgnd - WHITE, WHITE);

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_pinLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   float3 retMax = 2.0 * Fgnd.rgb;
   float3 retMin = retMax - 1.0.xxx;

   Fgnd.r = (Bgnd.r > retMax.r) ? retMax.r : (Bgnd.r < retMin.r) ? retMin.r : Bgnd.r;
   Fgnd.g = (Bgnd.g > retMax.g) ? retMax.g : (Bgnd.g < retMin.g) ? retMin.g : Bgnd.g;
   Fgnd.b = (Bgnd.b > retMax.b) ? retMax.b : (Bgnd.b < retMin.b) ? retMin.b : Bgnd.b;

   return lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_hardMix (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   float3 ref = 1.0.xxx - Bgnd.rgb;

   Fgnd.r = (Fgnd.r < ref.r) ? 0.0 : 1.0;
   Fgnd.g = (Fgnd.g < ref.g) ? 0.0 : 1.0;
   Fgnd.b = (Fgnd.b < ref.b) ? 0.0 : 1.0;

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 4 -----------------------------------------//

float4 ps_difference (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   Fgnd.rgb = abs (Fgnd.rgb - Bgnd.rgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_exclusion (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb * (1.0.xxx - (2.0 * Fgnd.rgb)));

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_subtract (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   Fgnd.rgb = max (Bgnd.rgb - Fgnd.rgb, 0.0.xxx);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_divide (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);

   Fgnd.r = (Fgnd.r == 0.0) ? 1.0 : min (Bgnd.r / Fgnd.r, 1.0);
   Fgnd.g = (Fgnd.g == 0.0) ? 1.0 : min (Bgnd.g / Fgnd.g, 1.0);
   Fgnd.b = (Fgnd.b == 0.0) ? 1.0 : min (Bgnd.b / Fgnd.b, 1.0);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 5 -----------------------------------------//

float4 ps_hue (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.xw = (fn_rgb2hsv (Fgnd)).xw;

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_saturation (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.yw = fn_rgb2hsv (Fgnd).yw;

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_colour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);
   float4 blnd = fn_rgb2hsv (Fgnd);

   blnd.x = (fn_rgb2hsv (Bgnd)).x;

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_luminosity (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = fn_tex2D (s_Background, xy2);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.zw = (fn_rgb2hsv (Fgnd)).zw;

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Normal {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_main (); } }

technique Export {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_export (); } }

//--------------------------------------- GROUP 1 -----------------------------------------//

technique Group_1 { pass P_1 { PixelShader = compile PROFILE ps_dummy (); } }

technique Darken {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_darken (); } }

technique Multiply {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_multiply (); } }

technique ColourBurn {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_colourBurn (); } }

technique LinearBurn {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_linearBurn (); } }

technique DarkerColour {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_darkerColour (); } }

//--------------------------------------- GROUP 2 -----------------------------------------//

technique Group_2 { pass P_1 { PixelShader = compile PROFILE ps_dummy (); } }

technique Lighten {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_lighten (); } }

technique Screen {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_screen (); } }

technique ColourDodge {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_colourDodge (); } }

technique LinearDodge {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_linearDodge (); } }

technique LighterColour {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_lighterColour (); } }

//--------------------------------------- GROUP 3 -----------------------------------------//

technique Group_3 { pass P_1 { PixelShader = compile PROFILE ps_dummy (); } }

technique Overlay {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_overlay (); } }

technique SoftLight {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_softLight (); } }

technique Hardlight {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_hardLight (); } }

technique Vividlight {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_vividLight (); } }

technique Linearlight {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_linearLight (); } }

technique Pinlight {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_pinLight (); } }

technique HardMix {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_hardMix (); } }

//--------------------------------------- GROUP 4 -----------------------------------------//

technique Group_4 { pass P_1 { PixelShader = compile PROFILE ps_dummy (); } }

technique Difference {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_difference (); } }

technique Exclusion {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_exclusion (); } }

technique Subtract {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_subtract (); } }

technique Divide {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_divide (); } }

//--------------------------------------- GROUP 5 -----------------------------------------//

technique Group_5 { pass P_1 { PixelShader = compile PROFILE ps_dummy (); } }

technique Hue  {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_hue (); } }

technique Saturation {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_saturation (); } }

technique Colour {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_colour (); } }

technique Luminosity {
   pass P_1 < string Script = "RenderColorTarget0 = Fg;"; >
            { PixelShader = compile PROFILE ps_logic (); }
   pass P_2 { PixelShader = compile PROFILE ps_luminosity (); } }
