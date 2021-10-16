// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
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
// Built 2021-07-17 jwrl.
// Build date does not reflect upload date because of forum upload problems.
// This rebuild addresses a problem with the original mosaic generation when applied to
// sources of differing aspect ratios and/or sizes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Mosaic transfer";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Obliterates the outgoing image into expanding blocks as it fades to the incoming image";
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

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Mixed, s_Mixed);

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
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mix (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
    float4 Fgnd = GetPixel (s_Foreground, uv1);
    float4 Bgnd = GetPixel (s_Background, uv2);

   return (Fgnd + Bgnd) / (Fgnd.a + Bgnd.a);
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float Tscale  = TileSize * 0.2;                    // Prescale the tile size by 1/5
   float mosaic  = max (0.00000001, Tscale * 0.2);    // Scale mosaic and prevent zero values
   float range_1 = Amount * 2.0;                      // range_1 reaches 1.0 at 50% point
   float range_2 = max (0.0, range_1 - 1.0);          // range_2 starts at 50% point

   // We perform a slight zoom in the size, which is dependant on the tile size.  While
   // this is a nice enhancement to the effect, it also has the extremely practical effect
   // of ensuring that we never run off the edges of the frame when sampling the mosaic.

   float2 xy = (uv3 * (1.0 - Tscale)) + (Tscale * 0.5).xx;

   // Generate the mosaic addressing, compensating for the aspect ratio

   xy.x    = (round ((xy.x - 0.5) / mosaic) * mosaic) + 0.5;
   mosaic *= _OutputAspectRatio;
   xy.y    = (round ((xy.y - 0.5) / mosaic) * mosaic) + 0.5;

   // Ensure that range_1 can't overflow

   range_1 = min (range_1, 1.0);

   // This produces the 50% mixed mosaic then does a level dependant mix from Fg to
   // the mosaic for the first half of the transition, followed by a level dependant
   // mix from the mosaic to Bg for the second half of the transition.

   float4 m_1 = GetPixel (s_Mixed, xy);               // GetPixel could really just be tex2D
   float4 m_2 = max (m_1.r, max (m_1.g, m_1.b)) >= range_1 ? GetPixel (s_Foreground, uv1) : m_1;

   return max (m_2.r, max (m_2.g, m_2.b)) >= range_2 ? m_2 : GetPixel (s_Background, uv2);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Mosaic_Dx
{
   pass P_1 < string Script = "RenderColorTarget0 = Mixed;"; > ExecuteShader (ps_mix)
   pass P_2 ExecuteShader (ps_main)
}

