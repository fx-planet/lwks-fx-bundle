// @Maintainer jwrl
// @Released 2021-09-01
// @Author jwrl
// @Created 2021-09-01
// @see https://www.lwks.com/media/kunena/attachments/6375/Autofill_640.png

/**
 This effect provides an automatic fill to clips which don't have the same aspect ratio
 as the sequence in which they're used.  The fill can be the blurred foreground, a flat
 colour, a blurred background, or mixtures of all three.  If no background is connected
 adjusting the background setting will fade the colour used by Bgd mix to black.

 What do the various controls do?

   Fill amount  - allows the fill outside the clip bounds to be faded in and out.
   Fill blur    - varies the fill blurriness.  0% passes the fill through unchanged.
   Fill/Fgd mix - mixes the foreground with the fill colour and the fill background
                  mix prior to the blur being applied.
   Background   - mixes between the fill colour and the Bg (background) input if
                  it's connected, or fades the fill colour to black if it's not.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Autofill.fx
//
// Built 2021-09-01 jwrl.
// The build date is the date that I restructured the big blur effect created by khaver
// as modified by schrauber.  Once I had done that the rest was simple.  Unfortunately
// there is a downside - we perform a few needless blur operations on areas of the frame
// that we will never use.  I can't think of a way to get round this while still getting
// the visual result that I want.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Auto fill";
   string Category    = "Stylize";
   string SubCategory = "Simple tools";
   string Notes       = "Provides an automatic fill to clips which don't have the same aspect ratio as the sequence";
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

#define SetInputMode(TEX, SMPL, MODE) \
                                      \
 texture TEX;                         \
                                      \
 sampler SMPL = sampler_state         \
 {                                    \
   Texture   = <TEX>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define SetTargetMode(TGT, SMP, MODE) \
                                      \
 texture TGT : RenderColorTarget;     \
                                      \
 sampler SMP = sampler_state          \
 {                                    \
   Texture   = <TGT>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }
#define Execute2param(SHD,P1,P2) { PixelShader = compile PROFILE SHD (P1, P2); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs & Samplers
//-----------------------------------------------------------------------------------------//

SetInputMode (Fg, s_Foreground, Mirror);
DefineInput (Bg, s_Background);

SetTargetMode (Fill, s_Fill, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Fill amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float FillBlur
<
   string Description = "Fill blur";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float FillMix
<
   string Description = "Fill/Fgd mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

int FgdFillMode
<
   string Description = "Fgd fill mode";
   string Enum = "Mirror Fg at edges,Copy Fg to edges";
> = 0;

float4 FillColour
<
   string Group = "Mix between fill colour and background";
   string Description = "Fill colour";
   bool SupportsAlpha = true;
> = { 0.24, 0.49, 1.0, 1.0 };

float BgndMix
<
   string Group = "Mix between fill colour and background";
   string Description = "Background";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_init (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   // This shader combines the background, foreground and colour components to create
   // the master fill shader.  It will be returned mapped to TEXCOORD3 for later use.

   float4 Bgnd = lerp (FillColour, GetPixel (s_Background, uv2), BgndMix);

   // For wrap mode we don't have an explicit wrap declaration.  We use the fractional
   // part of the Fg address and duplicate frac to fix any negative fractional values.

   float2 xy = FgdFillMode ? frac (frac (uv1) + 1.0.xx) : uv1;

   return lerp (EMPTY, lerp (Bgnd, tex2D (s_Foreground, xy), FillMix), Amount);
}

float4 ps_blur (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3, uniform sampler s_blur, uniform int run) : COLOR
{
   // This shader blurs the fill and combines it with the unmodified foreground.
   // If the foreground address is within legal bounds and we're on the last run
   // we can simply return the unmodified foreground video.

   if ((run == 3) && !Overflow (uv1)) return tex2D (s_Foreground, uv1);

   // Now we check to see if we need to do the blur at all.  If not we get out.

   if (FillBlur <= 0.0) return tex2D (s_blur, uv3);

   float4 retval = EMPTY;  // This must be set to all zeros at the start of the blur.

   // xy1 will be used to receive the rotation vectors, xy2 has the scaled blur amount

   float2 xy1, xy2 = float2 (1.0, _OutputAspectRatio) * FillBlur * 0.05;

   // Ar is used to calculate the angle of rotation.  Increments by 7.5 degrees (in
   // radians) on each run to oversample the blur at a different angle each time.

   float Ar = run * 0.1309;

   // The following for-next loop samples at 30 degree offsets 12 times for a total
   // of 360 degrees.

   for (int i = 0; i < 12; i++) {
      sincos (Ar, xy1.y, xy1.x);       // Calculate the rotation vectors from the angle
      xy1 *= xy2;                      // Apply the scaled blur to them
      xy1 += uv3;                      // Add the address of the pixel that we need
      retval += tex2D (s_blur, xy1);   // Add the offset pixel to retval to give the blur
      Ar += 0.5236;                    // Add 30 degrees in radians to the angle of rotation
   }

   // Divide the blurred result by 12 to bring the video back to legal levels and quit.

   return retval / 12.0;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Autofill
{
   pass P_1 < string Script = "RenderColorTarget0 = Fill;"; > ExecuteShader (ps_init)
   pass P_2 < string Script = "RenderColorTarget0 = Fill;"; > Execute2param (ps_blur, s_Fill, 0)
   pass P_3 < string Script = "RenderColorTarget0 = Fill;"; > Execute2param (ps_blur, s_Fill, 1)
   pass P_4 < string Script = "RenderColorTarget0 = Fill;"; > Execute2param (ps_blur, s_Fill, 2)
   pass P_5 Execute2param (ps_blur, s_Fill, 3)
}

