// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Stretch_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/StretchDissolve.mp4

/**
 Stretches the image horizontally through the dissolve.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Stretch_Dx.fx
//
// Version history:
//
// Rewrite 2021-07-25 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Stretch transition";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Stretches the image horizontally through the dissolve";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Outw, s_Outgoing);
DefineTarget (Inw, s_Incoming);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int StretchMode
<
   string Description = "Stretch mode";
   string Enum = "Horizontal,Vertical";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float Stretch
<
   string Description = "Stretch";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_in (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_Background, uv); }
float4 ps_out (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_Foreground, uv); }

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy = uv - (0.5).xx;

   float dissAmt = saturate (lerp (Amount, ((1.5 * Amount) - 0.25), Stretch));
   float stretchAmt = lerp (0.0, saturate (sin (Amount * PI)), Stretch);
   float distort;

   if (StretchMode == 0) {
      distort = sin (xy.y * PI);
      distort = sin (distort * HALF_PI);

      xy.y = lerp (xy.y, distort / 2.0, stretchAmt);
      xy.x /= 1.0 + (5.0 * stretchAmt);
   }
   else {
      distort = sin (xy.x * PI);
      distort = sin (distort * HALF_PI);

      xy.x = lerp (xy.x, distort / 2.0, stretchAmt);
      xy.y /= 1.0 + (5.0 * stretchAmt);
   }

   xy += (0.5).xx;

   float4 fgPix = GetPixel (s_Outgoing, xy);
   float4 bgPix = GetPixel (s_Incoming, xy);

   return lerp (fgPix, bgPix, dissAmt);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Stretch_Dx
{
   pass P_1 < string Script = "RenderColorTarget0 = Outw;"; > ExecuteShader (ps_out)
   pass P_2 < string Script = "RenderColorTarget0 = Inw;"; > ExecuteShader (ps_in)
   pass P_3 ExecuteShader (ps_main)
}
