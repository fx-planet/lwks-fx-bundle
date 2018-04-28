// @Maintainer jwrl
// @Released 2018-04-28
// @Author jwrl
// @Created 2016-02-10
// @see https://www.lwks.com/media/kunena/attachments/6375/DX_ColourTile_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_ColourTile.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_ColourTile.fx
//
// This obliterates the outgoing image with a mosaic pattern of highly coloured tiles
// that progressively fill the screen to halfway through the effect.  It then removes
// the tiles progressively to show the incoming image.  The tile build and "un-build"
// are from the brightest to the darkest sections of a dissolve between the two images
// and back again.  This makes the linearity of this effect highly dependant on the
// black/white balance between the two images used.  If this is important to you, you
// can adjust it by adding intermediate keyframes within the transition.
//
// Modified 2018-04-28 by jwrl.
// This effect was originally developed not long after Dx_Blocks.fx, but never released.
// At the time I was using a simple noise source to generate the coloured tiles but was
// never happy with the result.  There was way too much white for my liking.  However I
// found it while going through my development history, did some code cleanup, changed
// the noise generation shader to the one I now use here, and this is the result.
//
// Attribution:
// The code in this effect is original work by Lightworks user jwrl, and developed for
// use in the Lightworks non-linear editor. Should this effect be ported to another edit
// platform or used in part or in whole in an effect in any other non-linear editor this
// attribution must be included. Negotiations to modify or suspend this requirement can
// be undertaken by contacting jwrl at www.lwks.com, where the original effect plus the
// software on which it was designed to run may also be found.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Coloured tiles";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Tiles : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Outgoing = sampler_state { Texture = <Fg>; };
sampler s_Incoming = sampler_state { Texture = <Bg>; };

sampler s_Tiles = sampler_state { Texture = <Tiles>; };

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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI 1.5707963268
#define SCALE   float3(1.2, 0.8, 1.0)     // According to my made-up theory this should be
                                          // 0.8, 1.2, 1.0, but that doesn't look as good
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This sets up a mix between the two sources and uses it to generate a colour pseudo
// random noise pattern which in turn is later used to generate the mosaic wipe.

float4 ps_mix (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 retval = tex2D (s_Outgoing, xy1);

   retval = lerp (retval, tex2D (s_Incoming, xy2), Amount);

   // This next section was produced empirically.  What I wanted was to produce colour
   // noise that was more than just RGB pixels, but more subtle mixes of those primaries.
   // I experimented with various combinations of things until I had a satisfying mix.

   float a, b;

   sincos (Amount * HALF_PI, a, b);
   retval.rgb = min (abs (retval.rgb - float3 (a, b, frac ((xy1.x + xy1.y) * 1.2345 + Amount))), 1.0);
   retval.a   = 1.0;

   float3 x = retval.aga;

   for (int i = 0; i < 32; i++) {
      retval.rgb = SCALE * abs (retval.gbr / dot (retval.brg, retval.rgb) - x);
   }

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float Tscale  = TileSize * 0.2;                    // Prescale the tile size by 1/5
   float mosaic  = max (0.00000001, Tscale * 0.2);    // Scale mosaic and prevent zero values

   // We perform a slight zoom which is dependant on the tile size.  This is a nice
   // enhancement to the effect and also has the effect of ensuring that we never run
   // off the edges of the noise pattern when sampling the mosaic.

   float2 xy = (uv * (1.0 - Tscale)) + (Tscale * 0.5).xx;

   // Generate the mosaic addressing, compensating for the aspect ratio

   xy.x    = (round ((xy.x - 0.5) / mosaic) * mosaic) + 0.5;
   mosaic *= _OutputAspectRatio;
   xy.y    = (round ((xy.y - 0.5) / mosaic) * mosaic) + 0.5;

   // This recovers the required input depending on whether the transition has passed the
   // halfway point or not.  It also recovers a gated version of the same source for use
   // in generating the coloured mosaic tiles.

   float4 retval, gating;

   if (Amount < 0.5) {
      retval = tex2D (s_Outgoing, uv);
      gating = tex2D (s_Outgoing, xy);
   }
   else {
      retval = tex2D (s_Incoming, uv);
      gating = tex2D (s_Incoming, xy);
   }

   // The reference tile level depending on the luminance value of the gated source is now
   // calculated, and a range value that ramps from 1.0 to 0.0 to 1.0 again is produced.

   float level = (gating.r + gating.g + gating.b + gating.b) * 0.25;
   float range = abs ((2.0 * Amount) - 1.0);

   // Finally if the gating level exceeds the expected range we show the tile colour.

   return (level >= range) ? tex2D (s_Tiles, xy) : retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ColourMod
{
   pass P_1
   < string Script = "RenderColorTarget0 = Tiles;"; > 
   { PixelShader = compile PROFILE ps_mix (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

