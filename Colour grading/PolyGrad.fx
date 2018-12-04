// @Maintainer jwrl
// @Released 2018-12-04
// @Author khaver
// @Created 2014-11-22
// @see https://www.lwks.com/media/kunena/attachments/6375/PolyGrad_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect PolyGrad.fx
//
// PolyGrad emulates to a degree the operation of power windows.  This maskable grading
// tool can add that little extra polish to your colourgrade.
//
// To use it, apply the effect and turn on "Show Guides".  This will allow you to position
// the corners of the polygon mask.  The red area shows where the colourgrade effect will
// be at 100%, and the green area is where the effect influence will be at 0%.  Increasing
// the feather amount will increase the area between the red and green zones.  When a
// corner node gets near the edge of frame it will snap to that edge.
//
// Once the areas are set turn off "Show Guides" and adjust the other parameters as you
// would any other colourgrading tool.
//
// Subcategory added by jwrl for v.14 and up 10 Feb 2017
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified by LW user jwrl 4 December 2018.
// Added creation date.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "PolyGrad";
   string Category    = "Colour";
   string SubCategory = "Repair";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture bg;
texture Tex1 : RenderColorTarget;
texture Tex2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

float4 MaskColor
<
   string Description = "Grad Color";
> = {0.0,0.0,0.0,0.0};

int Mode
<
        string Description = "Blend mode";
        string Enum = "Add,Subtract,Multiply,Screen,Overlay,Soft Light,Hard Light,Exclusion,Lighten,Darken,Difference,Burn";
> = 2;

float feather
<
	string Description = "Feather";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.0f;

float strength
<
	string Description = "Strength";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.5f;

bool invert
<
	string Description = "Flip";
> = false;

bool show
<
	string Description = "Show Guides";
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
> = 0.2879;

float P2Y
<
   string Description = "P2";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2879;

float P3X
<
   string Description = "P3";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2;

float P3Y
<
   string Description = "P3";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float P4X
<
   string Description = "P4";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2879;

float P4Y
<
   string Description = "P4";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.7121;

float P5X
<
   string Description = "P5";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float P5Y
<
   string Description = "P5";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.8;

float P6X
<
   string Description = "P6";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.7121;

float P6Y
<
   string Description = "P6";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.7121;

float P7X
<
   string Description = "P7";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.8;

float P7Y
<
   string Description = "P7";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float P8X
<
   string Description = "P8";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.7121;

float P8Y
<
   string Description = "P8";
   string Group = "Coordinates";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2879;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputWidth,  _OutputHeight, _OutputAspectRatio;

#define _psize 8
 
#pragma warning ( disable : 3571 )

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
	float io, ioa;
	if (oddNodes){ io = 1.0f;} // ioa = 1.01;}
	else {io = 0.0f;} // ioa = -0.01;}

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
	d.y = d.y / _OutputAspectRatio;
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

