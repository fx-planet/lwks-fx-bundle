// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Zoom_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/ZoomDissolve.mp4

/**
 This effect either:
   Zooms into the outgoing image as it dissolves to the new image which zooms in to
   fill the frame.
 OR
   Zooms out of the outgoing image and dissolves to the new one while it's zooming out
   to full frame.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Zoom_Dx.fx
//
// Rewrite 2021-07-25 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Zoom dissolve";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Zooms between the two sources";
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
   AddressU  = Mirror;                \
   AddressV  = Mirror;                \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define HALF_PI   1.5707963268

#define SAMPLE    80
#define DIVISOR   82.0

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

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Direction
<
   string Group = "Zoom";
   string Description = "Direction";
   string Enum = "Zoom in,Zoom out";
> = 0;

float Strength
<
   string Group = "Zoom";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Xcentre
<
   string Description = "Zoom centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ycentre
<
   string Description = "Zoom centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_RawBg, uv); }

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float4 outgoing = tex2D (s_Foreground, uv);
   float4 incoming = tex2D (s_Background, uv);

   if (Strength > 0.0) {
      float strength_1, strength_2, scale_1 = 1.0, scale_2 = 1.0;

      sincos (Amount * HALF_PI, strength_2, strength_1);

      strength_1 = Strength * (1.0 - strength_1);
      strength_2 = Strength * (1.0 - strength_2);

      if (Direction == 0) scale_1 -= strength_1;
      else scale_2 -= strength_2;

      float2 centreXY = float2 (Xcentre, 1.0 - Ycentre);
      float2 xy0 = uv - centreXY;
      float2 xy1, xy2;

      strength_1 /= SAMPLE;
      strength_2 /= SAMPLE;

      for (int i = 0; i <= SAMPLE; i++) {
         xy1 = xy0 * scale_1 + centreXY;
         xy2 = xy0 * scale_2 + centreXY;
         outgoing += tex2D (s_Foreground, xy1);
         incoming += tex2D (s_Background, xy2);
         scale_1  += strength_1;
         scale_2  += strength_2;
      }

      outgoing /= DIVISOR;
      incoming /= DIVISOR;
   }

   return lerp (outgoing, incoming, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dx_Zoom
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_main)
}

