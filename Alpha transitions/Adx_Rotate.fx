// @Maintainer jwrl
// @Released 2018-04-06
// @Author jwrl
// @Created 2016-06-10
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaRotate_1_2016-08-14.png
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaRotate.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Adx_Rotate.fx
//
// This rotates one title out and the other in.  Alpha levels can be boosted to support
// Lightworks titles, which is the default setting.  The boost technique uses gamma
// rather than simple amplification to correct alpha levels.  This closely matches the
// way that Lightworks handles titles internally.
//
// LW 14+ version by jwrl 19 May 2017
// Added subcategory "Alpha"
//
// Modified 8 August 2017 by jwrl.
// Renamed from AlphaRotateMix.fx for name consistency through the alpha dissolve range.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha rotate";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture In1;
texture In2;
texture In3;

texture Fg1 : RenderColorTarget;
texture Fg2 : RenderColorTarget;
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
   string Enum = "Rotate Right,Rotate Down,Rotate Left,Rotate Up";
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

#define FX_IN   0
#define FX_OUT  1
#define FX1_FX2 2
#define FX2_FX1 3

#define HALF_PI 1.5707963

#define EMPTY   (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mode_sw_1 (float2 xy : TEXCOORD1) : COLOR      // Alpha foreground
{
   float4 retval = (Ttype == FX2_FX1) ? tex2D (In2Sampler, xy) : (Ttype == FX_IN) ? EMPTY : tex2D (In1Sampler, xy);

   if (!Boost_On) return retval;

   retval.a = (Ttype == FX_IN) ? pow (retval.a, 1.0 / max (1.0, Boost_I + 1.0))
                               : pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0));
   return retval;
}

float4 ps_mode_sw_2 (float2 xy : TEXCOORD1) : COLOR      // Alpha background
{
   float4 retval = (Ttype == FX1_FX2) ? tex2D (In2Sampler, xy) : (Ttype == FX_OUT) ? EMPTY : tex2D (In1Sampler, xy);

   if (!Boost_On) return retval;

   retval.a = (Ttype == FX_OUT) ? pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0))
                                : pow (retval.a, 1.0 / max (1.0, Boost_I + 1.0));
   return retval;
}

float4 ps_mode_sw_3 (float2 xy : TEXCOORD1) : COLOR      // Post-process background
{
   return ((Ttype == FX1_FX2) || (Ttype == FX2_FX1)) ? tex2D (In3Sampler, xy) : tex2D (In2Sampler, xy);
}

float4 ps_rotate_right (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 ((uv.x - 1.0) / (1.0 - Amount) - (Amount * 0.2) + 1.0, ((uv.y - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv.y) * uv.x * sin (Amount * HALF_PI));
   float2 xy2 = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 ((uv.x / Amount) - ((1.0 - Amount) * 0.2), ((uv.y - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv.y) * uv.x * cos (Amount * HALF_PI));

   float4 Fgd1   = fn_illegal (xy1) ? EMPTY : tex2D (Fg1Sampler, xy1);
   float4 Fgd2   = fn_illegal (xy2) ? EMPTY : tex2D (Fg2Sampler, xy2);
   float4 fgdPix = max (Fgd1, Fgd2);

   return lerp (tex2D (BgdSampler, uv), fgdPix, fgdPix.a);
}

float4 ps_rotate_left (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 (uv.x / (1.0 - Amount) + (Amount * 0.2), ((uv.y - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv.y) * (1.0 - uv.x) * sin (Amount * HALF_PI));
   float2 xy2 = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 ((uv.x - 1.0) / Amount + 1.0 + ((1.0 - Amount) * 0.2), ((uv.y - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv.y) * (1.0 - uv.x) * cos (Amount * HALF_PI));

   float4 Fgd1   = fn_illegal (xy1) ? EMPTY : tex2D (Fg1Sampler, xy1);
   float4 Fgd2   = fn_illegal (xy2) ? EMPTY : tex2D (Fg2Sampler, xy2);
   float4 fgdPix = max (Fgd1, Fgd2);

   return lerp (tex2D (BgdSampler, uv), fgdPix, fgdPix.a);
}

float4 ps_rotate_down (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 (((uv.x - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv.x) * uv.y * sin (Amount * HALF_PI), (uv.y - 1.0) / (1.0 - Amount) - (Amount * 0.2) + 1.0);
   float2 xy2 = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 (((uv.x - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv.x) * uv.y * cos (Amount * HALF_PI), (uv.y / Amount) - ((1.0 - Amount) * 0.2));

   float4 Fgd1   = fn_illegal (xy1) ? EMPTY : tex2D (Fg1Sampler, xy1);
   float4 Fgd2   = fn_illegal (xy2) ? EMPTY : tex2D (Fg2Sampler, xy2);
   float4 fgdPix = max (Fgd1, Fgd2);

   return lerp (tex2D (BgdSampler, uv), fgdPix, fgdPix.a);
}

float4 ps_rotate_up (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 (((uv.x - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv.x) * (1.0 - uv.y) * sin (Amount * HALF_PI), uv.y / (1.0 - Amount) + (Amount * 0.2));
   float2 xy2 = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 (((uv.x - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv.x) * (1.0 - uv.y) * cos (Amount * HALF_PI), (uv.y - 1.0) / Amount + 1.0 + ((1.0 - Amount) * 0.2));

   float4 Fgd1   = fn_illegal (xy1) ? EMPTY : tex2D (Fg1Sampler, xy1);
   float4 Fgd2   = fn_illegal (xy2) ? EMPTY : tex2D (Fg2Sampler, xy2);
   float4 fgdPix = max (Fgd1, Fgd2);

   return lerp (tex2D (BgdSampler, uv), fgdPix, fgdPix.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique rotate_right
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_rotate_right (); }
}

technique rotate_down
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_rotate_down (); }
}

technique rotate_left
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_rotate_left (); }
}

technique rotate_up
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_rotate_up (); }
}
