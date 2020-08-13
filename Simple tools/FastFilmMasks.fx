// @Maintainer jwrl
// @Released 2020-08-14
// @Author jwrl
// @Created 2020-08-14
// @see https://www.lwks.com/media/kunena/attachments/6375/FastFilmMasks_640.png

/**
 This effect is a quick way to crop video to standard television and film aspect ratios.
 It also supports custom aspect ratios.  The result will be either letterboxed or pillar
 boxed, depending on the aspect ratio of the project.  Unlike the built-in Lightworks
 letterbox mode, this provides the ease and convenience of quick selection of a known
 preset aspect ratio or the ability to interactively set a custom aspect ratio using a
 simple fader control.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FastFilmMasks.fx
//
// Built 2020-08-14 jwrl.
// This effect is built on the same theory as used in the letterbox section of the older
// AnamorphicTools.fx.  Because it doesn't need to deal with the DVE components needed
// for anamorphic correction and resizing, it's very much simpler and faster than that
// earlier effect.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fast film masks";
   string Category    = "DVE";
   string SubCategory = "Simple tools";
   string Notes       = "A quick way of masking video to custom or standard film and TV aspect ratios";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Preset
<
   string Description = "Aspect ratio";
   string Enum = "1.33:1 (SD 4:3)," \
                 "1.375:1 (Classic academy)," \
                 "1.5:1 (VistaVision)," \
                 "1.66:1 (Super 16)," \
                 "1.78:1 (HD 16:9)," \
                 "1.85:1 (US widescreen)," \
                 "1.9:1 (2K)," \
                 "2.2:1 (70 mm/Todd-AO)," \
                 "2.35:1 (pre-1970 Cinemascope)," \
                 "2.39:1 (Panavision)," \
                 "2.76:1 (Ultra Panavision)," \
                 "3.5:1 (Ultra Wide Screen)," \
                 "Custom";
> = 5;

float Custom
<
   string Description = "Custom aspect:1";
   float MinVal = 0.5;
   float MaxVal = 4.0;
> = 1.78;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

float _aspect [] = { 1.3333333333, 1.375, 1.5, 1.6666666667, 1.7777777778,
                     1.85, 1.8962962963, 2.2, 2.35, 2.39, 2.76, 3.5 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float ratio = (Preset < 12) ? _aspect [Preset] : max (Custom, 1.0e-6);

   ratio /= _OutputAspectRatio;

   float2 xy = (ratio < 1.0) ? abs (float2 ((uv.x - 0.5) / ratio, uv.y - 0.5))
                             : abs (float2 (uv.x - 0.5, (uv.y - 0.5) * ratio));

   return (max (xy.x, xy.y) > 0.5) ? float4 (0.0.xxx, 1.0) : tex2D (s_Input, uv);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique FastFilmMasks
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
