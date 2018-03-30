//--------------------------------------------------------------//
// Lightworks user effect Adx_Stretch.fx
//
// Created by LW user jwrl 24 May 2016
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaStretchMix.fx by jwrl 8 August 2017 for
// name consistency through the alpha dissolve range.
//
// This effect stretches the title(s) horizontally or
// vertically to transition into or out of a title, or to
// dissolve between titles.  It also composites the result
// over a background layer.
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
   string Description = "Alpha stretch dissolve";
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
texture Bgd : RenderColorTarget;
texture Fg2 : RenderColorTarget;

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
> = 0.5;

int SetTechnique
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Transition";
   string Enum = "Fade in,Fade out,Dissolve FX1 > FX2,Dissolve FX2 > FX1";
> = 0;

int StretchMode
<
   string Group = "Stretch";
   string Description = "Mode";
   string Enum = "Horizontal > Horizontal,Vertical > Vertical,Vertical > Horizontal,Horizontal > Vertical";
> = 0;

float Stretch
<
   string Group = "Stretch";
   string Description = "Size";
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

#define H_H     0
#define V_V     1
#define V_H     2

#define PI      3.141593
#define HALF_PI 1.570796

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

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - 0.5;

   float distort, stretch = Stretch * (1.0 - Amount);

   if ((StretchMode == H_H) || (StretchMode == V_H)) {
      distort = sin (xy.y * PI) * HALF_PI;
      distort = sin (distort) / 2.0;

      xy.y = lerp (xy.y, distort, stretch);
      xy.x /= 1.0 + (5.0 * stretch);
   }
   else {
      distort = sin (xy.x * PI) * HALF_PI;
      distort = sin (distort) / 2.0;

      xy.x = lerp (xy.x, distort, stretch);
      xy.y /= 1.0 + (5.0 * stretch);
   }

   xy += 0.5;

   float4 Fgnd = tex2D (Fg1Sampler, xy);
   float4 Bgnd = tex2D (BgdSampler, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - 0.5;

   float distort, stretch = Stretch * Amount;

   if ((StretchMode == V_V) || (StretchMode == V_H)) {
      distort = sin (xy.x * PI) * HALF_PI;
      distort = sin (distort) / 2.0;

      xy.x  = lerp (xy.x, distort, stretch);
      xy.y /= 1.0 + (5.0 * stretch);
   }
   else {
      distort = sin (xy.y * PI) * HALF_PI;
      distort = sin (distort) / 2.0;

      xy.y  = lerp (xy.y, distort, stretch);
      xy.x /= 1.0 + (5.0 * stretch);
   }

   xy += 0.5;

   float4 Fgnd = tex2D (Fg1Sampler, xy);
   float4 Bgnd = tex2D (BgdSampler, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - Amount));
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = uv - 0.5;
   float2 xy2 = xy1;

   float stretch1 = Stretch * (1.0 - Amount);
   float stretch2 = Stretch * Amount;

   float distort1 = sin (xy1.y * PI) * HALF_PI;
   float distort2 = sin (xy1.x * PI) * HALF_PI;

   distort1 = sin (distort1) / 2.0;
   distort2 = sin (distort2) / 2.0;

   float distort3 = 1.0 + (5.0 * stretch1);
   float distort4 = 1.0 + (5.0 * stretch2);

   if (StretchMode == H_H) {
      xy1.y = lerp (xy1.y, distort1, stretch1);
      xy1.x /= distort3;

      xy2.y = lerp (xy2.y, distort1, stretch2);
      xy2.x /= distort4;
   }
   else if (StretchMode == V_V) {
      xy1.x = lerp (xy1.x, distort2, stretch1);
      xy1.y /= distort3;

      xy2.x = lerp (xy2.x, distort2, stretch2);
      xy2.y /= distort4;
   }
   else if (StretchMode == V_H) {
      xy1.y = lerp (xy1.y, distort1, stretch1);
      xy1.x /= distort3;

      xy2.x = lerp (xy2.x, distort2, stretch2);
      xy2.y /= distort4;
   }
   else {
      xy1.x = lerp (xy1.x, distort2, stretch1);
      xy1.y /= distort3;

      xy2.y = lerp (xy2.y, distort1, stretch2);
      xy2.x /= distort4;
   }

   xy1 += 0.5;
   xy2 += 0.5;

   float4 Fgnd = tex2D (Fg2Sampler, xy2);
   float4 Bgnd = tex2D (BgdSampler, uv);

   Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - Amount));
   Fgnd = tex2D (Fg1Sampler, xy1);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Stretch_In
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Stretch_Out
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique Stretch_1_2
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique Stretch_2_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_O (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

