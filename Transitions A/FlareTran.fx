// @Maintainer jwrl
// @Released 2018-04-09
// @Author khaver
// @see https://www.lwks.com/media/kunena/attachments/6375/FlareTran.png
// @see https://www.lwks.com/media/kunena/attachments/6375/FlareTran.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlareTran.fx
//
// FlareTran is a transition that dissolves through an over-exposure style flare.
// Amongst other things it can be used to simulate the burn out effect that happens
// when a film camera stops.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles interlaced media.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "FlareTran";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture InClip;
texture OutClip;
texture Sample : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state
{
   Texture = <InClip>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler OutputSampler = sampler_state
{
   Texture = <OutClip>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp1 = sampler_state
{
   Texture = <Sample>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool Swap
<
	string Description = "Swap target track";
> = false;

float CentreX
<
   string Description = "Origin";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float CentreY
<
   string Description = "Origin";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0f;
   float MaxVal = 1.0f;
> = 0.2f;

float stretch
<
   string Description = "Stretch";
   float MinVal = 0.0f;
   float MaxVal = 10.0f;
> = 5.0f;

float Timing
<
   string Description = "Timing";
   float MinVal = 0.0f;
   float MaxVal = 1.0f;
> = 0.5f;

float adjust
<
   string Description = "Progress";
   float MinVal = 0.0f;
   float MaxVal = 1.0f;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5f;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

#define OutputHeight (_OutputWidth/_OutputAspectRatio)

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_adjust ( float2 xy : TEXCOORD1 ) : COLOR
{
   float flare = (adjust * 2.0) - 1.0;
   flare = 1.0 - abs(flare);
   float4 Color;
   if (Swap) Color = tex2D( OutputSampler, xy);
   else Color = tex2D( InputSampler, xy);
   if (Color.r < 1.0f-flare) Color.r = 0.0f;
   if (Color.g < 1.0f-flare) Color.g = 0.0f;
   if (Color.b < 1.0f-flare) Color.b = 0.0f;
   return Color;
}

float4 ps_main( float2 xy1 : TEXCOORD1 ) : COLOR
{
   float4 ret;
   float Stretch = 10.0 - stretch;
   float2 amount = float2 (1.0, _OutputAspectRatio) * Stretch / _OutputWidth;

   float centreY = 1.0f - CentreY;

   float x = xy1.x - CentreX;
   float y = xy1.y - centreY;

   float2 adj = amount;
   float flare = Strength * 2.0;
   if (flare > 1.0) flare = 2.0 - flare;
   
   float4 source;
   if (adjust < Timing) source = tex2D( InputSampler, xy1 );
   else source = tex2D( OutputSampler, xy1 );
   //float4 negative = tex2D( Samp1, xy1 );
   ret = tex2D( Samp1, float2( x * adj.x + CentreX, y * adj.y + centreY ) );

   for (int count = 1; count < 15; count++) {
   adj += amount;
   ret += tex2D( Samp1, float2( x * adj.x + CentreX, y * adj.y + centreY ) )*(count*Strength);
   }

   ret = ret / 17.0f;
   ret = ret + source;

   return saturate(float4(ret.rgb,1.0f));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Flare
{
   pass Pass1
   <
      string Script = "RenderColorTarget0 = Sample;";
   >
   {
      PixelShader = compile PROFILE ps_adjust();
   }

   pass Pass2
   {
      PixelShader = compile PROFILE ps_main();
   }
}
