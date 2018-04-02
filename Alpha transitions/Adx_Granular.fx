// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Adx_Granular.fx
//
// Created by LW user jwrl 25 May 2016
// @Author jwrl
// @CreationDate "25 May 2016"
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaGranMix.fx by jwrl 8 August 2017 for
// name consistency through alpha dissolve range.
//
// This effect uses a granular noise driven dissolve to
// transition into or out of a title, or between titles.
// It also composites the result over a background layer.
//
// Alpha levels are boosted to support Lightworks titles, which
// is now the default setting.  The boost amount is tied to the
// incoming and outgoing titles, rather than FX1 and FX2 as
// with the earlier version.
//
// The boost technique also now uses gamma rather than gain to
// adjust the alpha levels.  This more closely matches the way
// that Lightworks handles titles.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  THE BUG WAS NOT IN THE WAY THIS EFFECT
// WAS ORIGINALLY IMPLEMENTED.
//
// It appears that when a height parameter is needed one can
// not reliably use _OutputHeight.  It returns only half the
// actual frame height when interlaced media is playing and
// only when it is playing.  For that reason the output height
// should always be obtained by dividing _OutputWidth by
// _OutputAspectRatio until such time as the bug in the
// Lightworks code can be fixed.  It seems that after contact
// with the developers that is very unlikely to be soon.
//
// Note: This fix has been fully tested, and appears to be a
// reliable solution regardless of the pixel aspect ratio.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha granular dissolve";
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

texture Buffer_0 : RenderColorTarget;
texture Buffer_1 : RenderColorTarget;
texture Buffer_2 : RenderColorTarget;
texture Buffer_3 : RenderColorTarget;

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

