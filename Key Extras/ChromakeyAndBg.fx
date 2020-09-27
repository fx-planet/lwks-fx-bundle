// @Maintainer jwrl
// @Released 2020-09-27
// @Author jwrl
// @Created 2020-07-23
// @see https://www.lwks.com/media/kunena/attachments/6375/ChromakeyAndBg_640.png

/**
 This effect is a customised version of the Lightworks Chromakey effect with cropping and
 some simple DVE adjustments added.  A means of generating an infinite cyclorama style
 background has also been added.  The colour of the background and its linearity can be
 adjusted to give a very realistic studio look.

 The ChromaKey sections are based on work copyright (c) LWKS Software Ltd.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromakeyAndBg.fx
//
// This effect is an extension of a previous effect, "Chromakey with DVE".
//
// Version history:
//
// Update 2020-09-27 jwrl.
// Revised header block.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chromakey and background";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "A chromakey effect with a simple DVE and cyclorama background generation.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture DVEvid  : RenderColorTarget;
texture RawKey  : RenderColorTarget;
texture BlurKey : RenderColorTarget;
texture FullKey : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Input>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_DVEvideo = sampler_state
{
   Texture   = <DVEvid>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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

float4 HorizonColour
<
   string Group = "Cyclorama";
   string Description = "Lighting colour";
   bool SupportsAlpha = false;
> = { 0.631, 0.667, 0.702, 1.0 };

float Lighting
<
   string Group = "Cyclorama";
   string Description = "Overhead light";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.5;
   float MaxVal = 2.0;
> = 1.5;

float Groundrow
<
   string Group = "Cyclorama";
   string Description = "Groundrow light";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.5;
   float MaxVal = 2.0;
> = 1.1;

float Horizon
<
   string Group = "Cyclorama";
   string Description = "Horizon line";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.1;
   float MaxVal = 0.9;
> = 0.3;

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

float blur [] = { 20.0 / 64.0, 15.0 / 64.0, 6.0 / 64.0, 1.0 / 64.0 };  // See Pascal's Triangle

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
// It is a new addition to the original Lightworks chromakey effect.
//-----------------------------------------------------------------------------------------//

float4 ps_dve (float2 uv : TEXCOORD1) : COLOR
{
   // Calculate the crop boundaries.  These are limited to the edge of frame so that no
   // illegal addresses for the input sampler ranges can ever be produced.

   float L = max (0.0, CropLeft);
   float R = min (1.0, CropRight);
   float T = max (0.0, 1.0 - CropTop);
   float B = min (1.0, 1.0 - CropBottom);

   // Set up the scale factor, using the Z axis position.  Unlike the Lightworks 3D DVE
   // the range isn't linear and operates smallest to largest.  Since it is intended to
   // just fine tune position it does not cover the full range of the 3D DVE.

   float scale = pow (max ((CentreZ + 1.0) * 0.5, 0.0001) + 0.5, 4.0);

   // Set up the image position and scaling

   float2 xy = ((uv - 0.5.xx) / scale) + float2 (-CentreX, CentreY) + 0.5.xx;

   // Now return the cropped, repositioned and resized image.

   return (xy.x >= L) && (xy.y >= T) && (xy.x <= R) && (xy.y <= B)
          ? tex2D (s_Input, xy) : EMPTY;
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

   // Now return to the Lightworks original, minus the rgba = tex2D() section and
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
//      2.  Original background sampler replaced with generated version.
//      3.  The invert key function which is pointless in this context has been removed.
//      4.  Redundant TEXCOORD2 has been removed.
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (s_DVEvideo, uv);
   float4 Key = tex2D (s_FullKey, uv);

   // Key.w = spill removal amount
   // Key.x = blurred key
   // Key.y = raw, unblurred key

   // Using min (Key.x, Key.y) means that any softness around the key causes the
   // foreground to shrink in from the edges.

   float mix = saturate ((1.0 - min (Key.x, Key.y) * Fgd.a) * 2.0);

   // If we just want to show the key we can get out now.  Because we no longer have the
   // invert key function this process has become simpler than the Lightworks original.

   if (Reveal) return float4 (mix.xxx, 1.0);

   // Perform spill removal on the foreground if necessary

   if (Key.w > 0.8) {
      float fgLum = (Fgd.r + Fgd.g + Fgd.b) / 3.0;

      // Remove spill.

      Fgd = lerp (Fgd, fgLum.xxxx, ((Key.w - 0.8) / 0.2) * RemoveSpill);
   }

   //  From here on differs significantly from the code in the Lightworks effect.

   // Now we generate the background. The groundrow distance to the centre point, cg,
   // is first calculated using a range limited version of Horizon.  Subtracting that
   // from 1 gives the lighting distance to the centre point, which is stored in cl.

   float cg = clamp (Horizon, 0.1, 0.9);
   float cl = 1.0 - cg;

   // If we are at the top of the "cyclorama" the gamma uses the value set in Lighting,
   // otherwise the Groundrow value is used.  The amount of gamma correction to use is
   // given by the normalised distance of the Y position from Horizon.

   float gamma = (uv.y < cl) ? lerp (1.0 / Lighting, 1.0, uv.y / cl)
                             : lerp (1.0 / Groundrow, 1.0, (1.0 - uv.y) / cg);

   if (gamma < 1.0) gamma = pow (gamma, 3.0);

   // The appropriate gamma correction is now applied to the colour of the "cyclorama"
   // to produce the desired lighting effect on the background.  That is then combined
   // with the foreground and the alpha is set to 1 and we quit.

   return float4 (lerp (Fgd, pow (HorizonColour, gamma), mix).rgb, 1.0);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ChromakeyAndBg
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
