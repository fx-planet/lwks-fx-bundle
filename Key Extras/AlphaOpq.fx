// @Maintainer jwrl
// @Released 2020-09-29
// @Author jwrl
// @Created 2019-05-12
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaOpq_640.png

/**
 This simple effect turns the alpha channel of a clip fully on, making it opaque.  There
 are two modes available - the first simply turns the alpha on, the second adds a flat
 background colour where previously the clip was transparent.  The default colour used
 is black, and the image can be unpremultiplied in this mode if desired.

 A means of boosting alpha before processing to support clips such as Lightworks titles
 has also been included.  This only functions when the background is being replaced.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AlphaOpq.fx
//
// Version history:
//
// Update 2020-09-29 jwrl.
// Revised header block.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha opaque";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "Makes a transparent image or title completely opaque";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Opacity mode";
   string Enum = "Make opaque,Blend with colour";
> = 0;

int KeyMode
<
   string Description = "Type of alpha channel";
   string Enum = "Standard,Premultiplied,Lightworks title effects";
> = 0;

float4 Colour
<
   string Description = "Background colour";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.0, 0.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_0 (float2 uv : TEXCOORD1) : COLOR
{
   return float4 (tex2D (s_Input, uv).rgb, 1.0);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (s_Input, uv);

   if (KeyMode == 2) Fgd.a = pow (Fgd.a, 0.5);
   if (KeyMode > 0) Fgd.rgb /= Fgd.a;

   return float4 (lerp (Colour.rgb, Fgd.rgb, Fgd.a), 1.0);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique AlphaOpq_0
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_0 (); }
}

technique AlphaOpq_1
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_1 (); }
}
