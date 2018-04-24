// @maintainer jwrl
// @released 2018-04-24
// @author jwrl
// @author EditShare
// @created 2018-04-02
// @Licence Copyright (c) EditShare EMEA.  All Rights Reserved
// @see https://www.lwks.com/media/kunena/attachments/6375/Transporter_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Transporter.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Transporter.fx
//
// This is a customised version of Editshare's Chromakey effect with a transitional Star
// Trek-like transporter sparkle effect added.  This is definitely not a copy of any of
// any of the Star Trek versions of that effect, nor is it intended to be.  At most it
// should be regarded as an interpretation of the idea behind the effect.
//
// The transition is quite complex.  During the first 0.3 of the transition progress
// the sparkles/stars build, then hold for the next 0.4 of the transition.  They then
// decay.  Under that, after the first 0.3 of the transition the chromakey starts a
// linear fade in, reaching full value at 70% of the transition progress.  When the
// transition is at 100% the result is exactly the same as a standard chromakey.
//
// Because significant sections of this effect are copyright (c) EditShare EMEA and all
// rights are reserved it must not be used in other effects in whole or in part without
// the express written permission of Editshare.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Transporter";
   string Category    = "Key";
   string SubCategory = "Special Fx";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;                               // Original: fg
texture Bg;                               // Original: bg

//-----------------------------------------------------------------------------------------//
// Intermediate textures
//-----------------------------------------------------------------------------------------//

texture InpDVE   : RenderColorTarget;     // *** NEW ***
texture RawKey   : RenderColorTarget;
texture BlurKey1 : RenderColorTarget;     // Original: BlurredKey1
texture BlurKey2 : RenderColorTarget;     // Original: BlurredKey2

//-----------------------------------------------------------------------------------------//
// Samplers - one for each texture
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };      // Original: FgSampler
sampler s_Background = sampler_state { Texture = <Bg>; };      // Original: BgSampler

sampler s_DVE = sampler_state { Texture = <InpDVE>; };         // *** NEW ***

