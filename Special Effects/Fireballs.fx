// @Maintainer jwrl
// @Released 2021-10-22
// @Author jwrl
// @Author Unknown
// @Created 2021-10-22
// @see https://www.lwks.com/media/kunena/attachments/6375/FireballOverlay_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/FireballOverlay.mp4

/**
 This is a fireball effect that can be scaled and positioned to simulate explosions and
 other catastrophic effects.  The flicker rate and hue of the flames can be adjusted,
 the size can fill the frame or reduce to zero, and it can be positioned in frame by
 dragging the centre point of the effect.

 The result can then optionally be blended with a video background layer.  This function
 has the ability to be disabled because with some display cards leaving it enabled when
 using the fireball alone can give unpredictable results.

 NOTE: THIS EFFECT WILL ONLY COMPILE ON VERSIONS OF LIGHTWORKS LATER THAN 14.0.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fireballs.fx
//
// jwrl's note:
// This effect is based on a matchbook fireball effect called CPGP_Fireball.glsl found
// at https://logik-matchbook.org and designed for Autodesk applications.  I don't know
// the original author to credit them properly but I am very grateful to them.
//
// I have added an intensity and hue adjustment, and position and scaling adjustments to
// increase the flexibility.  I have also enhanced it so that the result can be composited
// over a background image.  This has meant adding an opacity adjustment, and the key can
// also be inverted to use the flames as a variable bordered vignette.
//
// Version history:
//
// Rewrite 2021-10-22 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fireballs";
   string Category    = "Stylize";
   string SubCategory = "Special Effects";
   string Notes       = "Produces a hot fireball and optionally blends it with a background image";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH   // Only available in version 14.5 and up
Bad_LW_version    // Forces a compiler error if the Lightworks version is bad.
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

#define MINIMUM 0.00001
#define TWO_PI  6.2831853072

float _Progress;
float _Length;

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Group = "Overlay settings";
   string Description = "Fireball mode";
   string Enum = "Overlay over input,Standalone (ignores overlay settings)";
> = 0;

float Amount
<
   string Group = "Overlay settings";
   string Description = "Fireball opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool InvertAlpha
<
   string Group = "Overlay settings";
   string Description = "Invert key";
> = false;

float Speed
<
   string Group = "Fireball settings";
   string Description = "Flicker rate";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 0.5;

float Hue
<
   string Group = "Fireball settings";
   string Description = "Flame hue";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

float Intensity
<
   string Group = "Fireball settings";
   string Description = "Flame intensity";
   float MinVal = 0.5;
   float MaxVal = 1.5;
> = 1.0;

float Size
<
   string Group = "Fireball settings";
   string Description = "Fireball size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float PosX
<
   string Description = "Fireball position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosY
<
   string Description = "Fireball position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_noise (float3 coord, float res)
{
   coord *= res;

   float3 f = frac (coord);
   float3 s = float3 (1e0, 1e2, 1e4);
   float3 xyz = floor (fmod (coord, res)) * s;
   float3 XYZ = floor (fmod (coord + 1.0.xxx, res)) * s;

   f = f * f * (3.0.xxx - 2.0 * f);

   float4 v = float4 (xyz.x + xyz.y + xyz.z, XYZ.x + xyz.y + xyz.z,
                      xyz.x + XYZ.y + xyz.z, XYZ.x + XYZ.y + xyz.z);
   float4 r = frac (sin (v * 1e-3) * 1e5);

   float r0 = lerp (lerp (r.x, r.y, f.x), lerp (r.z, r.w, f.x), f.y);

   r = frac (sin ((v + XYZ.z - xyz.z) * 1e-3) * 1e5);

   float r1 = lerp (lerp (r.x, r.y, f.x), lerp (r.z, r.w, f.x), f.y);

   return lerp (r0, r1, f.z) * 2.0 - 1.0;
}

float4 fn_hueShift (float4 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float3 hsv = float3 (0.0.xx, Cmax);

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac ((hsv.x + (Hue / 60.0) + 6.0) / 6.0) * 6.0;
      hsv.y = (1.0 - (Cmin / Cmax)) / min (Intensity, 1.0);
   }

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (1.0 - hsv.y * (1.0 - f));

   if (i == 0) return float4 (hsv.z, r, p, rgb.a);
   if (i == 1) return float4 (q, hsv.z, p, rgb.a);
   if (i == 2) return float4 (p, hsv.z, r, rgb.a);
   if (i == 3) return float4 (p, q, hsv.z, rgb.a);
   if (i == 4) return float4 (r, p, hsv.z, rgb.a);

   return float4 (hsv.z, p, q, rgb.a);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main_0 (float2 uv : TEXCOORD2) : COLOR
{
   float4 Bgnd = tex2D (s_Input, uv);

   float2 xy = float2 ((uv.x - PosX) * _OutputAspectRatio, 1.0 - uv.y - PosY);

   xy /= max (Size * 5.0, MINIMUM);

   if (abs (xy.x) < MINIMUM) xy.x = MINIMUM;

   if (abs (xy.y) < MINIMUM) xy.y = MINIMUM;

   float red  = 3.0 * (1.0 - length (2.0 * xy));
   float time = _Progress * _Length * Speed * 0.05;
   float cd_y = (length (xy) * 0.4) - time - 0.5;
   float power = 32.0;

   float3 coord = float3 (atan2 (xy.x, xy.y) / TWO_PI, cd_y, time + time) + 0.5.xxx;

   for (int i = 0; i <= 6; i++) {
      red   += (24.0 / power) * fn_noise (coord, power);
      power += 16.0;
   }

   float4 Fgnd = max (red, 0.0).xxxx;

   Fgnd.g *= Fgnd.g;
   Fgnd.b  = min (1.0 - (max (1.0 - Intensity, 0.0) * 0.025), Fgnd.r * Fgnd.g * 0.15);
   Fgnd.a  = saturate (Fgnd.r + Fgnd.g + Fgnd.b);
   Fgnd.g *= 0.4;

   Fgnd = fn_hueShift (saturate (Fgnd * Intensity));

   return (InvertAlpha) ? lerp (Fgnd, Bgnd, Fgnd.a) : lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_main_1 (float2 uv : TEXCOORD0) : COLOR
{
   float2 xy = float2 ((uv.x - PosX) * _OutputAspectRatio, 1.0 - uv.y - PosY);

   xy /= max (Size * 5.0, MINIMUM);

   if (abs (xy.x) < MINIMUM) xy.x = MINIMUM;

   if (abs (xy.y) < MINIMUM) xy.y = MINIMUM;

   float red = 3.0 * (1.0 - length (2.0 * xy));
   float time = _Progress * _Length * Speed * 0.05;
   float cd_y = (length (xy) * 0.4) - time - 0.5;
   float power = 32.0;

   float3 coord = float3 (atan2 (xy.x, xy.y) / TWO_PI, cd_y, time + time) + 0.5.xxx;

   for (int i = 0; i <= 6; i++) {
      red  += (24.0 / power) * fn_noise (coord, power);
      power += 16.0;
   }

   float4 Fgnd = max (red, 0.0).xxxx;

   Fgnd.g *= Fgnd.g;
   Fgnd.b  = min (1.0 - (max (1.0 - Intensity, 0.0) * 0.025), Fgnd.r * Fgnd.g * 0.15);
   Fgnd.a  = saturate (Fgnd.r + Fgnd.g + Fgnd.b);
   Fgnd.g *= 0.4;

   return fn_hueShift (saturate (Fgnd * Intensity));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Fireballs_0
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main_0)
}

technique Fireballs_1
{
   pass P_1 ExecuteShader (ps_main_1)
}

