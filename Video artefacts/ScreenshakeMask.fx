// @Maintainer jwrl
// @Released 2021-12-23
// @Author jwrl
// @Author hugly
// @Author flyingrub https://www.shadertoy.com/view/wsBXWW
// @Created 2021-12-23
// @see https://www.lwks.com/media/kunena/attachments/6375/ScreenShake_640.png

/**
 This effect adds an adjustable pseudo-random shake to the screen.  So that the edges of the
 frame aren't seen the image is zoomed in slightly.  Masking has also been provided for the
 cases where the background aspect ratio doesn't match the project.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ScreenShakeMask.fx
//
// Version history:
//
// Build 2021-11-01 jwrl.
// Modified hugly's effect based on flyingrub's original to add masking.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Screen shake with mask";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Random screen shake, slightly zoomed in, no motion blur";
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

uniform float _Progress;
uniform float _Length;

#define iTime (_Length * _Progress) 

#define SIXTH_3 0.1666667.xxx
#define THIRD_3 0.3333333.xxx
#define HALF_3  0.5.xxx
#define ONE_3   1.0.xxx

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Fg);
DefineInput (Mask, s_Mask);

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
> = 1.0;

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

float4 ps_Screenshake (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float2 xy = ((uv1 - 0.5.xx) / 1.04) + 0.5.xx;   //** zoom

   float3 p3 = float3 (0.0.xx, frac (iTime / 13.0) * speed * 104.0) + 200.0.xxx;

   xy += float2 (simplex3d (p3), simplex3d (p3 + 10.0.xxx)) * strength / 30.0;

   return Overflow (uv2) ? EMPTY : GetPixel (s_Fg, xy);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ScreenShakeMask { pass one ExecuteShader (ps_Screenshake) }

