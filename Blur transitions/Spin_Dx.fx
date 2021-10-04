// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Spin_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/SpinDissolve.mp4

/**
 This effect performs a transition between two sources.  During the process it applies a
 rotational blur, the direction, aspect ratio, centring and strength of which can be
 adjusted.

 To better handle varying aspect ratios code has been included to allow the blur to
 exceed the input frame boundaries.  The subjective effect of this changes as the effect
 progresses, thus allowing for differing incoming and outgoing media aspect ratios.

 The blur section is based on a rotational blur converted by Lightworks user windsturm
 from original code created by rakusan - http://kuramo.ch/webgl/videoeffects/
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Spin_Dx.fx
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
   string Description = "Spin dissolve";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Uses a rotational blur to transition between two sources";
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
   AddressU  = Mirror;                \
   AddressV  = Mirror;                \
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
#define ExecuteParam(SHD,PRM) { PixelShader = compile PROFILE SHD (PRM); }

#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define RANGE_1    24
#define RANGE_2    48
#define RANGE_3    72
#define RANGE_4    96
#define RANGE_5    120

#define SAMPLES    120
#define INC_OFFSET 1.0 / SAMPLES
#define RETSCALE   (SAMPLES + 1) / 2.0

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

DefineTarget (Fblur, s_Fg_blur);
DefineTarget (Bblur, s_Bg_blur);

DefineTarget (Spin1, s_Spin1);
DefineTarget (Spin2, s_Spin2);
DefineTarget (Spin3, s_Spin3);
DefineTarget (Spin4, s_Spin4);

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

int CW_CCW
<
   string Group = "Spin";
   string Description = "Rotation direction";
   string Enum = "Anticlockwise,Clockwise";
> = 1;

float blurLen
<
   string Group = "Spin";
   string Description = "Arc (degrees)";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 90.0;

float aspectRatio
<
   string Group = "Spin";
   string Description = "Aspect 1:x";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float CentreX
<
   string Description = "Centre";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.5;

float CentreY
<
   string Description = "Centre";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_RawBg, uv); }

float4 ps_FgBlur (float2 uv : TEXCOORD3, uniform int base) : COLOR
{
   int range = base + RANGE_1;

   float blurAngle, Tcos, Tsin, mix = Amount;
   float spinAmt  = (radians (blurLen * saturate (mix + 0.04))) / SAMPLES;
   float spinOffs = 1.0 - (INC_OFFSET * base);

   float2 blurAspect  = float2 (1.0, aspectRatio * _OutputAspectRatio);
   float2 centreXY    = float2 (CentreX, 1.0 - CentreY);
   float2 angleXY, xy = (uv - centreXY) / blurAspect;

   float4 retval = tex2D (s_Foreground, uv);
   float4 image  = retval;

   mix  = saturate (mix * 8.0);
   spinAmt = (CW_CCW == 0) ? spinAmt * 2.0 : spinAmt * -2.0;
   blurAngle = spinAmt * base;

   for (int i = base; i < range; i++) {
      sincos (blurAngle, Tsin, Tcos);
      angleXY = (float2 ((xy.x * Tcos - xy.y * Tsin), (xy.x * Tsin + xy.y * Tcos)) * blurAspect) + centreXY;

      retval += (tex2D (s_Foreground, angleXY) * spinOffs);

      blurAngle += spinAmt;
      spinOffs -= INC_OFFSET;
   }

   retval /= RETSCALE;

   if (base == RANGE_4) {
      retval += tex2D (s_Spin1, uv) + tex2D (s_Spin2, uv);
      retval += tex2D (s_Spin3, uv) + tex2D (s_Spin4, uv);

      retval = lerp (image, retval, mix);
   }

   return retval;
}

float4 ps_BgBlur (float2 uv : TEXCOORD3, uniform int base) : COLOR
{
   int range = base - RANGE_1;

   float blurAngle, Tcos, Tsin, mix = 1.0 - Amount;
   float spinAmt  = (radians (blurLen * saturate (mix - 0.04))) / SAMPLES;
   float spinOffs = 1.0 - (INC_OFFSET * base);

   float2 blurAspect  = float2 (1.0, aspectRatio * _OutputAspectRatio);
   float2 centreXY    = float2 (CentreX, 1.0 - CentreY);
   float2 angleXY, xy = (uv - centreXY) / blurAspect;

   float4 retval = tex2D (s_Background, uv);
   float4 image  = retval;

   mix = saturate (mix * 8.0);
   spinAmt = (CW_CCW == 0) ? spinAmt * 2.0 : spinAmt * -2.0;
   blurAngle = spinAmt * (1 - base);

   for (int i = base; i > range; i--) {
      sincos (blurAngle, Tsin, Tcos);
      angleXY = (float2 ((xy.x * Tcos - xy.y * Tsin), (xy.x * Tsin + xy.y * Tcos)) * blurAspect) + centreXY;

      retval += (tex2D (s_Background, angleXY) * spinOffs);

      blurAngle += spinAmt;
      spinOffs -= INC_OFFSET;
   }

   retval /= RETSCALE;

   if (base == RANGE_1) {
      retval += tex2D (s_Spin1, uv) + tex2D (s_Spin2, uv);
      retval += tex2D (s_Spin3, uv) + tex2D (s_Spin4, uv);

      retval = lerp (image, retval, mix);
   }

   return retval;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 outgoing = tex2D (s_Fg_blur, uv3);
   float4 incoming = tex2D (s_Bg_blur, uv3);

   float mix = (Amount - 0.5) * 2.0;

   mix = (1.0 + (abs (mix) * mix)) / 2.0;

   return lerp (outgoing, incoming, mix);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Spin_Dx
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)

   pass P_0 < string Script = "RenderColorTarget0 = Spin1;"; > ExecuteParam (ps_FgBlur, 0)
   pass P_1 < string Script = "RenderColorTarget0 = Spin2;"; > ExecuteParam (ps_FgBlur, RANGE_1)
   pass P_2 < string Script = "RenderColorTarget0 = Spin3;"; > ExecuteParam (ps_FgBlur, RANGE_2)
   pass P_3 < string Script = "RenderColorTarget0 = Spin4;"; > ExecuteParam (ps_FgBlur, RANGE_3)
   pass P_4 < string Script = "RenderColorTarget0 = Fblur;"; > ExecuteParam (ps_FgBlur, RANGE_4)
   pass P_5 < string Script = "RenderColorTarget0 = Spin1;"; > ExecuteParam (ps_BgBlur, RANGE_5)
   pass P_6 < string Script = "RenderColorTarget0 = Spin2;"; > ExecuteParam (ps_BgBlur, RANGE_4)
   pass P_7 < string Script = "RenderColorTarget0 = Spin3;"; > ExecuteParam (ps_BgBlur, RANGE_3)
   pass P_8 < string Script = "RenderColorTarget0 = Spin4;"; > ExecuteParam (ps_BgBlur, RANGE_2)
   pass P_9 < string Script = "RenderColorTarget0 = Bblur;"; > ExecuteParam (ps_BgBlur, RANGE_1)

   pass P_X ExecuteShader (ps_main)
}

