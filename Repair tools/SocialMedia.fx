// @Maintainer jwrl
// @Released 2019-07-15
// @Author jwrl
// @Created 2019-07-14
// @see https://www.lwks.com/media/kunena/attachments/6375/SocialMedia_640.png

/**
 This is a simple effect that allows masking of the frame to support reframing for common
 social media formats.  Horizontal repositioning is provided to adjust for the masking.
 It is configured so that a 100% centering adjustment in either direction takes the
 actual edge of frame to the masked edge of frame and no further.  If the selected
 aspect ratio exceeds the project's output aspect ratio no action is taken at all.

 It relies on external transcoding using ffmpeg or similar to crop to the desired format.
 For that reason masking can be turned off to allow for floating point rounding errors
 in Lightworks and/or the external application used.  The workflow should be:

 1. Enable the mask that you wish.  The default is usually the best choice.
 2. Select the crop ratio using an aspect ratio preset.
 3. Adjust image centering for best composition, keyframing it as required.
 4. Once everything is as you wish set the mask type to "Unmasked".

 Then simply export your sequence and use an external application to crop it to the same
 aspect ratio as you were using in the effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SocialMedia.fx
//
// 2019-07-15:
// Original release date.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Social media formatter";
   string Category    = "DVE";
   string SubCategory = "Repair tools";
   string Notes       = "Provides cropping and positioning for common social media formats";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = Border;
   AddressV  = Border;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int AspectRatio
<
   string Description = "Aspect ratio";
   string Enum = "16:9 (landscape),3:2 (landscape),4:3 (landscape),5:4 (landscape),1:1,4:5 (portrait),3:4 (portrait),2:3 (portrait),9:16 (portrait)";
> = 8;

int SetTechnique
<
   string Description = "Mask type";
   string Enum = "Unmasked,Greyed edges,Blanked";
> = 1;

float Centre
<
   string Description = "Centering";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

float _aspect [] = { 1.7777777778, 1.5, 1.3333333333, 1.25, 1.0, 0.8, 0.75, 0.6666666667, 0.5625 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_0 (float2 uv : TEXCOORD1) : COLOR
{
   float limit = _aspect [AspectRatio] / _OutputAspectRatio;

   float2 xy = (limit >= 1.0) ? uv : uv - float2 ((1.0 - limit) * Centre * 0.5, 0.0);

   return tex2D (s_Input, xy); 
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float limit = _aspect [AspectRatio] / _OutputAspectRatio;
   float legal = abs (uv.x - 0.5) * 2.0;

   float2 xy = (limit >= 1.0) ? uv : uv - float2 ((1.0 - limit) * Centre * 0.5, 0.0);

   float4 retval = tex2D (s_Input, xy); 

   if (legal > limit) retval.rgb = (retval.rgb * 0.25) + 0.125.xxx;

   return retval;
}

float4 ps_main_2 (float2 uv : TEXCOORD1) : COLOR
{
   float limit = _aspect [AspectRatio] / _OutputAspectRatio;
   float legal = abs (uv.x - 0.5) * 2.0;

   if (legal > limit) return 0.0.xxxx;

   float2 xy = (limit >= 1.0) ? uv : uv - float2 ((1.0 - limit) * Centre * 0.5, 0.0);

   return tex2D (s_Input, xy); 
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SocialMedia_0
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_0 (); }
}

technique SocialMedia_1
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_1 (); }
}

technique SocialMedia_2
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_2 (); }
}

