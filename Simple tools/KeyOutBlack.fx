// @Maintainer jwrl
// @Released 2021-10-19
// @Author jwrl
// @Created 2021-10-19
// @see https://www.lwks.com/media/kunena/attachments/6375/KeyOutBlack_640.png

/**
 This effect is designed to turn on the foreground alpha layer wherever black is at absolute
 zero.  To soften the key edge a non-linear curve is derived from the bottom 0% to 2.5% of
 the video.  That is then combined with any alpha channel in the foreground layer and used
 to key it over the background.  The range over which the key is generated can be offset by
 up to 5% of the total video level to compensate for noise in blacks.

 While you can exceed the 5% limit by manually entering values, if you need more control over
 your key level there are better tools available.  A good start would be to try the Lightworks
 lumakey instead.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect KeyOutBlack.fx
//
// The theory behind this effect:
//
// First we crush the black level by up to 5% and get the maximum of the red, green and
// blue channels from the result.  We then derive the initial alpha channel from that
// maximum value, using the bottom 2.5% of the black crushed video.  The cosine of the
// preliminary alpha is used to smooth the clipping with an S curve.
//
// That synthetic alpha is then combined with the foreground video alpha to produce a
// composite alpha channel, which preserves any existing foreground transparency.  Finally,
// the derived alpha channel is used to key the foreground over the background video.  The
// opacity parameter allows for dissolving the foreground in or out.
//
// Version history:
//
// Rewrite 2021-10-19 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Key out black";
   string Category    = "Key";
   string SubCategory = "Simple tools";
   string Notes       = "This generates keys from absolute (super) black";
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define PI 3.1415926536

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Offset
<
   string Description = "Black clip";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 0.05;
> = 0.025;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return BdrPixel (s_RawBg, uv); }

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, uv);

   float3 v = saturate (Fgd.rgb - Offset.xxx);

   float alpha = (1.0 - cos (saturate (max (v.r, max (v.g, v.b)) * 40.0) * PI)) * 0.5;

   return lerp (tex2D (s_Background, uv), Fgd, min (alpha, Fgd.a) * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique KeyOutBlack
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 ExecuteShader (ps_main)
}

