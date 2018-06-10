// @Maintainer jwrl
// @Released 2018-06-10
// @Author jwrl
// @Created 2018-06-10
// @see https://www.lwks.com/media/kunena/attachments/6375/ChannelSelect_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChannelSelect.fx
//
// Channel selector can choose the RGBA channel to be used from up to four separate video
// layers.  It can be used as a simple matte generator for use in other blending effects,
// a means of producing black and white from colour, or just a means of producing a colour
// image from colour separations.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Channel selector";
   string Category    = "Colour";
   string SubCategory = "Technical";
   string Notes       = "Selectively combine RGBA channels from up to four layers";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture V1;
texture V2;
texture V3;
texture V4;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Video_1 = sampler_state { Texture = <V1>; };
sampler s_Video_2 = sampler_state { Texture = <V2>; };
sampler s_Video_3 = sampler_state { Texture = <V3>; };
sampler s_Video_4 = sampler_state { Texture = <V4>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SelectVideo_1
<
   string Description = "Select component to use from V1";
   string Enum = "RGB,Luminance,Red,Green,Blue,Alpha,Luminance as alpha,Red as alpha,Green as alpha,Blue as alpha,None"; 
> = 0;

int SelectVideo_2
<
   string Description = "Select component to use from V2";
   string Enum = "RGB,Luminance,Red,Green,Blue,Alpha,Luminance as alpha,Red as alpha,Green as alpha,Blue as alpha,None"; 
> = 6;

int SelectVideo_3
<
   string Description = "Select component to use from V3";
   string Enum = "RGB,Luminance,Red,Green,Blue,Alpha,Luminance as alpha,Red as alpha,Green as alpha,Blue as alpha,None"; 
> = 10;

int SelectVideo_4
<
   string Description = "Select component to use from V4";
   string Enum = "RGB,Luminance,Red,Green,Blue,Alpha,Luminance as alpha,Red as alpha,Green as alpha,Blue as alpha,None"; 
> = 10;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY (0.0).xxxx

#define LUMA  float3(0.2989, 0.5866, 0.1145)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_select (sampler vidSample, float2 xy, int vidSelect)
{
   if (vidSelect == 10) return EMPTY;

   float4 retval = tex2D (vidSample, xy);

   if (vidSelect == 0) return float4 (retval.rgb, 0.0);
   if (vidSelect == 2) return float4 (retval.r, 0.0.xxx);
   if (vidSelect == 3) return float4 (0.0, retval.g, 0.0.xx);
   if (vidSelect == 4) return float4 (0.0.xx, retval.b, 0.0);
   if (vidSelect == 5) return float4 (0.0.xxx, retval.a);
   if (vidSelect == 7) return float4 (0.0.xxx, retval.r);
   if (vidSelect == 8) return float4 (0.0.xxx, retval.g);
   if (vidSelect == 9) return float4 (0.0.xxx, retval.b);

   float luma = dot (retval.rgb, LUMA);

   if (vidSelect == 6) return float4 (0.0.xxx, luma);

   return float4 (luma.xxx, 0.0);
/*
   if (vidSelect == 6) return float4 (0.0.xxx, max (retval.r, max (retval.g, retval.b)));

   return float4 (dot (retval.rgb, LUMA).xxx, 0.0);
*/
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = fn_select (s_Video_1, uv, SelectVideo_1);

   retval = max (retval, fn_select (s_Video_2, uv, SelectVideo_2));
   retval = max (retval, fn_select (s_Video_3, uv, SelectVideo_3));

   return max (retval, fn_select (s_Video_4, uv, SelectVideo_4));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ChannelSelect
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

