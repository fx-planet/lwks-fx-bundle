// @Maintainer jwrl
// @Released 2020-09-29
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
// Update 2020-09-29 jwrl.
// Revised header block.
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
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture fg;
texture bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FGround = sampler_state {
        Texture = <fg>;
        AddressU = Clamp;
        AddressV = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };
sampler BGround = sampler_state {
        Texture = <bg>;
        AddressU = Clamp;
        AddressV = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };

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
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.0f;

bool green
<
	string Description = "Green";
> = true;

float gthresh
<
	string Description = "Green Threshold";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.0f;

bool blue
<
	string Description = "Blue";
> = true;

float bthresh
<
	string Description = "Blue Threshold";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.0f;

float mthresh
<
	string Description = "Master Threshold";
	float MinVal = -1.0f;
	float MaxVal = 1.0f;
> = 0.0f;

float bgain
<
	string Description = "Background Gain";
	float MinVal = 0.0f;
	float MaxVal = 2.0f;
> = 1.0f;

bool invert
<
	string Description = "Invert Mask";
> = false;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 DoIt( float2 uv : TEXCOORD1 ) : COLOR
{
  float4 FG, BG, ocolor;
  float delt;
  float ralph, galph, balph, alph;
  if (swap) {
    BG = tex2D( FGround, uv);
    FG = tex2D( BGround, uv);
  }
  else {
    BG = tex2D( BGround, uv);
    FG = tex2D( FGround, uv);
  }
  BG *= bgain;
 if (split && !show) {
    if (uv.x < 0.5) ocolor = FG; 
    else  ocolor = BG;
	return ocolor;
  }	
  ralph = abs(BG.r - FG.r);
  galph = abs(BG.g - FG.g);
  balph = abs(BG.b - FG.b);
  if (!red) ralph = 0.0;
  if (!green) galph = 0.0;
  if (!blue) balph = 0.0;
  if (ralph <= rthresh + mthresh && galph <= gthresh + mthresh && balph <= bthresh + mthresh) alph = 0.0;
  else alph = 1.0;
  if (invert) alph = 1.0 - alph;
  if (show) ocolor = float4(alph, alph, alph, 1.0);
  else ocolor = float4(FG.r, FG.g, FG.b, alph);
  return ocolor;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{

   pass Pass1
   {
      PixelShader = compile PROFILE DoIt();
   }
}
