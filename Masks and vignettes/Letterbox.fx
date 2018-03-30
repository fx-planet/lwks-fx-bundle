//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Letterbox";        // The title
   string Category    = "DVE";              // Governs the category that the effect appears in in Lightworks
   string SubCategory = "Crop Presets";     // Parameter added for version 14
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)
float _OutputAspectRatio, _OutputWidth, _OutputHeight;

texture Input;
texture Tex1 : RenderColorTarget;

sampler InputSampler = sampler_state {
	Texture = <Input>; 
        AddressU = Clamp;
        AddressV = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;

};
sampler Samp1 = sampler_state {
	Texture = <Tex1>; 
        AddressU = Clamp;
        AddressV = Clamp;
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

int Mask
<
	string Description = "Aspect Mask";
	string Enum = "None,4:3,16:9,1.85:1,2.40:1,Custom";
> = 0;

float Custom
<
	string Description = "Custom Aspect";
   float MinVal = 0.00;
   float MaxVal = 4.00;
> = 16.0f/9.0f;

bool Grid
<
	string Description = "Show";
> = false;

float Zoom
<
	string Description = "Zoom";
   float MinVal = 0.00;
   float MaxVal = 2.00;
> = 1.0;
float Rotate
<
	string Description = "Rotate";
   float MinVal = -30.00;
   float MaxVal = 30.00;
> = 0.0;

float PanX
<
   string Description = "Pan";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.00;
   float MaxVal = 2.00;
> = 0.5;

float PanY
<
   string Description = "Pan";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.00;
   float MaxVal = 2.00;
> = 0.5;

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

float4 main2( float2 uv : TEXCOORD1 ) : COLOR
{
	//float2 pix = float2(0.5f / _OutputWidth, 0.5f / _OutputHeight);
   float4  color = tex2D(Samp1,uv);
   float masp;
   float mtop, mbot, mleft, mright;
   if (Mask == 0) return color;
   if (Mask == 1) masp = 4.0f/3.0f;
   if (Mask == 2) masp = 16.0f/9.0f;
   if (Mask == 3) masp = 1.85f/1.0f;
   if (Mask == 4) masp = 2.40f/1.0f;
   if (Mask == 5) masp = Custom;
	//uv += pix;
   if (_OutputAspectRatio / masp < 1.0f) {
   		mtop = (1.0f-(_OutputAspectRatio / masp))/2.0f;
   		mbot = 1.0f - mtop;
   		if (Grid) {
   			if ((uv.y >= mbot && uv.y <= mbot + 0.005) || (uv.y <= mtop && uv.y >= mtop - 0.005)) color = float4(1,0,0,0);
   		}
   		else if (uv.y >= mbot || uv.y <= mtop) color = 0.0f;
   	}
   	else {
   		mleft = (1.0f - (1.0f / (_OutputAspectRatio/masp)))/2.0f;
   		mright = 1.0f - mleft;
   		if (Grid) {
   			if ((uv.x >= mright && uv.x <= mright + 0.005) || (uv.x <= mleft && uv.x >= mleft - 0.005)) color = float4(1,0,0,0);
   		}
   		else if (uv.x >= mright || uv.x <= mleft) color = 0.0f;
   	}
   return color;
}

float4 main1( float2 uv : TEXCOORD1 ) : COLOR
{
	//float2 pix = float2(0.5f / _OutputWidth, 0.5f / (_OutputHeight)); // * _OutputAspectRatio));
	//uv -= pix;
	if (Zoom == 1.0f && Rotate == 0.0f && PanX == 0.5f && PanY == 0.5f) return tex2D(InputSampler,uv);
	float4 color;
	//uv += pix;
	float X = (uv.x - 0.5f)/Zoom;
	float Y = (uv.y - 0.5f)/(Zoom*_OutputAspectRatio);
	X = X - ((PanX - 0.5f)/Zoom);
	Y = Y + ((PanY - 0.5f)/Zoom);
	
	float angle = radians(Rotate);
	float Tcos = cos(angle);
	float Tsin = sin(angle);
	float asp = 1.0f - ((1.0f-_OutputAspectRatio) * sin(angle));
	float Temp = (X * Tcos - Y * Tsin) + 0.5f;
	Y = (((Y * Tcos + X * Tsin)*_OutputAspectRatio) + 0.5f);
	X = Temp;
	if (X < 0.0 || X > 1.0f || Y < 0.0f || Y > 1.0f) color = float4(0,0,0,0);
	else color = tex2D(InputSampler,float2(X,Y));
   return color;
}


//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique SampleFxTechnique
{
   pass Pass1
   <
   string Script = "RenderColorTarget0 = Tex1;";
   >
   {
      PixelShader = compile PROFILE main1();
   }
   pass Pass2
   {
      PixelShader = compile PROFILE main2();
   }
}

