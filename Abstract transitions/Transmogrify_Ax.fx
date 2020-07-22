// @Maintainer jwrl
// @Released 2020-07-22
// @Author jwrl
// @Created 2018-06-13
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Transmogrify_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Transmogrify.mp4

/**
 This is a truly bizarre transition which can transition into or out of a title or
 between titles.  The outgoing title is blown apart into individual pixels which swirl
 away.  The incoming title materialises from a pixel cloud, and the result is then
 composited over the background layer.  Alpha levels can be boosted to better support
 Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Transmogrify_Ax.fx
//
// This is a revision of an earlier effect, Adx_Transmogrify.fx, which added the ability
// to wipe between two titles.  That added needless complexity, when the same result can
// be obtained by overlaying two effects.
//
// Version history:
//
// Modified jwrl 2020-07-22
// Reworded transition mode to read "Transition position".
// Reworded Boost text to match requirements for 2020.1 and up.
// Implemented Boost as a separate pass ahead of the main code.
// Corrected a bug that would have affected particle position on Linux/OS-X.
//
// Modified 23 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//
// Modified 2018-07-09 jwrl:
// Removed dependence on pixel size.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Transmogrify (alpha)";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "Breaks a title into a cloud of particles which blow apart";
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SCALE 0.000545

#define EMPTY (0.0).xxxx

float _OutputAspectRatio;
float _Progress;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (s_Sampler, uv);
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
   float2 pixSize = uv * float2 (1.0, _OutputAspectRatio) * SCALE;

   float rand = (uv * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5;

   pixSize += rand.xx;

   float2 xy = saturate (pixSize + sqrt (1.0 - _Progress).xx);

   float4 Fgnd = fn_tex2D (s_Key, lerp (float2 (xy.x, 1.0 - xy.y), uv, Amount));

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixSize = uv * float2 (1.0, _OutputAspectRatio) * SCALE;

   float rand = (uv * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5;

   pixSize += rand.xx;

   float4 Fgnd = fn_tex2D (s_Key, lerp (uv, saturate (pixSize + sqrt (_Progress).xx), Amount));

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Transmogrify_in
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Ax_Transmogrify_out
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_out (); }
}
