// @Maintainer jwrl
// @Released 2018-04-07
// @Author jwrl
// @Created 2016-09-08
// @see https://www.lwks.com/media/kunena/attachments/6375/CkeyPlus_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/CkeyPlus_4.png
// @see https://www.lwks.com/media/kunena/attachments/6375/CkeyPlus_9d.png
// @see https://www.lwks.com/media/kunena/attachments/6375/CkeyPlus_9b.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromakeyPlus.fx
//
// This is a combination chromakeyer and alpha cleanup tool to be used on problem keys.
// Since it needs a powerful GPU it may not be appropriate for use on a minimal
// Lightworks system.  It uses a modified version of the Editshare chromakey engine at
// its core because after many attempts to, I couldn't improve on it.
//
// It comes with a fair degree of cleanup and despill, and top/ bottom, left/right
// cropping is also provided with ±45 degree angular adjustment of the four individual
// crops.  Inner and outer external masks are also supported.
//
// Modified 11 September 2016 by jwrl.
// Despill now operates on the inner masked key component.  Also added an erode/expand
// capability as well as reorganising and renaming some of the parameters for better
// clarity.  Despill no longer operates on the outer masked key component.  The mask
// and crop overlay parameters have been expanded into their own group and provided
// with a processed mask in and mask out display.  The overlay displays the required
// colour normally, but as black when over fully saturated matching backgrounds.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles interlaced media.  When
// a height parameter is needed one cannot reliably use _OutputHeight, which can
// return wrong values when playing.  That is now fixed.
//
// Bug fix 20 July 2017 by jwrl:
// There was a compatibility issue between D3D (Windows) and Cg (Mac/Linux) compilers
// which caused this effect to fail on the latter.  The default state of the samplers
// differs between the two.  In this version all samplers have now been fully defined
// where they weren't previously.
//
// 8 December 2017 by jwrl:
// The mask inputs were renamed so that they didn't obscure each other when routing
// was shown vertically.  This then necessitated a change to the mask settings
// dialogue so that there was absolute clarity on what each mask did.  Finally the
// ShowOverlay parameter was grouped at the top of the crop setting parameters.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chromakey plus";
   string Category    = "Key";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture M1;
texture M2;

texture RawKey : RenderColorTarget;
texture Crops  : RenderColorTarget;

