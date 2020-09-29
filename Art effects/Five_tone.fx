// @Maintainer jwrl
// @Released 2020-09-29
// @Author idealsceneprod (Val Gameiro)
// @Created 2014-12-24
// @see https://www.lwks.com/media/kunena/attachments/6375/FiveTone_640.png

/**
 Five tone (FivetoneFx.fx) is a posterization effect that extends the existing Lightworks
 Two Tone and Tri-Tone effects.  It reduces input video to five tonal values.  Blending and
 colour values are all adjustable.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Five_tone.fx
//
// Version history:
//
// Update 2020-09-29 jwrl.
// Revised header block.
//
// Modified 11 July 2020 jwrl.
// Explicitly declared SupportsAlpha flag to be false in each colour parameter.
//
// Modified 13 August 2019 jwrl.
// Changed incorrect second "Threshold Three" parameter to "Threshold Four".
// Removed explicit declaration of clamp addressing to deal with the ClampToEdge cross
// platform bug.  The effect now defaults to the correct addressing mode.
//
// Modified 23 December 2018 jwrl.
// Changed subcategory.
// Added creation date.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//
// Cross platform compatibility check 27 July 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Bug fix 26 February 2017 by jwrl:
// Added workaround for the interlaced media height bug in Lightworks effects.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Five tone";
   string Category    = "Colour";
   string SubCategory = "Art Effects";
   string Notes       = "Extends the existing Lightworks Two Tone and Tri-Tone effects to provide five tonal values";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture ThresholdTexture : RenderColorTarget;
texture Blur1 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state { Texture = <Input>; };

sampler ThresholdSampler = sampler_state
{
   Texture = <ThresholdTexture>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BlurSampler = sampler_state
{
   Texture = <Blur1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Level1
<
   string Description = "Threshold One";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.20;

float Level2
<
   string Description = "Threshold Two";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.40;

float Level3
<
   string Description = "Threshold Three";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.60;

float Level4
<
   string Description = "Threshold Four";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.80;

float BlendOpacity
<
   string Description = "Blend";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float4 DarkColour
<
   string Description = "Dark Colour";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.0, 1.0 };

float4 MidColour
<
   string Description = "Mid Dark Colour";
   bool SupportsAlpha = false;
> = { 0.3, 0.3, 0.3, 1.0 };

float4 MidColour2
<
   string Description = "Mid Colour";
   bool SupportsAlpha = false;
> = { 0.5, 0.5, 0.5, 1.0 };

float4 MidColour3
<
   string Description = "Mid Light Colour";
   bool SupportsAlpha = false;
> = { 0.7, 0.7, 0.7, 1.0 };

float4 LightColour
<
   string Description = "Light Colour";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 1.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth = 1.0;

float blur[] = { 20.0 / 64.0, 15.0 / 64.0, 6.0  / 64.0, 1.0  / 64.0 };  // See Pascals Triangle

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 threshold_main( float2 xy1 : TEXCOORD1 ) : COLOR
{
	float4 src1 = tex2D( InputSampler, xy1 );
	float srcLum = ( ( src1.r * 0.3 ) + ( src1.g * 0.59 ) + ( src1.b * 0.11 ) );

	// out = alpha * new + (1 - alpha) * old
	if ( srcLum < Level1 )
		src1.rgb = BlendOpacity * DarkColour.rgb + (1 - BlendOpacity) * src1.rgb;
	else if ( srcLum < Level2 )
		src1.rgb = BlendOpacity * MidColour.rgb + (1 - BlendOpacity) * src1.rgb;
	else if ( srcLum < Level3 )
		src1.rgb = BlendOpacity * MidColour2.rgb + (1 - BlendOpacity) * src1.rgb;
	else if ( srcLum < Level4 )
		src1.rgb = BlendOpacity * MidColour3.rgb + (1 - BlendOpacity) * src1.rgb;
	else
		src1.rgb = BlendOpacity * LightColour.rgb + (1 - BlendOpacity) * src1.rgb;
	
   return src1;
}

float4 blur1_ps_main( float2 xy1 : TEXCOORD1 ) : COLOR
{
   // Explicitly query BETWEEN pixels to get extra averaging
   float2 onePixAcross   = float2( 0.5 / _OutputWidth, 0.0 );
   float2 twoPixAcross   = float2( 1.5 / _OutputWidth, 0.0 );
   float2 threePixAcross = float2( 2.5 / _OutputWidth, 0.0 );

   float4 keyPix = tex2D( ThresholdSampler, xy1 );

   float4 result = keyPix * blur[ 0 ];
   result += tex2D( ThresholdSampler, xy1 + onePixAcross )   * blur[ 1 ];
   result += tex2D( ThresholdSampler, xy1 - onePixAcross )   * blur[ 1 ];
   result += tex2D( ThresholdSampler, xy1 + twoPixAcross )   * blur[ 2 ];
   result += tex2D( ThresholdSampler, xy1 - twoPixAcross )   * blur[ 2 ];
   result += tex2D( ThresholdSampler, xy1 + threePixAcross ) * blur[ 3 ];
   result += tex2D( ThresholdSampler, xy1 - threePixAcross ) * blur[ 3 ];
   result.a = keyPix.a;

   return result;
}

float4 blur2_ps_main( float2 xy1 : TEXCOORD1 ) : COLOR
{
   // Explicitly query BETWEEN pixels to get extra averaging
   float2 onePixDown   = float2 (0.0, 0.5 * _OutputAspectRatio / _OutputWidth);
   float2 twoPixDown   = float2 (0.0, 1.5 * _OutputAspectRatio / _OutputWidth);
   float2 threePixDown = float2 (0.0, 2.5 * _OutputAspectRatio / _OutputWidth);

   float4 keyPix = tex2D( BlurSampler, xy1 );
   float4 source = tex2D( InputSampler, xy1 );

   float4 result = keyPix * blur[ 0 ];
   result += tex2D( BlurSampler, xy1 + onePixDown )   * blur[ 1 ];
   result += tex2D( BlurSampler, xy1 - onePixDown )   * blur[ 1 ];
   result += tex2D( BlurSampler, xy1 + twoPixDown )   * blur[ 2 ];
   result += tex2D( BlurSampler, xy1 - twoPixDown )   * blur[ 2 ];
   result += tex2D( BlurSampler, xy1 + threePixDown ) * blur[ 3 ];
   result += tex2D( BlurSampler, xy1 - threePixDown ) * blur[ 3 ];
   result.a = keyPix.a;

   result = lerp( source, result, source.a );
   result.a = source.a;

   return result;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique FiveTone
{
   pass ThresholdPass
   <
      string Script = "RenderColorTarget0 = ThresholdTexture;";
   >
   {
      PixelShader = compile PROFILE threshold_main();
   }

   pass BlurX
   <
      string Script = "RenderColorTarget0 = Blur1;";
   >
   {
      PixelShader = compile PROFILE blur1_ps_main();
   }

   pass BlurY
   {
      PixelShader = compile PROFILE blur2_ps_main();
   }
}
