// @Maintainer jwrl
// @Released 2020-05-04
// @Author jwrl
// @Created 2018-03-20
// @see https://www.lwks.com/media/kunena/attachments/6375/ChromakeyDVE_640.png

/**
 This effect is a customised version of Editshare's Chromakey effect with cropping and some
 simple DVE adjustments added.  The ChromaKey sections are copyright (c) EditShare EMEA.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromakeyWithDVE.fx
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 6 July 2018 jwrl.
// Made blur component resolution-independent.
//
// Modified 26 Nov 2018 by user schrauber:
// Changed subcategory from "User Effects" to "Key Extras".
//
// Modified 23 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 4 May 2020 jwrl.
// Incorporated crop into DVE shader.
// Some general code cleanup and commenting.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chromakey with DVE";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "A customised version of Editshare's Chromakey effect with cropping and a simple DVE";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Intermediate textures
//-----------------------------------------------------------------------------------------//

texture DVEvid  : RenderColorTarget;
texture RawKey  : RenderColorTarget;
texture BlurKey : RenderColorTarget;
texture FullKey : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state { Texture = <Bg>; };
sampler s_DVEvideo = sampler_state { Texture = <DVEvid>; };

sampler s_RawKey = sampler_state
{
   Texture   = <RawKey>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_BlurKey = sampler_state
{
   Texture   = <BlurKey>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_FullKey = sampler_state { Texture = <FullKey>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.00;
   float MaxVal = 1.00;
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
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float RemoveSpill
<
   string Group = "Key settings";
   string Description = "Remove spill";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

bool Invert
<
   string Group = "Key settings";
   string Description = "Invert";
> = false;

bool Reveal
<
   string Group = "Key settings";
   string Description = "Reveal";
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HUE_IDX 0
#define SAT_IDX 1
#define VAL_IDX 2

#define EMPTY   (0.0).xxxx

float _OutputWidth;
float _OutputHeight;

float _FallOff = 0.12;
float _oneSixth = 1.0 / 6.0;
float _minTolerance = 1.0 / 256.0;

float blur [] = { 20.0 / 64.0, 15.0 / 64.0, 6.0 / 64.0, 1.0 / 64.0 };  // See Pascals Triangle

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

//-----------------------------------------------------------------------------------------//
// fn_allPos
//
// This function is a replacement for all(), which has a Cg implementation bug.  It returns
// true if all of the RGB values are above 0.0.
//-----------------------------------------------------------------------------------------//

bool fn_allPos (float4 pixel)
{
   return (pixel.r > 0.0) && (pixel.g > 0.0) && (pixel.b > 0.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

//-----------------------------------------------------------------------------------------//
// ps_dve
//
// This simple shader adjusts the cropping, position and scaling of the foreground image.
// It is a new addition to the original Editshare chromakey effect.
//-----------------------------------------------------------------------------------------//

float4 ps_dve (float2 uv : TEXCOORD1) : COLOR
{
   // Calculate the crop boundaries.  These are limited to the edge of frame so that no
   // illegal addresses for the input sampler ranges can ever be produced.

   float L = max (0.0, CropLeft);
   float R = min (1.0, CropRight);
   float T = max (0.0, 1.0 - CropTop);
   float B = min (1.0, 1.0 - CropBottom);

   // Set up the scale factor, using the Z axis position.  Unlike the Editshare 3D DVE
   // the range isn't linear and operates smallest to largest.  Since it is intended to
   // just fine tune position it does not cover the full range of the 3D DVE.

   float scale = pow (max ((CentreZ + 1.0) * 0.5, 0.0001) + 0.5, 4.0);

   // Set up the image position and scaling

   float2 xy = ((uv - 0.5.xx) / scale) + float2 (-CentreX, CentreY) + 0.5.xx;

   // Now return the cropped, repositioned and resized image.

   return (xy.x >= L) && (xy.y >= T) && (xy.x <= R) && (xy.y <= B)
          ? tex2D (s_Foreground, xy) : EMPTY;
}

//-----------------------------------------------------------------------------------------//
// ps_keygen
//
// Convert the source to HSV and then compute its similarity with the specified key-colour.
//
// This has had preamble code added to check for the presence of valid video, and if there
// is none, quit.  As a result the original foreground sampler code has been removed.
//
// A new flag is also set in the returned z component if the key is valid.
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   // First recover the cropped image.

   float4 rgba = tex2D (s_DVEvideo, uv);

   // The float maxComponentVal has been set up here to save a redundant evalution
   // in the following conditional code.

   float maxComponentVal = max (max (rgba.r, rgba.g), rgba.b);

   // Check if rgba is zero and if it is we need do nothing.  This check is done
   // because up to now we have no way of knowing what the contents of rgba are.
   // This catches all null values in the original image.

   if (max (maxComponentVal, rgba.a) == 0.0) return rgba;

   // Now return to the Editshare original, minus the rgba = tex2D() section and
   // the maxComponentVal initialisation for the HSV conversion.

   float keyVal = 1.0;
   float hueSimilarity = 1.0;

   float4 hsva = 0.0;
   float4 tolerance1 = Tolerance + _minTolerance;
   float4 tolerance2 = tolerance1 + ToleranceSoftness;

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

   // New flag set in z to indicate that key generation actually took place

   return float4 (keyVal, keyVal, 1.0, 1.0 - hueSimilarity);
}

//-----------------------------------------------------------------------------------------//
// ps_blur1
//
// Does the horizontal component of the blur.  Added a check for a valid key presence at
// the start of the shader using the new flag in result.z.  If it isn't set, quit.
//-----------------------------------------------------------------------------------------//

float4 ps_blur1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 result = tex2D (s_RawKey, uv);

   // This next check will only be true if ps_keygen() has been bypassed.

   if (result.z == 0.0) return result;

   float2 onePixel    = float2 (KeySoftAmount / _OutputWidth, 0.0);
   float2 twoPixels   = onePixel * 2.0;
   float2 threePixels = onePixel * 3.0;

   // Calculate return result;

   result.x *= blur [0];
   result.x += tex2D (s_RawKey, uv + onePixel).x    * blur [1];
   result.x += tex2D (s_RawKey, uv - onePixel).x    * blur [1];
   result.x += tex2D (s_RawKey, uv + twoPixels).x   * blur [2];
   result.x += tex2D (s_RawKey, uv - twoPixels).x   * blur [2];
   result.x += tex2D (s_RawKey, uv + threePixels).x * blur [3];
   result.x += tex2D (s_RawKey, uv - threePixels).x * blur [3];

   return result;
}

//-----------------------------------------------------------------------------------------//
// ps_blur2
//
// Adds the vertical component of the blur.  Added a check for key presence at the start
// of the shader using the new flag in result.z.  If it isn't set, quit.
//-----------------------------------------------------------------------------------------//

float4 ps_blur2 (float2 uv : TEXCOORD1) : COLOR
{
   float4 result = tex2D (s_BlurKey, uv);

   if (result.z == 0.0) return result;

   float2 onePixel    = float2 (0.0, KeySoftAmount / _OutputHeight);
   float2 twoPixels   = onePixel * 2.0;
   float2 threePixels = onePixel * 3.0;

   // Calculate return result;

   result.x *= blur [0];
   result.x += tex2D (s_BlurKey, uv + onePixel).x    * blur [1];
   result.x += tex2D (s_BlurKey, uv - onePixel).x    * blur [1];
   result.x += tex2D (s_BlurKey, uv + twoPixels).x   * blur [2];
   result.x += tex2D (s_BlurKey, uv - twoPixels).x   * blur [2];
   result.x += tex2D (s_BlurKey, uv + threePixels).x * blur [3];
   result.x += tex2D (s_BlurKey, uv - threePixels).x * blur [3];

   return result;
}

//-----------------------------------------------------------------------------------------//
// ps_main
//
// Blend the foreground with the background using the key that was built in ps_keygen.
// Apply spill suppression as we go.
//
// New: 1.  Original foreground sampler replaced with DVE version.
//      2.  Opacity control added, allowing foreground to fade in or out.
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 retval;

   float4 Fgd = tex2D (s_DVEvideo, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 Key = tex2D (s_FullKey, xy1);

   // Key.w = spill removal amount
   // Key.x = blurred key
   // Key.y = raw, unblurred key

   // Using min (Key.x, Key.y) means that any softness around
   // the key causes the foreground to shrink in from the edges

   float mix = saturate ((1.0 - min (Key.x, Key.y) * Fgd.a) * 2.0);

   if (Reveal) {
      retval = lerp (mix, 1.0 - mix, Invert).xxxx;
      retval.a = 1.0;
   }
   else if (Invert) {
      retval = lerp (Bgd, Fgd, mix * Bgd.a);
      retval.a = max (Bgd.a, mix);
   }
   else {
      if (Key.w > 0.8) {
         float fgLum = (Fgd.r + Fgd.g + Fgd.b) / 3.0;

         // Remove spill.

         Fgd = lerp (Fgd, fgLum.xxxx, ((Key.w - 0.8) / 0.2) * RemoveSpill);
      }

      retval = lerp (Fgd, Bgd, mix * Bgd.a);
      retval.a = max (Bgd.a, 1.0 - mix);
   }

   return lerp (Bgd, retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ChromakeyWithDVE
{
   pass P_1
   < string Script = "RenderColorTarget0 = DVEvid;"; >
   { PixelShader = compile PROFILE ps_dve (); }

   pass P_2
   < string Script = "RenderColorTarget0 = RawKey;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_3
   < string Script = "RenderColorTarget0 = BlurKey;"; >
   { PixelShader = compile PROFILE ps_blur1 (); }

   pass P_4
   < string Script = "RenderColorTarget0 = FullKey;"; >
   { PixelShader = compile PROFILE ps_blur2 (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}
