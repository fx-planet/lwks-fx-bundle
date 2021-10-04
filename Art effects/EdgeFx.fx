// @Maintainer jwrl
// @Released 2021-07-26
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
// Rewrite 2021-07-26 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DeclareInput( TEXTURE, SAMPLER ) \
                                         \
   texture TEXTURE;                      \
                                         \
   sampler SAMPLER = sampler_state       \
   {                                     \
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
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DeclareInput (Input, TexSampler);

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
   string Group       = "Kernel";
   float MinVal       = -10.0;
   float MaxVal       = 10.0;
> = 2.0; // Default value

float K01
<
   string Description = "Kernel 1";
   string Group       = "Kernel";
   float MinVal       = -10.0;
   float MaxVal       = 10.0;
> = 2.0; // Default value

float K02
<
   string Description = "Kernel 2";
   string Group       = "Kernel";
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
   float4 org = GetPixel (TexSampler,uv);
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
    float4 c00 = GetPixel (TexSampler, texCoord - offX);
    float4 c01 = GetPixel (TexSampler, texCoord);
    float4 c02 = GetPixel (TexSampler, texCoord + offX);

	// Middle row
	texCoord = uv;
    float4 c10 = GetPixel (TexSampler, texCoord - offX);
    float4 c12 = GetPixel (TexSampler, texCoord + offX);

	// Bottom row
	texCoord = uv + offY;
    float4 c20 = GetPixel (TexSampler, texCoord - offX);
    float4 c21 = GetPixel (TexSampler, texCoord);
    float4 c22 = GetPixel (TexSampler, texCoord + offX);

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

technique SampleFxTechnique { pass SinglePass ExecuteShader (main) }

