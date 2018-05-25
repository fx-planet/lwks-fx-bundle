// @Maintainer jwrl
// @Released 2018-04-06
// @Author jwrl
// @Created 2016-07-03
// @see https://www.lwks.com/media/kunena/attachments/6375/Adx_Strips_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaStrips.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Adx_Strips.fx
//
// An alpha transition that splits title(s) into strips and compresses them to zero
// height.  The vertical centring can be adjusted so that the collapse is symmetrical.
//
// Alpha levels are boosted to support Lightworks titles, which is the default setting.
// The boost amount is tied to the incoming and outgoing titles, rather than FX1 and FX2
// as with the earlier version.  The boost technique also now uses gamma rather than
// gain to adjust the alpha levels.  This more closely visually matches the way that
// Lightworks handles titles.
//
// LW 14+ version by jwrl 19 May 2017
// Added subcategory "Alpha"
//
// Modified 8 August 2017 by jwrl.
// Renamed from AlphaStripMix.fx for name consistency through the alpha dissolve range.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha strips";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture In1;
texture In2;
texture In3;

texture Fgd : RenderColorTarget;
texture Bgd : RenderColorTarget;
texture Bg1 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

sampler FgdSampler = sampler_state {
   Texture   = <Fgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state {
   Texture   = <Bgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Bg1Sampler = sampler_state {
   Texture   = <Bg1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0 = 0.0;
   float KF1 = 1.0;
> = 0.5;

int SetTechnique
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Transition";
   string Enum = "Fade in,Fade out,Dissolve FX1 > FX2,Dissolve FX2 > FX1";
> = 0;

float Spacing
<
   string Group = "Strips";
   string Description = "Spacing";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float Spread
<
   string Group = "Strips";
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreX
<
   string Group = "Strips";
   string Description = "Centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreY
<
   string Group = "Strips";
   string Description = "Centre";
   string Flags = "SpecifiesPointY";
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HEIGHT   20.0

#define PI       3.141593
#define HALF_PI  1.570796

float _Progress;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

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
   float amount   = 1.0 - Amount;
   float Width    = 10.0 + (Spacing * 40.0);
   float centre_X = 1.0 - (2.0 * centreX);
   float centre_Y = 1.0 - centreY;
   float offset = sin (Width * uv.y * PI);
   float Height = 1.0 - cos (amount * HALF_PI);

   if (abs (offset) > 0.5) offset = -offset;

   offset = ((floor (offset * 5.2) / 5.0) + centre_X) * amount;

   float2 xy = uv + float2 (offset, -centre_Y);

   offset *= 2.0 * Spread;
   xy.y = (xy.y * ((Height * HEIGHT) + 1.0)) + offset + centre_Y;

   float4 Fgnd = tex2D (FgdSampler, saturate (xy));
   float4 Bgnd = tex2D (Bg1Sampler, uv);

   Fgnd.a *= saturate ((1.0 - amount) * 5.0);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float Width = 10.0 + (Spacing * 40.0);
   float centre_X = 1.0 - (2.0 * centreX);
   float centre_Y = 1.0 - centreY;
   float offset = sin (Width * uv.y * PI);
   float Height = 1.0 - cos (Amount * HALF_PI);

   if (abs (offset) > 0.5) offset = -offset;

   offset = ((floor (offset * 5.2) / 5.0) + centre_X) * Amount;

   float2 xy = uv + float2 (offset, -centre_Y);

   offset *= 2.0 * Spread;
   xy.y = (xy.y * ((Height * HEIGHT) + 1.0)) + offset + centre_Y;

   float4 Fgnd = tex2D (FgdSampler, saturate (xy));
   float4 Bgnd = tex2D (BgdSampler, uv);

   Fgnd.a *= saturate ((1.0 - Amount) * 5.0);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

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

   pass P_5 { PixelShader = compile PROFILE ps_main_in (); }
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

   pass P_5 { PixelShader = compile PROFILE ps_main_in (); }
}
