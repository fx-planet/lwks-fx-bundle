// @Maintainer jwrl
// @Released 2020-05-19
// @Author hugly
// @Author flyingrub https://www.shadertoy.com/view/wsBXWW
// @Created 2019-09-07
// @see https://www.lwks.com/media/kunena/attachments/6375/ScreenShake_640.png

/**
 This effect adds an adjustable pseudo-random shake to the screen.  So that the edges of the
 frame aren't seen the image is zoomed in slightly.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Screenshake.fx
//
// Ported to HLSL/Cg and adapted for Lightworks by hugly 2019-09-07
//
// Modified jwrl 2020-05-18.
// In order of application, the changes are:
//   Preserved Fg alpha channel throughout.
//   Added frac() to the time calculation to prevent speed overflow causing the shake to
//   stop prematurely.
//   Rewrote function random3() to reduce the maths operations.
//   Rewrote function simplex3d() to correct all implicit float3 conversions which wouldn't
//   have worked in Linux and OS/X.  Also simplified it to reduce the maths operations.
//   Added effects header block and a rudimentary description.
//   Changed subcategory from "User Effects" to "Video artefacts" for consistency with
//   other effects library subcategories.
//   Changed the sampler addressing to ClampToEdge, since the behaviour of Border differs
//   between Windows and Linux / OS/X.
//   Added check for _LENGTH to check for version 14.5 or better.  The effect will now
//   fail if earlier versions of Lightworks are used.
//
// Modified jwrl 2020-05-19.
// Changed frac (time) to frac (time / 13.0) and scaled the result by 13.  Since it was
// already scaled by 8, it is now scaled by 104.  This was done because a simple frac()
// gave a result that was too obviously cyclic.  Dividing by a prime number that is not
// related to a standard frame rate helps that.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Screen shake";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Random screen shake, slightly zoomed in, no motion blur";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Fg = sampler_state
{
   Texture   = <Fg>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float strength
<  string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float speed
<  string Description = "Speed";
   float MinVal = 0.4;
   float MaxVal = 2.0;
> = 1;

//-----------------------------------------------------------------------------------------//
// Global Declarations
//-----------------------------------------------------------------------------------------//

// This produces a compiler error if this is installed in version 14 or earlier.

#ifndef _LENGTH
Bad Lightworks version
#endif

uniform float _Progress;
uniform float _Length;

#define iTime (_Length * _Progress) 

#define SIXTH_3 0.1666667.xxx
#define THIRD_3 0.3333333.xxx
#define HALF_3  0.5.xxx
#define ONE_3   1.0.xxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 random3 (float3 c)
{
   float j = 4096.0 * sin (dot (c, float3 (17.0, 59.4, 15.0)));

   return frac (float3 (512.0, 64.0, 8.0) * j);
}

float simplex3d (float3 p)
{    
   float3 s = floor (p + dot (p, THIRD_3).xxx);
   float3 x = p - s + dot (s, SIXTH_3).xxx;

   float3 e  = step (0.0.xxx, x - x.yzx);
   float3 i1 = e * (ONE_3 - e.zxy);
   float3 i2 = ONE_3 - e.zxy * (ONE_3 - e);

   float3 x1 = x - i1 + SIXTH_3;
   float3 x2 = x - i2 + THIRD_3;
   float3 x3 = x - HALF_3;

   float4 w = float4 (dot (x, x), dot (x1, x1), dot (x2, x2), dot (x3, x3));

   w  = pow (max (0.6.xxxx - w, 0.0.xxxx), 4.0);
   w *= float4 (dot (random3 (s) - HALF_3, x), dot (random3 (s + i1) - HALF_3, x1),
                dot (random3 (s + i2) - HALF_3, x2), dot (random3 (s + ONE_3) - HALF_3, x3));

   return dot (w, 52.0.xxxx);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_Screenshake (float2 uv : TEXCOORD1) : COLOR
{    
   float2 xy = (uv + 0.02.xx) / 1.04.xx;   //** zoom

   float3 p3 = float3 (0.0.xx, frac (iTime / 13.0) * speed * 104.0) + 200.0.xxx;

   xy += float2 (simplex3d (p3), simplex3d (p3 + 10.0.xxx)) * strength / 30.0;

   return tex2D (s_Fg, xy);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique tech_Screenshake {pass one {PixelShader = compile PROFILE ps_Screenshake (); }}
