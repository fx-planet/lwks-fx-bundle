//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Cross platform compatibility check 27 July 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Explicitly define float2, float3 and float4 variables to
// address the behavioural difference between the D3D and Cg
// compilers when this is not done.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Edge";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

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

//--------------------------------------------------------------//
// Define parameters here.
//
// The Lightworks application will automatically generate
// sliders/controls for all parameters which do not start
// with a a leading '_' character
//--------------------------------------------------------------//
float Threshold
<
   string Description = "Threshold";
   float MinVal       = 0.00;
   float MaxVal       = 2.00;
> = 0.5; // Default value

float K00
<
   string Description = "Kernel 0";
   string Group       = "Kernel"; // Causes this parameter to be displayed in a group called 'Kernel'
   float MinVal       = -10.00;
   float MaxVal       = 10.00;
> = 2.0; // Default value

float K01
<
   string Description = "Kernel 1";
   string Group       = "Kernel"; // Causes this parameter to be displayed in a group called 'Kernel'
   float MinVal       = -10.00;
   float MaxVal       = 10.00;
> = 2.0; // Default value

float K02
<
   string Description = "Kernel 2";
   string Group       = "Kernel"; // Causes this parameter to be displayed in a group called 'Kernel'
   float MinVal       = -10.00;
   float MaxVal       = 10.00;
> = 1.0; // Default value

float TextureSizeX
<
   string Description = "Size X";
   float MinVal       = 1.0f;
   float MaxVal       = 2048.0f;
> = 512.0f; // Default value

float TextureSizeY
<
   string Description = "Size Y";
   float MinVal       = 1.0f;
   float MaxVal       = 2048.0f;
> = 512.0f; // Default value

bool Invert
<
	string Description = "Invert";
> = false;

bool Alpha
<
	string Description = "Edge to alpha";
> = false;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------
// Pixel Shader
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//
// Note that pixels are processed out of order, in parallel.
// Using shader model 2.0, so there's a 64 instruction limit -
// use multple passes if you need more.
//--------------------------------------------------------------
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



//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE main();
   }
}