texture Buff_1 : RenderColorTarget;
texture Buff_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state {
   Texture = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state {
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler M1Sampler = sampler_state {
   Texture   = <M1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler M2Sampler = sampler_state {
   Texture   = <M2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler rKeySampler = sampler_state
{
   Texture = <RawKey>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler CropSampler = sampler_state
{
   Texture = <Crops>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buf1Sampler = sampler_state
{
   Texture   = <Buff_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buf2Sampler = sampler_state
{
   Texture   = <Buff_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int showData
<
   string Group = "Chromakey";
   string Description = "Display key component";
   string Enum = "Final key,Foreground,Background,Mask_in,Mask_out,Preblur,Raw alpha,Processed alpha,Processed mask_in,Processed mask_out";
> = 0;

float Preblur
<
   string Group = "Chromakey";
   string Description = "Preblur";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.0;

float4 KeyColour
<
   string Group = "Chromakey";
   string Description = "Key Colour";
   string Flags = "SpecifiesColourRange";
> = { 150.0, 0.7, 0.75, 0.0 };

float4 Tolerance
<
   string Group = "Chromakey";
   string Description = "Tolerance";
   string Flags = "SpecifiesColourRange";
   bool Visible = false;
> = { 20.0, 0.3, 0.25, 0.0 };

float4 ToleranceSoftness
<
   string Group = "Chromakey";
   string Description = "Tolerance softness";
   string Flags = "SpecifiesColourRange";
   bool Visible = false;
> = { 15.0, 0.115, 0.11, 0.0 };

bool Invert
<
   string Group = "Chromakey";
   string Description = "Invert key";
> = false;

float alphaWhites
<
   string Group = "Fine tune";
   string Description = "Alpha whites";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float alphaBlacks
<
   string Group = "Fine tune";
   string Description = "Alpha blacks";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float alphaGamma
<
   string Group = "Fine tune";
   string Description = "Alpha gamma";
   float MinVal = 0.10;
   float MaxVal = 4.00;
> = 1.00;

float Erode
<
   string Group = "Fine tune";
   string Description = "Erode/expand";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float Feather
<
   string Group = "Fine tune";
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.0;

float RemoveSpill
<
   string Group = "Fine tune";
   string Description = "Remove spill";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

int showOverlay
<
   string Group = "Crop";
   string Description = "Display crop and mask overlays";
   string Enum = "None,All,Crop,Mask in,Mask out,Crop plus Mask in,Crop plus Mask out,Mask in plus Mask out";
> = 0;

float CropT
<
   string Group = "Crop";
   string Description = "Top";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float AngT
<
   string Group = "Crop";
   string Description = "Top rotation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropB
<
   string Group = "Crop";
   string Description = "Bottom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float AngB
<
   string Group = "Crop";
   string Description = "Bottom rotation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropL
<
   string Group = "Crop";
   string Description = "Left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float AngL
<
   string Group = "Crop";
   string Description = "Left rotation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropR
<
   string Group = "Crop";
   string Description = "Right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float AngR
<
   string Group = "Crop";
   string Description = "Right rotation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

bool cropInvert
<
   string Group = "Crop";
   string Description = "Invert crop";
> = false;

int MaskInState
<
   string Group = "External Masks";
   string Description = "M1 mask state";
   string Enum = "Inner mask disabled,Inner mask enabled,Inner mask Inverted";
> = 0;

int maskIn
<
   string Group = "External Masks";
   string Description = "M1 mask channel used";
   string Enum = "Red,Green,Blue,Alpha,Luminance";
> = 4;

int MaskOutState
<
   string Group = "External Masks";
   string Description = "M2 mask state";
   string Enum = "Outer mask disabled,Outer mask enabled,Outer mask Inverted";
> = 0;

int maskOut
<
   string Group = "External Masks";
   string Description = "M2 mask channel used";
   string Enum = "Red,Green,Blue,Alpha,Luminance";
> = 4;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLACK     (0.0).xxxx
#define GREEN     float2(0.0,1.0).xyxx

#define LOOP_1    16
#define END_1     65
#define RADIUS_1  4.5
#define ANGLE_1   0.19634954

#define LOOP_2    12
#define END_2     25
#define RADIUS_2  1.5
#define ANGLE_2   0.26179939

#define HUE_IDX   0
#define SAT_IDX   1
#define VAL_IDX   2

#define ONE_SIXTH  0.16666667
#define MIN_VALUE  0.00390625

#define MAX_GAMMA  10.0

// Display mode values

#define FGND       1
#define BGND       2
#define MASK_IN    3
#define MASK_OUT   4
#define PREBLUR    5
#define RAW_KEY    6
#define PROC_KEY   7
#define PROC_M_IN  8
#define PROC_M_OUT 9

// Display mask values

#define NO_MASKS   0
#define ALL_MASKS  1
#define CROP       2
#define CROP_IN    5
#define CROP_OUT   6
#define MARK_IO    7

// Mask and crop settings

#define MASK_OFF  0
#define MASKINV   2
#define LUMA      4

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - 0.5;

   float crop_T = uv.y - CropT - (xy.x * AngT * _OutputAspectRatio);
   float crop_B = uv.y - CropB + (xy.x * AngB * _OutputAspectRatio);
   float crop_L = uv.x - CropL - (xy.y * AngL / _OutputAspectRatio);
   float crop_R = uv.x - CropR + (xy.y * AngR / _OutputAspectRatio);

   float4 retval = ((crop_T < 0.0) || (crop_B > 0.0) || (crop_L < 0.0) || (crop_R > 0.0)) ? GREEN : BLACK;

   if (MaskInState != MASK_OFF) {
      float4 inMask = tex2D (M1Sampler, uv);

      retval.r = (maskIn == LUMA) ? max (inMask.r, max (inMask.g, inMask.b)) : inMask [maskIn];
   }

   if (MaskOutState != MASK_OFF) {
      float4 outMask = tex2D (M2Sampler, uv);

      retval.b = (maskOut == LUMA) ? max (outMask.r, max (outMask.g, outMask.b)) : outMask [maskOut];
   }

   if (MaskInState  != MASKINV) retval.r = 1.0 - retval.r;
   if (MaskOutState == MASKINV) retval.b = 1.0 - retval.b;

   return float4 (retval.rgb, max (retval.g, retval.b));
}

float4 ps_blur (float2 uv : TEXCOORD1, uniform sampler blurSampler, uniform float feather) : COLOR
{
   float4 retval = tex2D (blurSampler, uv);

   if (feather <= 0.0) return retval;

   float4 ret_1 = retval;
   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * RADIUS_1 * feather / _OutputWidth;

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy.x, xy.y);
      xy *= radius;
      ret_1 += tex2D (blurSampler, uv + xy);
      ret_1 += tex2D (blurSampler, uv - xy);
      xy += xy;
      ret_1 += tex2D (blurSampler, uv + xy);
      ret_1 += tex2D (blurSampler, uv - xy);
   }

   ret_1  /= END_1;
   radius *= RADIUS_2;

   for (int i = 0; i < LOOP_2; i++) {
      sincos ((i * ANGLE_2), xy.x, xy.y);
      xy *= radius;
      retval += tex2D (blurSampler, uv + xy);
      retval += tex2D (blurSampler, uv - xy);
   }

   retval /= END_2;

   return (ret_1 + retval) / 2.0;
}

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 rgba = tex2D (Buf1Sampler, uv);

   if (showData == PREBLUR) return rgba;

   float  maxComponentVal = max (max (rgba.r, rgba.g), rgba.b);
   float  componentRange  = maxComponentVal - min (min (rgba.r, rgba.g), rgba.b);
   float4 hsva = float3 (0.0, componentRange / maxComponentVal, maxComponentVal).xyzx;

   if (hsva [SAT_IDX] != 0.0) {
      hsva [HUE_IDX] = ((rgba.r == maxComponentVal) ? (rgba.g - rgba.b) / componentRange :
                        (rgba.g == maxComponentVal) ? 2.0 + ((rgba.b - rgba.r) / componentRange) : 4.0 + ((rgba.r - rgba.g) / componentRange)) * ONE_SIXTH;

      if (hsva [HUE_IDX] < 0.0) hsva [HUE_IDX] += 1.0;
   }

   float4 diff = abs (hsva - KeyColour);

   if (diff [HUE_IDX] > 0.5) diff [HUE_IDX] = 1.0 - diff [HUE_IDX];

   float  keyVal = 1.0, hueSimilarity = 1.0;
   float4 tolerance = Tolerance + MIN_VALUE - diff;
   float4 spread = tolerance + ToleranceSoftness;

   diff = -tolerance;

   if ((spread.r > 0.0) && (spread.g > 0.0) && (spread.b > 0.0)) {
      if ((tolerance.r > 0.0) && (tolerance.g > 0.0) && (tolerance.b > 0.0)) { keyVal = 0.0; }
      else {
         hueSimilarity = diff [HUE_IDX];
         diff /= ToleranceSoftness;
         keyVal = max (diff [HUE_IDX], max (diff [SAT_IDX], diff [VAL_IDX]));
         keyVal = pow (keyVal, 0.25);
      }
   }
   else hueSimilarity = diff [HUE_IDX];

   return (Invert) ? float4 ((1.0 - keyVal).xxx, hueSimilarity) : float4 (keyVal.xxx, 1.0 - hueSimilarity);
}

float4 ps_erode (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (Buf2Sampler, uv);

   if (Erode == 0.0) return retval;

   float  ret_1 = retval.g;
   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * RADIUS_1 * abs (Erode) / _OutputWidth;

   radius *= RADIUS_2;

   if (Erode > 0.0) {
      for (int i = 0; i < LOOP_2; i++) {
         sincos ((i * ANGLE_2), xy.x, xy.y);
         xy *= radius;
         ret_1 = max (ret_1, tex2D (Buf2Sampler, uv + xy).r);
         ret_1 = max (ret_1, tex2D (Buf2Sampler, uv - xy).r);
      }
   }
   else {
      for (int i = 0; i < LOOP_2; i++) {
         sincos ((i * ANGLE_2), xy.x, xy.y);
         xy *= radius;
         ret_1 = min (ret_1, tex2D (Buf2Sampler, uv + xy).r);
         ret_1 = min (ret_1, tex2D (Buf2Sampler, uv - xy).r);
      }
   }

   return float4 (ret_1.xx, retval.ba);
}

float4 ps_composite (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd  = tex2D (FgSampler, xy1);
   float4 Bgd  = tex2D (BgSampler, xy2);
   float4 key  = tex2D (rKeySampler, xy1);
   float4 crop = tex2D (CropSampler, xy1);

   if (showData == PREBLUR) return tex2D (Buf2Sampler, xy1);
   else if (showData == MASK_IN) return tex2D (M1Sampler, xy1);
   else if (showData == MASK_OUT) return tex2D (M2Sampler, xy1);
   else if (showData == FGND) return Fgd;
   else if (showData == BGND) return Bgd;
   else if (showData == RAW_KEY) return float2 (1.0 - key.b, 1.0).xxxy;

   key.r = tex2D (Buf1Sampler, xy1).r;
   key.r = saturate ((((1.0 - min (key.r, key.g) * Fgd.a) * 2.0) * (1.0 + alphaWhites)) + alphaBlacks);

   float gamma = (alphaGamma <= 0.1) ? MAX_GAMMA : 1.0 / alphaGamma;
   float mix   = pow (key.r, gamma);

   if (showData == PROC_KEY) return float2 (mix, 1.0).xxxy;
   else if (showData == PROC_M_IN) return float2 (1.0 - crop.r, 1.0).xxxy;
   else if (showData == PROC_M_OUT) return float4 (crop.bbb, 1.0);

   mix = min (crop.r, mix);

   if (cropInvert) {
      mix = max (crop.b, min (crop.g, mix));
      key.a = min ((1.0 - crop.b), key.a);
   }
   else {
      mix = max (crop.a, mix);
      key.a = min ((1.0 - crop.a), key.a);
   }

   if (key.a > 0.8) {
      float4 FgdLum = (Fgd.r + Fgd.g + Fgd.b) / 3.0;

      Fgd = lerp (Fgd, FgdLum, ((key.a - 0.8) / 0.2) * RemoveSpill);
   }

   float4 retval = lerp (Fgd, Bgd, mix * Bgd.a);

   return float4 (retval.rgb, max (Bgd.a, 1.0 - mix));
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Comp = tex2D (Buf2Sampler, uv);

   if (showOverlay == NO_MASKS) return Comp;

   float2 pixDiag = float2 (2.0, 2.0 * _OutputAspectRatio) / _OutputWidth;
   float4 crop = tex2D (CropSampler, uv);

   crop = tex2D (CropSampler, uv - pixDiag);

   float4 cropmax = tex2D (CropSampler, uv + pixDiag);
   float4 retval = min (crop, cropmax);

   pixDiag.y = -pixDiag.y;

   float4 cropmin = tex2D (CropSampler, uv + pixDiag);

   retval  = min (retval, cropmin);
   cropmax = max (cropmax, max (crop, cropmin));
   cropmin = tex2D (CropSampler, uv - pixDiag);
   cropmax = max (cropmax, cropmin);

   retval = saturate (cropmax - min (retval, cropmin));

   if ((showOverlay == CROP) || (showOverlay == CROP_OUT) || (showOverlay == MASK_OUT)) retval.r = 0.0;
   if ((showOverlay == MASK_IN) || (showOverlay == MASK_OUT) || (showOverlay == MARK_IO)) retval.g = 0.0;
   if ((showOverlay == CROP) || (showOverlay == CROP_IN) || (showOverlay == MASK_IN)) retval.b = 0.0;

   retval.a = max (retval.r, max (retval.g, retval.b));
   cropmin.rgb = (Comp.gbr + Comp.brg) / 2.0;
   cropmin = saturate (Comp - cropmin);

   if (cropmin.r > 0.75) retval.r = 0.0;
   if (cropmin.g > 0.75) retval.g = 0.0;
   if (cropmin.b > 0.75) retval.b = 0.0;

   return lerp (Comp, retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique cKeyPlus
{
   pass P_1
   < string Script = "RenderColorTarget0 = Crops;"; >
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Buff_1;"; >
   { PixelShader = compile PROFILE ps_blur (FgSampler, Preblur); }

   pass P_3
   < string Script = "RenderColorTarget0 = Buff_2;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_4
   < string Script = "RenderColorTarget0 = RawKey;"; >
   { PixelShader = compile PROFILE ps_erode (); }

   pass P_5
   < string Script = "RenderColorTarget0 = Buff_1;"; >
   { PixelShader = compile PROFILE ps_blur (rKeySampler, Feather); }

   pass P_6
   < string Script = "RenderColorTarget0 = Buff_2;"; >
   { PixelShader = compile PROFILE ps_composite (); }

   pass P_7
   { PixelShader = compile PROFILE ps_main (); }
}
