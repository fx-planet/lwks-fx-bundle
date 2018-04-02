// @ReleaseDate: 2018-03-31
// @Author: jwrl
// @CreationDate: "5 February 2017"
//--------------------------------------------------------------//
// ColourFilmAge.fx by Lightworks user jwrl 5 February 2017
//
// This effect mimics the aging of colour film.  It starts by
// emulating the fading of the film dye layers with age.  The
// default order is yellow, magenta, then cyan, but that order
// can be changed to the less common chemically induced yellow,
// cyan, magenta variant (I've only ever seen that once).
//
// Bleach bypass can also be applied in either the positive or
// negative domains, and a vibrance parameter adds an S-curve
// saturation adjustment.  Subjectively this gives a reasonably
// close approximation to the appearance of early Technicolor
// footage, although it makes no claim to be very accurate.
//
// Sprocket hole wear and tear can be emulated with separate
// horizontal and vertical adjustments.  Fixed size grain
// can also be applied, and is added prior to the dye layer
// fade process for consistency of emulation.
//
// The scratch generation has been adapted from the old time
// movie effect created by khaver, now supplied as standard
// with the Lightworks effects bundle.  The way that it has
// been implemented is very much my own so please don't blame
// him for any problems!  As with his effect the scratches
// can be created from either the video layer or an external
// damage input.
//
// The neg scratches fade as the dye layers do, which they
// would do in reality.  This has meant duplicating the
// scratch code, because the pos scratches must be opaque as
// the dye layers fade.  This doesn't seem to take too much
// in the way of resources and is worth the improvement in
// the look of the effect.  Duplication needs less overhead
// than it would as a function call.
//
// Because I haven't yet come up with a method of generating
// convincing (to me) neg and/or pos dirt, I have provided an
// external film dirt input instead.  I'm still trying to
// develop a simple, fast algorithm for this that doesn't
// yield square blocks.  Ideally, I would really like to have
// both dust and hairs generated internally, but I doubt if
// that would be realistically possible as a real-time effect.
//
// 31 July 2017 jwrl: Added flicker to the mix.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Colour film aging";
   string Category    = "Colour";
   string SubCategory = "Preset Looks";         // Added for LW14 - jwrl.
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Inp;
texture Dmg;
texture Drt;

