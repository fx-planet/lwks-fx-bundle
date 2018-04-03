// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect GhostBlur.fx
//
// Created by LW user jwrl May 9 2016 as YAblur.fx.
// @Author jwrl
// @Created "May 9 2016"
//
// This was an accident that looked interesting, so it was
// given a name and developed.  It is based on a radial
// anti-aliassing blur developed for another series of
// effects, further modulated by image content.
//
// Modified by jwrl 29 July 2017.
//
// Renamed from YAblur to Ghost blur - it feels more like the
// result that you get.  Opacity and Radius limiting added so
// that negative values of either will not be acted on.  Added
// a fogginess adjustment.  Really a gamma tweak applied while
// sampling the blur, it's also range limited to ensure that
// whiter than white video levels are controlled.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Ghost blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture prelim : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state {
        Texture   = <Input>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
        };

sampler preSampler = sampler_state {
        Texture   = <prelim>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
        };

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Radius
<
   string Description = "Radius";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float Fog
<
   string Description = "Fogginess";
   float MinVal       = -1.0;
   float MaxVal       = 1.0;
> = 0.0;

float Opacity
<
   string Description = "Amount";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 1.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define LOOP_1   29
#define RADIUS_1 0.1
#define ANGLE_1  0.216662

#define LOOP_2   23
#define RADIUS_2 0.066667
#define ANGLE_2  0.273182

#define FOG_LIM  0.8
#define FOG_MIN  0.4
#define FOG_MAX  4.0

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_prelim (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (FgSampler, uv);

   if ((Opacity <= 0.0) || (Radius <= 0.0)) return Fgd;

   float gamma = (Fog > 0.0) ? 1.0 - min (Fog * FOG_MIN, FOG_LIM) : 1.0 + abs (Fog) * FOG_MAX;

   float2 xy, radius = float2 (1.0 - Fgd.b, Fgd.r + Fgd.g) * Radius * RADIUS_1;

   float4 retval = 0.0.xxxx;

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy.x, xy.y);
      retval += pow (tex2D (FgSampler, uv + (xy * radius)), gamma);
   }

   retval /= LOOP_1;

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (FgSampler, uv);

   if ((Opacity <= 0.0) || (Radius <= 0.0)) return Fgd;

   float4 retval = tex2D (preSampler, uv);

   float2 xy, radius = float2 (retval.r + retval.b, 1.0 - retval.g) * Radius * RADIUS_2;

   float gamma = (Fog > 0.0) ? 1.0 - min (Fog * FOG_MIN, FOG_LIM) : 1.0 + abs (Fog) * FOG_MAX;

   retval = 0.0.xxxx;

   for (int i = 0; i < LOOP_2; i++) {
      sincos ((i * ANGLE_2), xy.x, xy.y);
      retval += pow (tex2D (preSampler, uv + (xy * radius)), gamma);
   }

   retval /= LOOP_2;

   return lerp (Fgd, saturate (retval), Opacity);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique SampleFxTechnique
{
   pass P_1
   < string Script = "RenderColorTarget0 = prelim;"; >
   { PixelShader = compile PROFILE ps_prelim (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
