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
   string Description = "Poly05";         // The title
   string Category    = "DVE";            // Governs the category that the effect appears in in Lightworks
   string SubCategory = "Crop Presets";   // Additional parameter for V14
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

 float _OutputWidth,  _OutputHeight, _OutputAspectRatio;

texture fg;
texture bg;
texture Tex1 : RenderColorTarget;
texture Tex2 : RenderColorTarget;

sampler FGround = sampler_state {
        Texture = <fg>;
        AddressU = Clamp;
        AddressV = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };
sampler BGround = sampler_state {
        Texture = <bg>;
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
sampler Samp2 = sampler_state {
        Texture = <Tex2>;
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

bool colormask
<
	string Description = "Color Mask";
> = false;

float4 MaskColor
<
   string Description = "Color";
> = {0.0,0.5,0.0,1.0};

bool invert
<
	string Description = "Invert";
> = false;

float feather
<
	string Description = "Feather";
	float MinVal = 0.0f;
	float MaxVal = 0.5f;
> = 0.0f;

float zoomit
<
	string Description = "Zoom";
	float MinVal = 0.0f;
	float MaxVal = 10.0f;
> = 1.0f;

float PanX
<
   string Description = "Move";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.00;
   float MaxVal = 2.00;
> = 0.5;

float PanY
<
   string Description = "Move";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.00;
   float MaxVal = 2.00;
> = 0.5;

bool aspect
<
	string Description = "Aspect Compensation";
> = false;

bool show
<
	string Description = "Show mask";
> = false;

float P1X
<
   string Description = "P1";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.3237;

float P1Y
<
   string Description = "P1";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2573;

float P2X
<
   string Description = "P2";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2147;

float P2Y
<
   string Description = "P2";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5927;

float P3X
<
   string Description = "P3";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float P3Y
<
   string Description = "P3";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.8;

float P4X
<
   string Description = "P4";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.7853;

float P4Y
<
   string Description = "P4";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5927;

float P5X
<
   string Description = "P5";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.6763;

float P5Y
<
   string Description = "P5";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2573;

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

#define _psize 5
 
float4 makePoly(float2 p, float2 poly[_psize]) {
	bool oddNodes = false;
	for(int i = 0; i < _psize; i++){
		int j = i + 1;
		if (j == _psize) j = 0;
  		if (((poly[i].y > p.y ) != (poly[j].y > p.y)) && (p.x < (poly[j].x-poly[i].x) * (p.y - poly[i].y) / (poly[j].y-poly[i].y) + poly[i].x)) oddNodes=!oddNodes;
	}
	float io;
	if (oddNodes) io = 1.0f;
	else io = 0.0f;

	return float4(io,io,io,io);
}

 
float distanceFromLine(float2 p, float2 l1, float2 l2) {
	float xDelta = l2.x - l1.x;
	float yDelta = l2.y - l1.y;
	
	float u = ((p.x - l1.x) * xDelta + (p.y - l1.y) * yDelta) / (xDelta * xDelta + yDelta * yDelta);
	float2 closestPointOnLine;
	if (u < 0) {
			closestPointOnLine = l1;
		} else if (u > 1) {
			closestPointOnLine = l2;
		} else {
			closestPointOnLine = float2(l1.x + u * xDelta, l1.y + u * yDelta);
		}
	float2 d = p - closestPointOnLine;
	return sqrt(d.x * d.x + d.y * d.y);
}

float distanceFromPoly(float2 p, float2 poly[_psize]) {
	float result = 100.0f;
	
	for(int i = 0; i < _psize; i++){
		int previousIndex = i - 1;
		if (previousIndex < 0) previousIndex = _psize - 1;
	
		float2 currentPoint = poly[i];
		float2 previousPoint = poly[previousIndex];
	
		float segmentDistance = distanceFromLine(p, previousPoint, currentPoint);
	
		if(segmentDistance < result) result = segmentDistance;
	}
	return result;
}

float4 main1( float2 xy : TEXCOORD1, uniform int run ) : COLOR
{

	float asp = 1.0f;
	if (aspect) asp = _OutputAspectRatio;
	float zoom = zoomit;
	if (zoom == 0.0f) zoom = 0.00001f;
	float z = zoom / asp;
	float2 poly[_psize];
	//float4 themask = tex2D(Samp1, xy);
	
	poly[0] = float2(P1X,1.0f - P1Y);
	poly[1] = float2(P2X,1.0f - P2Y);
	poly[2] = float2(P3X,1.0f - P3Y);
	poly[3] = float2(P4X,1.0f - P4Y);
	poly[4] = float2(P5X,1.0f - P5Y);
	//poly[5] = float2(P6X,1.0f - P6Y);
	//poly[6] = float2(P7X,1.0f - P7Y);
	//poly[7] = float2(P8X,1.0f - P8Y);
	//poly[8] = float2(P9X,1.0f - P9Y);
	//poly[9] = float2(P10X,1.0f - P10Y);
	//poly[10] = float2(P11X,1.0f - P11Y);
	//poly[11] = float2(P12X,1.0f - P12Y);
	//poly[12] = float2(P13X,1.0f - P13Y);
	//poly[13] = float2(P14X,1.0f - P14Y);
	//poly[14] = float2(P15X,1.0f - P15Y);
	//poly[15] = float2(P16X,1.0f - P16Y);

	float X = ((xy.x - 0.5f) / z) + 0.5f;
	float Y = ((xy.y - 0.5f) / zoom) + 0.5f;
	X = X - ((PanX - 0.5f)/z);
	Y = Y + ((PanY - 0.5f)/zoom);
	if (run == 0) {
		return makePoly(float2(X,Y), poly);
	}
	else {
		float4 themask = tex2D(Samp1, xy);
		float change;
		float distancefrom = distanceFromPoly(float2(X,Y),poly);
		if (distancefrom < feather) {
			change = ((1.0f / feather) * distancefrom)/2.0f;
			if (themask.a > 0.5f) themask = 1.0f - (0.5f - change);
			if (themask.a <= 0.5f) themask = 0.0f + (0.5f - change);
			return themask;
		}
		else return themask;
	}
}

float4 Combine( float2 uv : TEXCOORD1 ) : COLOR
{
  float4 color;
  float4 FG = tex2D( FGround, uv);
  float4 BG = tex2D( BGround, uv);
  if (colormask) BG = MaskColor;
  float4 Mask = tex2D( Samp2, uv);
  if (invert) Mask = 1.0f-Mask;
  if (show) color = Mask;
  else color = lerp(FG,BG,Mask.a);
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
      PixelShader = compile ps_2_b main1(0);
   }
   pass Pass2
   <
   string Script = "RenderColorTarget0 = Tex2;";
   >
   {
      PixelShader = compile ps_2_b main1(1);
   }
   pass Pass3
   {
      PixelShader = compile ps_2_b Combine();
   }
}

