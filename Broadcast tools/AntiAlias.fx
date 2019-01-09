// @Maintainer jwrl
// @Released 2018-10-25
// @Author jwrl
// @Created 2018-10-25
// @see https://www.lwks.com/media/kunena/attachments/6375/AntiAlias_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect AntiAlias.fx
//
// An octo-sampling anti-alias tool that samples at 45 degree intervals.  The sampling
// radius can be scaled over a two pixel range and the anti-aliassed image can be mixed
// with the unmodified input.  This version is a complete rewrite of the original anti-
// alias effect, which was needlessly complex for the result that it produced.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Antialias";
   string Category    = "User Effects";
   string SubCategory = "Broadcast";
   string Notes       = "A very clean octo-sampling adjustable anti-alias tool";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state {
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Radius
<
   string Description = "Radius";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float Opacity
<
   string Description = "Amount";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SQRT_2 0.7071067812

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fg = tex2D (s_Input, uv);

   if (Opacity <= 0.0) return Fg;

   float3 xyz = float3 (1.0, 0.0, _OutputAspectRatio) * Radius * 2.0 / _OutputWidth;

   float2 xy = xyz.xz * SQRT_2;

   float4 Aa = Fg + tex2D (s_Input, uv + xyz.xy);

   Aa += tex2D (s_Input, uv - xyz.xy);
   Aa += tex2D (s_Input, uv + xyz.yz);
   Aa += tex2D (s_Input, uv - xyz.yz);

   Aa += tex2D (s_Input, uv + xy);
   Aa += tex2D (s_Input, uv - xy);

   xy.x = -xy.x;

   Aa += tex2D (s_Input, uv + xy);
   Aa += tex2D (s_Input, uv - xy);
   Aa /= 9.0;

   return lerp (Fg, Aa, Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique AntiAlias
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
