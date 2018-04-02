// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Adx_Kaleido.fx
//
// Created by LW user jwrl 10 August 2016
// @Author jwrl
// @CreationDate "10 August 2016"
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaKaleidoMix.fx by jwrl 8 August 2017 for
// name consistency through alpha dissolve range.
//
// This is loosely based on Kaleido.fx by Lightworks user
// baopao (http://www.alessandrodallafontana.com/) which was
// in turn based on a pixel shader at http://pixelshaders.com/
// which was fine tuned for Cg compliance by Lightworks user
// nouanda.
//
// This effect has been built from that original.  In the
// process some further code optimisation has been done,
// mainly to address potental divide by zero errors.
//
// Alpha levels can be boosted to support Lightworks titles,
// which is the default setting.  The boost technique uses
// gamma rather than simple amplification to correct alpha
// levels.  This closely matches the way that Lightworks
// handles titles internally.
//
// Version 14.5 update 24 March 2018 by jwrl.
//
// Legality checking has been added to correct for a bug
// in XY sampler addressing on Linux and OS-X platforms.
// This effect should now function correctly when used with
// all current and previous Lightworks versions.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha kaleido mix";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture In1;
texture In2;
texture In3;

texture Fgd : RenderColorTarget;
texture Bgd : RenderColorTarget;
texture Bg1 : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler In1Sampler = sampler_state {
   Texture = <In1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In2Sampler = sampler_state {
   Texture = <In2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In3Sampler = sampler_state {
   Texture   = <In3>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FgdSampler = sampler_state {
   Texture   = <Fgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler  = sampler_state {
   Texture   = <Bgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Bg1Sampler = sampler_state {
   Texture   = <Bg1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
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

float Sides
<
   string Group = "Kaleidoscope";
   string Description = "Sides";
   float MinVal = 5.0;
   float MaxVal = 50.0;
> = 25.0;

float scaleAmt
<
   string Group = "Kaleidoscope";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.5;

float zoomFactor
<
   string Group = "Kaleidoscope";
   string Description = "Zoom";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float PosX
<
   string Group = "Kaleidoscope";
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float PosY
<
   string Group = "Kaleidoscope";
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
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

#define HALF_PI 1.570796
#define PI      3.141593
#define TWO_PI  6.283185

#define EMPTY   (0.0).xxxx

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//--------------------------------------------------------------//
// Shader
//--------------------------------------------------------------//

float4 ps_mode_sw_1_I (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (In1Sampler, uv);

   if (Boost_On) retval.a = pow (retval.a, 1.0 / max (1.0, Boost_I + 1.0));

   return retval;
}

float4 ps_mode_sw_1_O (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (In1Sampler, uv);

   if (Boost_On) retval.a = pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0));

   return retval;
}

float4 ps_mode_sw_2_I (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (In2Sampler, uv);

   if (Boost_On) retval.a = pow (retval.a, 1.0 / max (1.0, Boost_I + 1.0));

   return retval;
}

float4 ps_mode_sw_2_O (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (In2Sampler, uv);

   if (Boost_On) retval.a = pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0));

   return retval;
}

float4 ps_mode_sw_2_B (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In2Sampler, uv);
}

float4 ps_mode_sw_3_B (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In3Sampler, uv);
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float mixval = sin (Amount * HALF_PI);
   float Scale = 1.0 + ((1.0 - (scaleAmt * 0.4)) * (1.0 - Amount));
   float sideval = 1.0 + Sides - (Amount * Sides);
   float Zoom = 1.0 + zoomFactor - (Amount * zoomFactor);

   float2 PosXY = float2 (1.0 - PosX, 1.0 - PosY);
   float2 xy = float2 (1.0 - uv.x, uv.y) - PosXY;

   float radius = length (xy) / Zoom;
   float angle  = atan2 (xy.y, xy.x);

   angle = fmod (angle, TWO_PI / sideval);
   angle = abs (angle - (PI / sideval));

   sincos (angle, xy.y, xy.x);
   xy = ((xy * radius) + PosXY) / Scale;

   float4 Fgd = fn_illegal (xy) ? EMPTY : tex2D (FgdSampler, xy);
   float4 Bgd = tex2D (Bg1Sampler, uv);

   return lerp (Bgd, Fgd, Fgd.a * mixval);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float Scale = 1.0 + (Amount * (1.0 - (scaleAmt * 0.4)));
   float mixval = cos (Amount * HALF_PI);
   float sideval = 1.0 + (Amount * Sides);
   float Zoom = 1.0 + (Amount * zoomFactor);

   float2 PosXY = float2 (1.0 - PosX, 1.0 - PosY);
   float2 xy = float2 (1.0 - uv.x, uv.y) - PosXY;

   float radius = length (xy) / Zoom;
   float angle  = atan2 (xy.y, xy.x);

   angle = fmod (angle, TWO_PI / sideval);
   angle = abs (angle - (PI / sideval));

   sincos (angle, xy.y, xy.x);
   xy = ((xy * radius) + PosXY) / Scale;

   float4 Fgd = fn_illegal (xy) ? EMPTY : tex2D (FgdSampler, xy);
   float4 Bgd = tex2D (BgdSampler, uv);

   return lerp (Bgd, Fgd, Fgd.a * mixval);
}

//--------------------------------------------------------------//
// Technique
//--------------------------------------------------------------//

technique fade_in
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique fade_out
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique diss_Fx1_Fx2
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bg1;"; >
   { PixelShader = compile PROFILE ps_main_out (); }

   pass P_4 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_I (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique diss_Fx2_Fx1
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bg1;"; >
   { PixelShader = compile PROFILE ps_main_out (); }

   pass P_4 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main_in (); }
}

