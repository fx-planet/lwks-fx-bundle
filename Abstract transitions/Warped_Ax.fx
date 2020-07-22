// @Maintainer jwrl
// @Released 2020-07-22
// @Author jwrl
// @Created 2018-06-13
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Warp_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Warp.mp4

/**
 This effect warps into or out of a title.  It also composites the result over the
 background layer.  The warp is driven by the background image, so will be different
 each time that it's used.  Alpha levels can be boosted to support Lightworks titles,
 which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Warped_Ax.fx
//
// This is a revision of an earlier effect, Adx_Warp.fx, which provided the ability to
// wipe between two titles.  That added needless complexity, when the same result can
// be obtained by overlaying two effects.
//
// Version history:
//
// Modified jwrl 2020-07-22
// Reworded transition mode to read "Transition position".
// Reworded Boost text to match requirements for 2020.1 and up.
// Implemented Boost as a separate pass ahead of the main code.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Warped dissolve (alpha)";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "Warps a title into or out of the background";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Key : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Sup>; };
sampler s_Background = sampler_state { Texture = <Vid>; };

sampler s_Key = sampler_state
{
   Texture   = <Key>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "Lightworks effects: Disconnect the input and select";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
> = 0;

float Distortion
<
   string Description = "Distortion";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI 1.5707963268

#define EMPTY   (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (Vsample, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = tex2D (s_Background, uv);

   float3 warp = (Bgnd.rgb - 0.5.xxx) * Distortion * 4.0;

   float2 xy;

   float Amt = 1.0 - sin (Amount * HALF_PI);

   xy.x = saturate (uv.x + (warp.y - 0.5) * Amt);
   Amt *= 2.0;
   xy.y = saturate (uv.y + (warp.z - warp.x) * Amt);

   float4 Fgnd = fn_tex2D (s_Key, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = tex2D (s_Background, uv);

   float3 warp = (Bgnd.rgb - 0.5.xxxx) * Distortion * 4.0;

   float2 xy;

   float Amt = 1.0 - cos (Amount * HALF_PI);

   xy.y = saturate (uv.y + (0.5 - warp.x) * Amt);
   Amt *= 2.0;
   xy.x = saturate (uv.x + (warp.y - warp.z) * Amt);

   float4 Fgnd = fn_tex2D (s_Key, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Warped_Ax_in
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Warped_Ax_out
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_out (); }
}
