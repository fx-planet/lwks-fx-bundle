// @Maintainer jwrl
// @Released 2018-04-07
// @Author khaver
// @see https://www.lwks.com/media/kunena/attachments/6375/Flare_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Flare.fx
//
// Flare - original effect by khaver creates an adjustable lens flare effect.  The
// origin of the flare can be positioned by adjusting the X and Y sliders or by
// dragging the on-viewer icon with the mouse.
//
// Modified 11 February 2017 by jwrl.
// Added subcategory to effect header for version 14.
//
// Bug fix 26 February 2017 by jwrl.
// Corrects for a problem with the way that Lightworks handles interlaced media.
//
// Cross platform compatibility check 1 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Flare";
   string Category    = "Stylize";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;
texture Sample : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp1 = sampler_state
{
   Texture   = <Sample>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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
> = 0.1f;

float Stretch
<
   string Description = "Stretch";
   float MinVal = 0.0f;
   float MaxVal = 100.0f;
> = 5.0f;

float adjust
<
   string Description = "Adjust";
   float MinVal = 0.0f;
   float MaxVal = 1.0f;
> = 0.25f;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_adjust ( float2 xy : TEXCOORD1 ) : COLOR
{
   float4 Color = tex2D( InputSampler, xy);
   if (Color.r < 1.0f-adjust) Color.r = 0.0f;
   if (Color.g < 1.0f-adjust) Color.g = 0.0f;
   if (Color.b < 1.0f-adjust) Color.b = 0.0f;
   return Color;
}

float4 ps_main( float2 xy1 : TEXCOORD1 ) : COLOR
{
   float4 ret;
   float2 amount = float2( 1.0, _OutputAspectRatio ) * Stretch / _OutputWidth;

   float centreY = 1.0f - CentreY;

   float x = xy1.x - CentreX;
   float y = xy1.y - centreY;

   float2 adj = amount;
   
   float4 source = tex2D( InputSampler, xy1 );
   float4 negative = tex2D( Samp1, xy1 );
   ret = tex2D( Samp1, float2( x * adj.x + CentreX, y * adj.y + centreY ) );

   for (int count = 1; count < 13; count++) {
   adj += amount;
   ret += tex2D( Samp1, float2( x * adj.x + CentreX, y * adj.y + centreY ) )*(count*Strength);
   }

   ret = ret / 15.0f;
   ret = ret + source;

   return saturate(float4(ret.rgb,1.0f));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Blur
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