texture Noise : RenderColorTarget;
texture Chem  : RenderColorTarget;
texture Weave : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InputSampler = sampler_state
{
   Texture   = <Inp>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Dmge_Sampler = sampler_state
{
   Texture   = <Dmg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Dirt_Sampler = sampler_state
{
   Texture   = <Drt>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler NoiseSampler = sampler_state
{
   Texture   = <Noise>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Chem_Sampler = sampler_state
{
   Texture   = <Chem>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler WeaveSampler = sampler_state
{
   Texture = <Weave>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Vibrance
<
   string Group = "Chemistry";
   string Description = "Vibrance";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float bBypass
<
   string Group = "Chemistry";
   string Description = "Bleach bypass";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

int BbPosNeg
<
   string Group = "Chemistry";
   string Description = "Bypass type";
   string Enum = "Positive,Negative";
> = 0;

float fadeDyes
<
   string Group = "Chemistry";
   string Description = "Dye aging";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

int dyePriority
<
   string Group = "Chemistry";
   string Description = "Dye permanence";
   string Enum = "Cyan fades last,Magenta fades last";
> = 0;

float Flicker
<
   string Group = "Chemistry";
   string Description = "Flicker";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float GrainAmount
<
   string Group = "Grain and dirt";
   string Description = "Grain Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float DirtAmount
<
   string Group = "Grain and dirt";
   string Description = "External dirt";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

int DirtSense
<
   string Group = "Grain and dirt";
   string Description = "Dirt media";
   string Enum = "Black on white,White on black";
> = 0;

int DirtPhase
<
   string Group = "Grain and dirt";
   string Description = "Dirt type";
   string Enum = "Positive,Negative";
> = 0;

float WeaveHoriz
<
   string Group = "Sprocket hole wear";
   string Description = "Horiz weave";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float WeaveVert
<
   string Group = "Sprocket hole wear";
   string Description = "Vert weave";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

bool UseSource
<
   string Group = "Scratches";
   string Description = "Use source video for scratch generation";
> = true;

float NegDamage
<
   string Group = "Scratches";
   string Description = "Neg seed";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float NegDamageSmooth
<
   string Group = "Scratches";
   string Description = "Neg smoothness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float NegDamageAmount
<
   string Group = "Scratches";
   string Description = "Neg opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float PosDamage
<
   string Group = "Scratches";
   string Description = "Pos seed";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosDamageSmooth
<
   string Group = "Scratches";
   string Description = "Pos smoothness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosDamageAmount
<
   string Group = "Scratches";
   string Description = "Pos opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

bool DamageTrack
<
   string Group = "Scratches";
   string Description = "Show damage track";
> = false;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define PI      3.1415927

#define POS     0
#define NEG     1

#define MAGENTA 1

#define F_SCALE 0.2

#define LUMA    float3(0.25,0.65,0.11)

float _Progress;

float _OutputWidth;
float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_noise (float2 uv : TEXCOORD0) : COLOR
{
   float4 retval = 1.0.xxxx;

   float2 dotProd = float2 (12.9898, 78.233);

   float scale = 43758.5453;

   retval.xy = uv * float2 (1.0, 1.0 / _OutputAspectRatio) * _OutputWidth;
   retval.xy = 3.0 * floor (retval.xy / 3.0);
   retval.xy = float2 (retval.x, retval.y * _OutputAspectRatio) * (_Progress + 0.5) / _OutputWidth;

   retval.x = frac (sin (dot (retval.xy, dotProd)) * scale);
   retval.y = frac (sin (dot (retval.xy, dotProd)) * scale);
   retval.z = frac (sin (dot (retval.xy, dotProd)) * scale);

   return retval;
}

float4 ps_damage (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (InputSampler, uv);
   float4 grain = tex2D (NoiseSampler, uv);
   float4 ret_1, ret_2;

   float lum;

   if (Vibrance > 0.0) {
      ret_1 = float4 (cos (Fgd.r * PI), cos (Fgd.g * PI), cos (Fgd.b * PI), 1.0);
      ret_2 = (1.0.xxxx - ret_1) / 2.0;
      lum = dot (ret_2.rgb, LUMA);
      Fgd.rgb = lerp (Fgd.rgb, saturate (Fgd.rgb + ret_2.rgb - lum.xxx), Vibrance);
   }

   if (GrainAmount > 0.0) { Fgd.rgb = lerp (Fgd.rgb, abs (Fgd.rgb - grain.rgb), GrainAmount / 3.0); }

   if (bBypass > 0.0) {
      float bypass = (BbPosNeg == POS) ? bBypass * Fgd.a : Fgd.a;

      lum = dot (Fgd.rgb, LUMA);
      ret_1 = 2.0 * lum * Fgd;
      ret_2 = (2.0 * (Fgd + lum)) - ret_1 - 1.0.xxxx;

      ret_1 = lerp (ret_1, ret_2, min (1.0, max (0.0, 10.0 * (lum - 0.45))));

      ret_1 *= bypass;
      ret_1 += (1.0 - bypass) * Fgd;

      if (BbPosNeg == NEG) {
         ret_1 = (2.0 * Fgd) - ret_1;
         lum   = (ret_1.r + ret_1.g + ret_1.b) / 3.0;
         ret_1 = lerp (Fgd, saturate (lum.xxxx + ((ret_1 - lum.xxxx) * 0.5)), bBypass);
      }

      Fgd.rgb = ret_1.rgb;
   }

   if ((DirtPhase == 1) && (DirtAmount > 0.0)) {
      ret_1 = tex2D (Dirt_Sampler, uv);
      ret_2 = (DirtSense == 0) ? 1.0.xxxx - ret_1 : ret_1;
      ret_1 = max (Fgd, ret_2);
      Fgd.rgb = lerp (Fgd.rgb, ret_1.rgb, DirtAmount);
   }

   float2 scratchSeed  = lerp (float2 (0.1, 0.9), float2 (0.9, 0.1), _Progress) * float2 (0.001, 0.4);

   scratchSeed.x = frac (uv.x + scratchSeed.x);

   float scratch = UseSource ? tex2D (InputSampler, scratchSeed.yx).g
                             : tex2D (Dmge_Sampler, scratchSeed.yx).g;

   scratch = (2.0 * scratch) + NegDamage - 1.5;
   scratch = ((scratch > 0.0) && (scratch < 0.005)) ? 1.0 : 0.0;
   scratch = min (scratch, max (NegDamageSmooth, max (grain.b, grain.r)));

   if (DamageTrack) {
      if (UseSource) return (min (0.5 + scratch, 1.0)).xxxx;

      return min (tex2D (Dmge_Sampler, uv) + scratch.xxxx, 1.0.xxxx);
   }

   Fgd.rgb = lerp (Fgd.rgb, min (Fgd.rgb + scratch.xxx, 1.0.xxx), NegDamageAmount);

   return Fgd;
}

float4 ps_weave (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = _Progress.xx;
   float2 dotProd = float2 (89.1298, 23.837);

   float scale = 45437.5853;

   xy.x = (frac (sin (dot (xy, dotProd)) * scale) - 0.5) / _OutputWidth;
   xy.y = (frac (sin (dot (xy, dotProd)) * scale) - 0.5) * _OutputAspectRatio / _OutputWidth;

   float flkr = 1.0 - (frac ((xy.x + xy.y)  * 5.0) * max ( 0.0, Flicker) * F_SCALE);

   xy *= float2 (WeaveHoriz, WeaveVert) * 10.0;
   xy += uv;

   float4 Fgd = tex2D (Chem_Sampler, xy);

   scale = frac ((_Progress + 0.5) * 12345.6789);
   Fgd = lerp (Fgd, tex2D (InputSampler, xy), scale);

   if ((fadeDyes <= 0.0) && (Flicker <= 0.0)) return Fgd;

   float Fade_1 = saturate (fadeDyes * 2.0);
   float Fade_2 = saturate ((fadeDyes - 0.333333) * 2.0);
   float Fade_3 = saturate ((fadeDyes - 0.666667) * 2.0);

   float4 retval, ret_1 = float3 (Fgd.g * 0.8, 0.8, Fgd.a).yxyz;
   float4 ret_2 = float3 (Fgd.r * 0.8, 0.8, Fgd.a).xyyz;

   if (dyePriority == MAGENTA) { retval = ret_1; ret_1 = ret_2; ret_2 = retval; }

   ret_1  = min (ret_1, ret_2);
   retval = lerp (Fgd, ret_1, Fade_1);
   retval = lerp (retval, ret_2, Fade_2);
   retval = lerp (retval, 0.8.xxxx, Fade_3);

   return float4 (pow (retval.rgb, flkr.xxx), Fgd.a);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (WeaveSampler, uv);

   float2 scratchTex = tex2D (NoiseSampler, uv).rb;
   float2 scratchSeed  = lerp (float2 (0.1, 0.1), float2 (0.9, 0.9), _Progress) * float2 (0.001, 0.4);

   scratchSeed.x = frac (uv.x + scratchSeed.x);

   float scratch = UseSource ? tex2D (InputSampler, scratchSeed).g
                             : tex2D (Dmge_Sampler, scratchSeed).g;

   scratch = (2.0 * scratch) + PosDamage - 1.5;
   scratch = ((scratch > 0.0) && (scratch < 0.005)) ? 1.0 : 0.0;
   scratch = min (scratch, max (PosDamageSmooth, max (scratchTex.x, scratchTex.y)));

   if (DamageTrack) return max (retval - scratch.xxxx, 0.0.xxxx);

   retval.rgb = lerp (retval.rgb, max (retval.rgb - scratch.xxx, 0.0.xxx), PosDamageAmount);

   if ((DirtPhase == 0) && (DirtAmount > 0.0)) {
      float4 Fgd = tex2D (Dirt_Sampler, uv);

      if (DirtSense == 1) { Fgd = 1.0.xxxx - Fgd; }

      Fgd = min (retval, Fgd);

      retval.rgb = lerp (retval.rgb, Fgd.rgb, DirtAmount);
   }

   return retval;
}

//--------------------------------------------------------------//
//  Technique
//--------------------------------------------------------------//

technique Film_Fx
{
   pass P_1
   < string Script = "RenderColorTarget0 = Noise;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Chem;"; >
   { PixelShader = compile PROFILE ps_damage (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Weave;"; >
   { PixelShader = compile PROFILE ps_weave (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

