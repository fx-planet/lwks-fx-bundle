// @Maintainer jwrl
// @Released 2018-04-06
// @Author jwrl
// @Created 2017-10-28
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaPinchX_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaPinchX.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Adx_PinchX.fx
//
// This effect pinches the outgoing title to a point to clear the background shot, while
// zooming out of the pinched title.  It reverses the process to bring in the incoming
// title.  Trig functions have been used during the progress of the effect to make the
// acceleration smoother.
//
// While based on Wx_xPinch.fx, the direction swap has been made symmetrical, unlike that
// in Wx_xPinch.fx.  When used with titles which by their nature don't occupy the full
// screen, subjectively this approach looked better.  The wipe in and wipe out transitions
// also scale differently to the overlaps for the same reason.
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
   string Description = "Alpha X-pinch";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp_1;
texture Inp_2;
texture Inp_3;

texture In_1 : RenderColorTarget;
texture In_2 : RenderColorTarget;

texture Bgd : RenderColorTarget;

texture Pinch : RenderColorTarget;

texture Amt : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler AmtSampler = sampler_state
{
   Texture   = <Amt>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In1Sampler = sampler_state
{
   Texture = <Inp_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In2Sampler = sampler_state
{
   Texture = <Inp_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In3Sampler = sampler_state
{
   Texture   = <Inp_3>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg1Sampler = sampler_state
{
   Texture   = <In_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg2Sampler = sampler_state
{
   Texture   = <In_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler VidSampler = sampler_state
{
   Texture   = <Pinch>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Bgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
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

int SetTechnique
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Transition";
   string Enum = "Wipe in,Wipe out,Wipe FX1 > FX2,Wipe FX2 > FX1";
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

#define MID_PT     (0.5).xx

#define EMPTY      (0.0).xxxx

#define HALF_PI    1.5707963268
#define QUARTER_PI 0.7853981634

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

float4 ps_amt_inp (float2 uv : TEXCOORD1) : COLOR
{
   float  amount = (Amount + 1.0) * QUARTER_PI;
   float4 retval = cos (amount).xxxx;

   retval.y = 1.0 - sin (amount);

   return retval;
}

float4 ps_amt_op (float2 uv : TEXCOORD1) : COLOR
{
   float  amount = Amount * QUARTER_PI;
   float4 retval = sin (amount).xxxx;

   retval.z = 1.0 - cos (amount);

   return retval;
}

float4 ps_amt_std (float2 uv : TEXCOORD1) : COLOR
{
   float  amount = Amount * HALF_PI;
   float4 retval = cos (amount).xxxx;

   retval.x  = sin (amount);
   retval.yz = (1.0).xx - retval.xw;

   return retval;
}

float4 ps_inp_1 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In1Sampler, uv);
}

float4 ps_inp_2 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In2Sampler, uv);
}

float4 ps_inp_3 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In3Sampler, uv);
}

float4 ps_fg_2 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (Fg2Sampler, uv);
}

float4 ps_pinch_in (float2 uv : TEXCOORD1) : COLOR
{
   float progress = tex2D (AmtSampler, uv).w;

   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return fn_illegal (xy) ? EMPTY : tex2D (Fg1Sampler, xy);
}

float4 ps_pinch_out (float2 uv : TEXCOORD1) : COLOR
{
   float progress = tex2D (AmtSampler, uv).x;

   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return fn_illegal (xy) ? EMPTY : tex2D (Fg1Sampler, xy);
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float progress = tex2D (AmtSampler, uv).y;
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   float4 Fgd = fn_illegal (xy) ? EMPTY : tex2D (VidSampler, xy);

   if (Boost_On) Fgd.a = pow (Fgd.a, 1.0 / max (1.0, Boost_I + 1.0));

   return lerp (tex2D (BgdSampler, uv), Fgd, Fgd.a);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float progress = tex2D (AmtSampler, uv).z;
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   float4 Fgd = fn_illegal (xy) ? EMPTY : tex2D (VidSampler, xy);

   if (Boost_On) Fgd.a = pow (Fgd.a, 1.0 / max (1.0, Boost_O + 1.0));

   return lerp (tex2D (BgdSampler, uv), Fgd, Fgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique PinchIn
{
   pass P_0
   < string Script = "RenderColorTarget0 = Amt;"; >
   { PixelShader = compile PROFILE ps_amt_inp (); }

   pass P_1
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_in (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique PinchOut
{
   pass P_0
   < string Script = "RenderColorTarget0 = Amt;"; >
   { PixelShader = compile PROFILE ps_amt_op (); }

   pass P_1
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_out (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique PinchFX1_FX2
{
   pass P_0
   < string Script = "RenderColorTarget0 = Amt;"; >
   { PixelShader = compile PROFILE ps_amt_std (); }

   pass P_1
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_3 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_out (); }

   pass P_4
   < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_main_out (); }

   pass P_5
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_6
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_fg_2 (); }

   pass P_7
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_in (); }

   pass P_8
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique PinchFX2_FX1
{
   pass P_0
   < string Script = "RenderColorTarget0 = Amt;"; >
   { PixelShader = compile PROFILE ps_amt_std (); }

   pass P_1
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_3 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_out (); }

   pass P_4
   < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_main_out (); }

   pass P_5
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_6
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_fg_2 (); }

   pass P_7
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_in (); }

   pass P_8
   { PixelShader = compile PROFILE ps_main_in (); }
}
