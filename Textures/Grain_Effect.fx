// @Maintainer jwrl
// @Released 2020-11-15
// @Author khaver
// @Created 2011-04-17
// @see https://www.lwks.com/media/kunena/attachments/6375/Grain_640.png

/**
 This is a simple means of applying a video noise style of grain.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Grain_Effect.fx
//
// Version history:
//
// Update 2020-11-15 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 7 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Cross platform compatibility check 2 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Fully defined float3 variable to fix the behavioural differences between the D3D and
// Cg compilers in mathematical functions.
//
// Subcategory added by jwrl 10 Feb 2017
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Grain effect";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "This is a simple means of applying a video noise style of grain";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Input;

sampler FgSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Strength
<
	string Description = "Strength";
	string Group = "Master";
	float MinVal = 0.00;
	float MaxVal = 100.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _Progress;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float _rand(float2 co, float seed){
    float rand;
	rand = frac((dot(co.xy,float2(co.x+123,co.y+13))) * seed + _Progress);
	return rand;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main ( float2 xy : TEXCOORD1 ) : COLOR
{
   float2 loc;
   loc.x = xy.x + 0.00013f;
   loc.y = xy.y + 0.00123f;
   if (loc.x > 1.0f) loc.x = 1.0f;
   if (loc.y > 1.0f) loc.y = 1.0f;
   float4 source = tex2D( FgSampler, xy );
   float x = sin(loc.x) + cos(loc.y) + _rand(loc,((source.g+1.0)*loc.x)) * 1000;
   float grain = frac(fmod(x, 13) * fmod(x, 123)) - 0.5f;

   source.rgb = saturate (source.rgb + (grain * (Strength / 100)).xxx);
  
   return source;

}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Grain
{
   pass SinglePass
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
