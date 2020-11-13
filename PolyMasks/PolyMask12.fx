// @Maintainer jwrl
// @Released 2020-11-13
// @Author khaver
// @Created 2011-12-08
// @see https://www.lwks.com/media/kunena/attachments/6375/Polymask_640.png

/**
 This a user adjustable mask with twelve sides.  The edges of the mask can be feathered, and
 a background colour can be set.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PolyMask12.fx
//
// Version history.
//
// Update 2020-11-13 jwrl.
// Added Cansize switch for LW 2021 support.
//
// Modified 2 December 2018 jwrl.
// Changed subcategory.
// Added creation date.
//
// 4 April 2018: Modification by jwrl
// Metadata header block added to better support GitHub repository.
//
// 21 March 2018: Version 14.5 modification by jwrl
// This will compile in all Lightworks versions on Linux or OS-X, and Lightworks versions
// 14.5+ running under Windows.  If running Lightworks version 14.0 or lower Windows users
// should use the older Windows version.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "PolyMask 12";
   string Category    = "DVE";
   string SubCategory = "Polymasks";
   string Notes       = "A twelve sided adjustable mask with feathered edges and optional background colour";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture fg;
texture bg;
texture Tex1 : RenderColorTarget;
texture Tex2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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
> = 0.5;

float P1Y
<
   string Description = "P1";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2;

float P2X
<
   string Description = "P2";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.35;

float P2Y
<
   string Description = "P2";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2402;

float P3X
<
   string Description = "P3";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2402;

float P3Y
<
   string Description = "P3";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.35;

float P4X
<
   string Description = "P4";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2;

float P4Y
<
   string Description = "P4";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float P5X
<
   string Description = "P5";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2402;

float P5Y
<
   string Description = "P5";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.65;

float P6X
<
   string Description = "P6";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.35;

float P6Y
<
   string Description = "P6";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.7598;

float P7X
<
   string Description = "P7";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float P7Y
<
   string Description = "P7";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.8;

float P8X
<
   string Description = "P8";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.65;

float P8Y
<
   string Description = "P8";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.7598;

float P9X
<
   string Description = "P9";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.7598;

float P9Y
<
   string Description = "P9";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.65;

float P10X
<
   string Description = "P10";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.8;

float P10Y
<
   string Description = "P10";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float P11X
<
   string Description = "P11";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.7598;

float P11Y
<
   string Description = "P11";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.35;

float P12X
<
   string Description = "P12";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.65;

float P12Y
<
   string Description = "P12";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2402;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputWidth,  _OutputHeight, _OutputAspectRatio;

#define _psize 12

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

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
	poly[5] = float2(P6X,1.0f - P6Y);
	poly[6] = float2(P7X,1.0f - P7Y);
	poly[7] = float2(P8X,1.0f - P8Y);
	poly[8] = float2(P9X,1.0f - P9Y);
	poly[9] = float2(P10X,1.0f - P10Y);
	poly[10] = float2(P11X,1.0f - P11Y);
	poly[11] = float2(P12X,1.0f - P12Y);
	//poly[12] = float2(P13X,1.0f - P13Y);
	//poly[13] = float2(P14X,1.0f - P14Y);

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

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique PolyMask12
{

   pass Pass1
   <
   string Script = "RenderColorTarget0 = Tex1;";
   >
   {
      PixelShader = compile PROFILE main1(0);
   }
   pass Pass2
   <
   string Script = "RenderColorTarget0 = Tex2;";
   >
   {
      PixelShader = compile PROFILE main1(1);
   }
   pass Pass3
   {
      PixelShader = compile PROFILE Combine();
   }
}
