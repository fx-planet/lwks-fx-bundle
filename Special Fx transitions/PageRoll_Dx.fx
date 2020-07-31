// @Maintainer jwrl
// @Released 2020-07-31
// @Author khaver
// @Author Eduardo Castineyra
// @Created 2018-06-01
// @see https://www.lwks.com/media/kunena/attachments/6375/PageRoll_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/PageRoll.mp4

/**
 This is the classic page turn transition.
*/

//-----------------------------------------------------------------------------------------//
// Original Shadertoy author:
// Eduardo Castineyra (casty) (2015-08-30) https://www.shadertoy.com/view/MtBSzR
//
// Creative Commons Attribution 4.0 International License
//-----------------------------------------------------------------------------------------//
// PageRoll_Dx.fx for Lightworks was adapted by user khaver 1 June 2018 from original
// code by the above author taken from the Shadertoy website:
// https://www.shadertoy.com/view/MtBSzR
//
// This adaptation retains the same Creative Commons license shown above.  It cannot be
// used for commercial purposes.
//
// note: code comments are from the original author(s).
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Modified 2020-07-31 jwrl.
// Reformatted the effect header.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Page Roll";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Page Roll Transition";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture vid1;
texture vid2;

texture vid11 : RenderColorTarget;
texture vid22 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler V1Sampler = sampler_state
{
	Texture = <vid1>;
	AddressU = Clamp;
	AddressV = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler V2Sampler = sampler_state
{
	Texture = <vid2>;
	AddressU = Clamp;
	AddressV = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler V1aSampler = sampler_state
{
	Texture = <vid11>;
	AddressU = Clamp;
	AddressV = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler V2aSampler = sampler_state
{
	Texture = <vid22>;
	AddressU = Clamp;
	AddressV = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float radius
<
   string Description = "Page Radius";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

bool BACK
<
	string Description = "Image on backside";
> = true;

int Direction
<
   string Description = "Direction";
   string Enum = "TLtoBR,BLtoTR,TRtoBL,BRtoTL,LtoR,RtoL,TtoB,BtoT";
> = 0;

bool REVERSE
<
	string Description = "Reverse";
> = false;

float PROG
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float _Progress;
float _OutputWidth;
float _OutputHeight;
float _OutputAspectRatio;

#define PI 3.141592
#define DIST 2
static float3 _cyl = float3(0.0,0.0,0.0);

/// 1D function x: _cylFun(t); y: normal at that point.
float2 curlFun(float t, float maxt, float rad){
	float2 ret = float2(t, 1.0);
    if (t < _cyl[DIST] - rad)
        return ret;					/// Before the curl
	if (t > _cyl[DIST] + rad)
        return float2(-1.0,-1.0);			/// After the curl

    /// Inside the curl
    float a = asin((t - _cyl[DIST]) / rad);
    float ca = -a + PI;
    ret.x = _cyl[DIST] + ca * rad;
    ret.y = cos(ca);

    if (ret.x < maxt) return ret;					/// We see the back face

    if (t < _cyl[DIST])
        return float2(t, 1.0);		/// Front face before the curve starts
    ret.y = cos(a);
    ret.x = _cyl[DIST] + a * rad;
    return ret.x < maxt ? ret : float2(-1.0,-1.0);  /// Front face curve
	}

float4 flipvid1 ( float2 fragCoord : TEXCOORD1 ) : COLOR
{
	if (Direction == 2 || Direction == 6) fragCoord = float2(fragCoord.x,1.0 - fragCoord.y);
	if (Direction == 1 || Direction == 4) fragCoord = float2(1.0 - fragCoord.x,fragCoord.y);
	if (Direction == 0) fragCoord = float2(1.0 - fragCoord.x,1.0 - fragCoord.y);
	return tex2D(V1Sampler, fragCoord);
}

float4 flipvid2 ( float2 fragCoord : TEXCOORD1 ) : COLOR
{
	if (Direction == 2 || Direction == 6) fragCoord = float2(fragCoord.x,1.0 - fragCoord.y);
	if (Direction == 1 || Direction == 4) fragCoord = float2(1.0 - fragCoord.x,fragCoord.y);
	if (Direction == 0) fragCoord = float2(1.0 - fragCoord.x,1.0 - fragCoord.y);
	return tex2D(V2Sampler, fragCoord);
}

float4 mainImage( float2 fragCoord : TEXCOORD1 ) : COLOR
{
	float rad = radius;
	if (Direction == 4 || Direction == 5 || Direction == 6 || Direction == 7) rad *= 0.8;
	float start = (rad * 0.5);
	float prog = PROG;
	if (REVERSE) prog = 1.0 - PROG;
	prog = prog + ((1.0 - prog) * start);
	if (prog > 1.0) prog = 1.0;
	if (Direction == 2 || Direction == 6) fragCoord = float2(fragCoord.x,1.0 - fragCoord.y);
	if (Direction == 1 || Direction == 4) fragCoord = float2(1.0 - fragCoord.x,fragCoord.y);
	if (Direction == 0) fragCoord = float2(1.0 - fragCoord.x,1.0 - fragCoord.y);
	float4 fragColor;
    float2 uv = fragCoord.xy;
    float2 ur = float2(1.0,1.0);
    float2 mouse = float2(1.0-prog,1.0-prog);
	if (Direction == 4 || Direction == 5) mouse = float2(1.0-prog,0.0);
	if (Direction == 6 || Direction == 7) mouse = float2(0.0,1.0-prog);
    float d = length(mouse * (1.0 + 4.0*rad)) - 2.0*rad;
    _cyl = float3(normalize(mouse), d);

    d = dot(uv, _cyl.xy);
    float2 end = abs((ur - uv) / _cyl.xy);
    float maxt = d + min(end.x, end.y);
    float2 cf = curlFun(d, maxt, rad);
    float2 tuv = uv + _cyl.xy * (cf.x - d);

	float shadow = 1.0 - smoothstep (0.0, rad * 2.0, -(d - _cyl[DIST]));
   	shadow *= (smoothstep(-rad, rad, (maxt - (cf.x + 1.5 * PI * rad + rad))));
    float4 curr = tex2D(V1aSampler, tuv);
	if (REVERSE) curr = tex2D(V2aSampler, tuv);
    if (BACK) curr = cf.y > 0.0 ? curr * cf.y  * (1.0 - shadow): (curr * 0.25 + 0.75) * (-cf.y);
	else curr = cf.y > 0.0 ? curr * cf.y  * (1.0 - shadow): -cf.y;
    shadow = smoothstep (0.0, rad * 2.0, (d - _cyl[DIST]));
	float4 next = tex2D(V2aSampler, uv);
	if (REVERSE) next = tex2D(V1aSampler, uv);
	if (prog == 1.0) return float4(next.rgb,1.0);
    next *= shadow;
    fragColor = cf.x > 0.0 ? curr : next;
	return float4(fragColor.rgb,1.0);
}



//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique PageRoll
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = vid11;";
   >
   {
      PixelShader = compile PROFILE flipvid1 ();
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = vid22;";
   >
   {
      PixelShader = compile PROFILE flipvid2 ();
   }

   pass pass_three
   {
      PixelShader = compile PROFILE mainImage ();
   }
}
