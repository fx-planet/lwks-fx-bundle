// @Maintainer jwrl
// @Released 2020-11-09
// @Author jwrl
// @Created 2017-06-06
// @see https://www.lwks.com/media/kunena/attachments/6375/SoftFoggyBlur_640.png

/**
 This blur effect mimics the classic "petroleum jelly on the lens" look.  It does this by
 combining a radial and a spin blur effect.  The spin component has an adjustable aspect
 ratio which can have significant effect on the final look.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftFoggyBlur.fx
//
// Version history:
//
// Modified jwrl 2020-11-09:
// Added CanSize switch for LW 2021 support.
//
// Modified by LW user jwrl 2020-05-16:
// Reduced maths operations required to set up blur strength and aspect ratio.
// No longer pass parameters into ps_spin_blur().
//
// Modified by LW user jwrl 2018-12-23:
// Formatted the descriptive block so that it can automatically be read.
//
// Modified by LW user jwrl 2018-09-26:
// Added notes to header.
//
// Modified by LW user jwrl 2018-04-05:
// Metadata header block added to better support GitHub repository.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Soft foggy blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This blur effect mimics the classic 'petroleum jelly on the lens' look";
   bool CanSize       = false;
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

sampler s_Input = sampler_state {
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blur_1 = sampler_state {
   Texture   = <blur_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blur_2 = sampler_state {
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

float Strength
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
   string Description = "Aspect ratio 1:x";
   float MinVal = 0.2;
   float MaxVal = 5.0;
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

#define DIV_1    18.5
#define DIV_2    18.975

#define SCALE_1  0.0027777778    // 0.1 / 36
#define SCALE_2  0.0009259259    // 0.1 / 108
#define SCALE_3  0.0096962736    // PI / 324

#define W_DIFF_1 0.0277777778
#define W_DIFF_2 0.0555555556

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_radial_blur (float2 uv : TEXCOORD1, uniform sampler s_blur, uniform int ss) : COLOR
{
   if ((Amount == 0.0) || (Strength == 0.0)) return tex2D (s_Input, uv);

   float4 retval = 0.0.xxxx;

   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 xy = uv - centre;

   float S  = Strength * ss;
   float Scale = 1.0;
   float weight = 1.0;

   for (int i = 0; i < 36; i++) {
      xy *= Scale;
      retval += tex2D (s_blur, xy + centre) * weight;
      weight -= W_DIFF_1;
      Scale  -= S;
   }

   return retval / DIV_1;
}

float4 ps_spin_blur (float2 uv : TEXCOORD1) : COLOR
{
   if ((Amount == 0.0) || (Strength == 0.0)) return tex2D (s_Input, uv);

   float4 retval = 0.0.xxxx;

   float spin   = Strength * SCALE_3;
   float weight = 1.0;
   float angle  = 0.0;
   float C, S;

   float2 aspect = float2 (1.0, max (Aspect, 0.0001)) * _OutputAspectRatio);
   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 xy     = (uv - centre) / aspect;
   float2 xy1, xy2;

   for (int i = 0; i < 18; i++) {
      sincos (angle, S, C);

      S *= float2 (xy.y, -xy.x);
      C *= xy;
      xy1 = (C + S) * aspect + centre;
      xy2 = (C - S) * aspect + centre;

      retval += ((tex2D (s_Blur_2, xy1) + tex2D (s_Blur_2, xy2)) * weight);

      weight -= W_DIFF_2;
      angle  += spin;
   }

   return retval / DIV_2;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float offset = 0.7 - (Strength / 2.7777778);
   float adjust = 1.0 + (Strength / 1.5);

   float4 blurry = tex2D (s_Blur_1, uv);
   float4 retval = lerp (blurry, float4 (((blurry.rgb - offset.xxx) * adjust) + offset.xxx, blurry.a), 0.1);

   return lerp (tex2D (s_Input, uv), retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SoftFoggyBlur
{
   pass P_1
   < string Script = "RenderColorTarget0 = blur_1;"; >
   { PixelShader = compile PROFILE ps_radial_blur (s_Input, SCALE_1); }

   pass P_2
   < string Script = "RenderColorTarget0 = blur_2;"; >
   { PixelShader = compile PROFILE ps_radial_blur (s_Blur_1, SCALE_2); }

   pass P_3
   < string Script = "RenderColorTarget0 = blur_1;"; >
   { PixelShader = compile PROFILE ps_spin_blur (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}