sampler BgdSampler  = sampler_state {
   Texture   = <In_2>;
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

sampler Buffer_0_S  = sampler_state {
   Texture   = <Buffer_0>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buffer_1_S  = sampler_state {
   Texture   = <Buffer_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buffer_2_S  = sampler_state {
   Texture   = <Buffer_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buffer_3_S  = sampler_state {
   Texture   = <Buffer_3>;
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

int SetTechnique
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Transition type";
   string Enum = "Top to bottom,Left to right,Radial,No gradient";
> = 1;

bool TransDir
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Invert transition direction";
> = false;

float gWidth
<
   string Group = "Granules";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool TransVar
<
   string Group = "Granules";
   string Description = "Static pattern";
> = false;

bool Sparkling
<
   string Group       = "Sparkles";
   string Description = "Enable sparkle edge";
> = true;

float pSize
<
   string Group       = "Sparkles";
   string Description = "Size";
   float MinVal = 1.00;
   float MaxVal = 10.0;
> = 5.5;

float pSoftness
<
   string Group       = "Sparkles";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float4 starColour
<
   string Group       = "Sparkles";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 0.0, 1.0 };

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

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

#define OutputHeight (_OutputWidth/_OutputAspectRatio)

#define FX_IN   0
#define FX_OUT  1
#define FX1_FX2 2
#define FX2_FX1 3

// Pascal's triangle magic numbers for blur

#define BLUR_0  0.3125
#define BLUR_1  0.2344
#define BLUR_2  0.09375
#define BLUR_3  0.01563

#pragma warning ( disable : 3571 )

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

float4 vertical_grad (float2 uv : TEXCOORD1) : COLOR
{
   float retval = lerp (0.0, 1.0, uv.y);

   if (TransDir) retval = 1.0 - retval;

   retval = saturate ((5 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

float4 horizontal_grad (float2 uv : TEXCOORD1) : COLOR
{
   float retval = lerp (0.0, 1.0, uv.x);

   if (TransDir) retval = 1.0 - retval;

   retval = saturate ((5 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

float4 radial_grad (float2 uv : TEXCOORD1) : COLOR
{
   float progress = abs (distance (uv, float2 (0.5, 0.5))) * 1.414;
   float4 pixel = tex2D (Fg1Sampler, uv);

   float colOneAmt = 1.0 - progress;
   float colTwoAmt = progress;

   float retval = (lerp (pixel, 0.0, 1.0) * colOneAmt) +
                  (lerp (pixel, 1.0, 1.0) * colTwoAmt) +
                  (pixel * (1.0 - (colOneAmt + colTwoAmt)));

   if (TransDir) retval = 1.0 - retval;

   retval = saturate ((5 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

float4 noise_gen (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = saturate (uv + float2 (0.00013, 0.00123));

   float seed = (TransVar) ? 0.0 : Amount;
   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + seed) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + rndval * 1000;

   float retval = saturate (frac (fmod (rndval, 17) * fmod (rndval, 94)) * 3);

   return retval.xxxx;
}

float4 Soften_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval   = tex2D (Buffer_1_S, uv);

   float2 offset_X1 = float2 (pSoftness / _OutputWidth, 0.0);
   float2 offset_X2 = offset_X1 * 2.0;
   float2 offset_X3 = offset_X1 * 3.0;

   retval *= BLUR_0;
   retval += tex2D (Buffer_1_S, uv + offset_X1) * BLUR_1;
   retval += tex2D (Buffer_1_S, uv - offset_X1) * BLUR_1;
   retval += tex2D (Buffer_1_S, uv + offset_X2) * BLUR_2;
   retval += tex2D (Buffer_1_S, uv - offset_X2) * BLUR_2;
   retval += tex2D (Buffer_1_S, uv + offset_X3) * BLUR_3;
   retval += tex2D (Buffer_1_S, uv - offset_X3) * BLUR_3;

   return retval;
}

float4 Soften_2 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval   = tex2D (Buffer_2_S, uv);

   float2 offset_Y1 = float2 (0.0, pSoftness * _OutputAspectRatio / _OutputWidth);
   float2 offset_Y2 = offset_Y1 * 2.0;
   float2 offset_Y3 = offset_Y1 * 3.0;

   retval *= BLUR_0;
   retval += tex2D (Buffer_2_S, uv + offset_Y1) * BLUR_1;
   retval += tex2D (Buffer_2_S, uv - offset_Y1) * BLUR_1;
   retval += tex2D (Buffer_2_S, uv + offset_Y2) * BLUR_2;
   retval += tex2D (Buffer_2_S, uv - offset_Y2) * BLUR_2;
   retval += tex2D (Buffer_2_S, uv + offset_Y3) * BLUR_3;
   retval += tex2D (Buffer_2_S, uv - offset_Y3) * BLUR_3;

   return retval;
}

float4 Combine (float2 uv : TEXCOORD1) : COLOR
{
   bool dualTrans = (Ttype == FX1_FX2) || (Ttype == FX2_FX1);

   float4 Fg1Pix = tex2D (Fg1Sampler, uv);
   float4 Fg2Pix = tex2D (Fg2Sampler, uv);
   float4 BgdPix = tex2D (BgdSampler, uv);

   float4 noise = tex2D (Buffer_3_S, ((uv - 0.5) / pSize) + 0.5);

   float grad  = tex2D (Buffer_0_S, uv).x;
   float level = saturate (((0.5 - grad) * 2) + noise);

   float4 retval = (Ttype == FX_OUT) ? lerp (BgdPix, Fg1Pix, Fg1Pix.a * (1.0 - level))
                                     : lerp (BgdPix, Fg1Pix, Fg1Pix.a * level);

   if (dualTrans) retval = lerp (retval, Fg2Pix, Fg2Pix.a * (1.0 - level));

   if (!Sparkling) return retval;

   level = 0.5 - abs (level - 0.5);

   float stars = saturate ((pow (level, 3.0) * 4.0) + level);

   stars *= (dualTrans) ? max (Fg1Pix.a, Fg2Pix.a) : Fg1Pix.a;

   return lerp (retval, starColour, stars);
}

float4 Combine_flat (float2 uv : TEXCOORD1) : COLOR
{
   bool dualTrans = (Ttype == FX1_FX2) || (Ttype == FX2_FX1);

   float4 Fg1Pix = tex2D (Fg1Sampler, uv);
   float4 Fg2Pix = tex2D (Fg2Sampler, uv);
   float4 BgdPix = tex2D (BgdSampler, uv);

   float4 noise = tex2D (Buffer_3_S, ((uv - 0.5) / pSize) + 0.5);

   float level = saturate (((Amount - 0.5) * 2.0) + noise.x);

   float4 retval = (Ttype == FX_OUT) ? lerp (BgdPix, Fg1Pix, Fg1Pix.a * (1.0 - level))
                                     : lerp (BgdPix, Fg1Pix, Fg1Pix.a * level);

   if (dualTrans) retval = lerp (retval, Fg2Pix, Fg2Pix.a * (1.0 - level));

   if (!Sparkling) return retval;

   level = 0.5 - abs (level - 0.5);

   float stars = saturate ((pow (level, 3.0) * 4.0) + level);

   stars *= (dualTrans) ? max (Fg1Pix.a, Fg2Pix.a) : Fg1Pix.a;

   return lerp (retval, starColour, stars);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique TopToBottom
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = In_3;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4 < string Script = "RenderColorTarget0 = Buffer_0;"; >
   { PixelShader = compile PROFILE vertical_grad (); }

   pass P_5 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE noise_gen (); }

   pass P_6 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE Soften_1 (); }

   pass P_7 < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE Soften_2 (); }

   pass P_8
   { PixelShader = compile PROFILE Combine (); }
}

technique LeftToRight
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = In_3;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4 < string Script = "RenderColorTarget0 = Buffer_0;"; >
   { PixelShader = compile PROFILE horizontal_grad (); }

   pass P_5 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE noise_gen (); }

   pass P_6 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE Soften_1 (); }

   pass P_7 < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE Soften_2 (); }

   pass P_8
   { PixelShader = compile PROFILE Combine (); }
}

technique Radial
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = In_3;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4 < string Script = "RenderColorTarget0 = Buffer_0;"; >
   { PixelShader = compile PROFILE radial_grad (); }

   pass P_5 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE noise_gen (); }

   pass P_6 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE Soften_1 (); }

   pass P_7 < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE Soften_2 (); }

   pass P_8
   { PixelShader = compile PROFILE Combine (); }
}

technique Flat
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = In_3;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE noise_gen (); }

   pass P_5 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE Soften_1 (); }

   pass P_6 < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE Soften_2 (); }

   pass P_7
   { PixelShader = compile PROFILE Combine_flat (); }
}

