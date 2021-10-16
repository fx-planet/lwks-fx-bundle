// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_ColourTile_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_ColourTile.mp4

/**
 This obliterates the outgoing image with a mosaic pattern of highly coloured tiles that
 progressively fill the screen to halfway through the effect.  It then removes the tiles
 progressively to show the incoming image.  The tile build and "un-build" are from the
 brightest to the darkest sections of a dissolve between the two images and back again.
 This makes the linearity of this effect highly dependant on the black/white balance
 between the two images used.  If this is important to you, you can adjust it by adding
 intermediate keyframes within the transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourTile_Dx.fx
//
// Version history:
//
// Built 2021-07-24 jwrl.
// Build date does not reflect upload date because of forum upload problems.
// This rebuild addresses a problem with the original mosaic generation when applied to
// sources of differing aspect ratios and/or sizes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Coloured tiles";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Transitions between images using a mosaic pattern of highly coloured tiles";
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

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define HALF_PI 1.5707963268
#define SCALE   float3(1.2, 0.8, 1.0)     // According to my made-up theory this should be
                                          // 0.8, 1.2, 1.0, but that doesn't look as good
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Tiles, s_Tiles);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float TileSize
<
   string Description = "Tile size";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This sets up a mix between the two sources and uses it to generate a colour pseudo
// random noise pattern which in turn is later used to generate the mosaic wipe.

float4 ps_mix (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 retval = GetPixel (s_Foreground, uv1);

   retval = lerp (retval, GetPixel (s_Background, uv2), Amount);

   // This next section was produced empirically.  What I wanted was to produce colour
   // noise that was more than just RGB pixels, but more subtle mixes of those primaries.
   // I experimented with various combinations of things until I had a satisfying mix.

   float a, b;

   sincos (Amount * HALF_PI, a, b);
   retval.rgb = min (abs (retval.rgb - float3 (a, b, frac ((uv1.x + uv1.y) * 1.2345 + Amount))), 1.0);
   retval.a   = 1.0;

   float3 x = retval.aga;

   for (int i = 0; i < 32; i++) {
      retval.rgb = SCALE * abs (retval.gbr / dot (retval.brg, retval.rgb) - x);
   }

   return retval;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float Tscale  = TileSize * 0.2;                    // Prescale the tile size by 1/5

   // Generate the mosaic size, compensating for the aspect ratio

   float2 mosaic = float2 (1.0, _OutputAspectRatio) * max (1.0e-6, Tscale * 0.2);

   // We perform a slight zoom which is dependent on the tile size.  This ensures that
   // we never run off the edges of the noise pattern when sampling the mosaic.  The
   // mosaic address is generated for each of the three video sources, which are Fg,
   // Bg and sequence.

   float2 Mscale = (1.0 - Tscale) / mosaic;

   float2 xy1 = (round ((uv1 - 0.5.xx) * Mscale) * mosaic) + 0.5.xx;
   float2 xy2 = (round ((uv2 - 0.5.xx) * Mscale) * mosaic) + 0.5.xx;
   float2 xy3 = (round ((uv3 - 0.5.xx) * Mscale) * mosaic) + 0.5.xx;

   // This recovers the required input depending on whether the transition has passed the
   // halfway point or not.  It also recovers a gated version of the source to be used in
   // generating the coloured mosaic tiles.

   float4 gating = lerp (GetPixel (s_Foreground, xy1), GetPixel (s_Background, xy2), Amount);
   float4 retval = (Amount < 0.5) ? GetPixel (s_Foreground, uv1) : GetPixel (s_Background, uv2);

   // The reference tile level depending on the luminance value of the gated source is now
   // calculated, and a range value that runs from 1.0 to 0.0 back to 1.0 again is produced.

   float level = max (gating.r, max (gating.g, gating.b));
   float range = abs (Amount - 0.5) * 2.0;

   // Finally if the gating level exceeds the expected range we show the tile colour.

   return (level >= range) ? GetPixel (s_Tiles, xy3) : retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ColourMod
{
   pass P_1 < string Script = "RenderColorTarget0 = Tiles;"; > ExecuteShader (ps_mix)
   pass P_2 ExecuteShader (ps_main)
}

