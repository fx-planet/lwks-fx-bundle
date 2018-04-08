// @Maintainer jwrl
// @Released 4 April 2018
// @Author khaver
// @see https://www.lwks.com/media/kunena/attachments/6375/Letterbox.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Letterbox.fx
//
// This effect applies a simple letterbox style mask at a range of industry standard
// ratios or a user set custom mask.
//
// Modified by LW user jwrl 4 April 2018.
// Metadata header block added to better support GitHub repository.  Description added,
// code sections labelled.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Letterbox";
   string Category    = "DVE";
   string SubCategory = "Crop Presets";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;
texture Tex1 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio, _OutputWidth, _OutputHeight;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Letterbox
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
