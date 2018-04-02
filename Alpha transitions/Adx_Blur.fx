// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Adx_Blur.fx
//
// Created by LW user jwrl 24 May 2016
// @Author: jwrl
// @CreationDate: "24 May 2016"
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaBlurMix.fx by jwrl 8 August 2017 for name
// consistency through alpha dissolve range.
//
// This effect is used to transition into or out of a title, or
// to dissolve between titles.  It also composites the result
// over a background layer.
//
// During the process it also applies a directional blur,
// the angle and strength of which can be independently set
// for both the incoming and outgoing vision sources.  A
// setting to tie both incoming and outgoing blurs together
// is also provided.
//
// Alpha levels are boosted to support Lightworks titles, which
// is now the default setting.  The boost amount is tied to the
// incoming and outgoing titles, rather than FX1 and FX2 as
// with the earlier version.
//
// The boost technique also now uses gamma rather than gain to
// adjust the alpha levels.  This more closely matches the way
// that Lightworks handles titles.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha blur dissolve";
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

texture ovl1Proc : RenderColorTarget;
texture ovl2Proc : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler In1Sampler = sampler_state {
   Texture   = <In1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In2Sampler = sampler_state
{
   Texture   = <In2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg1Sampler = sampler_state
{ 
   Texture   = <In_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg2Sampler = sampler_state {
   Texture   = <In_3>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler ovl1Sampler = sampler_state
{
   Texture   = <ovl1Proc>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler ovl2Sampler = sampler_state
{
   Texture   = <ovl2Proc>;
   AddressU  = Mirror;
   AddressV  = Mirror;
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

sampler BgdSampler = sampler_state {
   Texture   = <In_2>;
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

float o_Angle
<
   string Group = "Primary blur";
   string Description = "Angle";
   float MinVal = -180.00;
   float MaxVal = 180.0;
> = 0.0;

float o_Strength
<
   string Group = "Primary blur";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float o_Spread
<
   string Group = "Primary blur";
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int SetTechnique
<
   string Group = "Secondary blur";
   string Description = "Settings";
   string Enum = "Use primary blur settings,Use blur settings below";
> = 0;

float i_Angle
<
   string Group = "Secondary blur";
   string Description = "Angle";
   float MinVal = -180.00;
   float MaxVal = 180.0;
> = 0.0;

float i_Strength
<
   string Group = "Secondary blur";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float i_Spread
<
   string Group = "Secondary blur";
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
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

#define FX_IN     0
#define FX_OUT    1
#define FX1_FX2   2
#define FX2_FX1   3

#define SAMPLES   60
#define SAMPSCALE 61

#define STRENGTH  0.01

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Pixel Shader
//--------------------------------------------------------------//

float4 ps_mode_sw_1 (float2 xy : TEXCOORD1) : COLOR
{
   return (Ttype == FX2_FX1) ? tex2D (In2Sampler, xy) : tex2D (In1Sampler, xy);
}

float4 ps_mode_sw_2 (float2 xy : TEXCOORD1) : COLOR
{
   return ((Ttype == FX1_FX2) || (Ttype == FX2_FX1)) ? tex2D (In3Sampler, xy) : tex2D (In2Sampler, xy);
}

float4 ps_mode_sw_3 (float2 xy : TEXCOORD1) : COLOR
{
   return (Ttype == FX1_FX2) ? tex2D (In2Sampler, xy) : tex2D (In1Sampler, xy);
}

float4 ps_blur (float2 uv : TEXCOORD1, uniform sampler bSamp, uniform float bStrn, uniform float bAng, uniform int bOffs) : COLOR
{
   if ((bStrn == 0.0) || ((bOffs == 0) && (Ttype == FX_IN)) || ((bOffs == 1) && (Ttype == FX_OUT))) return tex2D (bSamp, uv);

   float2 blurOffset, xy = uv;
   float4 retval = 0.0;

   sincos (radians (bAng + (bOffs * 180)), blurOffset.y, blurOffset.x);
   blurOffset *= (bStrn * abs (bOffs - Amount) * STRENGTH);

   for (int i = 0; i < SAMPLES; i++) {
      retval += tex2D (bSamp, xy);
      xy += blurOffset;
      }
    
   retval /= SAMPSCALE;

   return saturate (retval);
}

float4 ps_main (float2 xy : TEXCOORD1, uniform int modeSet) : COLOR
{
   float4 bgdImage = tex2D (BgdSampler, xy);
   float4 fgdImage = tex2D (ovl1Sampler, xy);

   if (Boost_On) fgdImage.a = pow (fgdImage.a, 1.0 / max (1.0, Boost_O + 1.0));

   float Mix = saturate (((Amount - 0.5) * ((o_Strength * 3) + 1.5)) + 0.5);

   float4 retval = (Ttype == FX_IN) ? bgdImage : lerp (bgdImage, fgdImage, fgdImage.a * (1.0 - Mix));

   if (Ttype == FX_OUT) return retval;

   if (Ttype != FX_IN) {
      if (modeSet == 1) Mix = saturate (((Amount - 0.5) * ((i_Strength * 3) + 1.5)) + 0.5);
   }

   fgdImage = tex2D (ovl2Sampler, xy);
   if (Boost_On) fgdImage.a = pow (fgdImage.a, 1.0 / max (1.0, Boost_I + 1.0));

   return lerp (retval, fgdImage, fgdImage.a * Mix);
}

//--------------------------------------------------------------//
// Technique
//--------------------------------------------------------------//

technique blurDiss_0
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = In_3;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4 < string Script = "RenderColorTarget0 = ovl1Proc;"; >
   { PixelShader = compile PROFILE ps_blur (Fg1Sampler, o_Spread, o_Angle, 0); }

   pass P_5 < string Script = "RenderColorTarget0 = ovl2Proc;"; >
   { PixelShader = compile PROFILE ps_blur (Fg2Sampler, o_Spread, o_Angle, 1); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (0); }
}

technique blurDiss_1
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = In_3;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4 < string Script = "RenderColorTarget0 = ovl1Proc;"; >
   { PixelShader = compile PROFILE ps_blur (Fg1Sampler, o_Spread, o_Angle, 0); }

   pass P_5 < string Script = "RenderColorTarget0 = ovl2Proc;"; >
   { PixelShader = compile PROFILE ps_blur (Fg2Sampler, i_Spread, i_Angle, 1); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (1); }
}

