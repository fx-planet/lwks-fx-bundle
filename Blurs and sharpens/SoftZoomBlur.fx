// @Maintainer jwrl
// @Released 2020-09-29
// @Author jwrl
// @Created 2017-07-06
// @see https://www.lwks.com/media/kunena/attachments/6375/SoftZoomBlur_640.png

/**
 This blur effect is similar to the Lightworks radial blur effect, but is very much
 softer in the result that it can produce.  The blur length range is also much greater
 than that provided by the Lightworks effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftZoomBlur.fx
//
// Version history:
//
// Modified jwrl 2020-09-29:
// Reformatted the effect header.
//
// Modified by LW user jwrl 23 December 2018.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Soft zoom blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "Similar to the Lightworks radial blur effect but very much softer";
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

float Amount
<
   string Description = "Blur density";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CentreX
<
   string Description = "Blur centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CentreY
<
   string Description = "Blur centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define DIVISOR 18.5

#define SCALE_1 36
#define SCALE_2 108
#define SCALE_3 324

#define WEIGHT  1.0
#define W_DIFF  0.0277778

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_blur (float2 uv : TEXCOORD1, uniform sampler blurSampler, uniform int scale) : COLOR
{
   if ((Amount == 0.0) || (Length == 0.0)) return tex2D (InpSampler, uv);

   float4 retval = 0.0.xxxx;

   float2 center = float2 (CentreX, 1.0 - CentreY);
   float2 xy = uv - center;

   float S  = (Length * 0.1) / scale;
   float Scale = 1.0;
   float weight = WEIGHT;

   for (int i = 0; i < 36; i++) {
      xy *= Scale;
      retval += tex2D (blurSampler, xy + center) * weight;
      weight -= W_DIFF;
      Scale  -= S;
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

technique soft_zoom_blur
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
