// @Maintainer jwrl
// @Released 2021-10-06
// @Author khaver
// @Released 2016-10-19
// @see https://www.lwks.com/media/kunena/attachments/6375/DeltaMask_640.png

/**
 This is a delta mask or difference matte effect which  subtracts the background from the
 foreground to produce an image with transparency.  This can then be used with external
 blend or DVE effects in the same way as a title or image key.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DeltaMaskFx.fx
//
// Version history:
//
// Update 2021-10-06 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//
// Update 2020-11-13 jwrl.
// Added Cansize switch for LW 2021 support.
//
// Modified 3 September 2020 by user jwrl:
// Corrected "Notes" text.
// Corrected the descriptive text, which related to an entirely different effect.
// 
// Modified 23 Dec 2018 by user jwrl:
// Added creation date.
// Reformatted the effect description for markup purposes.
//
// Modified 26 Nov 2018 by user schrauber:
// Changed subcategory from "User Effects" to "Key Extras".
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14 update 18 Feb 2017 jwrl.
// Changed category from "Keying" to "Key", added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "DeltaMask";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "This delta mask effect removes the background from the foreground.";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (fg, FGround);
DefineInput (bg, BGround);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool show
<
   string Description = "Show";
> = false;

bool split
<
   string Description = "Split Screen";
> = false;

bool swap
<
   string Description = "Swap Tracks";
> = false;

bool red
<
   string Description = "Red";
> = true;

float rthresh
<
   string Description = "Red Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

bool green
<
   string Description = "Green";
> = true;

float gthresh
<
   string Description = "Green Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

bool blue
<
   string Description = "Blue";
> = true;

float bthresh
<
   string Description = "Blue Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float mthresh
<
   string Description = "Master Threshold";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float bgain
<
   string Description = "Background Gain";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

bool invert
<
   string Description = "Invert Mask";
> = false;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 DoIt (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 FG, BG, ocolor;

   float delt;
   float ralph, galph, balph, alph;

   if (swap) {
      BG = GetPixel (FGround, uv1);
      FG = GetPixel (BGround, uv2);
   }
   else {
      BG = GetPixel (BGround, uv2);
      FG = GetPixel (FGround, uv1);
   }

   BG *= bgain;

   if (split && !show) {
      ocolor = (uv1.x < 0.5) ? FG : BG;

      return ocolor;
   }	

   ralph = abs (BG.r - FG.r);
   galph = abs (BG.g - FG.g);
   balph = abs (BG.b - FG.b);

   if (!red) ralph = 0.0;
   if (!green) galph = 0.0;
   if (!blue) balph = 0.0;

   alph = (ralph <= rthresh + mthresh && galph <= gthresh + mthresh && balph <= bthresh + mthresh)
        ? 0.0 : 1.0;

   if (invert) alph = 1.0 - alph;

   return (show) ? float4 (alph.xxx, 1.0) : float4 (FG.rgb, alph);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique { pass Pass1 ExecuteShader (DoIt) }

