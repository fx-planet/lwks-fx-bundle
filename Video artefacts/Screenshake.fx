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
// Added effects header block and a rudimentary description.
// Changed the Border addressing to ClampToEdge, since the behaviour of Border differs
// between Windows and Linux / OS/X.
// Added check for _LENGTH to check for version 14.5 or better.  The effect will fail
// if earlier versions of Lightworks are used.
// Changed subcategory from "User Effects" to "Video artefacts" for consistency with other
// effects library categories.
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

float3 random3(float3 c) 
{
    float j = 4096.0*sin(dot(c,float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = frac(512.0*j);
    j *= .125;
    r.x = frac(512.0*j);
    j *= .125;
    r.y = frac(512.0*j);
    return r;
}

float simplex3d(float3 p) 
{    
    float3 s = floor(p + dot(p, float3(F3.xxx)));
    float3 x = p - s + dot(s, float3(G3.xxx));
    
    float3 e = step(float3(0.0.xxx), x - x.yzx);
    float3 i1 = e*(1.0 - e.zxy);
    float3 i2 = 1.0 - e.zxy*(1.0 - e);
        
    float3 x1 = x - i1 + G3;
    float3 x2 = x - i2 + 2.0*G3;
    float3 x3 = x - 1.0 + 3.0*G3;
    
    float4 w, d;
    
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w  = dot(x3, x3);
    
    w = max(0.6 - w, 0.0);
    
    d.x = dot(random3(s)-.5, x);
    d.y = dot(random3(s + i1)-.5, x1);
    d.z = dot(random3(s + i2)-.5, x2);
    d.w = dot(random3(s + 1.0)-.5, x3);

    w *= w;    w *= w;    d *= w;   //**
	 
    return dot(d, float4(52.0.xxxx));
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_Screenshake(float2 uv : TEXCOORD ) : COLOR
{    
    uv = (uv + 0.02.xx) / 1.04.xx;   //** zoom
    
    float3 p3 = float3(0,0, iTime * speed) * 8.0 + 200.0;

    float2 noise = float2(simplex3d(p3), simplex3d(p3 + 10.0)) * strength/30;

    return float4( tex2D( s_Fg, uv + noise).rgb, 1.0);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique tech_Screenshake {pass one {PixelShader = compile PROFILE ps_Screenshake (); }}

