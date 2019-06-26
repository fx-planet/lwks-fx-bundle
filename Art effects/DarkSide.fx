// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2017-02-25
// @see https://www.lwks.com/media/kunena/attachments/6375/TheDarkSide_640.png

/**
The dark side (DarkSide.fx) gives a dark "glow" (don't know what else to call it) to an
image.  All parameters are minimum range limited to prevent manual entry of illegal or
negative values.  There is no such limit to the maximum values possible.  The alpha
channel is fully preserved throughout.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DarkSide.fx
//
// Sort of based on the Lightworks "Glow" effect, I started work on this effect then
// decided to check the Editshare code.  Accordingly, the user interface is now exactly
// the same as theirs, with the exception of the "Size" parameter.  The code under the
// hood varies more than somewhat, and "Size" scales from 0% to 100%, not from 1 to 10.
//
// The main difference is that they have used different techniques for their four options:
// I had already built the luma version and opted to use conditional execution to expand
// the options to match theirs.  It's ever so slightly slower, but it adds the benefit of
// being able to feather the RGB values and apply a glow colour to them.
//
// One minor difference is that the box blur samples fifteen deep instead of thirteen.  I
// had already written that and had arrived at that figure empirically, and didn't feel
// the need to change it.  I was in fact going to use my super blur engine but decided that
// the complexity wasn't warranted, and opted for simplicity instead.
//
// The feather scale factor was a late change that I stole from the "Glow" effect, but done
// as a definition and not a constant.  Previously I hadn't scaled the value at all.  This
// is better because it gives better control.
//
// "GlowSpread" originally adjusted from 0 to 1 and was further offset and scaled prior to
// use.  Their implementation of "Spread" was simpler, so I used it.  I would have had to in
// any case to make the user interfaces match.
//
// If you're interested, the original settings order was Source, glowAmount, glowKnee,
// glowFeather, glowSpread then Colour.  You should be able to work out what the user would
// have seen from the parameter names.
//
// Cross platform compatibility check 1 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 6 July 2018 jwrl.
// Calculate glow related to frame size not pixel size.
//
// Modified 23 December 2018 jwrl.
// Changed subcategory.
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "The dark side";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "Creates a shadow enhancing soft darkness spread.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Glow_1 : RenderColorTarget;
texture Glow_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Input>; };

sampler s_Glow_1 = sampler_state
{
   Texture   = <Glow_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Glow_2 = sampler_state
{
   Texture   = <Glow_2>;
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
   string Description = "Source";
   string Enum = "Luminance,Red,Green,Blue";
> = 0;

float glowKnee
<
   string Description = "Tolerance";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float glowFeather
<
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float glowSpread
<
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float glowAmount
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 Colour
<
   string Description = "Colour difference";
> = { 0.0, 0.0, 0.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define RED     1
#define GREEN   2
#define BLUE    3

#define R_LUMA  0.2989
#define G_LUMA  0.5866
#define B_LUMA  0.1145

#define F_SCALE 0.5
#define P_SCALE 0.0015

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_extract_Y (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   float feather = max (glowFeather, 0.0) * F_SCALE;
   float knee = max (glowKnee, 0.0);
   float vid = (dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA))) * retval.a;

   if (vid < knee) { retval.rgb = 1.0.xxx; }
   else if (vid < (knee + feather)) { retval.rgb = lerp (1.0.xxx, Colour.rgb, (vid - knee) / feather); }
   else retval.rgb = Colour.rgb;

   return retval;
}

float4 ps_extract_R (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   float feather = max (glowFeather, 0.0) * F_SCALE;
   float knee = max (glowKnee, 0.0);
   float vid = retval.r * retval.a;

   if (vid < knee) { retval.rgb = 1.0.xxx; }
   else if (vid < (knee + feather)) { retval.rgb = lerp (1.0.xxx, Colour.rgb, (vid - knee) / feather); }
   else retval.rgb = Colour.rgb;

   return retval;
}

float4 ps_extract_G (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   float feather = max (glowFeather, 0.0) * F_SCALE;
   float knee = max (glowKnee, 0.0);
   float vid = retval.g * retval.a;

   if (vid < knee) { retval.rgb = 1.0.xxx; }
   else if (vid < (knee + feather)) { retval.rgb = lerp (1.0.xxx, Colour.rgb, (vid - knee) / feather); }
   else retval.rgb = Colour.rgb;

   return retval;
}

float4 ps_extract_B (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   float feather = max (glowFeather, 0.0) * F_SCALE;
   float knee = max (glowKnee, 0.0);
   float vid = retval.b * retval.a;

   if (vid < knee) { retval.rgb = 1.0.xxx; }
   else if (vid < (knee + feather)) { retval.rgb = lerp (1.0.xxx, Colour.rgb, (vid - knee) / feather); }
   else retval.rgb = Colour.rgb;

   return retval;
}

float4 ps_part_blur (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;
   float2 offset = float2 (max (glowSpread, P_SCALE) * P_SCALE, 0.0);

   float4 retval = tex2D (s_Glow_1, xy);

   xy += offset; retval += tex2D (s_Glow_1, xy);
   xy += offset; retval += tex2D (s_Glow_1, xy);
   xy += offset; retval += tex2D (s_Glow_1, xy);
   xy += offset; retval += tex2D (s_Glow_1, xy);
   xy += offset; retval += tex2D (s_Glow_1, xy);
   xy += offset; retval += tex2D (s_Glow_1, xy);
   xy += offset; retval += tex2D (s_Glow_1, xy);

   xy = uv - offset;
   retval += tex2D (s_Glow_1, xy);

   xy -= offset; retval += tex2D (s_Glow_1, xy);
   xy -= offset; retval += tex2D (s_Glow_1, xy);
   xy -= offset; retval += tex2D (s_Glow_1, xy);
   xy -= offset; retval += tex2D (s_Glow_1, xy);
   xy -= offset; retval += tex2D (s_Glow_1, xy);
   xy -= offset; retval += tex2D (s_Glow_1, xy);

   return retval / 15.0;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float amount = max (glowAmount, 0.0);

   float2 xy = uv;
   float2 offset = float2 (0.0, max (glowSpread, P_SCALE) * _OutputAspectRatio * P_SCALE);

   float4 retval = tex2D (s_Input, xy);
   float4 gloVal = tex2D (s_Glow_2, xy);

   xy += offset; gloVal += tex2D (s_Glow_2, xy);
   xy += offset; gloVal += tex2D (s_Glow_2, xy);
   xy += offset; gloVal += tex2D (s_Glow_2, xy);
   xy += offset; gloVal += tex2D (s_Glow_2, xy);
   xy += offset; gloVal += tex2D (s_Glow_2, xy);
   xy += offset; gloVal += tex2D (s_Glow_2, xy);
   xy += offset; gloVal += tex2D (s_Glow_2, xy);

   xy = uv - offset;
   gloVal += tex2D (s_Glow_2, xy);

   xy -= offset; gloVal += tex2D (s_Glow_2, xy);
   xy -= offset; gloVal += tex2D (s_Glow_2, xy);
   xy -= offset; gloVal += tex2D (s_Glow_2, xy);
   xy -= offset; gloVal += tex2D (s_Glow_2, xy);
   xy -= offset; gloVal += tex2D (s_Glow_2, xy);
   xy -= offset; gloVal += tex2D (s_Glow_2, xy);

   gloVal = saturate (retval - (gloVal / 15.0));

   return lerp (retval, gloVal, amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DarkSide_Y
{
   pass P_1
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_extract_Y (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_part_blur (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique DarkSide_R
{
   pass P_1
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_extract_R (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_part_blur (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique DarkSide_G
{
   pass P_1
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_extract_G (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_part_blur (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique DarkSide_B
{
   pass P_1
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_extract_B (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_part_blur (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}
