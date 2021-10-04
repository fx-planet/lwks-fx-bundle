// @Maintainer jwrl
// @Released 2021-09-01
// @Author jwrl
// @Created 2021-09-01
// @see https://www.lwks.com/media/kunena/attachments/6375/BorderCrop_640.png

/**
 This started out to be a revised SimpleCrop.fx, but since it adds a feathered,
 coloured border and a soft drop shadow was given its own name.  It's now essentially
 the same as DualDVE.fx without the DVE components but with input swapping instead.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BorderedCrop.fx
//
// Version history:
//
// Rewrite 2021-09-01 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bordered crop";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "A crop tool with border, feathering and drop shadow.";
   bool CanSize       = true;
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

#define EMPTY  (0.0).xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define BORDER_SCALE   0.0666667
#define BORDER_FEATHER 0.05

#define SHADOW_SCALE   0.2
#define SHADOW_FEATHER 0.1

#define BLACK float4(0.0.xxx,1.0)

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);
DefineTarget (FgdCrop, s_FgdCrop);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool Swap
<
   string Description = "Swap background and foreground video";
> = false;

float CropLeft
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float CropTop
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropRight
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropBottom
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float BorderWidth
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float BorderFeather
<
   string Group = "Border";
   string Description = "Feathering";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float4 BorderColour
<
   string Group = "Border";
   string Description = "Colour";
> = { 0.694, 0.255, 0.710, 1.0 };

float Opacity
<
   string Group = "Drop shadow";
   string Description = "Shadow density";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Feather
<
   string Group = "Drop shadow";
   string Description = "Feathering";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

float Shadow_X
<
   string Group = "Drop shadow";
   string Description = "Shadow offset";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.6;

float Shadow_Y
<
   string Group = "Drop shadow";
   string Description = "Shadow offset";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These two passes map the foreground and background clips to TEXCOORD3, so that
// variations in clip geometry and rotation are handled without too much effort.

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return Overflow (uv) ? BLACK : tex2D (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_crop (float2 uv : TEXCOORD3) : COLOR
{
   float bWidth = max (0.0, BorderWidth);

   float4 Fgnd   = Swap ? GetPixel (s_Background, uv) : GetPixel (s_Foreground, uv);
   float4 retval = lerp (Fgnd, BorderColour, min (1.0, bWidth * 50.0));

   float2 fx1 = float2 (1.0, _OutputAspectRatio) * max (0.0, BorderFeather) * BORDER_FEATHER;
   float2 fx2 = fx1 / 2.0;

   float2 Border = float2 (1.0, _OutputAspectRatio) * bWidth * BORDER_SCALE;
   float2 brdrTL = uv - float2 (CropLeft, 1.0 - CropTop) + Border;
   float2 brdrBR = float2 (CropRight, 1.0 - CropBottom) - uv + Border;
   float2 bAlpha = min (brdrTL, brdrBR) / fx1;

   float2 cropTL = brdrTL - Border + fx2;
   float2 cropBR = brdrBR - Border + fx2;
   float2 cAlpha = min (cropTL, cropBR) / fx1;

   retval.a = saturate (min (bAlpha.x, bAlpha.y));

   return lerp (retval, Fgnd, saturate (min (cAlpha.x, cAlpha.y)));
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float2 aspect = float2 (1.0, _OutputAspectRatio);
   float2 Border = aspect * max (0.0, BorderWidth) * BORDER_SCALE;
   float2 xy     = uv - float2 ((Shadow_X - 0.5), (0.5 - Shadow_Y) * _OutputAspectRatio) * SHADOW_SCALE;

   float4 Bgnd   = Swap ? GetPixel (s_Foreground, uv) : GetPixel (s_Background, uv);
   float4 Fgnd   = GetPixel (s_FgdCrop, uv);
   float4 retval = GetPixel (s_FgdCrop, xy);

   float2 shadowTL = xy - float2 (CropLeft, 1.0 - CropTop) + Border;
   float2 shadowBR = float2 (CropRight, 1.0 - CropBottom) - xy + Border;
   float2 sAlpha   = saturate (min (shadowTL, shadowBR) / (aspect * Feather * SHADOW_FEATHER));

   float alpha = sAlpha.x * sAlpha.y * retval.a * Opacity;

   retval = lerp (Bgnd, BLACK, alpha);

   return lerp (retval, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique BorderedCrop
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = FgdCrop;"; > ExecuteShader (ps_crop)
   pass P_2 ExecuteShader (ps_main)
}

