// @Maintainer jwrl
// @Released 2020-05-18
// @Author flyingrub https://www.shadertoy.com/view/wsBXWW
// @Author hugly
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
// Modified jwrl 2020-05-18:
// Preserved Fg alpha channel throughout.
// Added effects header block and a rudimentary description.
// Changed the Border addressing to ClampToEdge, since the behaviour of Border differs
// between Windows and Linux / OS/X.
// Added check for _LENGTH to check for version 14.5 or better.  The effect will fail
// if earlier versions of Lightworks are used.
// Changed subcategory from "User Effects" to "Video artefacts" for consistency with other
// effects library categories.
// Rewrote function random3() to reduce the maths operations.
// Rewrote function simplex3d() to correct the implicit float3 conversions which wouldn't
// have worked in Linux and OS/X.
// Added frac() to the time calculation to prevent speed overflow causing the shake to
// stop prematurely.
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

#ifndef _LENGTH
Bad Lightworks version
#endif

uniform float _Progress;
uniform float _Length;

#define iTime (_Length * _Progress) 

#define F3 0.3333333
#define G3 0.1666667

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
   float3 s = floor (p + dot (p, F3.xxx).xxx);
   float3 x = p - s + dot (s, G3.xxx).xxx;

   float3 e = step (0.0.xxx, x - x.yzx);
   float3 i1 = e * (1.0.xxx - e.zxy);
   float3 i2 = 1.0.xxx - e.zxy * (1.0.xxx - e);

   float3 x1 = x - i1 + G3;
   float3 x2 = x - i2 + 2.0 * G3;
   float3 x3 = x - 1.0.xxx + 3.0 * G3;

   float4 w = float4 (dot (x, x), dot (x1, x1), dot (x2, x2), dot (x3, x3));

   w = pow (max (0.6.xxxx - w, 0.0.xxxx), 4.0);

   float4 d = float4 (dot (random3 (s) - 0.5.xxx, x), dot (random3 (s + i1) - 0.5.xxx, x1),
                      dot (random3 (s + i2) - 0.5.xxx, x2), dot (random3 (s + 1.0.xxx) - 0.5.xxx, x3));

   return dot (d * w, 52.0.xxxx);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_Screenshake (float2 uv : TEXCOORD1) : COLOR
{    
   float2 xy = (uv + 0.02.xx) / 1.04.xx;   //** zoom

   float3 p3 = float3 (0.0.xx, frac (iTime * speed)) * 8.0 + 200.0.xxx;

   xy += float2 (simplex3d (p3), simplex3d (p3 + 10.0.xxx)) * strength / 30.0;

   return tex2D (s_Fg, xy);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique tech_Screenshake {pass one {PixelShader = compile PROFILE ps_Screenshake (); }}
