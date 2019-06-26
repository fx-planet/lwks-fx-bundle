// @Maintainer jwrl
// @Released 2018-12-27
// @Author jwrl
// @Created 2018-06-10
// @see https://www.lwks.com/media/kunena/attachments/6375/ChannelSelect_640.png

/**
Channel selector can choose the RGBA channel to be used from up to four separate video
layers.  It can be used as a simple matte generator for use in other blending effects,
a means of producing black and white from colour, or just a means of producing a colour
image from colour separations.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChannelSelector.fx
//
// Modified 6 December 2018 jwrl.
// Changed category and subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Channel selector";
   string Category    = "User";
   string SubCategory = "Switches";
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
   string Enum = "RGBA,Luminance,Red,Green,Blue,Alpha,None"; 
> = 0;

int RouteVideo_1
<
   string Description = "Select channel to assign V1 to";
   string Enum = "RGBA,RGB,Red,Green,Blue,Alpha,None"; 
> = 0;

int SelectVideo_2
<
   string Description = "Select component to use from V2";
   string Enum = "RGBA,Luminance,Red,Green,Blue,Alpha,None"; 
> = 6;

int RouteVideo_2
<
   string Description = "Select channel to assign V2 to";
   string Enum = "RGBA,RGB,Red,Green,Blue,Alpha,None"; 
> = 6;

int SelectVideo_3
<
   string Description = "Select component to use from V3";
   string Enum = "RGBA,Luminance,Red,Green,Blue,Alpha,None"; 
> = 6;

int RouteVideo_3
<
   string Description = "Select channel to assign V3 to";
   string Enum = "RGBA,RGB,Red,Green,Blue,Alpha,None"; 
> = 6;

int SelectVideo_4
<
   string Description = "Select component to use from V4";
   string Enum = "RGBA,Luminance,Red,Green,Blue,Alpha,None"; 
> = 6;

int RouteVideo_4
<
   string Description = "Select channel to assign V4 to";
   string Enum = "RGBA,RGB,Red,Green,Blue,Alpha,None"; 
> = 6;

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
   if (vidSelect == 6) return EMPTY;

   float4 retval = tex2D (vidSample, xy);

   if (vidSelect == 1) return retval;
   if (vidSelect == 2) return retval.rrrr;
   if (vidSelect == 3) return retval.gggg;
   if (vidSelect == 4) return retval.bbbb;
   if (vidSelect == 5) return retval.aaaa;

   return dot (retval.rgb, LUMA).xxxx;
}

float4 fn_route (float4 video_src, float4 video_ref, int vidRoute)
{
   if (vidRoute == 1) return float4 (video_src.rgb, video_ref.a);
   if (vidRoute == 2) return float4 (video_src.r, video_ref.gba);
   if (vidRoute == 3) return float4 (vide_ref.r video_src.g, video_ref.ba);
   if (vidRoute == 4) return float4 (vide_ref.rg video_src.b, video_ref.a);
   if (vidRoute == 5) return float4 (video_ref.rgb, video_src.a);
   if (vidRoute == 6) return video_ref;

   return video_src;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 newvid = fn_select (s_Video_1, uv, SelectVideo_1);
   float4 retval = fn_route (newvid, EMPTY, RouteVideo_1);

   newvid = fn_select (s_Video_2, uv, SelectVideo_2);
   retval = fn_route (newvid, retval, RouteVideo_2);
   newvid = fn_select (s_Video_3, uv, SelectVideo_3);
   retval = fn_route (newvid, retval, RouteVideo_3);
   newvid = fn_select (s_Video_4, uv, SelectVideo_4);

   return fn_route (newvid, retval, RouteVideo_4);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ChannelSelector
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