float3 method(float3 fg, float3 bg) {
	float3 newc;
	if (Mode == 0) newc = saturate(bg + fg);		//Add
   
	if (Mode == 1) newc = saturate(bg - fg);	 	//Subtract
   
	if (Mode == 2) newc = bg * fg;	//Multiply
   
	if (Mode == 3) newc = 1.0 - ((1.0 - fg) * (1.0 - bg));	//Screen
   
	if (Mode == 4) {									//Overlay
		if (bg.r < 0.5) newc.r = 2.0 * fg.r * bg.r;
		else newc.r = 1.0 - (2.0 * ( 1.0 - fg.r) * ( 1.0 - bg.r));
	
		if (bg.g < 0.5) newc.g = 2.0 * fg.g * bg.g;
		else newc.g = 1.0 - (2.0 * ( 1.0 - fg.g) * ( 1.0 - bg.g));
	
		if (bg.b < 0.5) newc.b = 2.0 * fg.b * bg.b;
		else newc.b = 1.0 - (2.0 * ( 1.0 - fg.b) * ( 1.0 - bg.b));
	}

	if (Mode == 5) newc = ( 1.0 - bg) * (fg * bg) + (bg * (1.0 - ((1.0 - bg) * (1.0 - fg)))); //Soft Light
   
	if (Mode == 6) { 									//Hard Light
		if (fg.r < 0.5 ) newc.r = 2.0 * fg.r * bg.r;
		else newc.r = 1.0 - ( 2.0 * (1.0 - fg.r) * (1.0 - bg.r));
	
		if (fg.g < 0.5 ) newc.g = 2.0 * fg.g* bg.g;
		else newc.g = 1.0 - ( 2.0 * (1.0 - fg.g) * (1.0 - bg.g));
	
		if (fg.b < 0.5 ) newc.b = 2.0 * fg.b * bg.b;
		else newc.b = 1.0 - ( 2.0 * (1.0 - fg.b) * (1.0 - bg.b));
	}
   
	if (Mode == 7) newc = fg + bg - (2.0 * fg * bg);	//Exclusion
   
	if (Mode == 8) newc = max(fg, bg);	//Lighten
   
	if (Mode == 9) newc = min(fg, bg);	//Darken
   
	if (Mode == 10) newc = abs( fg - bg);		//Difference
   
	if (Mode == 11) newc = saturate(1.0 - (( 1.0 - fg) / bg));	//Burn
	return newc;
}

float4 main1( float2 xy : TEXCOORD1, uniform int run ) : COLOR
{
	float pixelsx = 0.04; //20.0 / _OutputWidth;
	float pixelsy = 0.04; //20.0 / _OutputHeight;

	float2 poly[_psize];
	
	poly[0] = float2(P1X,1.0f - P1Y);
	poly[1] = float2(P2X,1.0f - P2Y);
	poly[2] = float2(P3X,1.0f - P3Y);
	poly[3] = float2(P4X,1.0f - P4Y);
	poly[4] = float2(P5X,1.0f - P5Y);
	poly[5] = float2(P6X,1.0f - P6Y);
	poly[6] = float2(P7X,1.0f - P7Y);
	poly[7] = float2(P8X,1.0f - P8Y);
	for (int i = 0; i < _psize; i++){
		if (poly[i].x < pixelsx) poly[i].x = 0.0;
		if (poly[i].x > 1.0 - pixelsx) poly[i].x = 1.0;
		if (poly[i].y < pixelsy) poly[i].y = 0.0;
		if (poly[i].y > 1.0 - pixelsy) poly[i].y = 1.0;
	}
	if (run == 0) {
		return makePoly(xy, poly);
	}
	else {
		float4 themask = tex2D(Samp1, xy);
		float change;
		float distancefrom = distanceFromPoly(xy,poly);
		if (distancefrom < feather) {
			change = ((1.0f / feather) * distancefrom)/1.0f;
			if (themask.a > 0.5f) themask = 1.0f;
			if (themask.a <= 0.5f) themask = 0.0f + (1.0f - change);
			return themask;
		}
		else return themask;
	}
}

float4 Combine( float2 uv : TEXCOORD1 ) : COLOR
{
	float4 color;
	float4 orig = tex2D( BGround, uv);
	float3 bg, fg, newc;
	bg = orig.rgb;
	fg = MaskColor.rgb;
	float4 Mask = tex2D( Samp2, uv);
	if (invert) Mask = 1.0f-Mask;
	if (show) {
		color = orig;
		if (Mask.a < 0.01) color = lerp(orig,float4(0,1,0,Mask.a),0.5);
		if (Mask.a > 0.99) color = lerp(orig,float4(1,0,0,Mask.a),0.5);
	}
	else {
		newc = method(fg, bg); //clamp(bg + fg, 0.0, 1.0);	//Add  
		color = lerp(orig,float4(newc.r, newc.g, newc.b, orig.a), Mask.a * strength);
	}
	return color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique PolyGrad
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
