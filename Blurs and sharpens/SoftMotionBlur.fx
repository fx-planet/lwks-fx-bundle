// @Maintainer jwrl
// @Released 2018-04-05
// @Author jwrl
// @Created 2017-07-06
// @see https://www.lwks.com/media/kunena/attachments/6375/SoftMotionBlur_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftMotionBlur.fx
//
// This blur is actually a simple directional blur.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Soft motion blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture blur_1 : RenderColorTarget;
texture blur_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InpSampler = sampler_state {
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler b1_Sampler = sampler_state {
   Texture   = <blur_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler b2_Sampler = sampler_state {
   Texture   = <blur_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Length
<
   string Description = "Blur length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Angle
<
   string Description = "Blur direction";
   float MinVal = 0.0;
   float MaxVal = 360.0;
> = 180.0;

float Amount
<
   string Description = "Blur density";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define DIVISOR 18.5

#define SCALE_1 36
#define SCALE_2 108
#define SCALE_3 324

#define WEIGHT  1.0
#define W_DIFF  0.0277778

#define PI      3.1415927

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_blur (float2 uv : TEXCOORD1, uniform sampler blurSampler, uniform int scale) : COLOR
{
   if ((Amount == 0.0) || (Length == 0.0)) return tex2D (InpSampler, uv);

   float4 retval = 0.0.xxxx;

   float S, C, weight = WEIGHT;

   sincos (PI * (Angle / 180.0), S, C);

   float2 xy1 = uv;
   float2 xy2 = float2 (-C, -S * _OutputAspectRatio) * (Length / scale);

   for (int i = 0; i < 36; i++) {
      retval += tex2D (blurSampler, xy1) * weight;
      weight -= W_DIFF;
      xy1 += xy2;
   }

   return retval / DIVISOR;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float offset = 0.7 - (Length / 2.7777778);
   float adjust = 1.0 + (Length / 1.5);

   float4 blurry = tex2D (b1_Sampler, uv);
   float4 retval = lerp (blurry, float4 (((blurry.rgb - offset.xxx) * adjust) + offset.xxx, blurry.a), 0.1);

   return lerp (tex2D (InpSampler, uv), retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique soft_motion_blur
{
   pass P_1
   < string Script = "RenderColorTarget0 = blur_1;"; >
   { PixelShader = compile PROFILE ps_blur (InpSampler, SCALE_1); }

   pass P_2
   < string Script = "RenderColorTarget0 = blur_2;"; >
   { PixelShader = compile PROFILE ps_blur (b1_Sampler, SCALE_2); }

   pass P_3
   < string Script = "RenderColorTarget0 = blur_1;"; >
   { PixelShader = compile PROFILE ps_blur (b2_Sampler, SCALE_3); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}
