// @Maintainer jwrl
// @Released 2018-04-08
// @Author jwrl
// @Created 2016-02-12
// @see https://www.lwks.com/media/kunena/attachments/6375/Low_res_cam.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Low_res_cam.fx
//
// This effect was designed to simulate the pixellation that you get when a low-res
// camera is blown up just that little too much.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles interlaced media.
//
// Cross platform compatibility check 3 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Low-res camera";
   string Category    = "Stylize";
   string SubCategory = "Simulation";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Buffer_0 : RenderColorTarget;
texture Buffer_1 : RenderColorTarget;
texture Buffer_2 : RenderColorTarget;
texture Buffer_3 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buffer_0_S   = sampler_state
{
   Texture   = <Buffer_0>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buffer_1_S   = sampler_state
{
   Texture   = <Buffer_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buffer_2_S   = sampler_state
{
   Texture   = <Buffer_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buffer_3_S   = sampler_state
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

#define BLUR_0  0.3125
#define BLUR_1  0.2344
#define BLUR_2  0.09375
#define BLUR_3  0.01563

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 set_in (float2 xy : TEXCOORD1) : COLOR
{
   return tex2D (InputSampler, xy);
}

float4 do_mosaic (float2 xy : TEXCOORD1) : COLOR
{
   float2 uv;

   if (blockSize == 0.0) return tex2D (Buffer_0_S, xy);

   float Xsize = blockSize / 50;
   uv.x = (round ((xy.x - 0.5) / Xsize) * Xsize) + 0.5;

   float Ysize = Xsize * _OutputAspectRatio;
   uv.y = (round ((xy.y - 0.5) / Ysize) * Ysize) + 0.5;

   return tex2D (Buffer_0_S, uv);
}

float4 preblur (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (Buffer_1_S, xy);

   if (blurAmt == 0.0) return retval;

   float2 offset_X1 = float2 ((blurAmt * 2.0) / _OutputWidth, 0.0);
   float2 offset_X2 = offset_X1 + offset_X1;
   float2 offset_X3 = offset_X1 + offset_X2;

   retval *= BLUR_0;
   retval += tex2D (Buffer_1_S, xy + offset_X1) * BLUR_1;
   retval += tex2D (Buffer_1_S, xy - offset_X1) * BLUR_1;
   retval += tex2D (Buffer_1_S, xy + offset_X2) * BLUR_2;
   retval += tex2D (Buffer_1_S, xy - offset_X2) * BLUR_2;
   retval += tex2D (Buffer_1_S, xy + offset_X3) * BLUR_3;
   retval += tex2D (Buffer_1_S, xy - offset_X3) * BLUR_3;

   return retval;
}

float4 fullblur (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (Buffer_2_S, xy);

   if (blurAmt == 0.0) return retval;

   float2 offset_Y1 = float2 (0.0, (blurAmt * _OutputAspectRatio * 2.0) / _OutputWidth);
   float2 offset_Y2 = offset_Y1 + offset_Y1;
   float2 offset_Y3 = offset_Y1 + offset_Y2;

   retval *= BLUR_0;
   retval += tex2D (Buffer_2_S, xy + offset_Y1) * BLUR_1;
   retval += tex2D (Buffer_2_S, xy - offset_Y1) * BLUR_1;
   retval += tex2D (Buffer_2_S, xy + offset_Y2) * BLUR_2;
   retval += tex2D (Buffer_2_S, xy - offset_Y2) * BLUR_2;
   retval += tex2D (Buffer_2_S, xy + offset_Y3) * BLUR_3;
   retval += tex2D (Buffer_2_S, xy - offset_Y3) * BLUR_3;

   return retval;
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 Image = tex2D (InputSampler, xy);

   if (Amount == 0.0) return Image;

   float4 blurMosaic = tex2D (Buffer_3_S, xy);

   return lerp (Image, blurMosaic, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique pre_mosaic
{
   pass P_1
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE set_in (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE preblur (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Buffer_0;"; >
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
   < string Script = "RenderColorTarget0 = Buffer_0;"; >
   { PixelShader = compile PROFILE set_in (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE do_mosaic (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
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
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE set_in (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE preblur (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Buffer_0;"; >
   { PixelShader = compile PROFILE fullblur (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE do_mosaic (); }

   pass P_5
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE preblur (); }

   pass P_6
   < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE fullblur (); }

   pass P_7
   { PixelShader = compile PROFILE ps_main (); }
}
