// @Maintainer jwrl
// @Released 2021-11-01
// @Author jwrl
// @Created 2021-11-01
// @see https://www.lwks.com/media/kunena/attachments/6375/CameraDistortions_640.png

/**
 Camera distortions adds colour fringing effects, pincushion distortion, scaling and
 anamorphic adjustment to an image.  The centre of action of the effect can also be
 adjusted.  It can be used to simulate camera distortion or possibly even correct it,
 and can also be used as an effect in its own right.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CameraDistortions.fx
//
// This effect was suggested by CubicLensDistortion.fx by Lightworks user brdloush.
// This implementation is my own, based on the cubic lens distortion algorithm from
// SSontech (Syntheyes) - http://www.ssontech.com/content/lensalg.htm
// 
//     r2 = image_aspect*image_aspect*u*u + v*v
//     f = 1 + r2*(k + kcube*sqrt(r2))
//     u' = f*u
//     v' = f*v
//
// Although brdloush's version was based on code published by Francois Tarlier in 2010,
// this version re-implements the original Ssontech algorithm, and uses none of
// M. Tarlier's code.  I have not maintained the variable names used in the original
// algorithm, but the code should be clear enough to identify them.
//
// The most notable difference is the use of float2 variables for screen coordinate
// mathematics wherever possible.  This means that some parts require indexing where
// they didn't in the original algorithm.  It also means that overall the code is much
// simpler and will execute faster.  For example the last two lines shown above can
// now be expressed as a single line, viz:
//
//     uv'= f*uv
//
// which executes as a single function but is equivalent to
//
//     uv'.x = f*uv.x
//     uv'.y = f*uv.y
//
// The centring function is additional to any of the published work as far as I'm
// aware, and is entirely my own.  Also new is a means of automatically scaling the
// image while using the basic distortion.  This only applies to positive values of
// the basic distortion and doesn't apply at all to cubic distortion.
//
// I understand that one implementation of this algorithm had chromatic aberration
// correction.  I've done something similar, providing both optical and electronic
// aberrations.  As far as I'm aware these are both original work.
//
// Optical color artefacts are applied prior to distortion, and electronic artefacts
// are applied after it.  This ensures that lens fringing stays inside the image
// boundary while colour registration errors affect the whole frame.
//
// All of the above notwithstanding, you can do what you will with this effect.  It
// would be nice to be credited if you decide to use it elsewhere or change it in
// any way - jwrl.
//
// Version history:
//
// Rewrite 2021-11-01 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.  This
// version has also slightly reduced the number of conditionals used.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Camera distortion";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Simulates a range of digital camera distortion artefacts";
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
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define STEPS     12
#define FRNG_INC  1.0/STEPS

#define DICHROIC  0.01
#define CHIP_ERR  0.0025
#define DISTORT   0.35355339

#define HORIZ     true
#define VERT      false

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);
DefineTarget (Lens, s_Lens);
DefineTarget (Distort, s_Distort);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool DistortScale
<
   string Group = "Distortion";
   string Description = "Enable basic distortion autoscaling";
> = false;

float BasicDistortion
<
   string Group = "Distortion";
   string Description = "Basic";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CubicDistortion
<
   string Group = "Distortion";
   string Description = "Cubic";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Scale
<
   string Group = "Distortion";
   string Description = "Scale";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float AnamorphicDistortion
<
   string Group = "Distortion";
   string Description = "Anamorphic";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

int SetTechnique
<
   string Group = "Chromatic aberration";
   string Description = "Camera type";
   string Enum = "Single chip,Single chip (portrait),Three chip,Three chip (portrait)";
> = 0;

float OpticalErrors
<
   string Group = "Chromatic aberration";
   string Description = "Optical errors";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ElectronicErrors
<
   string Group = "Chromatic aberration";
   string Description = "Electronic errors";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_lens (float2 uv : TEXCOORD2) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   if (OpticalErrors != 0.0) {
      retval.rgb = 0.0.xxx;

      float2 centre = float2 (Xcentre, 1.0 - Ycentre);
      float2 fringe, xy = uv - centre;

      float fringing = 0.0;
      float strength = 1.0;
      float str_diff = (OpticalErrors / 100.0) * length (xy);

      for (int i = 0; i < STEPS; i++) {
         fringe = tex2D (s_Input, (xy * strength) + centre).rg / STEPS;

         retval.rg += fringe * float2 (1.0 - fringing, fringing);

         fringing += FRNG_INC;
         strength -= str_diff;
      }

      for (int i = 0; i < STEPS; i++) {
         fringe = tex2D (s_Input, (xy * strength) + centre).gb / STEPS;

         retval.gb += fringe * float2 (2.0 - fringing, fringing - 1.0);

         fringing += FRNG_INC;
         strength -= str_diff;
      }

      for (int i = 0; i < STEPS; i++) {
         fringe = tex2D (s_Input, (xy * strength) + centre).rb / STEPS;

         retval.rb += fringe * float2 (fringing - 2.0, 3.0 - fringing);

         fringing += FRNG_INC;
         strength -= str_diff;
      }
   }

   return retval;
}

float4 ps_distort (float2 uv : TEXCOORD2) : COLOR
{
   float autoscale [] = { 1.0,    0.8249, 0.7051, 0.6175, 0.5478, 0.4926, 0.4462,
                          0.4093, 0.3731, 0.3476, 0.3243, 0.3039, 0.286,  0.2707,
                          0.2563, 0.2435, 0.2316, 0.2214, 0.2116, 0.2023, 0.1942 };

   if (!BasicDistortion && !CubicDistortion && !AnamorphicDistortion) return tex2D (s_Lens, uv);

   float sa, sb = (Scale * ((Scale / 2.0) - 1.0)) + 0.5;

   sb += pow (max (0.0, -Scale) * DISTORT, 2.0);

   if (DistortScale) {
      float a_s0 = saturate (BasicDistortion) * 20;
      float a_s1 = floor (a_s0);
      float a_s2 = ceil (a_s0);

      sa = autoscale [a_s1];

      if (a_s1 != a_s2) {
         a_s0 -= a_s1;
         a_s0  = sqrt (a_s0 / 9) + (0.666667 * a_s0);
         sa = lerp (sa, autoscale [a_s2], a_s0);
      }
   }
   else sa = 1.0;

   float2 centre = float2 (Xcentre, 1.0 - Ycentre);
   float2 sf = max (0.0, float2 (AnamorphicDistortion, -AnamorphicDistortion));
   float2 xy = 2.0 * (uv - centre);

   sf = (sb.xx - (sf * sf * DISTORT)) * xy * sa;

   float r = _OutputAspectRatio * _OutputAspectRatio * xy.x * xy.x + xy.y * xy.y;
   float f = CubicDistortion ? 1.0 + (r * (BasicDistortion + (CubicDistortion * sqrt (r))))
                             : 1.0 + (r * BasicDistortion);
   xy = (sf * f) + centre;

   return GetPixel (s_Lens, xy);
}

float4 ps_single_H (float2 uv : TEXCOORD2) : COLOR
{
   if (ElectronicErrors == 0.0) return tex2D (s_Distort, uv);

   float offset = (ElectronicErrors * CHIP_ERR) / _OutputAspectRatio;

   float2 xy1 = float2 (uv.x - offset, uv.y);
   float2 xy2 = float2 (uv.x + offset, uv.y);

   float4 retval = tex2D (s_Distort, xy1);

   retval.g = tex2D (s_Distort, xy2).g;

   return retval;
}

float4 ps_single_V (float2 uv : TEXCOORD2) : COLOR
{
   if (ElectronicErrors == 0.0) return tex2D (s_Distort, uv);

   float offset = ElectronicErrors * CHIP_ERR;

   float2 xy1 = float2 (uv.x, uv.y - offset);
   float2 xy2 = float2 (uv.x, uv.y + offset);

   float4 retval = tex2D (s_Distort, xy1);

   retval.g = tex2D (s_Distort, xy2).g;

   return retval;
}

float4 ps_dichroic_H (float2 uv : TEXCOORD2) : COLOR
{
   float4 retval = tex2D (s_Distort, uv);

   if (ElectronicErrors != 0.0) {
      float offset = (ElectronicErrors * DICHROIC) / _OutputAspectRatio;

      float2 xy1 = float2 (uv.x + offset, uv.y);
      float2 xy2 = float2 (uv.x - offset, uv.y);

      retval.r = tex2D (s_Distort, xy1).r;
      retval.b = tex2D (s_Distort, xy2).b;
   }

   return retval;
}

float4 ps_dichroic_V (float2 uv : TEXCOORD2) : COLOR
{
   float4 retval = tex2D (s_Distort, uv);

   if (ElectronicErrors != 0.0) {
      float offset = ElectronicErrors * DICHROIC;

      float2 xy1 = float2 (uv.x, uv.y - offset);
      float2 xy2 = float2 (uv.x, uv.y + offset);

      retval.r = tex2D (s_Distort, xy1).r;
      retval.b = tex2D (s_Distort, xy2).b;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique OneChip_H
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Lens;"; > ExecuteShader (ps_lens)
   pass P_3 < string Script = "RenderColorTarget0 = Distort;"; > ExecuteShader (ps_distort)
   pass P_4 ExecuteShader (ps_single_H)
}

technique OneChip_V
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Lens;"; > ExecuteShader (ps_lens)
   pass P_3 < string Script = "RenderColorTarget0 = Distort;"; > ExecuteShader (ps_distort)
   pass P_4 ExecuteShader (ps_single_V)
}

technique ThreeChip_H
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Lens;"; > ExecuteShader (ps_lens)
   pass P_3 < string Script = "RenderColorTarget0 = Distort;"; > ExecuteShader (ps_distort)
   pass P_4 ExecuteShader (ps_dichroic_H)
}

technique ThreeChip_V
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Lens;"; > ExecuteShader (ps_lens)
   pass P_3 < string Script = "RenderColorTarget0 = Distort;"; > ExecuteShader (ps_distort)
   pass P_4 ExecuteShader (ps_dichroic_V)
}

