// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Adx_Zoom.fx
//
// Created by LW user jwrl 24 May 2016
// @Author jwrl
// @CreationDate "24 May 2016"
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaZoomMix.fx by jwrl 8 August 2017 for
// name consistency through the alpha dissolve range.
//
// This effect is a user-selectable zoom in or zoom out that
// transitions into or out of a title or between titles.  It
// also composites the result over a background layer.
//
// Alpha levels can be boosted to support Lightworks titles,
// which is the default setting.  The boost technique uses
// gamma rather than simple amplification to correct alpha
// levels.  This closely matches the way that Lightworks
// handles titles internally.
//
// Version 14.1 update 24 March 2018 by jwrl.
//
// Added LINUX and OSX test to allow support for changing
// "Clamp" to "ClampToEdge" on those platforms.  It will now
// function correctly when used with Lightworks versions 14.5
// and higher under Linux or OS-X and fixes a bug associated
// with using this effect with transitions on those platforms.
//
// The bug still exists when using older versions of Lightworks.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha zoom dissolve";
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

texture blurBuff : RenderColorTarget;
texture ovl1Proc : RenderColorTarget;
texture ovl2Proc : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef OSX
#define Clamp ClampToEdge
#endif

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
sampler BufrSampler = sampler_state
{
   Texture   = <blurBuff>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler ovl1Sampler = sampler_state
{
   Texture   = <ovl1Proc>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler ovl2Sampler = sampler_state
{
   Texture   = <ovl2Proc>;
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
   string Group = "Zoom";
   string Description = "Direction";
   string Enum = "Zoom out,Zoom in";
> = 0;

float zoomAmount
<
   string Group = "Zoom";
   string Description = "Strength";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Xcentre
<
   string Group = "Zoom";
   string Description = "Centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Group = "Zoom";
   string Description = "Centre";
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

#define FX_IN   0
#define FX_OUT  1
#define FX1_FX2 2
#define FX2_FX1 3

#define SAMPLE  61
#define DIVISOR 61.0    // Sorts out float issues with Linux

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_mode_sw_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = (Ttype == FX2_FX1) ? tex2D (In2Sampler, uv) : tex2D (In1Sampler, uv);

   if (Boost_On) retval.a = pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0));

   return retval;
}

float4 ps_mode_sw_2 (float2 uv : TEXCOORD1) : COLOR
{
   return ((Ttype == FX1_FX2) || (Ttype == FX2_FX1)) ? tex2D (In3Sampler, uv) : tex2D (In2Sampler, uv);
}

float4 ps_mode_sw_3 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = (Ttype == FX1_FX2) ? tex2D (In2Sampler, uv) : tex2D (In1Sampler, uv);

   if (!Boost_On) return retval;

   retval.a = (Ttype == FX_OUT) ? pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0))
                                : pow (retval.a, 1.0 / max (1.0, Boost_I + 1.0));
   return retval;
}

float4 ps_zoom_A (float2 uv : TEXCOORD1, uniform sampler imgSampler) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (imgSampler, uv);

   float zoomStrength = zoomAmount * (1.0 - Amount);
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = (0.0).xxxx;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (imgSampler, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_B (float2 uv : TEXCOORD1, uniform sampler imgSampler) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (imgSampler, uv);

   float zoomStrength = zoomAmount * Amount / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = (0.0).xxxx;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (imgSampler, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_C (float2 uv : TEXCOORD1, uniform sampler imgSampler) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (imgSampler, uv);

   float zoomStrength = zoomAmount * (1.0 - Amount) / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = (0.0).xxxx;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (imgSampler, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_D (float2 uv : TEXCOORD1, uniform sampler imgSampler) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (imgSampler, uv);

   float zoomStrength = zoomAmount * Amount;
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = (0.0).xxxx;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (imgSampler, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd   = tex2D (ovl1Sampler, uv);
   float4 Bgnd   = tex2D (BgdSampler, uv);
   float4 retval = (Ttype == FX_OUT) ? Bgnd : lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   if (Ttype == FX_IN) return retval;

   Fgnd = tex2D (ovl2Sampler, uv);

   return lerp (retval, Fgnd, Fgnd.a * (1.0 - Amount));
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd   = tex2D (ovl2Sampler, uv);
   float4 Bgnd   = tex2D (BgdSampler, uv);
   float4 retval = (Ttype == FX_IN) ? Bgnd : lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - Amount));

   if (Ttype == FX_OUT) return retval;

   Fgnd = tex2D (ovl1Sampler, uv);

   return lerp (retval, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique ZoomDissolveOut
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = In_3;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4 < string Script = "RenderColorTarget0 = blurBuff;"; >
   { PixelShader = compile PROFILE ps_zoom_A (Fg2Sampler); }

   pass P_5 < string Script = "RenderColorTarget0 = ovl1Proc;"; >
   { PixelShader = compile PROFILE ps_zoom_A (BufrSampler); }

   pass P_6 < string Script = "RenderColorTarget0 = blurBuff;"; >
   { PixelShader = compile PROFILE ps_zoom_B (Fg1Sampler); }

   pass P_7 < string Script = "RenderColorTarget0 = ovl2Proc;"; >
   { PixelShader = compile PROFILE ps_zoom_B (BufrSampler); }

   pass P_8
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique ZoomDissolveIn
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = In_3;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4 < string Script = "RenderColorTarget0 = blurBuff;"; >
   { PixelShader = compile PROFILE ps_zoom_C (Fg2Sampler); }

   pass P_5 < string Script = "RenderColorTarget0 = ovl1Proc;"; >
   { PixelShader = compile PROFILE ps_zoom_C (BufrSampler); }

   pass P_6 < string Script = "RenderColorTarget0 = blurBuff;"; >
   { PixelShader = compile PROFILE ps_zoom_D (Fg1Sampler); }

   pass P_7 < string Script = "RenderColorTarget0 = ovl2Proc;"; >
   { PixelShader = compile PROFILE ps_zoom_D (BufrSampler); }

   pass P_8
   { PixelShader = compile PROFILE ps_main_in (); }
}

