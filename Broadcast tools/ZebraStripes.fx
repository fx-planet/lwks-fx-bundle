// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Lightworks effect ZebraStripes.fx
//
// Created by Lightworks user jwrl 20 April 2016.
// @Author: jwrl
// @CreationDate: "20 April 2016"
//
// This analyzes the input media and displays zebra stripes
// when an overload occurs.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Zebra pattern";
   string Category    = "User";
   string SubCategory = "Broadcast";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InputSampler = sampler_state {
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Params
//--------------------------------------------------------------//

float whites
<
   string Description = "White level";
   float MinVal = 0;
   float MaxVal = 255;
> = 235;

float blacks
<
   string Description = "Black level";
   float MinVal = 0;
   float MaxVal = 255;
> = 16;

//--------------------------------------------------------------//
// Definitions and other global stuff
//--------------------------------------------------------------//

#define SCALE_PIXELS 400.00

#define STRIPES      6.0

#define RED_LUMA     0.3
#define GREEN_LUMA   0.59
#define BLUE_LUMA    0.11

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (InputSampler, xy);

   float luma = dot (retval.rgb, float3 (RED_LUMA, GREEN_LUMA, BLUE_LUMA));
   float peak_white = whites / 255.0;
   float full_black = blacks / 255.0;

   float x = xy.x * SCALE_PIXELS;
   float y = xy.y * SCALE_PIXELS;

   x = frac (x / STRIPES);
   y = frac (y / STRIPES);

   if (luma >= peak_white) retval.rgb = (retval.rgb + float (round (frac (x + y))).xxx) / 2.0;

   if (luma <= full_black) retval.rgb = (retval.rgb + float (round (frac (x + 1.0 - y))).xxx) / 2.0;

   return retval;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique zebra_pattern
{
   pass zebra
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