sampler s_RawKey = sampler_state          // Original: RawKeySampler
{
   Texture   = <RawKey>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_BlurKey1 = sampler_state        // Original: BlurredKey1Sampler
{
   Texture   = <BlurKey1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_BlurKey2 = sampler_state        // Original: BlurredKey2Sampler
{
   Texture   = <BlurKey2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

//----------------------------------------- NEW ------------------------------------------

float Transition
<
   string Description = "Transition";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.0;

//----------------------------------------------------------------------------------------

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
   string Group = "Key settings";         // New group assigned
   string Description = "Key softness";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float RemoveSpill
<
   string Group = "Key settings";         // New group assigned
   string Description = "Remove spill";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//----------------------------------------- NEW ------------------------------------------

bool HideBgd
<
   string Group = "Key settings";
   string Description = "Hide background";
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
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.0;

float CropTop
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.0;

float CropRight
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.0;

float CropBottom
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HUE_IDX 0
#define SAT_IDX 1
#define VAL_IDX 2

float _oneSixth = 1.0 / 6.0;           // Original const declaration removed
float _minTolerance = 1.0 / 256.0;     // Original const declaration removed

float _OutputWidth  = 1.0;
float _OutputHeight = 1.0;

// See Pascals Triangle - original const declaration removed

float blur [] = { 20.0 / 64.0, 15.0 / 64.0, 6.0 / 64.0, 1.0 / 64.0 };

//----------------------------------------- NEW ------------------------------------------

float _OutputAspectRatio;

#define EMPTY   (0.0).xxxx

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//
// This function is a replacement for all(), which has an implementation bug.  It
// returns true if all of the RGB values are above 0.0.
//-----------------------------------------------------------------------------------------//

bool fn_allPos (float4 pixel)
{
   return (min (pixel.r, min (pixel.g, pixel.b)) > 0.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//
// ps_dve
//
// DVE and crop routine added by jwrl to give masking, scaling and position adjustment
//-----------------------------------------------------------------------------------------//

float4 ps_dve (float2 uv : TEXCOORD1) : COLOR
{
   // First we set up the scale factor, using the Z axis position.  Unlike the Editshare
   // 3D DVE the transition isn't linear and operates smallest to largest.  Since it has
   // been designed to fine tune position it does not cover the full range of the 3D DVE.
   // If your image is as bad as that you probably need other tools anyway.

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

   return (xy.x < left) || (xy.x > right) || (xy.y < top) || (xy.y > bottom)
          ? EMPTY : tex2D (s_Foreground, xy);
}

//-----------------------------------------------------------------------------------------//
// ps_keygen
//
// Convert the source to HSV and then compute its similarity with the specified key-colour.
//
// Originally called keygen_ps_main, this has had preamble code added by jwrl to check for
// the presence of alpha data, and if there is none, return.  Instead of the foreground
// sampler code originally used we now use the DVE sampler.
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   //--------------------------------------- NEW ----------------------------------------

   float4 rgba = tex2D (s_DVE, uv);

   // Check if alpha is zero and if it is we need do nothing.  There is no image so quit.

   if (rgba.a == 0.0) return rgba;

   //------------------------------------------------------------------------------------

   float keyVal = 1.0;
   float hueSimilarity = 1.0;

   float4 hsva = 0.0;
   float4 tolerance1 = Tolerance + _minTolerance;
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

      hsva [HUE_IDX] *= _oneSixth;

      if (hsva [HUE_IDX] < 0.0) hsva [HUE_IDX] += 1.0;
   }

   // Calc difference between current pixel and specified key-colour

   float4 diff = abs (hsva - KeyColour);

   if (diff [HUE_IDX] > 0.5) diff [HUE_IDX] = 1.0 - diff [HUE_IDX];

   // Work out how transparent/opaque the corrected pixel will be

   if (fn_allPos (tolerance2 - diff)) {
      if (fn_allPos (tolerance1 - diff)) { keyVal = 0.0; }
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

   return float4 (keyVal, keyVal, keyVal, 1.0 - hueSimilarity);
}

//-----------------------------------------------------------------------------------------//
// ps_blur_noise - originally Blur1, which did the horizontal component of the blur used
// for generating key softness.
//
// New code added by jwrl: instead of indexing into the sampler using RGBA notation we
// now use XYZW, and have added a pseudo random noise generator which returns in Z.
// This was unused in the original effect and gives us the required seeds of the sparkle
// effect needed for the transporter.
//-----------------------------------------------------------------------------------------//

float4 ps_blur_noise (float2 uv : TEXCOORD1) : COLOR
{
   float2 onePixAcross   = float2 (KeySoftAmount / _OutputWidth, 0.0);
   float2 twoPixAcross   = onePixAcross * 2.0;
   float2 threePixAcross = onePixAcross + twoPixAcross;

   float4 result = tex2D (s_RawKey, uv);

   // Calculate return result;

   result.x *= blur [0];
   result.x += tex2D (s_RawKey, uv + onePixAcross).x   * blur [1];
   result.x += tex2D (s_RawKey, uv - onePixAcross).x   * blur [1];
   result.x += tex2D (s_RawKey, uv + twoPixAcross).x   * blur [2];
   result.x += tex2D (s_RawKey, uv - twoPixAcross).x   * blur [2];
   result.x += tex2D (s_RawKey, uv + threePixAcross).x * blur [3];
   result.x += tex2D (s_RawKey, uv - threePixAcross).x * blur [3];

   //--------------------------------------- NEW ----------------------------------------

   float scale = (1.0 - starSize) * 800.0;
   float seed  = Transition;
   float Y = saturate ((round (uv.y * scale) / scale) + 0.000123);

   scale *= _OutputAspectRatio;

   float X = saturate ((round (uv.x * scale) / scale) + 0.00013);
   float rndval = frac (sin ((X * 13.9898) + (Y * 79.233) + seed) * 43758.5453);

   rndval = sin (X) + cos (Y) + rndval * 1000.0;

   float amt   = frac (fmod (rndval, 17.0) * fmod (rndval, 94.0)) * 3.0;
   float alpha = max (0.0, abs (sin (Transition * HALF_PI) - 0.5) - 0.2) + 2.7;

   result.z = amt <= alpha ? 0.0 : tex2D (s_RawKey, uv).y;

   //------------------------------------------------------------------------------------

   return result;
}

//-----------------------------------------------------------------------------------------//
// ps_blur_stars - originally Blur2, which did the vertical component of the blur used
// for generating key softness.
//
// New code added by jwrl: instead of indexing into the sampler using RGBA notation we
// use XYZW.  Because of the changes in ps_blur_noise we now have gated noise in Z, and
// use that to create the star/sparkle effect for the transporter.  Three variables have
// been renamed (original names commented) to allow re-use in the new code.
//-----------------------------------------------------------------------------------------//

float4 ps_blur_stars (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = float2 (0.0, KeySoftAmount / _OutputHeight);   // onePixAcross
   float2 xy2 = xy1 * 2.0;                                     // TwoPixAcross
   float2 xy3 = xy1 + xy2;                                     // ThreePixAcross

   float4 result = tex2D (s_BlurKey1, uv);

   // Calculate return result;

   result.x *= blur [0];
   result.x += tex2D (s_BlurKey1, uv + xy1).x * blur [1];
   result.x += tex2D (s_BlurKey1, uv - xy1).x * blur [1];
   result.x += tex2D (s_BlurKey1, uv + xy2).x * blur [2];
   result.x += tex2D (s_BlurKey1, uv - xy2).x * blur [2];
   result.x += tex2D (s_BlurKey1, uv + xy3).x * blur [3];
   result.x += tex2D (s_BlurKey1, uv - xy3).x * blur [3];

   //--------------------------------------- NEW ----------------------------------------

   float stars = 0.0;

   xy1 = 0.0.xx;
   xy2 = 0.0.xx;
   xy3 = float2 (starLength / _OutputWidth, 0.0);

   float2 xy4 = float2 (0.0, starLength / _OutputHeight);

   for (int i = 0; i <= 25; i++) {
      stars += tex2D (s_BlurKey1, uv + xy1).z;
      stars += tex2D (s_BlurKey1, uv - xy1).z;
      stars += tex2D (s_BlurKey1, uv + xy2).z;
      stars += tex2D (s_BlurKey1, uv - xy2).z;

      xy1 += xy3;
      xy2 += xy4;
   }

   stars *= starStrength / 12.5;

   result.z = max (tex2D (s_BlurKey1, uv).z, stars);

   //------------------------------------------------------------------------------------

   return result;
}

//-----------------------------------------------------------------------------------------//
// ps_main - originally composite_ps_main.
//
// Blend the foreground with the background using the key that was built in ps_keygen.
// Apply spill-suppression as we go.
//
// Mods by jwrl: 1.  Key indexing changed from RGBA to XYZW for clarity.
//               2.  Original foreground sampler replaced with DVE version.
//               3.  Added background suppression for key lineup.  It also allows the
//                   foreground and alpha channel to be output for later use.
//               4.  Removed key inversion and alpha reveal code.
//               5.  Transition support added.
//               6.  Added the sparkles/stars for the transporter effect.
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 result;

   float4 fg  = tex2D (s_DVE, xy1);
   float4 bg  = HideBgd ? EMPTY : tex2D (s_Background, xy2);
   float4 key = tex2D (s_BlurKey2, xy1);

   // key.w = spill removal amount
   // key.x = blurred key
   // key.y = raw, unblurred key
   // key.z = star key for sparkle generation  *** NEW ***

   // Using min (key.x, key.y) means that any softness around the key causes the
   // foreground to shrink in from the edges.

   float mix = saturate ((1.0 - min (key.x, key.y) * fg.a) * 2.0);

   if (key.w > 0.8) {

      // This next section has been slightly rewritten to correct for a potential cross
      // platform issue.  I suspect the Editshare version has done something similar.

      float fgLum = (fg.r + fg.g + fg.b) / 3.0;    // Originally a float4

      // Remove spill.  Now swizzle fgLum to float4 here and change the original
      // divide by 0.2 to a multiply by 5.0.  Functionally the same, but simpler.

      fg = lerp (fg, fgLum.xxxx, (key.w - 0.8) * RemoveSpill * 5.0);
   }

   result = lerp (fg, bg, mix * bg.a);
   result.a = max (bg.a, 1.0 - mix);

   //--------------------------------------- NEW ----------------------------------------

   float Amount = min (max (sin (Transition * HALF_PI) - 0.3, 0.0) * 2.5, 1.0);

   fg = lerp (bg, result, Amount);

   return lerp (fg, starColour, key.z);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ChromakeyDVE
{
   pass P_1
   < string Script = "RenderColorTarget0 = InpDVE;"; >
   { PixelShader = compile PROFILE ps_dve (); }

   pass P_2
   < string Script = "RenderColorTarget0 = RawKey;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_3
   < string Script = "RenderColorTarget0 = BlurKey1;"; >
   { PixelShader = compile PROFILE ps_blur_noise (); }

   pass P_4
   < string Script = "RenderColorTarget0 = BlurKey2;"; >
   { PixelShader = compile PROFILE ps_blur_stars (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}
