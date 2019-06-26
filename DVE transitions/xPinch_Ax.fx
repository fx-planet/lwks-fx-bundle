// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_PinchX_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_PinchX.mp4

/**
This effect pinches the outgoing title to a point to clear the background shot, while
zooming out of the pinched title.  It reverses the process to bring in the incoming
title.  Trig functions have been used during the progress of the effect to make the
acceleration smoother.

While based on xPinch_Dx.fx, the direction swap has been made symmetrical, unlike that
in xPinch_Dx.fx.  When used with titles which by their nature don't occupy the full
screen, subjectively this approach looked better.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect xPinch_Ax.fx
//
// This is a revision of an earlier effect, Adx_PinchX.fx, which also had the ability to
// wipe between two titles.  That added needless complexity, when the same functionality
// can be obtained by overlaying two effects.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "X-pinch (alpha)";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Pinches the outgoing title to a point while zooming out";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Pinch : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Video = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture   = <Sup>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Pinch = sampler_state
{
   Texture   = <Pinch>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "If using a Lightworks text effect disconnect its input and set this first";
   string Enum = "Crawl/Roll/Titles,Video/External image";
> = 0;

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
   string Description = "Transition";
   string Enum = "Wipe in,Wipe out";
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define MID_PT     (0.5).xx

#define EMPTY      (0.0).xxxx

#define QUARTER_PI 0.7853981634

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (Vsample, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_pinch_in (float2 uv : TEXCOORD1) : COLOR
{
   float progress = sin ((1.0 - Amount) * QUARTER_PI);
   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return fn_tex2D (s_Super, xy);
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float progress = 1.0 - cos (sin ((1.0 - Amount) * QUARTER_PI));
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   float4 Fgnd = fn_tex2D (s_Pinch, xy);

   if (Boost == 0) {
      Fgnd.a = pow (Fgnd.a, 0.5);
      Fgnd.rgb /= Fgnd.a;
   }

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_pinch_out (float2 uv : TEXCOORD1) : COLOR
{
   float progress = sin (Amount * QUARTER_PI);
   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return fn_tex2D (s_Super, xy);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float progress = 1.0 - cos (sin (Amount * QUARTER_PI));
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   float4 Fgnd = fn_tex2D (s_Pinch, xy);

   if (Boost == 0) {
      Fgnd.a = pow (Fgnd.a, 0.5);
      Fgnd.rgb /= Fgnd.a;
   }

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_xPinch_in
{
   pass P_1
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_in (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Ax_xPinch_out
{
   pass P_1
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_out (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_out (); }
}

