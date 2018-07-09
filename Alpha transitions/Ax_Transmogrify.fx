// @Maintainer jwrl
// @Released 2018-07-09
// @Author jwrl
// @Created 2018-06-13
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Transmogrify_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Transmogrify.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Transmogrify.fx
//
// This is a truly bizarre transition which can transition into or out of a title or
// between titles.  The outgoing title is blown apart into individual pixels which swirl
// away.  The incoming title materialises from a pixel cloud, and the result is then
// composited over the background layer.  Alpha levels can be boosted to better support
// Lightworks titles, which is the default setting.
//
// This is a revision of an earlier effect, Adx_Transmogrify.fx, which added the ability
// to wipe between two titles.  That added needless complexity, when the same result can
// be obtained by overlaying two effects.
//
// Modified 2018-07-09 jwrl:
// Removed dependence on pixel size.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha transmogrify";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Breaks a title into a cloud of particles which blow apart";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Video = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture   = <Sup>;
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
   string Description = "If using a Lightworks text effect disconnect its input and set this first";
   string Enum = "Crawl/Roll/Titles,Video/External image";
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
   string Description = "Transition";
   string Enum = "Waft in,Waft out";
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

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   float4 retval = tex2D (Vsample, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixSize = uv * float2 (1.0, _OutputAspectRatio) * SCALE;

   float rand = (uv * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5;

   pixSize += rand.xx;

   float2 xy = saturate (pixSize + sqrt (1.0 - _Progress));

   float4 Fgnd = fn_tex2D (s_Super, lerp (float2 (xy.x, 1.0 - xy.y), uv, Amount));

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixSize = uv * float2 (1.0, _OutputAspectRatio) * SCALE;

   float rand = (uv * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5;

   pixSize += rand.xx;

   float4 Fgnd = fn_tex2D (s_Super, lerp (uv, saturate (pixSize + sqrt (_Progress)), Amount));

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Transmogrify_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Ax_Transmogrify_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_out (); }
}
