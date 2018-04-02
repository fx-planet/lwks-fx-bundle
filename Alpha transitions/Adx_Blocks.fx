//--------------------------------------------------------------//
// Lightworks user effect Adx_Blocks.fx
//
// Created by LW user jwrl 24 May 2016
// @Author: jwrl
// @CreationDate: "24 May 2016"
//  LW 14+ version by jwrl 19 May 2017
// Renamed from AlphaBlockMix.fx by jwrl 8 August 2017 for name
// consistency through alpha dissolve range.
//
// This effect is used to transition into or out of a title, or
// to dissolve between titles.  It also composites the result
// over a background layer.
//
// The title fading out builds into larger and larger blocks
// as it fades.  The incoming title does the reverse of that.
// A bug that caused the unmodified image to remain visible
// under the blocks has been corrected in this version.
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
   string Description = "Alpha block dissolve";
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

texture Bgd : RenderColorTarget;

texture ovl1Proc : RenderColorTarget;
texture ovl2Proc : RenderColorTarget;

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
   Texture = <In_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg2Sampler = sampler_state {
   Texture = <In_2>;
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

sampler ovl1Sampler = sampler_state {
   Texture = <ovl1Proc>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler ovl2Sampler = sampler_state {
   Texture = <ovl2Proc>;
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

float blockSize
<
   string Group = "Blocks";
   string Description = "Size";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float AR
<
   string Group = "Blocks";
   string Description = "Aspect ratio";
   float MinVal = 0.25;
   float MaxVal = 4.00;
> = 1.0;

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

#define BLOCKS   0.1

#define HALF_PI  1.570796

float _OutputAspectRatio;

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

float4 ps_matte_in (float2 uv : TEXCOORD1) : COLOR
{
   if (blockSize <= 0.0) return tex2D (Fg2Sampler, uv);

   float2 xy;

   float AspectRatio = clamp (AR, 0.01, 10.0);
   float Ysize, Xsize = cos (Amount * HALF_PI);

   Xsize *= blockSize * BLOCKS;
   Ysize  = Xsize * AspectRatio * _OutputAspectRatio;

   xy.x = (round ((uv.x - 0.5) / Xsize) * Xsize) + 0.5;
   xy.y = (round ((uv.y - 0.5) / Ysize) * Ysize) + 0.5;

   return tex2D (Fg2Sampler, xy);
}

float4 ps_matte_out (float2 uv : TEXCOORD1) : COLOR
{
   if (blockSize <= 0.0) tex2D (Fg1Sampler, uv);

   float2 xy;

   float AspectRatio = clamp (AR, 0.01, 10.0);
   float Ysize, Xsize = sin (Amount * HALF_PI);

   Xsize *= blockSize * BLOCKS;
   Ysize  = Xsize * AspectRatio * _OutputAspectRatio;

   xy.x = (round ((uv.x - 0.5) / Xsize) * Xsize) + 0.5;
   xy.y = (round ((uv.y - 0.5) / Ysize) * Ysize) + 0.5;

   return tex2D (Fg1Sampler, xy);
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (ovl1Sampler, uv);
   float4 Bgnd = tex2D (BgdSampler, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (ovl2Sampler, uv);
   float4 Bgnd = tex2D (BgdSampler, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - Amount));
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd_1 = tex2D (ovl1Sampler, uv);
   float4 Fgd_2 = tex2D (ovl2Sampler, uv);
   float4 Bgnd  = lerp (tex2D (BgdSampler, uv), Fgd_2, Fgd_2.a * (1.0 - Amount));

   return lerp (Bgnd, Fgd_1, Fgd_1.a * Amount);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique blockDx_in
{
   pass P_1 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3 < string Script = "RenderColorTarget0 = ovl1Proc;"; >
   { PixelShader = compile PROFILE ps_matte_in (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique blockDx_out
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_B (); }

   pass P_3 < string Script = "RenderColorTarget0 = ovl2Proc;"; >
   { PixelShader = compile PROFILE ps_matte_out (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique blockDx_1_2
{
   pass P_1 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_I (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4 < string Script = "RenderColorTarget0 = ovl1Proc;"; >
   { PixelShader = compile PROFILE ps_matte_in (); }

   pass P_5 < string Script = "RenderColorTarget0 = ovl2Proc;"; >
   { PixelShader = compile PROFILE ps_matte_out (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}

technique blockDx_2_1
{
   pass P_1 < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2_O (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3_B (); }

   pass P_4 < string Script = "RenderColorTarget0 = ovl1Proc;"; >
   { PixelShader = compile PROFILE ps_matte_in (); }

   pass P_5 < string Script = "RenderColorTarget0 = ovl2Proc;"; >
   { PixelShader = compile PROFILE ps_matte_out (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}

