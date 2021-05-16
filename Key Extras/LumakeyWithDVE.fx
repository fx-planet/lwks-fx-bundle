// @Maintainer jwrl
// @Released 2021-05-16
// @Author jwrl
// @Created 2021-05-16
// @see https://www.lwks.com/media/kunena/attachments/6375/LumakeyWithDVE_640.png

/**
 DESCRIPTION:
 This is a luminance key similar to the Lightworks effect, but with some differences.  A crop
 function and a simple DVE have been included to provide these often-needed functions without
 the need to add any external effects.

 DIFFERENCES:
 The most obvious difference from the Lightworks version is in the way that the parameters
 are identified.  "Tolerance" is labelled "Key clip" in this effect, "Edge Softness" is now
 "Key Softness" and "Invert" has become "Invert key".  These are the industry standard terms
 used for these functions, so this change makes the effect more consistent with any existing
 third party key software.

 Regardless of whether the key is inverted or not, the clip setting in this keyer always works
 from black at 0% to white at 100%.  In the Lightworks effect the equivalent setting changes
 sense when the key is inverted.  This is unexpected to say the least and has been avoided.
 Key softness in this effect is symmetrical around the key edge.  This is consistent with the
 way that a traditional analog luminance keyer works.  The background image can be suppressed
 so that the alpha signal produced can be passed on to other effects.

 DVE AND CROP COMPONENTS:
 Cropping can be set up by dragging the upper left and lower right corners of the crop area
 on the edit viewer, or in the normal way by dragging the sliders.  The crop is a simple hard
 edged one, and operates before the DVE.  The DVE is a simple 2D DVE, and unlike the earlier
 version of this effect scaling is now implemented identically to the Lightworks 2D DVE.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LumakeyWithDVE.fx
//
// NOTE:  This keyer uses an algorithm derived from the LWKS Software Ltd lumakey effect,
// but this implementation is entirely my own.
//
// Version history:
//
// Rewrite 2021-05-16 jwrl.
// Complete rewrite of the original effect to make it fully compliant with the resolution
// independent model used in Lightworks 2021 and higher.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lumakey with DVE";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "A keyer which respects any existing foreground alpha and can pass the generated alpha to external effects";
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

#define CompileShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define BadPos(P, p1, p2) (P < max (0.0, p1)) || (P > min (1.0, 1.0 - p2))
#define Bad_XY(XY, L, R, T, B)  (BadPos (XY.x, L, R) || BadPos (XY.y, T, B))

#define EMPTY 0.0.xxxx

#define R_LUMA 0.2989
#define G_LUMA 0.5866
#define B_LUMA 0.1145

#define SHOW_BGD 1

float _BgXScale = 1.0;
float _BgYScale = 1.0;
float _FgXScale = 1.0;
float _FgYScale = 1.0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float KeyClip
<
   string Group = "Key settings";
   string Description = "Key clip";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Softness
<
   string Group = "Key settings";
   string Description = "Key softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

bool InvertKey
<
   string Group = "Key settings";
   string Description = "Invert key";
> = false;

bool ShowAlpha
<
   string Group = "Key settings";
   string Description = "Display alpha channel";
> = false;

bool HideBg
<
   string Group = "Key settings";
   string Description = "Hide background";
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

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   // This DVE section is a much cutdown version of the Lightworks 2D DVE.  It doesn't
   // include drop shadow generation which would be pointless in this configuration.
   // The first section adjusts the position allowing for the foreground resolution.
   // A resolution corrected scale factor is also created and applied.

   float Xpos = (0.5 - CentreX) * _BgXScale / _FgXScale;
   float Ypos = (CentreY - 0.5) * _BgYScale / _FgYScale;
   float scaleX = max (0.00001, MasterScale * XScale / _FgXScale);
   float scaleY = max (0.00001, MasterScale * YScale / _FgYScale);

   float2 xy = uv1 + float2 (Xpos, Ypos);

   xy.x = ((xy.x - 0.5) / scaleX) + 0.5;
   xy.y = ((xy.y - 0.5) / scaleY) + 0.5;

   // Now the scaled, positioned and cropped Fg is recovered along with Bg.

   float4 Fgd = Bad_XY (xy, CropL, CropR, CropT, CropB) ? EMPTY : tex2D (s_Foreground, xy);
   float4 Bgd = HideBg ? EMPTY : tex2D (s_Background, uv2);

   // From now on is the lumakey.  We first set up the key clip and softness from the
   // Fgd luminance.

   float luma  = dot (Fgd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   float edge  = max (0.00001, Softness);
   float clip  = (KeyClip * 1.0002) - (edge * 0.5) - 0.0001;
   float alpha = saturate ((luma - clip) / edge);

   // Now invert the alpha channel if necessary and combine it with Fgd.a.

   if (InvertKey) alpha = 1.0 - alpha;

   alpha = min (Fgd.a, alpha);

   // Exit, showing the composite result or the alpha channel as opaque white on black.

   return (ShowAlpha) ? float4 (alpha.xxx, 1.0) : lerp (Bgd, Fgd, alpha * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LumakeyWithDVE
{
   pass P_1 CompileShader (ps_main)
}
