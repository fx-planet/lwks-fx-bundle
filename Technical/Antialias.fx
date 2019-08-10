// @Maintainer jwrl
// @Released 2018-08-10
// @Author jwrl
// @Created 2016-05-09
// @see https://www.lwks.com/media/kunena/attachments/6375/AntiAlias_640.png

/**
 A two pass rotary anti-alias tool that samples first at 6 degree intervals then at 7.5
 degree intervals using different radii for each pass.  This is done to give a very smooth
 result.  The radii can be scaled and the antialias blur can be faded.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Antialias.fx
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
//
// Modified by LW user jwrl 6 December 2018.
// Changed subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 10 Aug 2019 by user jwrl:
// Changed sampler addressing to mirror.  This improves handling of frame edges.
// Changed blur calculation to correctly respect aspect ratio.
// Changed angle calculation from multiplication to addition.
// Squared Radius to make antialias application less linear.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Antialias";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "A two pass rotary anti-alias tool that gives a very smooth result";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture preBlur : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state {
        Texture   = <Inp>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
        };

sampler s_preBlur = sampler_state {
        Texture   = <preBlur>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
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

#define LOOP_1    30
#define DIVISOR_1 LOOP_1*2.0
#define RADIUS_1  0.00125
#define ANGLE_1   0.10472

#define LOOP_2    24
#define DIVISOR_2 LOOP_2*2.0
#define RADIUS_2  0.001
#define ANGLE_2   0.1309

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_pass_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (s_Input, uv);

   if ((Opacity == 0.0) || (Radius == 0.0)) return Fgd;

   float4 retval = (0.0).xxxx;
   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Radius * Radius * RADIUS_1;
   float angle = 0.0;

   for (int i = 0; i < LOOP_1; i++) {
      sincos (angle, xy.x, xy.y);
      xy *= radius;
      retval += tex2D (s_Input, uv + xy);
      retval += tex2D (s_Input, uv - xy);
      angle  += ANGLE_1;
   }

   retval /= DIVISOR_1;

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (s_Input, uv);

   if ((Opacity == 0.0) || (Radius == 0.0)) return Fgd;

   float4 retval = (0.0).xxxx;
   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Radius * Radius * RADIUS_2;
   float angle = 0.0;

   for (int i = 0; i < LOOP_2; i++) {
      sincos (angle, xy.x, xy.y);
      xy *= radius;
      retval += tex2D (s_preBlur, uv + xy);
      retval += tex2D (s_preBlur, uv - xy);
      angle  += ANGLE_2;
   }

   retval /= DIVISOR_2;
   retval = lerp (Fgd, retval, Opacity);

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Antialias
{
   pass P_1
   < string Script = "RenderColorTarget0 = preBlur;"; >
   { PixelShader = compile PROFILE ps_pass_1 (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
