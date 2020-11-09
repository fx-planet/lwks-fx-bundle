// @Maintainer jwrl
// @Released 2020-11-09
// @Author jwrl
// @Created 2016-06-30
// @see https://www.lwks.com/media/kunena/attachments/6375/SuperBlur_640.png

/**
 This is a spin-off from my radial blur as used in several other effects.  To ensure
 ps_2_b compliance for Windows users this is a three or five pass effect.  This is
 achieved by taking two or five passes through the one shader, then in the case of the
 standard blur, ending in a second shader.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect StrongBlur.fx
//
// Version history:
//
// Modified jwrl 2020-11-09:
// Added CanSize switch for LW 2021 support.
//
// Modified by LW user jwrl 1 July 2018.
// Doubled the values of the radii used to calculate the blur to allow maximum blur to
// be stronger.  Also added a "standard blur" option which approximates the range that
// the Lightworks blur effect covers.
//
// Modified by LW user jwrl 30 June 2018.
// Changed blur calculation to be based on a fixed percentage of frame size rather than
// based on pixel size.  The problem was identified by schrauber, for which, thanks.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//
// Modified for version 14 11 February 2017.
// Added subcategory "Blurs and Sharpens"
//
// Modified 2 July 2016
// This version modified at khaver's suggestion to reduce the number of render targets.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Strong blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This is an extremely smooth blur with two ranges, standard and super";
   bool CanSize       = false;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Blur_1 : RenderColorTarget;
texture Blur_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blur_1 = sampler_state
{
   Texture   = <Blur_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blur_2 = sampler_state
{
   Texture   = <Blur_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Blur strength";
   string Enum = "Standard blur,Super blur";
> = 1;

float Size
<
   string Description = "Radius";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float Amount
<
   string Description = "Amount";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LOOP     12
#define DIVIDE   49

#define RADIUS_1 0.004
#define RADIUS_2 0.01
#define RADIUS_3 0.02
#define RADIUS_4 0.035
#define RADIUS_5 0.056

#define ANGLE    0.2617993878

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_std (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Blur_2, uv);

   if ((Size > 0.0) && (Amount > 0.0)) {
      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Size * RADIUS_3;

      for (int i = 0; i < LOOP; i++) {
         sincos ((i * ANGLE), xy.x, xy.y);
         xy *= radius;
         retval += tex2D (s_Blur_2, uv + xy);
         retval += tex2D (s_Blur_2, uv - xy);
         xy += xy;
         retval += tex2D (s_Blur_2, uv + xy);
         retval += tex2D (s_Blur_2, uv - xy);
      }

      retval /= DIVIDE;

      if (Amount < 1.0)
         return lerp (tex2D (s_Input, uv), retval, Amount);
   }

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1, uniform sampler blurSampler, uniform float blurRadius) : COLOR
{
   float4 retval = tex2D (blurSampler, uv);

   if ((Size > 0.0) && (Amount > 0.0)) {
      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Size * blurRadius;

      for (int i = 0; i < LOOP; i++) {
         sincos ((i * ANGLE), xy.x, xy.y);
         xy *= radius;
         retval += tex2D (blurSampler, uv + xy);
         retval += tex2D (blurSampler, uv - xy);
         xy += xy;
         retval += tex2D (blurSampler, uv + xy);
         retval += tex2D (blurSampler, uv - xy);
      }

      retval /= DIVIDE;

      if ((blurRadius == RADIUS_5) && (Amount < 1.0))
         return lerp (tex2D (s_Input, uv), retval, Amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique StrongBlur_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Blur_1;"; >
   { PixelShader = compile PROFILE ps_main (s_Input, RADIUS_1); }

   pass P_2
   < string Script = "RenderColorTarget0 = Blur_2;"; >
   { PixelShader = compile PROFILE ps_main (s_Blur_1, RADIUS_2); }

   pass P_3
   { PixelShader = compile PROFILE ps_std (); }
}

technique StrongBlur_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Blur_1;"; >
   { PixelShader = compile PROFILE ps_main (s_Input, RADIUS_1); }

   pass P_2
   < string Script = "RenderColorTarget0 = Blur_2;"; >
   { PixelShader = compile PROFILE ps_main (s_Blur_1, RADIUS_2); }

   pass P_3
   < string Script = "RenderColorTarget0 = Blur_1;"; >
   { PixelShader = compile PROFILE ps_main (s_Blur_2, RADIUS_3); }

   pass P_4
   < string Script = "RenderColorTarget0 = Blur_2;"; >
   { PixelShader = compile PROFILE ps_main (s_Blur_1, RADIUS_4); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (s_Blur_2, RADIUS_5); }
}
