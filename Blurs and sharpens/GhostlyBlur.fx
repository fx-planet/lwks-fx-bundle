// @Maintainer jwrl
// @Released 2021-08-31
// @Author jwrl
// @Created 2021-08-31
// @see https://www.lwks.com/media/kunena/attachments/6375/GhostBlur_640.png

/**
 Originally created as YAblur.fx, this was an accident that looked interesting, so it was
 given a name and further developed.  It is based on a radial anti-aliassing blur developed
 for another series of effects, further modulated by image content.  The result is a very
 soft ghostly blur.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GhostlyBlur.fx
//
// Version history:
//
// Rewrite 2021-08-31 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Ghostly blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "The sort of effect that you get when looking through a fogged window";
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

#define SetInputMode(TEX, SMPL, MODE) \
                                      \
 texture TEX;                         \
                                      \
 sampler SMPL = sampler_state         \
 {                                    \
   Texture   = <TEX>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define SetTargetMode(TGT, SMP, MODE) \
                                      \
 texture TGT : RenderColorTarget;     \
                                      \
 sampler SMP = sampler_state          \
 {                                    \
   Texture   = <TGT>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

#define LOOP_1   29
#define RADIUS_1 0.1
#define ANGLE_1  0.216662

#define LOOP_2   23
#define RADIUS_2 0.066667
#define ANGLE_2  0.273182

#define FOG_LIM  0.8
#define FOG_MIN  0.4
#define FOG_MAX  4.0

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

SetInputMode (Input, s_RawInp, Mirror);

SetTargetMode (FixInp, s_Input, Mirror);
SetTargetMode (prelim, s_prelim, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Radius
<
   string Description = "Radius";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float Fog
<
   string Description = "Fogginess";
   float MinVal       = -1.0;
   float MaxVal       = 1.0;
> = 0.0;

float Opacity
<
   string Description = "Amount";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_RawInp, uv); }

float4 ps_prelim (float2 uv1 : TEXCOORD2, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Input, uv2);

   if ((Opacity <= 0.0) || Overflow (uv1)) return Fgd;

   float gamma = 3.0 / ((1.5 + Fog) * 2.0);

   float2 xy, radius = (Radius * Radius * RADIUS_1).xx;

   radius *= float2 ((1.0 - Fgd.b) / _OutputAspectRatio, Fgd.r + Fgd.g);

   float4 retval = EMPTY;

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy.x, xy.y);
      retval += pow (tex2D (s_Input, uv2 + (xy * radius)), gamma);
   }

   retval /= LOOP_1;

   return retval;
}

float4 ps_main (float2 uv1 : TEXCOORD2, float2 uv2 : TEXCOORD2) : COLOR
{
   if (Overflow (uv1)) return EMPTY;

   float4 Fgd = tex2D (s_Input, uv2);

   if (Opacity <= 0.0) return Fgd;

   float gamma = 3.0 / ((1.5 + Fog) * 2.0);

   float4 retval = tex2D (s_prelim, uv2);

   float2 xy, radius = (Radius * Radius * RADIUS_2).xx;

   radius *= float2 ((retval.r + retval.b) / _OutputAspectRatio, 1.0 - retval.g);

   retval = EMPTY;

   for (int i = 0; i < LOOP_2; i++) {
      sincos ((i * ANGLE_2), xy.x, xy.y);
      retval += pow (tex2D (s_prelim, uv2 + (xy * radius)), gamma);
   }

   retval /= LOOP_2;

   retval.rgb += lerp (0.0.xxx, Fgd.rgb - (Fgd.rgb * retval.rgb), saturate (-Fog));

   return lerp (Fgd, saturate (retval), Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique GhostlyBlur
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 < string Script = "RenderColorTarget0 = prelim;"; > ExecuteShader (ps_prelim)
   pass P_2 ExecuteShader (ps_main)
}

