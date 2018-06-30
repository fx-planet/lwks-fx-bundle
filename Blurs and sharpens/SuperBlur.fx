// @Maintainer jwrl
// @Released 2018-04-05
// @Author jwrl
// @Created 2017-06-30
// @see https://www.lwks.com/media/kunena/attachments/6375/SuperBlur_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect SuperBlur.fx
//
// This is a spin-off from my radial blur as used in several of my other effects.  To
// ensure ps_2_0 compliance for Windows users this is a five pass effect, however this
// is achieved by taking five passes through the one shader.
//
// Modified for version 14 11 February 2017.
// Added subcategory "Blurs and Sharpens"
//
// Modified 2 July 2016
// This version modified at khaver's suggestion to reduce the number of render targets.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles interlaced media.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//
// Modified by LW user jwrl 30 June 2018.
// Changed blur calculation to be based on a fixed percentage of frame size rather than
// based on pixel size.  The problem was identified by schrauber, for which, thanks.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Super blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Blur_1 : RenderColorTarget;
texture Blur_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgdSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler b1_Sampler = sampler_state
{
   Texture   = <Blur_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler b2_Sampler = sampler_state
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

#define RADIUS_1 0.002
#define RADIUS_2 0.005
#define RADIUS_3 0.01
#define RADIUS_4 0.0175
#define RADIUS_5 0.028

#define ANGLE    0.261799

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1, uniform sampler blurSampler, uniform float blurRadius) : COLOR
{
   float4 retval = tex2D (blurSampler, uv);

   if ((Size > 0.0) && (Amount > 0.0)) {
      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * blurRadius * Size;

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
         return lerp (tex2D (FgdSampler, uv), retval, Amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SuperBlur
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = Blur_1;";
   >
   {
      PixelShader = compile PROFILE ps_main (FgdSampler, RADIUS_1);
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = Blur_2;";
   >
   {
      PixelShader = compile PROFILE ps_main (b1_Sampler, RADIUS_2);
   }

   pass pass_three
   <
      string Script = "RenderColorTarget0 = Blur_1;";
   >
   {
      PixelShader = compile PROFILE ps_main (b2_Sampler, RADIUS_3);
   }

   pass pass_four
   <
      string Script = "RenderColorTarget0 = Blur_2;";
   >
   {
      PixelShader = compile PROFILE ps_main (b1_Sampler, RADIUS_4);
   }

   pass pass_five
   {
      PixelShader = compile PROFILE ps_main (b2_Sampler, RADIUS_5);
   }
}
