//--------------------------------------------------------------//
// Lightworks user effect SuperBlur.fx
//
// Created by LW user jwrl 30 June 2016.
// @Author: jwrl
// @CreationDate: "30 June 2016"
//  Modified for version 14 11 February 2017.
//
// This version modified at khaver's suggestion to reduce the
// number of render targets used - 2 July 2016.
//
// This is a spin-off from my radial blur as used in several
// of my other effects.  To ensure ps_2_0 compliance for
// Windows users this is a five pass effect, however this is
// achieved by taking five passes through the one shader.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  THE BUG WAS NOT IN THE WAY THIS EFFECT
// WAS ORIGINALLY IMPLEMENTED.
//
// It appears that when a height parameter is needed one can
// not reliably use _OutputHeight.  It returns only half the
// actual frame height when interlaced media is playing and
// only when it is playing.  For that reason the output height
// should always be obtained by dividing _OutputWidth by
// _OutputAspectRatio until such time as the bug in the
// Lightworks code can be fixed.  It seems that after contact
// with the developers that is very unlikely to be soon.
//
// Note: This fix has been fully tested, and appears to be a
// reliable solution regardless of the pixel aspect ratio.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Super blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture Blur_1 : RenderColorTarget;
texture Blur_2 : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define LOOP     12
#define DIVIDE   49

#define RADIUS_1 4.0
#define RADIUS_2 10.0
#define RADIUS_3 20.0
#define RADIUS_4 35.0
#define RADIUS_5 56.0

#define ANGLE    0.261799

float _OutputAspectRatio;
float _OutputWidth;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1, uniform sampler blurSampler, uniform float blurRadius) : COLOR
{
   float4 retval = tex2D (blurSampler, uv);

   if ((Size > 0.0) && (Amount > 0.0)) {
      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * blurRadius * Size / _OutputWidth;

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

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

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
