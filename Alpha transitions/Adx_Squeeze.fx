//--------------------------------------------------------------//
// Lightworks user effect Adx_Squeeze.fx
//
// Created by Lightworks user jwrl 1 June 2016.
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaSqueezeMix.fx by jwrl 8 August 2017 for
// name consistency through the alpha dissolve range.
//
// This mimics the Lightworks squeeze effect but supports alpha
// channel transitions.  Alpha levels can be boosted to support
// Lightworks titles, which is the default setting.  The boost
// technique uses gamma rather than simple amplification to
// correct alpha levels.  This closely matches the way that
// Lightworks handles titles internally.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha squeeze";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture In1;
texture In2;
texture In3;

texture Fg1 : RenderColorTarget;
texture Fg2 : RenderColorTarget;
texture Bgd : RenderColorTarget;

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
   Texture   = <Fg1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg2Sampler = sampler_state {
   Texture   = <Fg2>;
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
> = 0.0;

int Ttype
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Transition";
   string Enum = "Fade in,Fade out,Dissolve FX1 > FX2,Dissolve FX2 > FX1";
> = 0;

int SetTechnique
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Type";
   string Enum = "Squeeze Right,Squeeze Down,Squeeze Left,Squeeze Up";
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

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define FX_IN   0
#define FX_OUT  1
#define FX1_FX2 2
#define FX2_FX1 3

#define HALF_PI 1.5707963

#define BLACK   (0.0).xxxx

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_mode_sw_1 (float2 xy : TEXCOORD1) : COLOR      // Alpha foreground
{
   float4 retval = (Ttype == FX2_FX1) ? tex2D (In2Sampler, xy) : (Ttype == FX_IN) ? BLACK : tex2D (In1Sampler, xy);

   if (!Boost_On) return retval;

   retval.a = (Ttype == FX_IN) ? pow (retval.a, 1.0 / max (1.0, Boost_I + 1.0))
                               : pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0));
   return retval;
}

float4 ps_mode_sw_2 (float2 xy : TEXCOORD1) : COLOR      // Alpha background
{
   float4 retval = (Ttype == FX1_FX2) ? tex2D (In2Sampler, xy) : (Ttype == FX_OUT) ? BLACK : tex2D (In1Sampler, xy);

   if (!Boost_On) return retval;

   retval.a = (Ttype == FX_OUT) ? pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0))
                                : pow (retval.a, 1.0 / max (1.0, Boost_I + 1.0));
   return retval;
}

float4 ps_mode_sw_3 (float2 xy : TEXCOORD1) : COLOR      // Post-process background
{
   return ((Ttype == FX1_FX2) || (Ttype == FX2_FX1)) ? tex2D (In3Sampler, xy) : tex2D (In2Sampler, xy);
}

float4 ps_squeeze_right (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 ((uv.x - 1.0) / (1.0 - Amount) + 1.0, uv.y);
   float2 xy2 = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 (uv.x / Amount, uv.y);

   float4 Fgd1 = (xy1.x != saturate (xy1.x)) ? BLACK : tex2D (Fg1Sampler, xy1);
   float4 Fgd2 = (xy2.x != saturate (xy2.x)) ? BLACK : tex2D (Fg2Sampler, xy2);
   float4 Fgnd = max (Fgd1, Fgd2);

   return lerp (tex2D (BgdSampler, uv), Fgnd, Fgnd.a);
}

float4 ps_squeeze_left (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 (uv.x  / (1.0 - Amount), uv.y);
   float2 xy2 = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 ((uv.x - 1.0) / Amount + 1.0, uv.y);

   float4 Fgd1 = (xy1.x != saturate (xy1.x)) ? BLACK : tex2D (Fg1Sampler, xy1);
   float4 Fgd2 = (xy2.x != saturate (xy2.x)) ? BLACK : tex2D (Fg2Sampler, xy2);
   float4 Fgnd = max (Fgd1, Fgd2);

   return lerp (tex2D (BgdSampler, uv), Fgnd, Fgnd.a);
}

float4 ps_squeeze_down (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 (uv.x, (uv.y - 1.0) / (1.0 - Amount) + 1.0);
   float2 xy2 = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 (uv.x, uv.y / Amount);

   float4 Fgd1 = (xy1.y != saturate (xy1.y)) ? BLACK : tex2D (Fg1Sampler, xy1);
   float4 Fgd2 = (xy2.y != saturate (xy2.y)) ? BLACK : tex2D (Fg2Sampler, xy2);
   float4 Fgnd = max (Fgd1, Fgd2);

   return lerp (tex2D (BgdSampler, uv), Fgnd, Fgnd.a);
}

float4 ps_squeeze_up (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 (uv.x, uv.y  / (1.0 - Amount));
   float2 xy2 = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 (uv.x, (uv.y - 1.0) / Amount + 1.0);

   float4 Fgd1 = (xy1.y != saturate (xy1.y)) ? BLACK : tex2D (Fg1Sampler, xy1);
   float4 Fgd2 = (xy2.y != saturate (xy2.y)) ? BLACK : tex2D (Fg2Sampler, xy2);
   float4 Fgnd = max (Fgd1, Fgd2);

   return lerp (tex2D (BgdSampler, uv), Fgnd, Fgnd.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique squeeze_right
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_squeeze_right (); }
}

technique squeeze_down
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_squeeze_down (); }
}

technique squeeze_left
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_squeeze_left (); }
}

technique squeeze_up
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_squeeze_up (); }
}

