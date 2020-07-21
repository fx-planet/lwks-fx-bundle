// @Maintainer jwrl
// @Released 2020-07-21
// @Author jwrl
// @Created 2020-07-21
// @see https://www.lwks.com/media/kunena/attachments/6375/WhipPanAx_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/WhipPan_AxAdx.mp4

/**
 This effect performs a whip pan style transition between to bring a title onto the screen
 or off the screen.  Unlike the blur dissolve effect, this pans the title.  It is limited
 to producing vertical and horizontal whips only.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhipPan_Ax.fx
//
// Version history:
//
// Built 2020-07-21 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Whip pan (alpha)";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Uses a directional blur to simulate a whip pan into or out of a title";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Inp : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Background = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture   = <Sup>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Input = sampler_state
{ 
   Texture   = <Inp>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
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
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
> = 0;

int Mode
<
   string Description = "Whip direction";
   string Enum = "Left to right,Right to left,Top to bottom,Bottom to top";
> = 0;

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH   // This effect is only available for version 14.5 and up
Bad_LW_version    // Forces a compiler error if the Lightworks version is less.
#endif

#ifdef WINDOWS
#define PROFILE   ps_3_0 
#endif

#define L_R       0
#define R_L       1
#define T_B       2
#define B_T       3

#define HALF_PI   1.5707963268

#define SAMPLES   120
#define SAMPSCALE 121.0

#define STRENGTH  0.00125

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_blur_I (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = fn_tex2D (s_Super, uv);

   float amount = 1.0 - cos (saturate ((1.0 - Amount) * 2.0) * HALF_PI);

   if ((amount == 0.0) || (Strength <= 0.0)) return retval;

   float2 xy1 = uv;
   float2 xy2 = (Mode < T_B) ? float2 (amount, 0.0)
                             : float2 (0.0, amount * _OutputAspectRatio);

   xy2 *= Strength * STRENGTH;

   for (int i = 0; i < SAMPLES; i++) {
      retval += fn_tex2D (s_Super, xy1);
      xy1 -= xy2;
   }

   return retval / SAMPSCALE;
}

float4 ps_blur_O (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = fn_tex2D (s_Super, uv);

   float amount = 1.0 - cos (saturate (Amount * 2.0) * HALF_PI);

   if ((amount == 0.0) || (Strength <= 0.0)) return retval;

   float2 xy1 = uv;
   float2 xy2 = (Mode < T_B) ? float2 (amount, 0.0)
                             : float2 (0.0, amount * _OutputAspectRatio);

   xy2 *= Strength * STRENGTH;

   for (int i = 0; i < SAMPLES; i++) {
      retval += fn_tex2D (s_Super, xy1);
      xy1 -= xy2;
   }

   return retval / SAMPSCALE;
}

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (1.0 - sin (Amount * HALF_PI)) * 1.5 * Strength;

   float2 xy = (Mode == L_R) ? uv + float2 (amount, 0.0)
             : (Mode == R_L) ? uv - float2 (amount, 0.0)
             : (Mode == T_B) ? uv + float2 (0.0, amount) : uv - float2 (0.0, amount);

   float4 Overlay = tex2D (s_Input, xy);

   return lerp (tex2D (s_Background, uv), Overlay, Overlay.a);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (1.0 - cos (Amount * HALF_PI)) * 1.5 * Strength;

   float2 xy = (Mode == L_R) ? uv - float2 (amount, 0.0)
             : (Mode == R_L) ? uv + float2 (amount, 0.0)
             : (Mode == T_B) ? uv - float2 (0.0, amount) : uv + float2 (0.0, amount);

   float4 Overlay = tex2D (s_Input, xy);

   return lerp (tex2D (s_Background, uv), Overlay, Overlay.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WhipPan_Dx_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Inp;"; >
   { PixelShader = compile PROFILE ps_blur_I (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique WhipPan_Dx_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Inp;"; >
   { PixelShader = compile PROFILE ps_blur_O (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}

