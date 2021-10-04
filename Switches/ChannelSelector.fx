// @Maintainer jwrl
// @Released 2021-09-22
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
// Version history:
//
// Update 2021-09-22 jwrl:
// Modified to support resolution independence.
//
// Prior to 2018-12-27:
// Various updates and patches for cross platform support.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Channel selector";
   string Category    = "User";
   string SubCategory = "Switches";
   string Notes       = "Selectively combine RGBA channels from up to four layers";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define LUMA  float3(0.2989, 0.5866, 0.1145)

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (V1, s_Video_1);
DefineInput (V2, s_Video_2);
DefineInput (V3, s_Video_3);
DefineInput (V4, s_Video_4);

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
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_select (sampler vidSample, float2 xy, int vidSelect)
{
   if (vidSelect == 6) return EMPTY;

   float4 retval = GetPixel (vidSample, xy);

   if (vidSelect == 0) return retval;
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
   if (vidRoute == 3) return float4 (video_ref.r, video_src.g, video_ref.ba);
   if (vidRoute == 4) return float4 (video_ref.rg, video_src.b, video_ref.a);
   if (vidRoute == 5) return float4 (video_ref.rgb, video_src.a);
   if (vidRoute == 6) return video_ref;

   return video_src;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2,
                float2 uv3 : TEXCOORD3, float2 uv4 : TEXCOORD4) : COLOR
{
   float4 newvid = fn_select (s_Video_1, uv1, SelectVideo_1);
   float4 retval = fn_route (newvid, EMPTY, RouteVideo_1);

   newvid = fn_select (s_Video_2, uv2, SelectVideo_2);
   retval = fn_route (newvid, retval, RouteVideo_2);
   newvid = fn_select (s_Video_3, uv3, SelectVideo_3);
   retval = fn_route (newvid, retval, RouteVideo_3);
   newvid = fn_select (s_Video_4, uv4, SelectVideo_4);

   return fn_route (newvid, retval, RouteVideo_4);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ChannelSelector { pass P_1 ExecuteShader (ps_main) }

