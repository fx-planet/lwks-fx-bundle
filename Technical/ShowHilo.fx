// @Maintainer jwrl
// @Released 2020-09-28
// @Author juhartik
// @AuthorEmail juha@linearteam.org
// @Created 2016-05-09
// @see https://www.lwks.com/media/kunena/attachments/6375/JHshowHiLo_640.png

/**
 This effect blinks extreme blacks and whites.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ShowHiLo.fx
//
// JH Analysis Show Hi/Lo v1.0 - Juha Hartikainen - juha@linearteam.org - Blinks extreme
// darks/highlights.
//
// Version history:
//
// Update 2020-09-28 jwrl.
// Revised header block.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified by LW user jwrl 6 December 2018.
// Changed effect name.
// Changed subcategory.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
// 
// Modified 11 February 2017 jwrl.
// Modified to sit in user category "Analysis" for version 14.  This will actually show
// as category "User", subcategory "Analysis" in 14 and as category "User" in earlier
// versions.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Show highs and lows";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "This effect blinks blacks and whites that exceed preset levels";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Input;

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float LoLimit
<
   string Description = "Low Limit";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float HiLimit
<
   string Description = "High Limit";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.95;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _Progress = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

half4 MainPS(float2 xy : TEXCOORD1) : COLOR
{
   float weight, flash;

   float4 color = tex2D(FgSampler, xy);

   weight=(color.r+color.g+color.b)/3.0;

   if ((weight <= LoLimit) || (weight >= HiLimit)) {
      if (frac(_Progress*50)>0.5) {
         flash = 1.0;
      } else flash = 0.0;

      color.r = color.g = color.b = flash;
   }

   return color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ShowHiLo
{
   pass p0
   {
      PixelShader = compile PROFILE MainPS();
   }
}
