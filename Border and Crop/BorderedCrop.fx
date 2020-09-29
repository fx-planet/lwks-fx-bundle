// @Maintainer jwrl
// @Released 2020-09-29
// @Author jwrl
// @Created 2017-05-03
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
// Update 2020-09-29 jwrl.
// Reformatted header block.
//
// Modified 23 December 2018 jwrl.
// Changed subcategory.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified 29 August 2018 jwrl.
// Added notes to header.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.  This effect will now function correctly when used with
// all current and previous Lightworks versions.
//
// Bug fix by LW user jwrl 20 July 2017
// This effect didn't work on Linux/Mac platforms.  It now does.  In the process
// significant code optimisation has been performed.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bordered crop";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "A crop tool with border, feathering and drop shadow.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fgd;
texture Bgd;

texture FgdCrop : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state {
   Texture   = <Fgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state {
   Texture   = <Bgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FcSampler = sampler_state {
   Texture   = <FgdCrop>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BORDER_SCALE   0.0666667
#define BORDER_FEATHER 0.05

#define SHADOW_SCALE   0.2
#define SHADOW_FEATHER 0.1

#define BLACK          float4(0.0.xxx,1.0)
#define EMPTY          (0.0).xxxx

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   float bWidth = max (0.0, BorderWidth);

   float4 Fgnd   = Swap ? tex2D (BgSampler, uv) : tex2D (FgSampler, uv);
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

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 aspect = float2 (1.0, _OutputAspectRatio);
   float2 Border = aspect * max (0.0, BorderWidth) * BORDER_SCALE;
   float2 xy     = uv - float2 ((Shadow_X - 0.5), (0.5 - Shadow_Y) * _OutputAspectRatio) * SHADOW_SCALE;

   float4 Bgnd   = Swap ? tex2D (FgSampler, uv) : tex2D (BgSampler, uv);
   float4 Fgnd   = tex2D (FcSampler, uv);
   float4 retval = fn_illegal (xy) ? EMPTY : tex2D (FcSampler, xy);

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
   pass P_1
   <
      string Script = "RenderColorTarget0 = FgdCrop;";
   >
   {
      PixelShader = compile PROFILE ps_crop ();
   }

   pass P_2
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
