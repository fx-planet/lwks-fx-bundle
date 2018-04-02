// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Adx_Fractals.fx
//
// Created by LW user jwrl 24 May 2016
// @Author: jwrl
// @CreationDate: "24 May 2016"
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaFractalMix.fx by jwrl 8 August 2017 for
// name consistency through alpha dissolve range.
//
// This effect uses a fractal-like pattern to transition into
// or out of a title, or to dissolve between titles.  It also
// composites the result over a background layer.
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
   string Description = "Alpha fractal dissolve";
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
texture Fg1 : RenderColorTarget;
texture Bgd : RenderColorTarget;

texture FracOut : RenderColorTarget;

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

sampler FgdSampler = sampler_state {
   Texture   = <Fgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg1Sampler = sampler_state {
   Texture   = <Fg1>;
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

sampler FracSampler = sampler_state {
   Texture   = <FracOut>;
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

float fractalOffset
<
   string Group = "Fractal";
   string Description = "Offset";   
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Rate
<
   string Group = "Fractal";
   string Description = "Rate";   
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Border
<
   string Group = "Fractal";
   string Description = "Edge size";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

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

#define FEATHER 0.1

float _OutputAspectRatio;
float _Progress;

//--------------------------------------------------------------//
// Shaders
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

float4 ps_fractal (float2 xy : TEXCOORD1) : COLOR
{
   float progress = saturate ((_Progress * 2.0 / 3.0) + 1.0 / 3.0);
   float speed = progress * Rate * 0.5;

   float3 fractal = float3 (xy.x / _OutputAspectRatio, xy.y, fractalOffset);

   for (int i = 0; i < 75; i++) {
      fractal.xzy = float3 (1.3, 0.999, 0.7) * (abs ((abs (fractal) / dot (fractal, fractal) - float3 (1.0, 1.0, speed))));
   }

   return float4 (fractal, max (fractal.g, max (fractal.r, fractal.b)));
}

float4 ps_main_in (float2 xy : TEXCOORD1) : COLOR
{
   float4 Ovly = tex2D (FracSampler, xy);
   float4 Bgnd = tex2D (BgdSampler, xy);

   float fractal = saturate (Ovly.a * ((Amount * 0.666667) + 0.333333));
   float FthrRng = Amount + FEATHER;

   if (fractal > FthrRng) return Bgnd;

   Ovly.a = 1.0;

   float bdWidth = Border * 0.1;
   float fracAmt = (fractal - Amount) / FEATHER;

   float4 Fgnd   = tex2D (FgdSampler, xy);
   float4 retval = (fractal <= (Amount - bdWidth)) ? Fgnd : lerp (Fgnd, Ovly, fracAmt);

   if (fractal > (Amount + bdWidth)) { retval = lerp (retval, Bgnd, fracAmt); }

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_out (float2 xy : TEXCOORD1) : COLOR
{
   float4 Ovly = tex2D (FracSampler, xy);
   float4 Bgnd = tex2D (BgdSampler, xy);
   float4 Fgnd = tex2D (FgdSampler, xy);

   float fractal = saturate (Ovly.a * ((Amount * 0.666667) + 0.333333));
   float FthrRng = Amount + FEATHER;

   if (fractal > FthrRng) return lerp (Bgnd, Fgnd, Fgnd.a);

   Ovly.a = 1.0;

   float bdWidth = Border * 0.1;
   float fracAmt = (fractal - Amount) / FEATHER;

   float4 retval = (fractal <= (Amount - bdWidth)) ? Bgnd : lerp (Bgnd, Ovly, fracAmt);

   if (fractal > (Amount + bdWidth)) { retval = lerp (retval, Fgnd, fracAmt); }

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 Ovly = tex2D (FracSampler, xy);
   float4 Fgd1 = tex2D (FgdSampler, xy);
   float4 Bgnd = tex2D (BgdSampler, xy);

   float fractal = saturate (Ovly.a * ((Amount * 0.666667) + 0.333333));
   float FthrRng = Amount + FEATHER;

   if (fractal > FthrRng) return lerp (Bgnd, Fgd1, Fgd1.a);

   Ovly.a = 1.0;

   float4 Fgd2 = tex2D (Fg1Sampler, xy);
   float4 retval;

   float bdWidth = Border * 0.1;

   if (fractal > (Amount - bdWidth)) {
      retval = lerp (Bgnd, Ovly, (fractal - Amount) / FEATHER);
      Ovly   = lerp (Fgd2, Ovly, (fractal - Amount) / FEATHER);
   }
   else {
      retval = Bgnd;
      Ovly   = Fgd2;
   }

   if (fractal <= (Amount + bdWidth)) {
      retval = lerp (Bgnd, retval, Fgd1.a);

      return lerp (retval, Ovly, Fgd2.a);
   }

   retval = lerp (retval, Fgd1, (fractal - Amount) / FEATHER);
   retval = lerp (Bgnd, retval, Fgd1.a);
   Ovly   = lerp (retval, Ovly, (fractal - Amount) / FEATHER);

   return lerp (retval, Ovly, Fgd2.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique doFadeIn
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3 < string Script = "RenderColorTarget0 = FracOut;"; >
   { PixelShader = compile PROFILE ps_fractal (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique doFadeOut
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3 < string Script = "RenderColorTarget0 = FracOut;"; >
   { PixelShader = compile PROFILE ps_fractal (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique doMain_1_2
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_I (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4 < string Script = "RenderColorTarget0 = FracOut;"; >
   { PixelShader = compile PROFILE ps_fractal (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

technique doMain_2_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Fgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4 < string Script = "RenderColorTarget0 = FracOut;"; >
   { PixelShader = compile PROFILE ps_fractal (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

