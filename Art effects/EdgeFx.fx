// @Maintainer jwrl
// @Released 2020-11-08
// @Author khaver
// @Created 2011-07-08
// @see https://www.lwks.com/media/kunena/attachments/6375/Edge_640.png

/**
 Edge (EdgeFx.fx) detects edges to give a similar result to the well known art program
 effect.  The edge detection is fully adjustable.  Invert and add a little blur over it
 to make the video look as if it's been sketched.

 It also provides a checkbox to move the generated edge to the alpha channel to allow
 the effect to be overlaid over the video and only affect the edges.  This allows masking
 of the Gaussian Blur effect to blur overly sharpened edges, to give just one example of
 the flexibility that this technique provides.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect EdgeFx.fx
//
// Version history:
//
// Update 2020-11-08 jwrl.
// Added CanSize switch for 2021 support.
//
// Modified by LW user jwrl 11 July 2020.
// Added "DisplayAsPercentage" flag to threshold for LW 2020.1 and higher.
//
// Modified by LW user jwrl 23 December 2018.
// Added creation date.
// Added Notes.
// Formatted the descriptive block so that it can be used for markdown purposes.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//
// Cross platform compatibility check 27 July 2017 jwrl.
// Explicitly defined samplers to correct for cross-platform sampler state defaults.
// Explicitly defined float2, float3 and float4 variables to address the behavioural
// difference between the D3D and Cg compilers when this is not done.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Edge";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "Detects edges to give a similar result to the well known art program effect";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Input;

sampler TexSampler = sampler_state
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

float Threshold
<
   string Description = "Threshold";
   string Flags       = "DisplayAsPercentage";
   float MinVal       = 0.0;
   float MaxVal       = 2.0;
> = 0.5; // Default value

float K00
<
   string Description = "Kernel 0";
   string Group       = "Kernel"; // Causes this parameter to be displayed in a group called 'Kernel'
   float MinVal       = -10.0;
   float MaxVal       = 10.0;
> = 2.0; // Default value

float K01
<
   string Description = "Kernel 1";
   string Group       = "Kernel"; // Causes this parameter to be displayed in a group called 'Kernel'
   float MinVal       = -10.0;
   float MaxVal       = 10.0;
> = 2.0; // Default value

float K02
<
   string Description = "Kernel 2";
   string Group       = "Kernel"; // Causes this parameter to be displayed in a group called 'Kernel'
   float MinVal       = -10.0;
   float MaxVal       = 10.0;
> = 1.0; // Default value

float TextureSizeX
<
   string Description = "Size X";
   float MinVal       = 1.0;
   float MaxVal       = 2048.0;
> = 512.0; // Default value

float TextureSizeY
<
   string Description = "Size Y";
   float MinVal       = 1.0;
   float MaxVal       = 2048.0;
> = 512.0; // Default value

bool Invert
<
   string Description = "Invert";
> = false;

bool Alpha
<
   string Description = "Edge to alpha";
> = false;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 main( float2 uv : TEXCOORD1 ) : COLOR
{
   float4 org = tex2D(TexSampler,uv);
   float ThreshholdSq = Threshold * Threshold;
   float2 TextureSizeInv = float2(1.0f / TextureSizeX, 1.0f / TextureSizeY);
   float K20 = -K00;
   float K21 = -K01;
   float K22 = -K02;

    float2 offX = float2(TextureSizeInv.x, 0);
    float2 offY = float2(0, TextureSizeInv.y);

    // Sample texture
	// Top row
	float2 texCoord = uv - offY;
    float4 c00 = tex2D(TexSampler, texCoord - offX);
    float4 c01 = tex2D(TexSampler, texCoord);
    float4 c02 = tex2D(TexSampler, texCoord + offX);

	// Middle row
	texCoord = uv;
    float4 c10 = tex2D(TexSampler, texCoord - offX);
    float4 c12 = tex2D(TexSampler, texCoord + offX);

	// Bottom row
	texCoord = uv + offY;
    float4 c20 = tex2D(TexSampler, texCoord - offX);
    float4 c21 = tex2D(TexSampler, texCoord);
    float4 c22 = tex2D(TexSampler, texCoord + offX);

    // Convolution
    float4 sx = 0;
    float4 sy = 0;

	// Convolute X
    sx += c00 * K00;
    sx += c01 * K01;
    sx += c02 * K02;
    sx += c20 * K20;
    sx += c21 * K21;
    sx += c22 * K22;

	// Convolute Y
    sy += c00 * K00;
    sy += c02 * K20;
    sy += c10 * K01;
    sy += c12 * K21;
    sy += c20 * K02;
    sy += c22 * K22;

	// Add and apply Threshold
    float4 s = sx * sx + sy * sy;
    float4 edge = 1.0.xxxx;
    edge.rgb =  1.0.xxx - float3( s.r <= ThreshholdSq,
					    s.g <= ThreshholdSq,
					    s.b <= ThreshholdSq ); // Alpha is always 1!
    if (Invert) edge.rgb = 1.0.xxx - edge.rgb;
    if (Alpha) {
    	float alpha = (edge.r + edge.g + edge.b) / 3.0f;
    	edge = float4(org.rgb, alpha);
    }
    return edge;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE main();
   }
}
