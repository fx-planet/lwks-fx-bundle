// @maintainer jwrl
// @released 2021-10-22
// @author jwrl
// @author LWKS Software Ltd
// @created 2021-10-22
// @Licence LWKS Software Ltd.  All Rights Reserved
// @see https://www.lwks.com/media/kunena/attachments/6375/Transporter_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Transporter.mp4

/**
 This is a customised version of the Lightworks Chromakey effect with a transitional
 Star Trek-like transporter sparkle effect added.  This is definitely not a copy of
 any of the Star Trek versions of that effect, nor is it intended to be.  At most it
 should be regarded as an interpretation of the idea behind the effect.

 The transition is quite complex.  During the first 0.3 of the transition progress the
 sparkles/stars build, then hold for the next 0.4 of the transition.  They then decay.
 Under that, after the first 0.3 of the transition the chromakey starts a linear fade
 in, reaching full value at 70% of the transition progress.  When the transition is at
 100% the result is exactly the same as a standard chromakey.

 Because significant sections of this effect are copyright (c) LWKS Software Ltd and
 all rights are reserved it cannot be used in other effects in whole or in part without
 the express written permission of LWKS Software Ltd.  The additional DVE component and
 the sparkle generation is an original implementation, although it is based on common
 algorithms.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Transporter1.fx
//
// Version history:
//
// Rewrite 2021-10-22 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Transporter 1";
   string Category    = "Key";
   string SubCategory = "Special Effects";
   string Notes       = "A modified chromakey to provide a Star Trek-like transporter effect";
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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define AllPos(XYZ) (min (XYZ.x, min (XYZ.y, XYZ.z)) > 0.0)

#define HUE_IDX   0
#define SAT_IDX   1
#define VAL_IDX   2

#define MIN_TOL   0.00390625
#define ONE_SIXTH 0.1666666667
#define HALF_PI   1.5707963268

#define W_SCALE   0.0005208
#define S_SCALE   0.000868
#define FADER     0.9333333333
#define FADE_DEC  0.0666666667

float _OutputAspectRatio;

float _Pascal [] = { 20.0 / 64.0, 15.0 / 64.0, 6.0 / 64.0, 1.0 / 64.0 };

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

DefineTarget (InpDVE, s_DVE);
DefineTarget (RawKey, s_RawKey);
DefineTarget (BlurKey1, s_BlurKey1);
DefineTarget (BlurKey2, s_BlurKey2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Transition
<
   string Description = "Transition";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float4 KeyColour
<
   string Description = "Key Colour";
   string Flags = "SpecifiesColourRange";
> = { 150.0, 0.7, 0.75, 0.0 };

float4 Tolerance
<
   string Description = "Tolerance";
   string Flags = "SpecifiesColourRange";
   bool Visible = false;
> = { 20.0, 0.3, 0.25, 0.0 };

float4 ToleranceSoftness
<
   string Description = "Tolerance softness";
   string Flags = "SpecifiesColourRange";
   bool Visible = false;
> = { 15.0, 0.115, 0.11, 0.0 };

float KeySoftAmount
<
   string Group = "Key settings";
   string Description = "Key softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float RemoveSpill
<
   string Group = "Key settings";
   string Description = "Remove spill";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool NoAlpha
<
   string Group = "Key settings";
   string Description = "Ignore foreground alpha";
> = false;

float CentreX
<
   string Description = "DVE position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreY
<
   string Description = "DVE position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreZ
<
   string Description = "DVE position";
   string Flags = "SpecifiesPointZ";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropLeft
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropTop
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CropRight
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CropBottom
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float starSize
<
   string Group = "Sparkle";
   string Description = "Spot size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float starLength
<
   string Group = "Sparkle";
   string Description = "Star length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float starStrength
<
   string Group = "Sparkle";
   string Description = "Star strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 starColour
<
   string Group = "Sparkle";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.9, 0.75, 0.0, 1.0 };

bool HideBgd
<
   string Group = "Key settings";
   string Description = "Hide background";
> = false;

//-----------------------------------------------------------------------------------------//
// Shaders
//
// ps_dve
//
// This DVE and crop shader is new.  It has been added to give masking, scaling and
// position adjustment.
//-----------------------------------------------------------------------------------------//

// These first two shaders simply isolate the foreground and background nodes from the
// resolution.  It does this by mapping all shaders onto the same texture coordinates.

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return BdrPixel (s_RawBg, uv); }

float4 ps_dve (float2 uv : TEXCOORD3) : COLOR
{
   // First we set up the scale factor, using the Z axis position.  Unlike the Lightworks
   // 3D DVE the transition isn't linear and operates smallest to largest.  Since it has
   // been designed to fine tune position it does not cover the full range of the 3D DVE.

   float Xcntr = 0.5 - CentreX;
   float Ycntr = 0.5 + CentreY;
   float scale = pow (max ((CentreZ + 1.0) * 0.5, 0.0001) + 0.5, 4.0);

   // Set up the image position

   float2 xy = ((uv - 0.5.xx) / scale) + float2 (Xcntr, Ycntr);

   // Now return the cropped and resized image.  To ensure that we don't get half pixel
   // oddities at the edge of frame we limit the range to 0.0 - 1.0.  This ensures that
   // we don't get over- or underflow.  If we do, black with no alpha is returned.

   float left = max (0.0, ((CropLeft - 0.5) / scale + Xcntr));
   float top = max (0.0, ((0.5 - CropTop) / scale + Ycntr));
   float right = min (1.0, ((CropRight - 0.5) / scale + Xcntr));
   float bottom = min (1.0, ((0.5 - CropBottom) / scale + Ycntr));

   if ((xy.x < left) || (xy.x > right) || (xy.y < top) || (xy.y > bottom)) return EMPTY;

   // Finally, if we don't want to use the foreground alpha, it's turned on regardless
   // of its actual value.

   return NoAlpha ? float4 (tex2D (s_Foreground, xy).rgb, 1.0) : tex2D (s_Foreground, xy);
}

//-----------------------------------------------------------------------------------------//
// ps_keygen
//
// Convert the source to HSV and then compute its similarity with the specified key colour.
//
// Originally called keygen_ps_main, this now uses the new DVE sampler for input instead
// of the original foreground sampler.  New code then checks for the presence of alpha
// data, and if there is none, returns.  This is the same result as that produced if the
// foreground colour exactly matches the key colour.
//
// From that point on the code is as used in the original keygen_ps_main().  Some const
// variables have been replaced with actual values.
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD3) : COLOR
{
   float4 rgba = tex2D (s_DVE, uv);

   // Check if alpha is zero and if it is we need do nothing.  There is no image so quit.

   if (rgba.a == 0.0) return rgba;

   float keyVal = 1.0;
   float hueSimilarity = 1.0;

   float4 hsva = 0.0.xxxx;
   float4 tolerance1 = Tolerance + MIN_TOL.xxxx;
   float4 tolerance2 = tolerance1 + ToleranceSoftness;

   float maxComponentVal = max (max (rgba.r, rgba.g), rgba.b);
   float minComponentVal = min (min (rgba.r, rgba.g), rgba.b);
   float componentRange  = maxComponentVal - minComponentVal;

   hsva [VAL_IDX] = maxComponentVal;
   hsva [SAT_IDX] = componentRange / maxComponentVal;

   if (hsva [SAT_IDX] == 0.0) { hsva [HUE_IDX] = 0.0; }     // undefined
   else {
      if (rgba.r == maxComponentVal) {
         hsva [HUE_IDX] = (rgba.g - rgba.b) / componentRange;
      }
      else if (rgba.g == maxComponentVal) {
         hsva [HUE_IDX] = 2.0 + ((rgba.b - rgba.r) / componentRange);
      }
      else hsva [HUE_IDX] = 4.0 + ((rgba.r - rgba.g) / componentRange);

      hsva [HUE_IDX] *= ONE_SIXTH;

      if (hsva [HUE_IDX] < 0.0) hsva [HUE_IDX] += 1.0;
   }

   // Calc difference between current pixel and specified key-colour

   float4 diff = abs (hsva - KeyColour);

   if (diff [HUE_IDX] > 0.5) diff [HUE_IDX] = 1.0 - diff [HUE_IDX];

   // Work out how transparent/opaque the corrected pixel will be

   float3 range = (tolerance2 - diff).rgb;

   if (AllPos (range)) {
      range = (tolerance1 - diff).rgb;

      if (AllPos (range)) { keyVal = 0.0; }
      else {
         diff -= tolerance1;
         hueSimilarity = diff [HUE_IDX];
         diff /= ToleranceSoftness;
         keyVal = max (diff [HUE_IDX], max (diff [SAT_IDX], diff [VAL_IDX]));
         keyVal = pow (keyVal, 0.25);
      }
   }
   else {
      diff -= tolerance1;
      hueSimilarity = diff [HUE_IDX];
   }

   return float2 (keyVal, 1.0 - hueSimilarity).xxxy;
}

//-----------------------------------------------------------------------------------------//
// ps_blur_noise - originally Blur1, which did the horizontal component of the blur used
// for generating key softness.
//
// Changes in this effect: instead of indexing into the sampler using RGBA notation we
// now use XYZW, and have added a pseudo random noise generator which returns in Z.  This
// was unused in the original effect and gives the required noise for the sparkles that
// the effect needs for the final transporter effect.  Some variables have been renamed.
//
// Instead of using frame width to calculate the sample offset a fixed value is now used.
// This has the benefit of making the visual effect of the feathering the same regardless
// of the size of the frame.  The downside is that for large frame sizes the sampling may
// become obvious.
//-----------------------------------------------------------------------------------------//

float4 ps_blur_noise (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy1 = float2 (KeySoftAmount * W_SCALE, 0.0);
   float2 xy2 = xy1 * 2.0;
   float2 xy3 = xy1 + xy2;

   float4 result = tex2D (s_RawKey, uv);

   // Calculate return result;

   result.x *= _Pascal [0];
   result.x += tex2D (s_RawKey, uv + xy1).x * _Pascal [1];
   result.x += tex2D (s_RawKey, uv - xy1).x * _Pascal [1];
   result.x += tex2D (s_RawKey, uv + xy2).x * _Pascal [2];
   result.x += tex2D (s_RawKey, uv - xy2).x * _Pascal [2];
   result.x += tex2D (s_RawKey, uv + xy3).x * _Pascal [3];
   result.x += tex2D (s_RawKey, uv - xy3).x * _Pascal [3];

   float scale = (1.0 - starSize) * 800.0;
   float seed  = Transition;
   float Y = saturate ((round (uv.y * scale) / scale) + 0.000123);

   scale *= _OutputAspectRatio;

   float X = saturate ((round (uv.x * scale) / scale) + 0.00013);
   float rndval = frac (sin ((X * 13.9898) + (Y * 79.233) + seed) * 43758.5453);

   rndval = sin (X) + cos (Y) + rndval * 1000.0;
   scale = (starStrength * 0.3) - 0.15;

   float amt   = (frac (fmod (rndval, 17.0) * fmod (rndval, 94.0)) * 3.0) + scale;
   float alpha = max (0.0, abs (sin (Transition * HALF_PI) - 0.5) - 0.2) + 2.7;

   result.z = amt <= alpha ? 0.0 : tex2D (s_RawKey, uv).y;

   return result;
}

//-----------------------------------------------------------------------------------------//
// ps_blur_stars - originally Blur2, which did the vertical component of the blur used
// for generating key softness.
//
// Changes in this effect: instead of indexing into the sampler using RGBA notation this
// uses XYZW.  Because of the changes in ps_blur_noise there is gated noise in Z.  That
// is used to create the star/sparkle effect for the transporter.  Some variables have
// been renamed.
//
// Instead of using frame height to calculate the sample offset a fixed value scaled by
// the aspect ratio is now used.  This has the pros and cons described in ps_blur_noise.
//-----------------------------------------------------------------------------------------//

float4 ps_blur_stars (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy1 = float2 (0.0, KeySoftAmount * _OutputAspectRatio * W_SCALE);
   float2 xy2 = xy1 + xy1;
   float2 xy3 = xy1 + xy2;

   float4 result = tex2D (s_BlurKey1, uv);

   // Calculate return result;

   result.x *= _Pascal [0];
   result.x += tex2D (s_BlurKey1, uv + xy1).x * _Pascal [1];
   result.x += tex2D (s_BlurKey1, uv - xy1).x * _Pascal [1];
   result.x += tex2D (s_BlurKey1, uv + xy2).x * _Pascal [2];
   result.x += tex2D (s_BlurKey1, uv - xy2).x * _Pascal [2];
   result.x += tex2D (s_BlurKey1, uv + xy3).x * _Pascal [3];
   result.x += tex2D (s_BlurKey1, uv - xy3).x * _Pascal [3];

   float stars = 0.0;
   float fader = FADER;

   xy1 = 0.0.xx;
   xy2 = 0.0.xx;
   xy3 = float2 (starLength * S_SCALE, 0.0);

   float2 xy4 = xy3.yx * _OutputAspectRatio;

   for (int i = 0; i <= 15; i++) {
      stars += tex2D (s_BlurKey1, uv + xy1).z * fader;
      stars += tex2D (s_BlurKey1, uv - xy1).z * fader;
      stars += tex2D (s_BlurKey1, uv + xy2).z * fader;
      stars += tex2D (s_BlurKey1, uv - xy2).z * fader;

      xy1 += xy3;
      xy2 += xy4;
      fader -= FADE_DEC;
   }

   result.z = saturate (max (tex2D (s_BlurKey1, uv).z, stars));

   return result;
}

//-----------------------------------------------------------------------------------------//
// ps_main - originally composite_ps_main.
//
// Blend the foreground with the background using the key that was built in ps_keygen.
// Apply spill suppression as we go.
//
// Mods in this effect: 1.  Key indexing changed from RGBA to XYZW for clarity.
//                      2.  Original foreground sampler replaced with DVE version.
//                      3.  Added background suppression for key lineup.  This allows
//                          the foreground and alpha channel to be output for later use.
//                      4.  Removed key inversion and alpha reveal code.
//                      5.  Transition support added.
//                      6.  Added the sparkles/stars for the transporter effect.
//
// Some variables have been renamed and the code has been slightly restructured.
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = tex2D (s_DVE, uv);
   float4 key = tex2D (s_BlurKey2, uv);

   // key.w = spill removal amount
   // key.x = blurred key
   // key.y = raw, unblurred key
   // key.z = star key for sparkle generation

   // Using min (key.x, key.y) means that any softness around the key causes the
   // foreground to shrink in from the edges.

   float mix = saturate ((1.0 - min (key.x, key.y) * Fgd.a) * 2.0);

   if (key.w > 0.8) {

      // This next section has been slightly rewritten to correct for a potential
      // cross-platform issue.

      float fgLum = (Fgd.r + Fgd.g + Fgd.b) / 3.0;    // Originally a float4

      // Remove spill.  Now swizzle fgLum to float4 here and change the original
      // divide by 0.2 to a multiply by 5.0.  Functionally the same, but simpler.

      Fgd = lerp (Fgd, fgLum.xxxx, (key.w - 0.8) * RemoveSpill * 5.0);
   }

   float4 Bgd = HideBgd ? EMPTY : tex2D (s_Background, uv);
   float4 result = lerp (Fgd, Bgd, mix * Bgd.a);

   result.a = max (Bgd.a, 1.0 - mix);

   float Amount = min (max (sin (Transition * HALF_PI) - 0.3, 0.0) * 2.5, 1.0);

   result = lerp (Bgd, result, Amount);

   Amount = saturate ((0.5 - abs (Transition - 0.5)) * 4.0);

   return lerp (result, starColour, key.z * Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Transporter1
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 < string Script = "RenderColorTarget0 = InpDVE;"; > ExecuteShader (ps_dve)
   pass P_4 < string Script = "RenderColorTarget0 = RawKey;"; > ExecuteShader (ps_keygen)
   pass P_5 < string Script = "RenderColorTarget0 = BlurKey1;"; > ExecuteShader (ps_blur_noise)
   pass P_6 < string Script = "RenderColorTarget0 = BlurKey2;"; > ExecuteShader (ps_blur_stars)
   pass P_7 ExecuteShader (ps_main)
}

