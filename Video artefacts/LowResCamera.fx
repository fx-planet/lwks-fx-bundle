// @Maintainer jwrl
// @Released 2021-11-01
// @Author jwrl
// @Created 2021-11-01
// @see https://www.lwks.com/media/kunena/attachments/6375/Low_res_cam_2018-05-23.png

/**
 This effect was designed to simulate the pixellation that you get when a low-resolution
 camera is blown up just that little too much.

 NOTE:  Because this effect needs to be able to precisely set mosaic sizes no matter
 what the original clip size or aspect ratio is it has not been possible to make it
 truly resolution independent.  What it does is lock the clip resolution to sequence
 resolution instead.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LowResCamera.fx
//
// Version history:
//
// Rewrite 2021-11-01 jwrl.
// Rewrite of the original effect to better support LW 2021 and higher.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Low-res camera";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Simulates the pixellation that you get when a low-res camera is blown up just that little too much";
   bool CanSize       = false;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

// Pascal's triangle magic numbers for blur

#define BLUR_0  0.001
#define BLUR_1  0.3125
#define BLUR_2  0.2344
#define BLUR_3  0.09375
#define BLUR_4  0.01563

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

DefineTarget (Buffer_1, s_Buffer_1);
DefineTarget (Buffer_2, s_Buffer_2);
DefineTarget (Buffer_3, s_Buffer_3);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Blur position";
   string Enum = "Apply blur before mosaic,Apply blur after mosaic,Apply blur either side of mosaic";
> = 0;

float blockSize
<
   string Description = "Pixellation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float blurAmt
<
   string Description = "Blurriness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.35;

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 set_in (float2 uv : TEXCOORD1) : COLOR
{
   return GetPixel (s_Input, uv);
}

float4 do_mosaic (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;

   if (blockSize == 0.0) return tex2D (s_Buffer_2, uv);

   float Xsize = blockSize / 50;
   xy.x = (round ((uv.x - 0.5) / Xsize) * Xsize) + 0.5;

   float Ysize = Xsize * _OutputAspectRatio;
   xy.y = (round ((uv.y - 0.5) / Ysize) * Ysize) + 0.5;

   return tex2D (s_Buffer_2, xy);
}

float4 preblur (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Buffer_3, uv);

   if (blurAmt == 0.0) return retval;

   float2 offset_X1 = float2 (blurAmt * BLUR_0, 0.0);
   float2 offset_X2 = offset_X1 + offset_X1;
   float2 offset_X3 = offset_X1 + offset_X2;

   retval *= BLUR_1;
   retval += tex2D (s_Buffer_3, uv + offset_X1) * BLUR_2;
   retval += tex2D (s_Buffer_3, uv - offset_X1) * BLUR_2;
   retval += tex2D (s_Buffer_3, uv + offset_X2) * BLUR_3;
   retval += tex2D (s_Buffer_3, uv - offset_X2) * BLUR_3;
   retval += tex2D (s_Buffer_3, uv + offset_X3) * BLUR_4;
   retval += tex2D (s_Buffer_3, uv - offset_X3) * BLUR_4;

   return retval;
}

float4 fullblur (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Buffer_1, uv);

   if (blurAmt == 0.0) return retval;

   float2 offset_Y1 = float2 (0.0, blurAmt * _OutputAspectRatio * BLUR_0);
   float2 offset_Y2 = offset_Y1 + offset_Y1;
   float2 offset_Y3 = offset_Y1 + offset_Y2;

   retval *= BLUR_1;
   retval += tex2D (s_Buffer_1, uv + offset_Y1) * BLUR_2;
   retval += tex2D (s_Buffer_1, uv - offset_Y1) * BLUR_2;
   retval += tex2D (s_Buffer_1, uv + offset_Y2) * BLUR_3;
   retval += tex2D (s_Buffer_1, uv - offset_Y2) * BLUR_3;
   retval += tex2D (s_Buffer_1, uv + offset_Y3) * BLUR_4;
   retval += tex2D (s_Buffer_1, uv - offset_Y3) * BLUR_4;

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Image = GetPixel (s_Input, uv);

   if (Amount == 0.0) return Image;

   return lerp (Image, GetPixel (s_Buffer_3, uv), Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique pre_mosaic
{
   pass P_1 < string Script = "RenderColorTarget0 = Buffer_3;"; > ExecuteShader (set_in)
   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (preblur)
   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (fullblur)
   pass P_4 < string Script = "RenderColorTarget0 = Buffer_3;"; > ExecuteShader (do_mosaic)
   pass P_5 ExecuteShader (ps_main)
}

technique postmosaic
{
   pass P_1 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (set_in)
   pass P_2 < string Script = "RenderColorTarget0 = Buffer_3;"; > ExecuteShader (do_mosaic)
   pass P_3 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (preblur)
   pass P_4 < string Script = "RenderColorTarget0 = Buffer_3;"; > ExecuteShader (fullblur)
   pass P_5 ExecuteShader (ps_main)
}

technique full_blur
{
   pass P_1 < string Script = "RenderColorTarget0 = Buffer_3;"; > ExecuteShader (set_in)
   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (preblur)
   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (fullblur)
   pass P_4 < string Script = "RenderColorTarget0 = Buffer_3;"; > ExecuteShader (do_mosaic)
   pass P_5 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (preblur)
   pass P_6 < string Script = "RenderColorTarget0 = Buffer_3;"; > ExecuteShader (fullblur)
   pass P_7 ExecuteShader (ps_main)
}

