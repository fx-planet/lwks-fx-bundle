// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Adx_Spin.fx
//
// Created by LW user jwrl 30 December 2016
// @Author jwrl
// @CreationDate "30 December 2016"
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaSpinMix.fx by jwrl 8 August 2017 for
// name consistency through alpha dissolve range.
//
// This effect is based on original shader code by rakusan
// (http://kuramo.ch/webgl/videoeffects/).
//
// The effect applies a rotational blur to transition into
// or out of a title or between titles.  The direction,
// aspect ratio, centring and strength of the blur can all
// be adjusted.  It then composites the result over the
// background layer.
//
// Alpha levels can be boosted to support Lightworks titles,
// which is the default setting.  The boost technique uses
// gamma rather than simple amplification to correct alpha
// levels.  This closely matches the way that Lightworks
// handles titles internally.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha spin dissolve";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture In1;
texture In2;
texture In3;

texture Fgnd : RenderColorTarget;
texture Bgnd : RenderColorTarget;

texture Spn1 : RenderColorTarget;
texture Spn2 : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler In1Sampler = sampler_state {
   Texture = <In1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In2Sampler = sampler_state {
   Texture = <In2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In3Sampler = sampler_state {
   Texture   = <In3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FgSampler = sampler_state {
   Texture   = <Fgnd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler  = sampler_state {
   Texture   = <Bgnd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Spn1Sampler = sampler_state {
   Texture   = <Spn1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Spn2Sampler = sampler_state {
   Texture   = <Spn2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Transition";
   string Enum = "Fade in,Fade out,Dissolve FX1 > FX2,Dissolve FX2 > FX1";
> = 0;

int CW_CCW
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Rotation direction";
   string Enum = "Anticlockwise,Clockwise";
> = 1;

float blurAmount
<
   string Group = "Spin";
   string Description = "Arc (degrees)";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 90.0;

float aspectRatio
<
   string Group = "Spin";
   string Description = "Aspect ratio 1:x";
   float MinVal = 0.01;
   float MaxVal = 10.00;
> = 1.0;

float centreX
<
   string Group = "Spin";
   string Description = "Centre";
   string Flags = "SpecifiesPointX";
   float MinVal = -0.50;
   float MaxVal = 1.50;
> = 0.5;

float centreY
<
   string Group = "Spin";
   string Description = "Centre";
   string Flags = "SpecifiesPointY";
   float MinVal = -0.50;
   float MaxVal = 1.50;
> = 0.5;

bool Boost_On
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Enable alpha boost";
> = false;

float Boost_O
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Boost outgoing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Boost_I
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Boost incoming";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define HALF_PI   1.570796

#define BLUR_0    20
#define BLUR_1    40
#define BLUR_2    60
#define BLUR_3    80
#define BLUR_4    100

#define BASE_0    1.0
#define BASE_1    0.8125
#define BASE_2    0.625
#define BASE_3    0.4375
#define BASE_4    0.25

#define REDUCE    0.009375

#define CCW       0
#define CW        1

#define FADE_IN   true
#define FADE_OUT  false

#define PASS_0    0
#define PASS_1    1
#define PASS_2    2
#define PASS_3    3
#define PASS_4    4

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_fixAlpha (float2 uv : TEXCOORD1, uniform sampler foreground, uniform float enhanceKey) : COLOR
{
   float4 retval = tex2D (foreground, uv);

   if (Boost_On) retval.a = pow (retval.a, 1.0 / max (1.0, enhanceKey + 1.0));

   return retval;
}

float4 ps_spinBlur (float2 xy : TEXCOORD1, uniform int passNum, uniform bool fade_in) : COLOR
{
   int start_count, end_count;
   float Tcos, Tsin, reduction, blurLen = Amount * HALF_PI;
   float2 angXY;

   blurLen = fade_in ? sin (blurLen) : cos (blurLen);
   blurLen = (1.0 - blurLen) * blurAmount;

   if (blurLen == 0.0) return tex2D (Spn1Sampler, xy);

   float4 retval = (0.0).xxxx;

   float2 outputAspect = float2 (1.0, _OutputAspectRatio);
   float2 blurAspect = float2 (1.0, aspectRatio);
   float2 centre = float2 (centreX, 1.0 - centreY );
   float2 uv = (xy - centre) / outputAspect / blurAspect;

   float amount = radians (blurLen) / BLUR_4;

   if (passNum == PASS_0) { start_count = 0; end_count = BLUR_0; reduction = BASE_0; }
   else if (passNum == PASS_1) { start_count = BLUR_0; end_count = BLUR_1; reduction = BASE_1; }
   else if (passNum == PASS_2) { start_count = BLUR_1; end_count = BLUR_2; reduction = BASE_2; }
   else if (passNum == PASS_3) { start_count = BLUR_2; end_count = BLUR_3; reduction = BASE_3; }
   else { start_count = BLUR_3; end_count = BLUR_4; reduction = BASE_4; }

   if ((fade_in && (CW_CCW == CCW)) || ((CW_CCW == CW) && !fade_in)) amount = -amount;

   float ang = amount * start_count;

   for (int i = start_count; i < end_count; i++) {
      sincos (ang, Tsin, Tcos);
      angXY = centre + float2 ((uv.x * Tcos - uv.y * Tsin),
              (uv.x * Tsin + uv.y * Tcos) * outputAspect.y) * blurAspect;

      retval = max (retval, (tex2D (Spn1Sampler, angXY) * reduction));

      reduction -= REDUCE;
      ang += amount;
   }

   if ((passNum == PASS_1) || (passNum == PASS_3)) { retval = max (retval, tex2D (FgSampler, xy)); }
   else if (passNum != PASS_0) retval = max (retval, tex2D (Spn2Sampler, xy));

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1, uniform sampler B_sampler, uniform bool fade_in) : COLOR
{
   float mixAmt = fade_in ? Amount : 1.0 - Amount;

   float4 Fgd = tex2D (FgSampler, uv);
   float4 Bgd = tex2D (B_sampler, uv);

   return lerp (Bgd, Fgd, Fgd.a * mixAmt);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique SpinDissIn
{
   pass P_1 < string Script = "RenderColorTarget0 = Spn1;"; >
   { PixelShader = compile PROFILE ps_fixAlpha (In1Sampler, Boost_I); }

   pass P_2 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_0, FADE_IN); }

   pass P_3 < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_1, FADE_IN); }

   pass P_4 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_2, FADE_IN); }

   pass P_5 < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_3, FADE_IN); }

   pass P_6 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_4, FADE_IN); }

   pass P_7
   { PixelShader = compile PROFILE ps_main (In2Sampler, FADE_IN); }
}

