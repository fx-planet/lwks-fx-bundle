// @Maintainer jwrl
// @Released 2018-12-21
// @Author khaver
// @Author toninoni
// @Created 2018-06-12
// @see https://www.lwks.com/media/kunena/attachments/6375/LensFlare_2_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LensFlare_2.mp4

/**
This effect is an accurate lens flare simulation.
*/

//-----------------------------------------------------------------------------------------//
// Original Shadertoy author:
// toninoni (2014-02-05) https://www.shadertoy.com/view/ldSXWK
//-----------------------------------------------------------------------------------------//
// LensFlare2.fx for Lightworks was adapted by user khaver 12 June 2018 from original
// code by the above author taken from the Shadertoy website:
// https://www.shadertoy.com/view/ldSXWK
//
// Modified jwrl 2018-12-23:
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lens Flare #2";
   string Category    = "Stylize";
   string SubCategory = "Filters";
   string Notes       = "Basic lens flare";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state { Texture = <Input>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CENTERX
<
   string Description = "Center";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.15;

float CENTERY
<
   string Description = "Center";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float AMOUNT
<
   string Description = "Intensity";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 2.0;

float COMPLEXITY
<
	string Description = "Lens Adjustment";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float DISTANCE
<
	string Description = "Flare Distance";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float ZOOM
<
   string Description = "Flare Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float SCATTER
<
   string Description = "Light Scatter";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool AFFECT
<
	string Description = "Use Image";
   string Group = "Image Content";
> = false;

float THRESH
<
   string Description = "Threshold";
   string Group = "Image Content";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//

float _Progress;
float _OutputWidth;
float _OutputHeight;
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//

float vary()
{
	float pixX = 1.0/_OutputWidth;
	float pixY = 1.0/_OutputHeight;
	float2 iMouse = float2(CENTERX,1.0 - CENTERY);
	float4 col = tex2D(InputSampler,iMouse);
	col += tex2D(InputSampler,iMouse - float2(pixX,pixY));
	col += tex2D(InputSampler,float2(iMouse.x,iMouse.y - pixY));
	col += tex2D(InputSampler,iMouse + float2(pixX,-pixY));

	col += tex2D(InputSampler,float2(iMouse.x - pixX,iMouse.y));
	col += tex2D(InputSampler,float2(iMouse.x + pixX,iMouse.y));

	col += tex2D(InputSampler,iMouse - float2(pixX,-pixY));
	col += tex2D(InputSampler,float2(iMouse.x,iMouse.y + pixY));
	col += tex2D(InputSampler,iMouse + float2(pixX,pixY));

	col = col / 9.0;
	float cout = dot(col.rgb,float3(0.33333,0.33334,0.33333));

	return cout;
}


float3 lensflare(float2 uv,float2 pos)
{
	float v = vary();
	if (v < THRESH) v = 0.0;
	if (!AFFECT) v = 1.0;

	pos *= DISTANCE;
    float intensity = AMOUNT;
	float scatter = (1.0 - SCATTER) * 0.85;
	float2 uvd = uv*(length(uv) * COMPLEXITY);

	float f1 = max(0.01-pow(length(uv+1.2*pos),1.9*ZOOM*v),.0)*7.0;

	float f2 = max(1.0/(1.0+32.0*pow(length(uvd+0.8*pos),2.0*ZOOM*v)),.0)*00.1;
	float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.85*pos),2.0*ZOOM*v)),.0)*00.08;
	float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.9*pos),2.0*ZOOM*v)),.0)*00.06;

	float2 uvx = lerp(uv,uvd,-0.5);

	float f4 = max(0.01-pow(length(uvx+0.4*pos),2.4*ZOOM*v),.0)*6.0;
	float f42 = max(0.01-pow(length(uvx+0.45*pos),2.4*ZOOM*v),.0)*5.0;
	float f43 = max(0.01-pow(length(uvx+0.5*pos),2.4*ZOOM*v),.0)*3.0;

	uvx = lerp(uv,uvd,-.4);

	float f5 = max(0.01-pow(length(uvx+0.2*pos),5.5*ZOOM*v),.0)*2.0;
	float f52 = max(0.01-pow(length(uvx+0.4*pos),5.5*ZOOM*v),.0)*2.0;
	float f53 = max(0.01-pow(length(uvx+0.6*pos),5.5*ZOOM*v),.0)*2.0;

	uvx = lerp(uv,uvd,-0.5);

	float f6 = max(0.01-pow(length(uvx-0.3*pos),1.6*ZOOM*v),.0)*6.0;
	float f62 = max(0.01-pow(length(uvx-0.325*pos),1.6*ZOOM*v),.0)*3.0;
	float f63 = max(0.01-pow(length(uvx-0.35*pos),1.6*ZOOM*v),.0)*5.0;

	float3 c = float3(.0,.0,.0);

	c.r+=f2+f4+f5+f6; c.g+=f22+f42+f52+f62; c.b+=f23+f43+f53+f63;
	c = c*1.3 - float3(length(uvd)*scatter,length(uvd)*scatter,length(uvd)*scatter);

	return c * intensity;
}

float3 cc(float3 color, float factor,float factor2)
{
	float w = color.x+color.y+color.z;
	return lerp(color,float3(w,w,w)*factor,w*factor2);
}

float4 mainImage( float2 fragCoord : TEXCOORD1) : COLOR
{
	float4 fragColor;
	float3 orig = tex2D (InputSampler, fragCoord).rgb;
	float2 uv = fragCoord.xy - 0.5;
	uv.x *= _OutputAspectRatio;
	float2 mouse = float2(CENTERX - 0.5, (1.0 - CENTERY) - 0.5);
	mouse.x *= _OutputAspectRatio;

	float3 color = float3(1.5,1.2,1.2)*lensflare(uv,mouse.xy);
	color = saturate(cc(color,.5,.1));
	fragColor = float4(color,1.0);
	fragColor = float4(saturate( orig.rgb + fragColor.rgb), 1.0);
	return fragColor;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Flare
{
   pass Pass1
   {
      PixelShader = compile PROFILE mainImage ();
   }
}
