// @Maintainer jwrl
// @Released 2018-12-26
// @Author khaver
// @Created 2011-05-18
// @see https://www.lwks.com/media/kunena/attachments/6375/ChromaticAbberationFixer_640.png

/**
This effect is pretty self explanatory.  When you need it, you need it.  It zooms in and
out of the red, green and blue channels independently to help remove the colour fringing
(chromatic aberration) in areas near the edges of the frame often produced by cheaper
lenses.  To see the fringing better while adjusting click the saturation check box.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromaticAbFixer.fx
//
// Cross platform compatibility check 29 July 2017 jwrl.
// Explicitly defined samplers to correct for platform default sampler state differences.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Addressing has been changed from Clamp to Mirror to bypass a bug in XY sampler
// addressing on Linux and OS-X platforms.  This effect should now function correctly
// when used with all current and previous Lightworks versions.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 2018-12-05 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified 26 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chromatic aberration fixer";
   string Category    = "Stylize";
   string SubCategory = "Repair tools";
   string Notes       = "Generates or removes chromatic aberration";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture V;

sampler VSampler = sampler_state
{
   Texture = <V>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float radjust
<
   string Description = "Red adjust";
   float MinVal       = -1.0f;
   float MaxVal       = 1.0f;
> = 0.0f; // Default value

float gadjust
<
   string Description = "Green adjust";
   float MinVal       = -1.0f;
   float MaxVal       = 1.0f;
> = 0.0f; // Default value

float badjust
<
   string Description = "Blue adjust";
   float MinVal       = -1.0f;
   float MaxVal       = 1.0f;
> = 0.0f; // Default value

bool saton
<
   string Description = "Saturation";
   string Group = "Saturation";
> = false;

float sat
<
   string Description = "Adjustment";
   string Group = "Saturation";
   float MinVal       = 0.0f;
   float MaxVal       = 4.0f;
> = 2.0f; // Default value

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 CAFix( float2 xy : TEXCOORD1 ) : COLOR
{
   float satad = sat;
   if (!saton) satad = 1.0f;
   float lumw = float3(0.299,0.587,0.114);
   float rad = ((radjust * 2 + 4)/100) + 0.96;
   float gad = ((gadjust * 2 + 4)/100) + 0.96;
   float bad = ((badjust * 2 + 4)/100) + 0.96;
   float red = tex2D(VSampler, float2( ((xy.x-0.5f)/(rad*_OutputAspectRatio/_OutputAspectRatio))+0.5f, ((xy.y-0.5f)/rad)+0.5f )).r;
   float green = tex2D(VSampler, float2( ((xy.x-0.5f)/(gad*_OutputAspectRatio/_OutputAspectRatio))+0.5f, ((xy.y-0.5f)/gad)+0.5f )).g;
   float blue = tex2D(VSampler, float2( ((xy.x-0.5f)/(bad*_OutputAspectRatio/_OutputAspectRatio))+0.5f, ((xy.y-0.5f)/bad)+0.5f )).b;
   float alpha = tex2D(VSampler,xy).a;
   float3 source = float3(red,green,blue);
   float3 lum = dot(source, lumw);
   float3 dest = lerp(lum, source, satad);
   return float4(dest,alpha);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique CAFixer
{
   pass SinglePass
   {
      PixelShader = compile PROFILE CAFix();
   }
}