technique SpinDissOut
{
   pass P_1 < string Script = "RenderColorTarget0 = Spn1;"; >
   { PixelShader = compile PROFILE ps_fixAlpha (In1Sampler, Boost_O); }

   pass P_2 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_0, FADE_OUT); }

   pass P_3 < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_1, FADE_OUT); }

   pass P_4 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_2, FADE_OUT); }

   pass P_5 < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_3, FADE_OUT); }

   pass P_6 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_4, FADE_OUT); }

   pass P_7
   { PixelShader = compile PROFILE ps_main (In2Sampler, FADE_OUT); }
}

technique SpinDissFX1_FX2
{
   pass P_1 < string Script = "RenderColorTarget0 = Spn1;"; >
   { PixelShader = compile PROFILE ps_fixAlpha (In1Sampler, Boost_O); }

   pass P_2 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_0, FADE_OUT); }

   pass P_3 < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_1, FADE_OUT); }

   pass P_4 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_2, FADE_OUT); }

   pass P_5 < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_3, FADE_OUT); }

   pass P_6 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_4, FADE_OUT); }

   pass P_7 < string Script = "RenderColorTarget0 = Bgnd;"; >
   { PixelShader = compile PROFILE ps_main (In3Sampler, FADE_OUT); }

   pass P_8 < string Script = "RenderColorTarget0 = Spn1;"; >
   { PixelShader = compile PROFILE ps_fixAlpha (In2Sampler, Boost_I); }

   pass P_9 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_0, FADE_IN); }

   pass P_A < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_1, FADE_IN); }

   pass P_B < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_2, FADE_IN); }

   pass P_C < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_3, FADE_IN); }

   pass P_D < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_4, FADE_IN); }

   pass P_E
   { PixelShader = compile PROFILE ps_main (BgSampler, FADE_IN); }
}

technique SpinDissFX2_FX1
{
   pass P_1 < string Script = "RenderColorTarget0 = Spn1;"; >
   { PixelShader = compile PROFILE ps_fixAlpha (In2Sampler, Boost_O); }

   pass P_2 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_0, FADE_OUT); }

   pass P_3 < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_1, FADE_OUT); }

   pass P_4 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_2, FADE_OUT); }

   pass P_5 < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_3, FADE_OUT); }

   pass P_6 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_4, FADE_OUT); }

   pass P_7 < string Script = "RenderColorTarget0 = Bgnd;"; >
   { PixelShader = compile PROFILE ps_main (In3Sampler, FADE_OUT); }

   pass P_8 < string Script = "RenderColorTarget0 = Spn1;"; >
   { PixelShader = compile PROFILE ps_fixAlpha (In1Sampler, Boost_I); }

   pass P_9 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_0, FADE_IN); }

   pass P_A < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_1, FADE_IN); }

   pass P_B < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_2, FADE_IN); }

   pass P_C < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_3, FADE_IN); }

   pass P_D < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur (PASS_4, FADE_IN); }

   pass P_E
   { PixelShader = compile PROFILE ps_main (BgSampler, FADE_IN); }
}

