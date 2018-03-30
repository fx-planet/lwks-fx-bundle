//--------------------------------------------------------------//
// Lightworks user effect Adx_Ripples.fx
//
// Created by LW user jwrl 25 May 2016
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaRippleMix.fx by jwrl 8 August 2017 for
// name consistency through alpha dissolve range.
//
// This effect is used to transition into or out of a title, or
// to dissolve between titles.  It also composites the result
// over a background layer.
//
// This effect starts off by rippling the outgoing title as
// it dissolves to the new one, on which it progressively loses
// the ripple.
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
   string Description = "Alpha ripple dissolve";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture In1;
texture In2;
texture In3;

texture In_1 : RenderColorTarget;
texture In_2 : RenderColorTarget;
texture In_3 : RenderColorTarget;

texture BlurXinput : RenderColorTarget;
texture BlurYinput : RenderColorTarget;

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

sampler Fg1Sampler = sampler_state {
   Texture   = <In_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg2Sampler = sampler_state {
   Texture   = <In_3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler  = sampler_state {
   Texture   = <In_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler XinSampler = sampler_state {
   Texture   = <BlurXinput>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler YinSampler = sampler_state {
   Texture   = <BlurYinput>;
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

int Ttype
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Transition";
   string Enum = "Fade in,Fade out,Dissolve FX1 > FX2,Dissolve FX2 > FX1";
> = 0;

int WaveType
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Wave type";
   string Enum = "Waves,Ripples";
> = 0;

float Frequency
<
   string Group = "Pattern";
   string Flags = "Frequency";
   float MinVal = 0.00;
   float MaxVal = 100.0;
> = 20.0;

float Speed
<
   string Group = "Pattern";
   string Description = "Speed";
   float MinVal = 0.00;
   float MaxVal = 50.0;
> = 25.0;

float BlurAmt
<
   string Group = "Pattern";
   string Description = "Blur";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float StrengthX
<
   string Group = "Pattern";
   string Description = "Strength";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 0.1;
> = 0.02;

float StrengthY
<
   string Group = "Pattern";
   string Description = "Strength";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 0.1;
> = 0.0;

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

#define FX_IN   0
#define FX_OUT  1
#define FX1_FX2 2
#define FX2_FX1 3

#define SAMPLE  30
#define SAMPLES 60

#define OFFSET  0.0005

#define CENTRE  (0.5).xx

#define EMPTY   (0.0).xxxx

#define HALF_PI 1.570796

float _Progress;

int iSeed = 15;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

float2 func_wave (float2 uv, float2 waves, float levels)
{
   float waveRate = _Progress * Speed / 2.0;

   float2 retXY, xy = (uv - CENTRE) * waves;
   float2 strength  = float2 (StrengthX, StrengthY) * levels;

   retXY = (WaveType == 0.0) ? float2 (sin (waveRate + xy.y), cos (waveRate + xy.x))
                             : float2 (sin (waveRate + xy.x), cos (waveRate + xy.y));

   return uv + (retXY * strength);
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_mode_sw_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = (Ttype == FX1_FX2) ? tex2D (In2Sampler, uv) : tex2D (In1Sampler, uv);

   if (!Boost_On) return retval;

   retval.a = (Ttype == FX_OUT) ? pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0))
                                : pow (retval.a, 1.0 / max (1.0, Boost_I + 1.0));
   return retval;
}

float4 ps_mode_sw_2 (float2 uv : TEXCOORD1) : COLOR
{
   return ((Ttype == FX1_FX2) || (Ttype == FX2_FX1)) ? tex2D (In3Sampler, uv) : tex2D (In2Sampler, uv);
}

float4 ps_mode_sw_3 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = (Ttype == FX2_FX1) ? tex2D (In2Sampler, uv) : tex2D (In1Sampler, uv);

   if (Boost_On) retval.a = pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0));

   return retval;
}

float4 ps_dissolve (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1, xy2, waves = float (Frequency * 2.0).xx;

   sincos ((Amount * HALF_PI), xy2.x, xy2.y);
   xy2 = (1.0).xx - xy2;

   xy1 = func_wave (uv, waves, xy2.x);
   xy2 = func_wave (uv, waves, xy2.y);

   float4 fg1Pix = tex2D (Fg1Sampler, xy1);
   float4 fg2Pix = tex2D (Fg1Sampler, xy2);

   float4 retval = (Ttype == FX_OUT) ? lerp (EMPTY, fg2Pix, 1.0 - Amount)
                                     : lerp (EMPTY, fg1Pix, Amount);

   if ((Ttype == FX_IN) || (Ttype == FX_OUT)) return retval;

   fg2Pix = tex2D (Fg2Sampler, xy2);

   return lerp (retval, fg2Pix, fg2Pix.a * (1.0 - Amount));
}

float4 ps_blur (float2 uv : TEXCOORD1) : COLOR
{
   float4 Inp = tex2D (XinSampler, uv);
   float4 retval = EMPTY;

   float BlurX;

   if (StrengthY > StrengthX) { BlurX = WaveType ? BlurAmt : (BlurAmt / 2); }
   else BlurX = WaveType ? (BlurAmt / 2) : BlurAmt;

   if (BlurX <= 0.0) return Inp;

   float Mix = (Ttype == FX_IN) ? 1.0 - Amount : Amount;

   if ((Ttype == FX1_FX2) || (Ttype == FX2_FX1)) {
     Mix = abs (Mix - 0.5) * 5.0;
     Mix = 1.0 - max (Mix - 1.5, 0.0);
   }

   float2 offset = float2 (BlurX, 0.0) * OFFSET;
   float2 blurriness = 0.0.xx;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (XinSampler, uv + blurriness);
      retval += tex2D (XinSampler, uv - blurriness);
      blurriness += offset;
   }
    
   retval /= SAMPLES;

   return lerp (Inp, retval, Mix);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd   = tex2D (BgdSampler, uv);
   float4 Fgnd   = tex2D (YinSampler, uv);
   float4 retval = EMPTY;

   float BlurY;

   if (StrengthY > StrengthX) { BlurY = WaveType ? (BlurAmt / 2) : (BlurAmt * 2); }
   else BlurY = WaveType ? (BlurAmt * 2) : (BlurAmt / 2);

   if (BlurY <= 0.0) return lerp (Bgnd, Fgnd, Fgnd.a);

   float Mix = (Ttype == FX_IN) ? 1.0 - Amount : Amount;

   if ((Ttype == FX1_FX2) || (Ttype == FX2_FX1)) {
     Mix = abs (Mix - 0.5) * 5.0;
     Mix = 1.0 - max (Mix - 1.5, 0.0);
   }

   float2 offset = float2 (0.0, BlurY) * OFFSET;
   float2 blurriness = 0.0.xx;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (YinSampler, uv + blurriness);
      retval += tex2D (YinSampler, uv - blurriness);
      blurriness += offset;
   }
    
   retval /= SAMPLES;

   Fgnd = lerp (Fgnd, retval, Mix);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Ripples
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = In_3;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4 < string Script = "RenderColorTarget0 = BlurXinput;"; >
   { PixelShader = compile PROFILE ps_dissolve (); }

   pass P_5 < string Script = "RenderColorTarget0 = BlurYinput;"; >
   { PixelShader = compile PROFILE ps_blur (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}

