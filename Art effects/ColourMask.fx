// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect ColourMask.fx
//
// Created by LW user jwrl 25 September 2017
// @Author jwrl
// @Created "25 September 2017"
//
// This effect duplicates the so-called "Pleasantville" effect.
// It's a modified version of the key generation section of
// Editshare's chromakey effect.  Angled cropping from my own
// octagonal vignette effect has been added to provide masking
// of areas of the selected colour that are not required.
//
// The parameters are grouped into three classifications: a
// master group, and the colour selection and crop groups.
// The latter two should be self explanatory.
//
// In the master effect settings the "Amount" adjustment
// runs from zero (no effect) to 100%.  The zero setting is
// helpful when setting up the colour mask, since it just
// shows the input video.  The saturation is adjustable
// from -100% to +100% and only affects the masked colour,
// and then only when the effect is visible.
//
// And for what it's worth, I deliberately chose not to use
// the name "Pleasantville" here.  I hate that name.  This
// effect has been used in film well prior to its use in that
// movie.  I've personally used it in the 1970s, and I've seen
// it used in movies as early as the late 1940s.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Colour mask";
   string Category    = "Colour";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Inp;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InpSampler = sampler_state
{
   Texture   = <Inp>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Group = "Master effect settings";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Saturation
<
   string Group = "Master effect settings";
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float4 KeyColour
<
   string Group = "Colour mask selection";
   string Description = "Key Colour";
   string Flags = "SpecifiesColourRange";
>;

float4 Tolerance
<
   string Group = "Colour mask selection";
   string Description = "Tolerance";
   string Flags = "SpecifiesColourRange";
   bool Visible = false;
>;

float4 ToleranceSoftness
<
   string Group = "Colour mask selection";
   string Description = "Tolerance softness";
   string Flags = "SpecifiesColourRange";
   bool Visible = false;
>;

bool Invert
<
   string Group = "Colour mask selection";
   string Description = "Invert colour selection";
> = false;

float CropT
<
   string Group = "Colour mask cropping";
   string Description = "Top";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float AngT
<
   string Group = "Colour mask cropping";
   string Description = "Top slope";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropB
<
   string Group = "Colour mask cropping";
   string Description = "Bottom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float AngB
<
   string Group = "Colour mask cropping";
   string Description = "Bottom slope";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropL
<
   string Group = "Colour mask cropping";
   string Description = "Left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float AngL
<
   string Group = "Colour mask cropping";
   string Description = "Left slope";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropR
<
   string Group = "Colour mask cropping";
   string Description = "Right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float AngR
<
   string Group = "Colour mask cropping";
   string Description = "Right slope";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

bool ShowMask
<
   string Group = "Colour mask cropping";
   string Description = "Show colour mask area";
> = false;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define EMPTY   (0.0).xxxx
#define BLACK   float2 (0.0, 1.0).xxxy

#define HUE_IDX 0
#define SAT_IDX 1
#define VAL_IDX 2

#define MIN_VAL (1.0 / 256.0).xxxx

float _OutputAspectRatio;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (InpSampler, uv);
   float4 Bgd = float4 (dot (Fgd.rgb, float3 (0.2989, 0.5866, 0.1145)).xxx, Fgd.a);
   float4 hsva = EMPTY;

   float4 tolerance1 = Tolerance + MIN_VAL;
   float4 tolerance2 = tolerance1 + ToleranceSoftness;

   float2 cropBR, cropTL, xy = uv - (0.5).xx;

   cropBR.x = uv.x - CropR + (xy.y * AngR / _OutputAspectRatio);
   cropBR.y = uv.y - CropB + (xy.x * AngB * _OutputAspectRatio);
   cropTL.x = uv.x - CropL - (xy.y * AngL / _OutputAspectRatio);
   cropTL.y = uv.y - CropT - (xy.x * AngT * _OutputAspectRatio);

   float mask = ((cropTL.x < 0.0) || (cropTL.y < 0.0) || (cropBR.x > 0.0) || (cropBR.y > 0.0)) ? 0.0 : 1.0;

   float maxVal = max (max (Fgd.r, Fgd.g), Fgd.b);
   float minVal = min (min (Fgd.r, Fgd.g), Fgd.b);
   float range  = maxVal - minVal;

   float hueValue = 1.0;
   float hueSimilarity = 1.0;

   hsva [VAL_IDX] = maxVal;
   hsva [SAT_IDX] = range / maxVal;

   if (hsva [SAT_IDX] != 0.0) {
      hsva [HUE_IDX] = (Fgd.r == maxVal) ? (Fgd.g - Fgd.b) / range
                     : (Fgd.g == maxVal) ? ((Fgd.b - Fgd.r) / range) + 2.0
                                         : ((Fgd.r - Fgd.g) / range) + 4.0;

      hsva [HUE_IDX] /= 6.0;

      if (hsva [HUE_IDX] < 0.0) hsva [HUE_IDX] += 1.0;
   }

   float4 diff = abs (hsva - KeyColour);

   if (diff [HUE_IDX] > 0.5) diff [HUE_IDX] = 1.0 - diff [HUE_IDX];

   diff [HUE_IDX] = abs (diff [HUE_IDX]);

   bool4 tolTest = (tolerance2 > diff);

   if (tolTest.x && tolTest.y && tolTest.z) {

      tolTest = (tolerance1 > diff);

      if (tolTest.x && tolTest.y && tolTest.z) { hueValue = 0.0; }
      else {
         diff -= tolerance1;
         hueSimilarity = diff [HUE_IDX];
         diff /= ToleranceSoftness;
         hueValue = max (diff [HUE_IDX], max (diff [SAT_IDX], diff [VAL_IDX]));
         hueValue = pow (hueValue, 0.25);
      }
   }
   else {
      diff -= tolerance1;
      hueSimilarity = diff [HUE_IDX];
   }

   hueValue = saturate ((hueValue + hueSimilarity - 1.0) * 2.0);
   hueValue = (1.0 - saturate (pow (hueValue, 0.25) * 1.5)) * mask;  // Scientifically determined "suck it and see" values!!!

   if (Invert) hueValue = 1.0 - hueValue;

   Fgd = lerp (Bgd, Fgd, (Saturation * Amount) + 1.0);
   Bgd = lerp (Fgd, Bgd, Amount);
   Fgd = lerp (Bgd, Fgd, hueValue);

   if (ShowMask) return lerp (BLACK, Fgd, mask);

   return Fgd;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Pleasantville
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

