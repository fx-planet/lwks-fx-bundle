// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Lightworks effect Dx_Transmogrify.fx
//
// Created by Lightworks user jwrl 10 May 2016.
// @Author: jwrl
// @CreationDate: "10 May 2016"
//
// This is is a truly bizarre transition.  Sort of a stripy
// blurry dissolve, I guess.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  When a height parameter is needed one
// cannot use _OutputHeight because it returns only half the
// actual frame height when interlaced media is playing.  In
// this effect the output height is obtained by dividing
// _OutputWidth by _OutputAspectRatio.  This is reliable
// regardless of the pixel aspect ratio or interlace mode.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Swizzled two float variables to float2.  This addresses the
// the behavioural differences between D3D and Cg compilers.
//
// Update August 10 2017 by jwrl - renamed from Transmogrify.fx
// for consistency across the dissolve range.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Transmogrify";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state {
        Texture   = <Fg>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
        };

sampler BgSampler = sampler_state {
        Texture   = <Bg>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
        };

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.0;

//--------------------------------------------------------------//
// Definitions and stuff
//--------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

float _Progress;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixSize = (uv / float2 (_OutputWidth, _OutputWidth / _OutputAspectRatio));

   float  rand = frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754);

   float2 xy1 = lerp (uv, saturate (pixSize + (sqrt (_Progress) - 0.5).xx + (uv * rand)), Amount);
   float2 xy  = saturate (pixSize + (sqrt (1.0 - _Progress) - 0.5).xx + (uv * rand));
   float2 xy2 = lerp (float2 (xy.x, 1.0 - xy.y), uv, Amount);

   float4 Fgd = tex2D (FgSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);

   return lerp (Fgd, Bgd, Amount);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique transmogrify
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

