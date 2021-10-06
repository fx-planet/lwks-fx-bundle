// @Maintainer jwrl
// @Released 2021-10-06
// @Author jwrl
// @Created 2021-10-06
// @see https://www.lwks.com/media/kunena/attachments/6375/ChromakeyWithDVE_640.png

/**
 This effect is a customised version of the Lightworks Chromakey effect with cropping and
 some simple DVE adjustments added.

 The ChromaKey sections are copyright (c) LWKS Software Ltd.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromakeyWithDVE.fx
//
// Version history:
//
// Rewrite 2021-10-06 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chromakey with DVE";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "A customised version of the Lightworks Chromakey effect with cropping and a simple DVE";
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

#define ExecuteShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define BadPos(P, p1, p2) (P < max (0.0, p1)) || (P > min (1.0, 1.0 - p2))
#define Bad_XY(XY, L, R, T, B)  (BadPos (XY.x, L, R) || BadPos (XY.y, T, B))

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define allPos(RGB) (all (RGB > 0.0))

#define HUE_IDX 0          // LWKS chromakey definitions
#define SAT_IDX 1
#define VAL_IDX 2

float _FallOff = 0.12;
float _oneSixth = 1.0 / 6.0;
float _minTolerance = 1.0 / 256.0;

float _OutputWidth  = 1.0;
float _OutputHeight = 1.0;

float _BgXScale = 1.0;
float _BgYScale = 1.0;
float _FgXScale = 1.0;
float _FgYScale = 1.0;

float blur[] = { 20.0 / 64.0, 15.0 / 64.0, 6.0  / 64.0, 1.0  / 64.0 };  // See Pascals Triangle

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_Background);

DefineTarget (RawFg, s_Foreground);
DefineTarget (DVEvid, s_DVEvideo);
DefineTarget (RawKey, s_RawKey);
DefineTarget (BlurKey, s_BlurKey);
DefineTarget (FullKey, s_FullKey);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float4 KeyColour
<
   string Group = "Chromakey";
   string Description = "Key Colour";
   string Flags = "SpecifiesColourRange";
>;

float4 Tolerance
<
   string Group = "Chromakey";
   string Description = "Tolerance";
   string Flags = "SpecifiesColourRange";
   bool Visible = false;
>;

float4 ToleranceSoftness
<
   string Group = "Chromakey";
   string Description = "Tolerance softness";
   string Flags = "SpecifiesColourRange";
   bool Visible = false;
>;

float KeySoftAmount
<
   string Group = "Chromakey";
   string Description = "Key softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float RemoveSpill
<
   string Group = "Chromakey";
   string Description = "Remove spill";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool Invert
<
   string Group = "Chromakey";
   string Description = "Invert";
> = false;

bool Reveal
<
   string Group = "Chromakey";
   string Description = "Reveal";
> = false;

float CentreX
<
   string Description = "DVE Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float CentreY
<
   string Description = "DVE Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float MasterScale
<
   string Group = "DVE Scale";
   string Description = "Master";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float XScale
<
   string Group = "DVE Scale";
   string Description = "X";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float YScale
<
   string Group = "DVE Scale";
   string Description = "Y";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float CropL
<
   string Group = "DVE Crop";
   string Description = "Left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropT
<
   string Group = "DVE Crop";
   string Description = "Top";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropR
<
   string Group = "DVE Crop";
   string Description = "Right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropB
<
   string Group = "DVE Crop";
   string Description = "Bottom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }

//-----------------------------------------------------------------------------------------//
// ps_DVE
//
// A much cutdown version of the standard 2D DVE effect, this version doesn't include
// drop shadow generation which would be pointless in this configuration.
//-----------------------------------------------------------------------------------------//
float4 ps_DVE (float2 uv : TEXCOORD3) : COLOR
{
   // The first section adjusts the position allowing for the foreground resolution.
   // A resolution corrected scale factor is also created and applied.

   float Xpos = (0.5 - CentreX);
   float Ypos = (CentreY - 0.5);
   float scaleX = max (0.00001, MasterScale * XScale);
   float scaleY = max (0.00001, MasterScale * YScale);

   float2 xy = uv + float2 (Xpos, Ypos);

   xy.x = ((xy.x - 0.5) / scaleX) + 0.5;
   xy.y = ((xy.y - 0.5) / scaleY) + 0.5;

   // Now the scaled, positioned and cropped foreground is recovered.

   return Bad_XY (xy, CropL, CropR, CropT, CropB) ? EMPTY : GetPixel (s_Foreground, xy);
}

//-----------------------------------------------------------------------------------------//
// ps_keygen
//
// Convert the source to HSV and then compute its similarity with the specified key-colour
//-----------------------------------------------------------------------------------------//
float4 ps_keygen (float2 uv : TEXCOORD3) : COLOR
{
   float keyVal = 1.0;
   float hueSimilarity = 1.0;

   float4 tolerance1 = Tolerance + _minTolerance;
   float4 tolerance2 = tolerance1 + ToleranceSoftness;

   float4 hsva = 0.0;
   float4 rgba = tex2D (s_DVEvideo, uv);

   float maxComponentVal = max (max (rgba.r, rgba.g), rgba.b);
   float minComponentVal = min (min (rgba.r, rgba.g), rgba.b);
   float componentRange  = maxComponentVal - minComponentVal;

   hsva[ VAL_IDX ] = maxComponentVal;
   hsva[ SAT_IDX ] = componentRange / maxComponentVal;

   if (hsva [SAT_IDX] == 0.0) { hsva [HUE_IDX] = 0.0; }   // undefined
   else {
      if (rgba.r == maxComponentVal) { hsva [HUE_IDX] = (rgba.g - rgba.b) / componentRange; }
      else if (rgba.g == maxComponentVal) { hsva [HUE_IDX] = 2.0 + ((rgba.b - rgba.r) / componentRange ); }
      else hsva [HUE_IDX] = 4.0 + ((rgba.r - rgba.g) / componentRange);

      hsva [HUE_IDX] *= _oneSixth;
      if (hsva [HUE_IDX] < 0.0) hsva [HUE_IDX] += 1.0;
      }

   // Calc difference between current pixel and specified key-colour

   float4 diff = abs (hsva - KeyColour);

   if (diff [HUE_IDX] > 0.5) diff [HUE_IDX] = 1.0 - diff [HUE_IDX];

   // Work out the opacity of the corrected pixel

   tolerance2 -= diff;
   diff -= tolerance1;

   if (allPos (tolerance2)) {
      if (allPos (diff)) {
         hueSimilarity = diff [HUE_IDX];
         diff /= ToleranceSoftness;
         keyVal = max (diff [HUE_IDX], max (diff [SAT_IDX], diff [VAL_IDX]));
         keyVal = pow (keyVal, 0.25);
         }
      else keyVal = 0.0;
      }
   else hueSimilarity = diff [HUE_IDX];

   return float4 (keyVal.xxx, 1.0 - hueSimilarity);
}

//-----------------------------------------------------------------------------------------//
// ps_blur1
//
// Blurs the image horizontally using Pascal's triangle
//-----------------------------------------------------------------------------------------//
float4 ps_blur1 (float2 uv : TEXCOORD3) : COLOR
{
   float2 onePixAcross   = float2 (KeySoftAmount / _OutputWidth, 0.0);
   float2 twoPixAcross   = onePixAcross * 2.0;
   float2 threePixAcross = onePixAcross * 3.0;

   float4 retval = tex2D (s_RawKey, uv);

   retval.r *= blur [0];
   retval.r += tex2D (s_RawKey, uv + onePixAcross).r * blur [1];
   retval.r += tex2D (s_RawKey, uv - onePixAcross).r * blur [1];
   retval.r += tex2D (s_RawKey, uv + twoPixAcross).r * blur [2];
   retval.r += tex2D (s_RawKey, uv - twoPixAcross).r * blur [2];
   retval.r += tex2D (s_RawKey, uv + threePixAcross).r * blur [3];
   retval.r += tex2D (s_RawKey, uv - threePixAcross).r * blur [3];

   return retval;
}

//-----------------------------------------------------------------------------------------//
// ps_blur2
//
// Blurs the image vertically
//-----------------------------------------------------------------------------------------//
float4 ps_blur2 (float2 uv : TEXCOORD3) : COLOR
{
   float2 onePixDown   = float2 (0.0, KeySoftAmount / _OutputHeight);
   float2 twoPixDown   = onePixDown * 2.0;
   float2 threePixDown = onePixDown * 3.0;

   float4 retval = tex2D (s_BlurKey, uv);

   retval.r *= blur [0];
   retval.r += tex2D (s_BlurKey, uv + onePixDown).r * blur [1];
   retval.r += tex2D (s_BlurKey, uv - onePixDown).r * blur [1];
   retval.r += tex2D (s_BlurKey, uv + twoPixDown).r * blur [2];
   retval.r += tex2D (s_BlurKey, uv - twoPixDown).r * blur [2];
   retval.r += tex2D (s_BlurKey, uv + threePixDown).r * blur [3];
   retval.r += tex2D (s_BlurKey, uv - threePixDown).r * blur [3];

   return retval;
}

//-----------------------------------------------------------------------------------------//
// ps_main
//
// Blends the cropped, resized and positioned foreground with the background using the
// key that was built in ps_keygen.   Apply spill-suppression as we go.
//-----------------------------------------------------------------------------------------//
float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval;

   float4 fg  = tex2D (s_DVEvideo, uv3);
   float4 bg  = Overflow (uv2) ? BLACK : tex2D (s_Background, uv2);
   float4 key = tex2D (s_FullKey, uv3);

   // key.r = blurred key
   // key.g = raw, unblurred key
   // key.a = spill removal amount

   // Using min (key.r, key.g) means that any softness around the key causes the foreground
   // to shrink in from the edges

   float mix = saturate ((1.0 - min (key.r, key.g) * fg.a) * 2.0);

   if (Reveal) {
      retval = lerp (mix, 1.0 - mix, Invert);
      retval.a = 1.0;
      }
   else {
      if (Invert) {
         retval = lerp (bg, fg, mix * bg.a);
         retval.a = max (bg.a, mix);
         }
      else {
         if (key.a > 0.8) {
            float4 fgLum = (fg.r + fg.g + fg.b) / 3.0;

            // Remove spill..

            fg = lerp (fg, fgLum, ((key.a - 0.8) / 0.2) * RemoveSpill);
            }

         retval = lerp (fg, bg, mix * bg.a);
         retval.a = max (bg.a, 1.0 - mix);
         }

      retval = lerp (bg, retval, Opacity);
      }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ChromakeyWithDVE
{
   pass P_0 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = DVEvid;"; > ExecuteShader (ps_DVE)
   pass P_2 < string Script = "RenderColorTarget0 = RawKey;"; > ExecuteShader (ps_keygen)
   pass P_3 < string Script = "RenderColorTarget0 = BlurKey;"; > ExecuteShader (ps_blur1)
   pass P_4 < string Script = "RenderColorTarget0 = FullKey;"; > ExecuteShader (ps_blur2)
   pass P_5 ExecuteShader (ps_main)
}
