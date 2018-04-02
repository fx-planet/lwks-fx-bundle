// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect CameraDistortions.fx
//
// Created by LW user jwrl 12 March 2016
// @Author jwrl
// @CreationDate "12 March 2016"
//
// This effect was suggested by CubicLensDistortion.fx by
// Lightworks user brdloush.  This implementation is my own,
// based on the cubic lens distortion algorithm from SSontech
// (Syntheyes) - http://www.ssontech.com/content/lensalg.htm
// 
//     r2 = image_aspect*image_aspect*u*u + v*v
//     f = 1 + r2*(k + kcube*sqrt(r2))
//     u' = f*u
//     v' = f*v
//
// Although brdloush's version was based on code published by
// François Tarlier in 2010, this version re-implements the
// original Ssontech algorithm, and uses none of M. Tarlier's
// code.  I have deliberately maintained the variable names
// used in the algorithm for consistency.
//
// The most notable difference is the use of float2 variables
// for screen coordinate mathematics wherever possible.  This
// means that some parts require indexing where they didn't
// in the original algorithm.  It also means that overall the
// code is much simpler and will execute faster.  For example
// the last two lines shown above can now be expressed as a
// single line, viz:
//
//     uv'= f*uv
//
// which executes as a single function but is equivalent to
//
//     uv'.x = f*uv.x
//     uv'.y = f*uv.y
//
// The centring function is additional to any of the published
// work as far as I'm aware, and is entirely my own.  Also new
// is a means of automatically scaling the image while using
// the basic distortion.  This only applies to positive values
// of the basic distortion and doesn't apply at all to cubic
// distortion.
//
// I also understand that one implementation of this algorithm
// had chromatic aberration correction.  I've done something
// similar, providing both optical and electronic aberrations.
// As far as I'm aware these are both original work.
//
// Optical color artefacts are applied prior to distortion, and
// electronic artefacts are applied after it.  This ensures that
// lens fringing stays inside the image boundary while colour
// registration errors affect the whole frame.
//
// All of the above notwithstanding, you can do what you will
// with this effect.  It would be nice to be credited if you
// decide to use it elsewhere or change it in any way - jwrl.
//
// Version 14 update 18 Feb 2017 jwrl: Added subcategory to
// effect header.
//
// Cross platform compatibility check 2 August 2017 jwrl.
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Rewrote ps_lens() to speed things up a little by doing less
// multiply operations in the loops and where possible by
// making any mathematical processes work on float2 variables
// rather than individually on two floats.
//
// Version 14.5 update 28 March 2018 by jwrl.
//
// Added LINUX and OSX test to allow support for changing
// "Clamp" to "ClampToEdge" on those platforms.  It will now
// function correctly when used with Lightworks versions 14.5
// and higher under Linux or OS-X and fixes a bug associated
// with using this effect with transitions on those platforms.
//
// The bug still exists when using older versions of Lightworks.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Camera distortions";
   string Category    = "Stylize";
   string SubCategory = "Simulation";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture L_Ab_Out : RenderColorTarget;
texture Dist_Out : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef OSX
#define Clamp ClampToEdge
#endif

