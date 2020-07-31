// @Maintainer jwrl
// @Released 2020-07-31
// @Author jwrl
// @Created 2016-02-12
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Mosaic_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Mosaic.mp4

/**
 This obliterates the outgoing image with a mosaic pattern that progressively fills the
 screen to halfway through the effect.  It then removes the mosaic progressively to show
 the incoming image.  The mosaic build and the incoming reveal are both from the darkest
 to the brightest sections of a 50 percent mix of the two images, making the progression
 in and out reasonably logical.

 The linearity of this effect is highly dependant on the black/white balance between the
 two images used.  If this is important to you, you can adjust it by adding intermediate
 keyframes within the transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Mosaic_Dx.fx
//
// Version history:
//
// Modified 2020-07-31 jwrl.
// Removed redundant technique producing the mosaic.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 2018-04-21 by jwrl.
// This effect was originally developed not long after Dx_Blocks.fx, but never released.
// It was an attempt to produce the mosaic tiles used in that effect without relying on
// Editshare code, but I felt at the time that I had never really succeeded in doing that.
// However I found it while going through my development history, did some code cleanup,
// changed the mix section to the more efficient one used in Dx_Erosion.fx, and this is
// the result.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Mosaic transfer";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Obliterates the outgoing image into expanding blocks as it fades to the incoming image";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Outgoing = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Incoming = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float Tscale  = TileSize * 0.2;                    // Prescale the tile size by 1/5
   float mosaic  = max (0.00000001, Tscale * 0.2);    // Scale mosaic and prevent zero values
   float range_1 = Amount * 2.0;                      // range_1 reaches 1.0 at 50% point
   float range_2 = max (0.0, range_1 - 1.0);          // range_2 starts at 50% point

   // We perform a slight zoom in the size of which is dependant on the tile size.  While
   // this is a nice enhancement to the effect, it also has the extremely practical effect
   // of ensuring that we never run off the edges of the frame when sampling the mosaic.

   float2 xy = (uv * (1.0 - Tscale)) + (Tscale * 0.5).xx;

   // Generate the mosaic addressing, compensating for the aspect ratio

   xy.x    = (round ((xy.x - 0.5) / mosaic) * mosaic) + 0.5;
   mosaic *= _OutputAspectRatio;
   xy.y    = (round ((xy.y - 0.5) / mosaic) * mosaic) + 0.5;

   // Ensure that range_1 can't overflow

   range_1 = min (range_1, 1.0);

   // This produces the 50% mixed mosaic then does a level dependant mix from Fg to
   // the mosaic for the first half of the transition, followed by a level dependant
   // mix from the mosaic to Bg for the second half of the transition.

   float4 m_1 = (tex2D (s_Incoming, xy) + tex2D (s_Outgoing, xy)) * 0.5;
   float4 m_2 = max (m_1.r, max (m_1.g, m_1.b)) >= range_1 ? tex2D (s_Outgoing, uv) : m_1;

   return max (m_2.r, max (m_2.g, m_2.b)) >= range_2 ? m_2 : tex2D (s_Incoming, uv);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique mosaic
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
