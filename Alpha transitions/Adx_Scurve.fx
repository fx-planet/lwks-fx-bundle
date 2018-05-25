// @Maintainer jwrl
// @Released 2018-04-06
// @Author jwrl
// @Created 2017-05-19
// @see https://www.lwks.com/media/kunena/attachments/6375/Adx_Scurve-640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaScurve.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Adx_Scurve.fx
//
// This is essentially the same as the S dissolve but extended to support alpha channels.
// A trigonometric curve is applied to the "Amount" parameter and the linearity of the
// curve can be adjusted.
//
// Alpha levels are boosted to support Lightworks titles, which is the default setting.
// The boost amount is tied to the incoming and outgoing titles, rather than FX1 and FX2
// as with the earlier version.  The boost technique also now uses gamma rather than
// gain to adjust the alpha levels.  This more closely visually matches the way that
// Lightworks handles titles.
//
// Modified 8 August 2017 by jwrl.
// Renamed from S_mix.fx for consistency of name through the alpha dissolve range.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha S dissolve";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture In1;
texture In2;
texture In3;

texture In_1 : RenderColorTarget;
texture In_2 : RenderColorTarget;

texture Bgd : RenderColorTarget;

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

sampler Fg1Sampler = sampler_state {
   Texture   = <In_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg2Sampler = sampler_state {
   Texture   = <In_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler  = sampler_state {
   Texture   = <Bgd>;
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
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float Linearity
<
   string Description = "Linearity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int SetTechnique
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Transition";
   string Enum = "Fade in,Fade out,Dissolve FX1 > FX2,Dissolve FX2 > FX1";
> = 0;

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

#define PI      3.1415927

#define HALF_PI 1.5707963

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
   float amount = (1.0 - sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Amount - amount;

   amount = saturate (amount + (curve * Linearity));

   float4 Fgnd = tex2D (Fg1Sampler, uv);
   float4 Bgnd = tex2D (BgdSampler, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a * amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (1.0 - sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Amount - amount;

   amount = 1.0 - saturate (amount + (curve * Linearity));

   float4 Fgnd = tex2D (Fg1Sampler, uv);
   float4 Bgnd = tex2D (BgdSampler, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a * amount);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (1.0 - sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Amount - amount;

   amount = saturate (amount + (curve * Linearity));

   float4 Fgd_1 = tex2D (Fg1Sampler, uv);
   float4 Fgd_2 = tex2D (Fg2Sampler, uv);

   float4 Bgnd = lerp (tex2D (BgdSampler, uv), Fgd_1, Fgd_1.a * (1.0 - amount));

   return lerp (Bgnd, Fgd_2, Fgd_2.a * amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique sDx_in
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique sDx_out
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique sDx_1_2
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_I (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique sDx_2_1
{
   pass P_1 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_O (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}
