// @Maintainer jwrl
// @Released 2021-10-28
// @Author jwrl
// @Created 2021-10-28
// @see https://www.lwks.com/media/kunena/attachments/6375/AntiAlias_640.png

/**
 A two pass rotary anti-alias tool that samples first at 6 degree intervals then at 7.5
 degree intervals using different radii for each pass.  This is done to give a very smooth
 result.  The radii can be scaled and the antialias blur can be faded.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Antialias.fx
//
// Version history:
//
// Rewrite 2021-10-28 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Antialias";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "A two pass rotary anti-alias tool that gives a very smooth result";
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

#define LOOP_1    30
#define DIVISOR_1 LOOP_1*2.0
#define RADIUS_1  0.00125
#define ANGLE_1   0.10472

#define LOOP_2    24
#define DIVISOR_2 LOOP_2*2.0
#define RADIUS_2  0.001
#define ANGLE_2   0.1309

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);
DefineTarget (preBlur, s_preBlur);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Radius
<
   string Description = "Radius";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Opacity
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_pass_1 (float2 uv : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Input, uv);

   if ((Opacity == 0.0) || (Radius == 0.0)) return Fgd;

   float4 retval = 0.0.xxxx;
   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * pow (Radius, 2.0) * RADIUS_1;
   float angle = 0.0;

   for (int i = 0; i < LOOP_1; i++) {
      sincos (angle, xy.x, xy.y);
      xy *= radius;
      retval += tex2D (s_Input, uv + xy);
      retval += tex2D (s_Input, uv - xy);
      angle  += ANGLE_1;
   }

   retval /= DIVISOR_1;

   return retval;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Input, uv2);

   if ((Opacity == 0.0) || (Radius == 0.0)) return Fgd;

   float4 retval = 0.0.xxxx;
   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * pow (Radius, 2.0) * RADIUS_2;
   float angle = 0.0;

   for (int i = 0; i < LOOP_2; i++) {
      sincos (angle, xy.x, xy.y);
      xy *= radius;
      retval += tex2D (s_preBlur, uv2 + xy);
      retval += tex2D (s_preBlur, uv2 - xy);
      angle  += ANGLE_2;
   }

   retval /= DIVISOR_2;
   retval = lerp (Fgd, retval, Opacity);

   return Overflow (uv1) ? EMPTY :  retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Antialias
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = preBlur;"; > ExecuteShader (ps_pass_1)
   pass P_3 ExecuteShader (ps_main)
}

