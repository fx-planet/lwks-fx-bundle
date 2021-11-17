// @Maintainer jwrl
// @Released 2021-11-17
// @Author jwrl
// @Created 2021-11-17
// @see https://forum.lwks.com/attachments/analogtvlock_640-png.39718/

/**
 This simulates loss of horizontal and/or vertical hold on analog TV sets.  To be most
 effective, it works best on 4x3 or 16x9 landscape media.  PAL and NTSC format video is
 supported, scanlines can be added, and horizontal unlock can be displaced horizontally.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AnalogTVlock.fx
//
// Version history:
//
// Created 2021-11-17 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Analog TV lock";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Simulates loss of horizontal and/or vertical hold on analog TV sets";
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define PI 3.1415926536

float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

SetTargetMode (Video, s_Video, Wrap);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int TVmode
<
   string Description = "TV standard";
   string Enum = "PAL,NTSC";
> = 0;

float Horizontal
<
   string Description = "Horizontal hold";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Offset
<
   string Description = "Horizontal offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Vertical
<
   string Description = "Vertical hold";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Strength
<
   string Description = "Line visibility";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This sets up vertical and horizontal sync intervals by scaling the video down slightly
// and adding greyscale levels outside it to emulate sync pulses and colour burst signals.
// It also adds scanlines.

float4 ps_init (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = float2 (uv.x * 1.2, uv.y * 1.1111);

   float blend = 0.002;
   float lines, mix, c_bst = 0.015;

   float4 retval = any (xy > 1.0) ? float2 (0.1, 1.0).xxxy : tex2D (s_Input, xy);
   float4 burst;

   if (TVmode == 0) {
      burst = float2 (0.2, 1.0).xxxy;
      lines = 600.0;
   }
   else {
      burst = float4 (0.28, 0.2, 0.0, 1.0);
      lines = 500.0;
   }

   if ((xy.y <= 1.0) || (xy.y >= 1.045)) {
      mix = smoothstep (1.012, 1.012 + blend, xy.x) * smoothstep (1.099, 1.099 - blend, xy.x);
      retval = lerp (retval, BLACK, mix);
      mix = smoothstep (1.121, 1.121 + c_bst, xy.x) * smoothstep (1.178, 1.178 - c_bst, xy.x);
      retval = lerp (retval, burst, mix);
   }
   else if ((xy.y >= 1.015) && (xy.y <= 1.03)) {
      mix = smoothstep (0.512, 0.512 + blend, xy.x) * smoothstep (0.968, 0.968 - blend, xy.x);
      mix = max (mix, smoothstep (0.468 + blend, 0.468, xy.x));
      mix = max (mix, smoothstep (1.012, 1.012 + blend, xy.x));
      retval = lerp (retval, BLACK, mix);
   }
   else {
      mix = smoothstep (0.512, 0.512 + blend, xy.x) * smoothstep (0.556, 0.556 - blend, xy.x);
      mix = max (mix, smoothstep (1.012, 1.012 + blend, xy.x) * smoothstep (1.056, 1.056 - blend, xy.x));
      retval = lerp (retval, BLACK, mix);
   }

   retval.rgb *= lerp (1.0, (sin (PI * xy.y * lines) + 1.0) * 0.5, Strength);
   retval.rgb += retval.rgb * Strength * 0.375;

   return saturate (retval);
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   if ((Horizontal == 0.0) && (Vertical == 0.0) && (Strength == 0.0))
      return GetPixel (s_Input, uv1);

   float2 xy = float2 (uv2.x / 1.2, uv2.y / 1.1111);

   xy.x += Offset;
   xy.x += TVmode == 0 ? Horizontal * round (xy.y * 300.0) / 12.0
                       : Horizontal * round (xy.y * 250.0) / 10.0;
   xy.y += Vertical;

   return tex2D (s_Video, xy);
}

//-----------------------------------------------------------------------------------------//
//  Techniques
//-----------------------------------------------------------------------------------------//

technique AnalogTVlock
{
   pass P_1 < string Script = "RenderColorTarget0 = Video;"; > ExecuteShader (ps_init)
   pass P_2 ExecuteShader (ps_main)
}

