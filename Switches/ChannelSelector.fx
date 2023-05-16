// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2018-06-10

/**
 Channel selector can choose the RGBA channel to be used from up to four separate video
 layers.  It can be used as a simple matte generator for use in other blending effects,
 a means of producing black and white from colour, or even as a means of producing a
 colour image from colour separations.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChannelSelector.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Channel selector", "User", "Switches", "Selectively combine RGBA channels from up to four layers", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (V1, V2, V3, V4);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SelectVideo_1, "Select component to use from V1", kNoGroup, 0, "RGBA|Luminance|Red|Green|Blue|Alpha|None");
DeclareIntParam (RouteVideo_1, "Select channel to assign to V1", kNoGroup, 0, "RGBA|RGB|Red|Green|Blue|Alpha|None");

DeclareIntParam (SelectVideo_2, "Select component to use from V2", kNoGroup, 6, "RGBA|Luminance|Red|Green|Blue|Alpha|None");
DeclareIntParam (RouteVideo_2, "Select channel to assign to V2", kNoGroup, 6, "RGBA|RGB|Red|Green|Blue|Alpha|None");

DeclareIntParam (SelectVideo_3, "Select component to use from V3", kNoGroup, 6, "RGBA|Luminance|Red|Green|Blue|Alpha|None");
DeclareIntParam (RouteVideo_3, "Select channel to assign to V3", kNoGroup, 6, "RGBA|RGB|Red|Green|Blue|Alpha|None");

DeclareIntParam (SelectVideo_4, "Select component to use from V4", kNoGroup, 6, "RGBA|Luminance|Red|Green|Blue|Alpha|None");
DeclareIntParam (RouteVideo_4, "Select channel to assign to V4", kNoGroup, 6, "RGBA|RGB|Red|Green|Blue|Alpha|None");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LUMA  float3(0.2989, 0.5866, 0.1145)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_select (sampler S, float2 uv, int video)
{
   if (video == 6) return kTransparentBlack;

   float4 retval = ReadPixel (S, uv);

   if (video == 5) return retval.aaaa;
   if (video == 4) return retval.bbbb;
   if (video == 3) return retval.gggg;
   if (video == 2) return retval.rrrr;

   return (video == 1) ? dot (retval.rgb, LUMA).xxxx : retval;
}

float4 fn_route (float4 src, float4 ref, int routing)
{
   if (routing == 1) return float4 (src.rgb, ref.a);
   if (routing == 2) return float4 (src.r, ref.gba);
   if (routing == 3) return float4 (ref.r, src.g, ref.ba);
   if (routing == 4) return float4 (ref.rg, src.b, ref.a);
   if (routing == 5) return float4 (ref.rgb, src.a);

   return (routing == 6) ? ref : src;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ChannelSelector)
{
   float4 newvid = fn_select (V1, uv1, SelectVideo_1);
   float4 retval = fn_route (newvid, kTransparentBlack, RouteVideo_1);

   newvid = fn_select (V2, uv2, SelectVideo_2);
   retval = fn_route (newvid, retval, RouteVideo_2);
   newvid = fn_select (V3, uv3, SelectVideo_3);
   retval = fn_route (newvid, retval, RouteVideo_3);
   newvid = fn_select (V4, uv4, SelectVideo_4);

   return fn_route (newvid, retval, RouteVideo_4);
}

