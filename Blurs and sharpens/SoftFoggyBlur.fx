// @Maintainer jwrl
// @Released 2018-04-05
// @Author jwrl
// @Created 2017-06-06
// @see https://www.lwks.com/media/kunena/attachments/6375/SoftFog_1.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftFoggyBlur.fx
//
// This blur effect mimics the classic "petroleum jelly on the lens" look.  It does this
// by combining a radial and a spin blur effect.  The spin component has an adjustable
// aspect ratio which can have significant effect on the final look.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Soft foggy blur";
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


//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Length
<
   string Description = "Blur strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Amount
<
   string Description = "Blur density";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Aspect
<
   string Description = "Spin aspect ratio";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

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

#define DIV_1    18.5
#define DIV_2    18.975

#define SCALE_1  36
#define SCALE_2  108
#define SCALE_3  324

#define WEIGHT   1.0
#define W_DIFF_1 0.0277778
#define W_DIFF_2 0.0555556

#define PI       3.1415927

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_radial_blur (float2 uv : TEXCOORD1, uniform sampler blurSampler, uniform int scale) : COLOR
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
      weight -= W_DIFF_1;
      Scale  -= S;
   }

   return retval / DIV_1;
}

float4 ps_spin_blur (float2 uv : TEXCOORD1, uniform sampler blurSampler, uniform int scale) : COLOR
{
   if ((Amount == 0.0) || (Length == 0.0)) return tex2D (InpSampler, uv);

   float4 retval = 0.0.xxxx;

   float spin   = (Length * PI) / scale;
   float weight = WEIGHT;
   float angle  = 0.0;
   float C, S;

   float2 blur_aspect  = float2 (1.0, (1.0 - (max (Aspect, 0.0) * 0.8) - (min (Aspect, 0.0) * 4.0)) * _OutputAspectRatio);
   float2 fxCentre     = float2 (CentreX, 1.0 - CentreY);
   float2 xy1, xy2, xy = (uv - fxCentre) / blur_aspect;
   float2 xyC, xyS;

   for (int i = 0; i < 18; i++) {
      sincos (angle, S, C);

      xyC = xy * C;
      xyS = float2 (xy.y, -xy.x) * S;
      xy1 = (xyC + xyS) * blur_aspect + fxCentre;
      xy2 = (xyC - xyS) * blur_aspect + fxCentre;

      retval += ((tex2D (blurSampler, xy1) + tex2D (blurSampler, xy2)) * weight);

      weight -= W_DIFF_2;
      angle  += spin;
   }

   return retval / DIV_2;
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

technique soft_foggy_blur
{
   pass P_1
   < string Script = "RenderColorTarget0 = blur_1;"; >
   { PixelShader = compile PROFILE ps_radial_blur (InpSampler, SCALE_1); }

   pass P_2
   < string Script = "RenderColorTarget0 = blur_2;"; >
   { PixelShader = compile PROFILE ps_radial_blur (b1_Sampler, SCALE_2); }

   pass P_3
   < string Script = "RenderColorTarget0 = blur_1;"; >
   { PixelShader = compile PROFILE ps_spin_blur (b2_Sampler, SCALE_3); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}
