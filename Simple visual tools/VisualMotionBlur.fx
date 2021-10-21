// @Maintainer jwrl
// @Released 2021-10-21
// @Author jwrl
// @Created 2021-10-21
// @see https://www.lwks.com/media/kunena/attachments/6375/VisMotionBlur_640.png

/**
 A directional blur that can be used to simulate fast motion, whip pans and the like.  This
 differs from other blur effects in that it is set up by visually dragging a central pin
 point in the record viewer to adjust the angle and strength of the blur.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VisualMotionBlur.fx
//
// Version history:
//
// Rewrite 2021-10-21 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Visual motion blur";
   string Category    = "Stylize";
   string SubCategory = "Simple visual tools";
   string Notes       = "A directional blur that can be quickly set up by visually dragging a central pin point.";
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

#define XY      1.0.xx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
    string Description = "Blur amount";
    float MinVal = 0.0;
    float MaxVal = 1.0;
> = 1.0;

float Blur_X
<
   string Description = "Blur";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Blur_Y
<
   string Description = "Blur";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR
{
   return Overflow (uv) ? BLACK : tex2D (s_RawInp, uv);
}

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Input, uv);

   // Centre the cursor X-Y coordiantes around zero.

   float2 xy0 = float2 (0.5 - Blur_X, (Blur_Y - 0.5) * _OutputAspectRatio);

   // If the amount is zero or less, or if xy0 is zero quit without doing anything.

   if ((Amount <= 0.0) || (distance (0.0.xx, xy0) == 0.0)) return Fgnd;

   // Initialise the mix value, initial pixel address and blur sample.

   float mix = 0.0327868852;
   float2 xy1 = uv;
   float4 Blur = Fgnd * mix;

   // Scale xy0 so that the derived blur length is reasonable and easily controlled.

   xy0 *= 0.005;

   // Do a directional blur by progressively sampling pixels at 60 deep, offset more
   // and more, and reducing their mix amount to zero linearly to fade the blur out.

   for (int i = 0; i < 60; i++) {
      mix -= 0.0005464481;
      xy1 += xy0;
      Blur += GetPixel (s_Input, xy1) * mix;
   }

   // Finally mix the blur back into the original foreground video.

   return lerp (Fgnd, Blur, Amount);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique VisualMotionBlur
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main)
}

