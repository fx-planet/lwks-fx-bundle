// @Maintainer jwrl
// @Released 2018-04-07
// @Author jwrl
// @Created 2018-03-20
// @see https://www.lwks.com/media/kunena/attachments/6375/ChromakeyDVE_3.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromakeyDVE.fx
//
// This effect is customised version of Editshare's Chromakey effect with cropping and
// simple DVE adjustments added.  The ChromaKey sections are copyright (c) EditShare EMEA.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chromakey with DVE";
   string Category    = "Key";
   string SubCategory = "Custom";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Intermediate textures
//-----------------------------------------------------------------------------------------//

texture InpCrop  : RenderColorTarget;
texture InpDVE   : RenderColorTarget;
texture RawKey   : RenderColorTarget;
texture BlurKey1 : RenderColorTarget;
texture BlurKey2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Cropped = sampler_state
{
   Texture   = <InpCrop>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_DVE = sampler_state
{
   Texture   = <InpDVE>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_RawKey = sampler_state
{
   Texture = <RawKey>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_BlurKey1 = sampler_state
{
   Texture = <BlurKey1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_BlurKey2 = sampler_state
{
   Texture = <BlurKey2>;
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

#define R_LUMA 0.2989
#define G_LUMA 0.5866
#define B_LUMA 0.1145

#define EMPTY  (0.0).xxxx

float _FallOff = 0.12;
float _oneSixth = 1.0 / 6.0;
float _minTolerance = 1.0 / 256.0;
float _OutputWidth  = 1.0;
float _OutputHeight = 1.0;

float blur [] = { 20.0 / 64.0, 15.0 / 64.0, 6.0 / 64.0, 1.0 / 64.0 };  // See Pascals Triangle

//-----------------------------------------------------------------------------------------//
// Functions
//
// This function is a replacement for all (), which has an implementation bug.  It
// returns true if all of the RGB values are above 0.0.
//-----------------------------------------------------------------------------------------//

bool fn_allPos (float4 pixel)
{
   return (pixel.r > 0.0) && (pixel.g > 0.0) && (pixel.b > 0.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//
// ps_crop
//
// New crop routine added by jwrl to allow selective masking of less than optimum footage
//-----------------------------------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   return (uv.x >= CropLeft) && (uv.y >= 1.0 - CropTop) &&
          (uv.x <= CropRight) && (uv.y <= 1.0 - CropBottom) ? tex2D (s_Foreground, uv) : EMPTY;
}

//-----------------------------------------------------------------------------------------//
// ps_dve
//
// This is a simple shader to adjust the position and scaling of the foreground image
//-----------------------------------------------------------------------------------------//

float4 ps_dve (float2 uv : TEXCOORD1) : COLOR
{
   // First we set up the scale factor, using the Z axis position.  Unlike the Editshare
   // 3D DVE the transition isn't linear and operates smallest to largest.  Since it has
   // been designed to fine tune position it does not cover the full range of the 3D DVE.
   // If your image is as bad as that you probably need other tools anyway.

   float scale = pow (max ((CentreZ + 1.0) * 0.5, 0.0001) + 0.5, 4.0);

   // Set up the image position

   float2 xy = ((uv - 0.5.xx) / scale) + float2 (-CentreX, CentreY) + 0.5.xx;

   // Now return the cropped and resized image.  To ensure that we don't get half pixel
   // oddities at the edge of frame we test for over- or underflow first

   return (xy.x >= 0.0) && (xy.y >= 0.0) && (xy.x <= 1.0) && (xy.y <= 1.0)
          ? tex2D (s_Cropped, xy) : EMPTY;
}

//-----------------------------------------------------------------------------------------//
// ps_keygen
//
// Convert the source to HSV and then compute its similarity with the specified key-colour.
//
// This has had preamble code added by jwrl to check for the presence of alpha data, and
// if there is none, quit.  As a result the original foreground sampler code was removed.
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   // First recover the cropped image.

   float4 rgba = tex2D (s_DVE, uv);

   // Check if alpha is zero and if it is we need do nothing.  There is no image so quit

   if (rgba.a == 0.0) return rgba;

   // Now return to the Editshare original, minus the rgba = tex2D() section

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
// Blur1 - does the horizontal component of the blur
//-----------------------------------------------------------------------------------------//

float4 ps_blur1 (float2 uv : TEXCOORD1) : COLOR
{
   float2 onePixAcross   = float2 (KeySoftAmount / _OutputWidth, 0.0);
   float2 twoPixAcross   = onePixAcross * 2.0;
   float2 threePixAcross = onePixAcross * 3.0;

   float4 result = tex2D (s_RawKey, uv);

   // Calculate return result;

   result.r *= blur [0];
   result.r += tex2D (s_RawKey, uv + onePixAcross).r   * blur [1];
   result.r += tex2D (s_RawKey, uv - onePixAcross).r   * blur [1];
   result.r += tex2D (s_RawKey, uv + twoPixAcross).r   * blur [2];
   result.r += tex2D (s_RawKey, uv - twoPixAcross).r   * blur [2];
   result.r += tex2D (s_RawKey, uv + threePixAcross).r * blur [3];
   result.r += tex2D (s_RawKey, uv - threePixAcross).r * blur [3];

   return result;
}

//-----------------------------------------------------------------------------------------//
// Blur2 - adds the vertical component of the blur
//-----------------------------------------------------------------------------------------//

float4 ps_blur2 (float2 uv : TEXCOORD1) : COLOR
{
   float2 onePixDown   = float2 (0.0, KeySoftAmount / _OutputHeight);
   float2 twoPixDown   = onePixDown * 2.0;
   float2 threePixDown = onePixDown * 3.0;

   float4 result = tex2D (s_BlurKey1, uv);

   // Calculate return result;

   result.r *= blur [0];
   result.r += tex2D (s_BlurKey1, uv + onePixDown).r   * blur [1];
   result.r += tex2D (s_BlurKey1, uv - onePixDown).r   * blur [1];
   result.r += tex2D (s_BlurKey1, uv + twoPixDown).r   * blur [2];
   result.r += tex2D (s_BlurKey1, uv - twoPixDown).r   * blur [2];
   result.r += tex2D (s_BlurKey1, uv + threePixDown).r * blur [3];
   result.r += tex2D (s_BlurKey1, uv - threePixDown).r * blur [3];

   return result;
}

//-----------------------------------------------------------------------------------------//
// Composite
//
// Blend the foreground with the background using the key that was built in ps_keygen.
// Apply spill-suppression as we go.
//
// Mods by jwrl: 1.  Original foreground sampler replaced with DVE version.
//               2.  Opacity control added, allowing foreground to fade in or out.
//               3.  Luminance calculation for despill changed.  The Lightworks key used
//                   an RGB average, so despill caused luminance shifts at the edges.
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 retval;

   float4 Fgd = tex2D (s_DVE, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 Key = tex2D (s_BlurKey2, xy1);

   // Key.w = spill removal amount
   // Key.x = blurred key
   // Key.y = raw, unblurred key

   // Using min (Key.x, Key.y) means that any softness around
   // the key causes the foreground to shrink in from the edges

   float mix = saturate ((1.0 - min (Key.x, Key.y) * Fgd.a) * 2.0);

   if (Reveal) {
      retval = lerp (mix, 1.0 - mix, Invert);
      retval.a = 1.0;
   }
   else if (Invert) {
      retval = lerp (Bgd, Fgd, mix * Bgd.a);
      retval.a = max (Bgd.a, mix);
   }
   else {
      if (Key.w > 0.8) {
         float fgLum = dot (Fgd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));

         // Remove spill..

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

technique ChromakeyDVE
{
   pass P_1
   < string Script = "RenderColorTarget0 = InpCrop;"; >
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   < string Script = "RenderColorTarget0 = InpDVE;"; >
   { PixelShader = compile PROFILE ps_dve (); }

   pass P_3
   < string Script = "RenderColorTarget0 = RawKey;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_4
   < string Script = "RenderColorTarget0 = BlurKey1;"; >
   { PixelShader = compile PROFILE ps_blur1 (); }

   pass P_5
   < string Script = "RenderColorTarget0 = BlurKey2;"; >
   { PixelShader = compile PROFILE ps_blur2 (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}