sampler FgSampler   = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler L_AbSampler = sampler_state
{
   Texture   = <L_Ab_Out>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler DistSampler = sampler_state
{
   Texture   = <Dist_Out>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

bool k_sc
<
   string Group = "Distortion";
   string Description = "Enable basic distortion autoscaling";
> = false;

float k
<
   string Group = "Distortion";
   string Description = "Basic";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float kcube
<
   string Group = "Distortion";
   string Description = "Cubic";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Scale
<
   string Group = "Distortion";
   string Description = "Scale";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.00;

float Ana
<
   string Group = "Distortion";
   string Description = "Anamorphic";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.00;

int SetTechnique
<
   string Group = "Chromatic aberration";
   string Description = "Camera type";
   string Enum = "Single chip,Single chip (portrait),Three chip,Three chip (portrait)";
> = 0;

float l_ab
<
   string Group = "Chromatic aberration";
   string Description = "Optical errors";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.00;

float d_ab_X
<
   string Group = "Chromatic aberration";
   string Description = "Electronic errors";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.00;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define STEPS     12
#define FRNG_INC  1.0/STEPS      // 0.08333333

#define DICHROIC  0.01
#define CHIP_ERR  0.0025
#define DISTORT   0.35355339

#define HORIZ     true
#define VERT      false

#define EMPTY     0.0.xxxx
#define BLACK     float2(0.0,1.0).xxxy

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_lens (float2 uv : TEXCOORD1) : COLOR
{
   if (l_ab == 0.0) return tex2D (FgSampler, uv);

   float4 retval = BLACK;

   float2 centre = float2 (Xcentre, 1.0 - Ycentre);
   float2 fringe, xy = uv - centre;

   float fringing = 0.0;
   float strength = 1.0;
   float str_diff = (l_ab / 100.0) * length (xy);

   for (int i = 0; i < STEPS; i++) {
      fringe = tex2D (FgSampler, (xy * strength) + centre).rg / STEPS;

      retval.rg += fringe * float2 (1.0 - fringing, fringing);

      fringing += FRNG_INC;
      strength -= str_diff;
   }

   for (int i = 0; i < STEPS; i++) {
      fringe = tex2D (FgSampler, (xy * strength) + centre).gb / STEPS;

      retval.gb += fringe * float2 (2.0 - fringing, fringing - 1.0);

      fringing += FRNG_INC;
      strength -= str_diff;
   }

   for (int i = 0; i < STEPS; i++) {
      fringe = tex2D (FgSampler, (xy * strength) + centre).rb / STEPS;

      retval.rb += fringe * float2 (fringing - 2.0, 3.0 - fringing);

      fringing += FRNG_INC;
      strength -= str_diff;
   }

   return retval;
}

float4 ps_distort (float2 uv : TEXCOORD1) : COLOR
{
   float autoscale [] = { 1.0,    0.8249, 0.7051, 0.6175, 0.5478, 0.4926, 0.4462,
                          0.4093, 0.3731, 0.3476, 0.3243, 0.3039, 0.286,  0.2707,
                          0.2563, 0.2435, 0.2316, 0.2214, 0.2116, 0.2023, 0.1942 };

   if ((k == 0.0) && (kcube == 0.0) && (Scale == 0.0) && (Ana == 0.0)) return tex2D (L_AbSampler, uv);

   float sa, s1 = 1.0 - Scale;

   if (k_sc) {
      float a_s0 = saturate (k) * 20;
      float a_s1 = floor (a_s0);
      float a_s2 = ceil (a_s0);

      sa = autoscale [a_s1];

      if (a_s1 != a_s2) {
         a_s0 -= a_s1;
         a_s0  = sqrt (a_s0 / 9) + (0.666667 * a_s0);
         sa = lerp (sa, autoscale [a_s2], a_s0);
      }
   }
   else sa = 1.0;

   float2 sf = saturate (-Scale) * DISTORT;
   float  sX = saturate (Ana);
   float  sY = saturate (-Ana);

   sX = sX * sX * DISTORT;
   sY = sY * sY * DISTORT;
   sf = (sf * sf) + (s1 * s1 / 2.0) - float2 (sX, sY);

   float2 c = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = 2.0 * (uv - c);

   float r2 = _OutputAspectRatio * _OutputAspectRatio * xy.x * xy.x + xy.y * xy.y;
   float f  = (kcube == 0.0) ? 1.0 + r2 * k : 1.0 + r2 * (k + kcube * sqrt (r2));

   xy = (xy * f * sf * sa) + c;

   float2 xy1 = abs (xy - saturate (xy));
   float  ofw = xy1.x + xy1.y;

   if (ofw != 0.0) return EMPTY;

   return tex2D (L_AbSampler, xy);
}

float4 ps_single (float2 uv : TEXCOORD1, uniform bool is_horiz) : COLOR
{
   if (d_ab_X == 0.0) return tex2D (DistSampler, uv);

   float offset = d_ab_X * CHIP_ERR;
   float2 xy1, xy2;

   if (is_horiz) {
      offset /= _OutputAspectRatio;
      xy1 = float2 (uv.x - offset, uv.y);
      xy2 = float2 (uv.x + offset, uv.y);
   }
   else {
      xy1 = float2 (uv.x, uv.y - offset);
      xy2 = float2 (uv.x, uv.y + offset);
   }

   float4 retval = tex2D (DistSampler, xy1);

   retval.g = tex2D (DistSampler, xy2).g;

   return retval;
}

float4 ps_dichroic (float2 uv : TEXCOORD1, uniform bool is_horiz) : COLOR
{
  float4 retval = tex2D (DistSampler, uv);

   if (d_ab_X == 0.0) return retval;

   float offset = d_ab_X * DICHROIC;
   float2 xy1, xy2;

   if (is_horiz) {
      offset /= _OutputAspectRatio;
      xy1 = float2 (uv.x + offset, uv.y);
      xy2 = float2 (uv.x - offset, uv.y);
   }
   else {
      xy1 = float2 (uv.x, uv.y - offset);
      xy2 = float2 (uv.x, uv.y + offset);
   }

   retval.r = tex2D (DistSampler, xy1).r;
   retval.b = tex2D (DistSampler, xy2).b;

   return retval;
}

//--------------------------------------------------------------//
// Technique
//--------------------------------------------------------------//

technique OneChip
{
   pass P_1
   < string Script = "RenderColorTarget0 = L_Ab_Out;"; >
   { PixelShader = compile PROFILE ps_lens (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Dist_Out;"; >
   { PixelShader = compile PROFILE ps_distort (); }

   pass P_3
   { PixelShader = compile PROFILE ps_single (HORIZ); }
}

technique OneChip_p
{
   pass P_1
   < string Script = "RenderColorTarget0 = L_Ab_Out;"; >
   { PixelShader = compile PROFILE ps_lens (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Dist_Out;"; >
   { PixelShader = compile PROFILE ps_distort (); }

   pass P_3
   { PixelShader = compile PROFILE ps_single (VERT); }
}

technique ThreeChip
{
   pass P_1
   < string Script = "RenderColorTarget0 = L_Ab_Out;"; >
   { PixelShader = compile PROFILE ps_lens (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Dist_Out;"; >
   { PixelShader = compile PROFILE ps_distort (); }

   pass P_3
   { PixelShader = compile PROFILE ps_dichroic (HORIZ); }
}

technique ThreeChip_p
{
   pass P_1
   < string Script = "RenderColorTarget0 = L_Ab_Out;"; >
   { PixelShader = compile PROFILE ps_lens (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Dist_Out;"; >
   { PixelShader = compile PROFILE ps_distort (); }

   pass P_3
   { PixelShader = compile PROFILE ps_dichroic (VERT); }
}

