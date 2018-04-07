// @Maintainer jwrl
// @Released 2018-04-07
// @Author jwrl
// @Created 2017-03-23
// @see https://www.lwks.com/media/kunena/attachments/6375/SimpleCrop_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/vCropPlus1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/SimpleCrop_3.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect SimpleCrop.fx
//
// This is a quick simple cropping tool.  You can also use it to blend images without
// using a blend effect.  It provides a simple border and the "sense" of the effect can
// be swapped so that background becomes foreground and vice versa.  With its extended
// alpha support you can also use it to crop and overlay two images with alpha channels
// over another background.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Simple crop";
   string Category    = "DVE";
   string SubCategory = "Crop Presets";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fgd;
texture Bgd;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture   = <Fgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <Bgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CropLeft
<
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float CropTop
<
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float CropRight
<
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float CropBottom
<
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

bool Swap
<
   string Description = "Swap background and foreground";
> = false;

int AlphaMode
<
   string Description = "Alpha channel output";
   string Enum = "Ignore alpha,Background only,Cropped foreground,Combined alpha,Overlaid alpha";
> = 3;

float Border
<
   string Group = "Border";
   string Description = "Thickness";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.1;

float4 Colour
<
   string Group = "Border";
   string Description = "Colour";
> = { 1.0, 1.0, 1.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd, Bgnd;
   float2 brdrEdge = (Border * 0.05).xx;

   brdrEdge.y *= _OutputAspectRatio;

   float2 cropTL = float2 (CropLeft, 1.0 - CropTop);
   float2 cropBR = float2 (CropRight, 1.0 - CropBottom);
   float2 bordTL = saturate (cropTL - brdrEdge);
   float2 bordBR = saturate (cropBR + brdrEdge);

   if (Swap) {
      Bgnd = tex2D (FgSampler, uv);
      Fgnd = tex2D (BgSampler, uv);
   }
   else {
      Fgnd = tex2D (FgSampler, uv);
      Bgnd = tex2D (BgSampler, uv);
   }

   if (all (uv > bordTL) && all (uv < bordBR)) { Bgnd = Colour; }
   else if (AlphaMode == 4) Bgnd.a = 0.0;

   if (any (uv < cropTL) || any (uv > cropBR)) { Fgnd = 0.0.xxxx; }

   float alpha = (AlphaMode == 0) ? 1.0
               : (AlphaMode == 1) ? Bgnd.a
               : (AlphaMode == 2) ? Fgnd.a : max (Bgnd.a, Fgnd.a);

   return float4 (lerp (Bgnd, Fgnd, Fgnd.a).rgb, alpha);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique crop
{
   pass Simple_Pass
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
