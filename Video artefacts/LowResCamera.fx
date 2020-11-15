// @Maintainer jwrl
// @Released 2020-11-15
// @Author jwrl
// @Created 2016-02-12
// @see https://www.lwks.com/media/kunena/attachments/6375/Low_res_cam_2018-05-23.png

/**
 This effect was designed to simulate the pixellation that you get when a low-resolution
 camera is blown up just that little too much.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LowResCamera.fx
//
// Version history:
//
// Update 2020-11-15 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 7 December 2018 jwrl.
// Changed subcategory.
//
// Modified 2018-07-07 jwrl:
// Made blur resolution independent.  Bug fix 2017-02-26 no longer applies and has been
// removed.
//
// Modified 2018-04-08 jwrl:
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Cross platform compatibility check 2017-08-03 jwrl:
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Bug fix 2017-02-26 jwrl:
// This corrects for a bug in the way that Lightworks handles interlaced media.
//
// Version 14 update 2017-02-18 jwrl:
// Added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Low-res camera";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Simulates the pixellation that you get when a low-res camera is blown up just that little too much";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Buffer_1 : RenderColorTarget;
texture Buffer_2 : RenderColorTarget;
texture Buffer_3 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Buffer_1 = sampler_state
{
   Texture   = <Buffer_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Buffer_2 = sampler_state
{
   Texture   = <Buffer_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Buffer_3 = sampler_state
{
   Texture   = <Buffer_3>;
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
   string Description = "Blur position";
   string Enum = "Apply blur before mosaic,Apply blur after mosaic,Apply blur either side of mosaic";
> = 2;

float blockSize
<
   string Description = "Pixellation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float blurAmt
<
   string Description = "Blurriness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

// Pascal's triangle magic numbers for blur

#define BLUR_0  0.001
#define BLUR_1  0.3125
#define BLUR_2  0.2344
#define BLUR_3  0.09375
#define BLUR_4  0.01563

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 set_in (float2 xy : TEXCOORD1) : COLOR
{
   return tex2D (s_Input, xy);
}

float4 do_mosaic (float2 xy : TEXCOORD1) : COLOR
{
   float2 uv;

   if (blockSize == 0.0) return tex2D (s_Buffer_2, xy);

   float Xsize = blockSize / 50;
   uv.x = (round ((xy.x - 0.5) / Xsize) * Xsize) + 0.5;

   float Ysize = Xsize * _OutputAspectRatio;
   uv.y = (round ((xy.y - 0.5) / Ysize) * Ysize) + 0.5;

   return tex2D (s_Buffer_2, uv);
}

float4 preblur (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Buffer_3, xy);

   if (blurAmt == 0.0) return retval;

   float2 offset_X1 = float2 (blurAmt * BLUR_0, 0.0);
   float2 offset_X2 = offset_X1 + offset_X1;
   float2 offset_X3 = offset_X1 + offset_X2;

   retval *= BLUR_1;
   retval += tex2D (s_Buffer_3, xy + offset_X1) * BLUR_2;
   retval += tex2D (s_Buffer_3, xy - offset_X1) * BLUR_2;
   retval += tex2D (s_Buffer_3, xy + offset_X2) * BLUR_3;
   retval += tex2D (s_Buffer_3, xy - offset_X2) * BLUR_3;
   retval += tex2D (s_Buffer_3, xy + offset_X3) * BLUR_4;
   retval += tex2D (s_Buffer_3, xy - offset_X3) * BLUR_4;

   return retval;
}

float4 fullblur (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Buffer_1, xy);

   if (blurAmt == 0.0) return retval;

   float2 offset_Y1 = float2 (0.0, blurAmt * _OutputAspectRatio * BLUR_0);
   float2 offset_Y2 = offset_Y1 + offset_Y1;
   float2 offset_Y3 = offset_Y1 + offset_Y2;

   retval *= BLUR_1;
   retval += tex2D (s_Buffer_1, xy + offset_Y1) * BLUR_2;
   retval += tex2D (s_Buffer_1, xy - offset_Y1) * BLUR_2;
   retval += tex2D (s_Buffer_1, xy + offset_Y2) * BLUR_3;
   retval += tex2D (s_Buffer_1, xy - offset_Y2) * BLUR_3;
   retval += tex2D (s_Buffer_1, xy + offset_Y3) * BLUR_4;
   retval += tex2D (s_Buffer_1, xy - offset_Y3) * BLUR_4;

   return retval;
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 Image = tex2D (s_Input, xy);

   if (Amount == 0.0) return Image;

   return lerp (Image, tex2D (s_Buffer_3, xy), Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique pre_mosaic
{
   pass P_1
   < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE set_in (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE preblur (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE fullblur (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE do_mosaic (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

technique postmosaic
{
   pass P_1
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE set_in (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE do_mosaic (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE preblur (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE fullblur (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

technique full_blur
{
   pass P_1
   < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE set_in (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE preblur (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE fullblur (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE do_mosaic (); }

   pass P_5
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE preblur (); }

   pass P_6
   < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE fullblur (); }

   pass P_7
   { PixelShader = compile PROFILE ps_main (); }
}
