// @Maintainer jwrl
// @Released 2018-06-21
// @Author khaver
// @Author saabi
// @Created 2018-06-20
// @see https://www.lwks.com/media/kunena/attachments/6375/OldFilmLook_640.png
//-----------------------------------------------------------------------------------------//
// Original Shadertoy author:
// saabi (2018-03-31) https://www.shadertoy.com/view/4dVcRy
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------------------------------------------//
// OldFilmLook.fx for Lightworks was adapted by user khaver 20 June 2018 from original
// code by the above author taken from the Shadertoy website:
// https://www.shadertoy.com/view/4dVcRy
//
// This adaptation retains the same Creative Commons license shown above.  It cannot be
// used for commercial purposes.
//
// note: code comments are from the original author(s).
//
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Old Film Look";        // The title
   string Category    = "Stylize";              // Governs the category that the effect appears in in Lightworks
   string SubCategory = "User Effects";
> = 0;

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float _Progress;
float _OutputWidth;
float _OutputHeight;
float _OutputAspectRatio;
float _Length = 0;
float _Frame = 0;
#define CTIME (_Length*_Progress)
#define iFrame _Frame

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;
texture Film : RenderColorTarget;

sampler InputSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Border;
   AddressV  = Border;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FilmSampler = sampler_state
{
   Texture   = <Film>;
   AddressU  = Border;
   AddressV  = Border;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float scale
<
   string Description = "Frame Zoom";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5; // Default value

float sprockets
<
   string Description = "Size";
   string Group = "Sprockets";
   float MinVal       = 0.0;
   float MaxVal       = 20.0;
> = 6.72; // Default value

float sprocket2
<
   string Description = "Alignment";
   string Group = "Sprockets";
   float MinVal       = 0.0;
   float MaxVal       = 10.0;
> = 3.19; // Default value

bool sprocket3
<
	string Description = "Double Quantity";
   string Group = "Sprockets";
> = false;

float gstrength
<
   string Description = "Grain Strength";
   string Group = "Flaws";
   float MinVal       = 0.0;
   float MaxVal       = 2.0;
> = 1.0; // Default value

float ScratchAmount
<
   string Description = "Scratch Amount";
   string Group = "Flaws";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5; // Default value

float NoiseAmount
<
   string Description = "Dirt Amount";
   string Group = "Flaws";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5; // Default value

float smallJitterProbability
<
   string Description = "Minor";
   string Group = "Jitter";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5; // Default value

float largeJitterProbability
<
   string Description = "Major";
   string Group = "Jitter";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.05; // Default value

float angleProbability
<
   string Description = "Rotational";
   string Group = "Jitter";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.15; // Default value

float flicker
<
   string Description = "Flicker Strength";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5; // Default value

static const float separation = 1.2;
static const float filmWidth = 1.4;
static const float2 smallJitterDisplacement = float2(0.003,0.003);
static const float2 largeJitterDisplacement = float2(0.03,0.03);
static const float angleJitter = 0.0349; //2.0*3.1415/180.0;

//--------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------

float time() {
    return CTIME * 0.0101;
}

float hash(float n) {
 	return frac(cos(n*89.42)*343.42);
}

float2 hash2(float2 n) {
 	return float2(hash(n.x*23.62-300.0+n.y*34.35),hash(n.x*45.13+256.0+n.y*38.89));
}

float worley(float2 c, float time) {
    float dis = 1.0;
    for(int x = -1; x <= 1; x++)
        for(int y = -1; y <= 1; y++){
            float2 p = floor(c)+float2(x,y);
            float2 a = hash2(p) * time;
            float2 rnd = 0.5+sin(a)*0.5;
            float d = length(rnd+float2(x,y)-frac(c));
            dis = min(dis, d);
        }
    return dis;
}

float worley2(float2 c, float time) {
    float w = 0.0;
    float a = 0.5;
    for (int i = 0; i<2; i++) {
        w += worley(c, time)*a;
        c*=2.0;
        time*=2.0;
        a*=0.5;
    }
    return w;
}
float worley5(float2 c, float time) {
    float w = 0.0;
    float a = 0.5;
    int i = 0;
    for (int i = 0; i<5; i++) {
        w += worley(c, time)*a;
        c*=2.0;
        time*=2.0;
        a*=0.5;
    }
    return w;
}

float rand(float2 co) {
    return frac(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
}

float2 jitter(float2 uv, float2 s, float seed) {
	return float2(rand(float2(time(),seed))-0.5, rand(float2(time(),seed+0.11))-0.5)*s;
}

float2 rot(float2 coord, float a) {
	coord.x *= _OutputAspectRatio * 2.;
    float sin_factor = sin(a);
    float cos_factor = cos(a);
    coord = mul(coord,float2x2(cos_factor, -sin_factor, sin_factor, cos_factor));
	coord.x /= _OutputAspectRatio * 2.;
	return coord;
}

float4 vignette(float2 uv, float strength) {
    float l = length(uv);
    l = pow(l, 2.25);
	return 1.0 - float4(float3(l,l,l)*strength,1.0);
}

float4 bw(float4 c) {
    float v = c.r*.15+c.g*.8 + c.b*.05;
    return float4(float3(v,v,v),1.0);
}

float4 sepia(float4 c, float s) {
	float or = (c.r * .393) + (c.g *.769) + (c.b * .189);
	float og = (c.r * .349) + (c.g *.686) + (c.b * .168);
	float ob = (c.r * .272) + (c.g *.534) + (c.b * .131);
    return float4(float3(or,og,ob) * s,1.0);
}

float4 frame(float2 uv, float fn) {
    if (abs(uv.x) > 0.5 || abs(uv.y) > 0.5) return sepia(float4(0.03,0.02,0.0,0.02),1.0);

    float strength = 64.0 * gstrength;
    float x = (uv.x + 4.0 ) * (uv.y + 4.0 ) * (CTIME + 10.0);
	float4 grain = float(fmod((fmod(x, 13.0) + 1.0) * (fmod(x, 123.0) + 1.0), 0.01)-0.005).xxxx * strength;
    float4 i = tex2D( InputSampler , uv+0.5);
    float fnn = floor((fn+0.5)/separation)+CTIME;
    fnn = fmod(fnn/20.0,1.0);
    float fj = rand(float2(fnn, 5.34))*2.0;


    float4 ic = lerp(float4(i.rgb,1.0), float4(i.rgb * (fj + 0.0) ,1.0), flicker);
    ic *= vignette(uv*2.5, 0.25);
    float4 bwc = bw(ic);

    uv.x *= 100.0 + CTIME*.10;
    uv.y *= 100.;
    float dis = worley5(uv/64.0, CTIME*50.0);
    float3 c = lerp(float(-1.0).xxx, float(10.).xxx, dis);
    float4 spots = float4(clamp(c,0.0,1.0), 1.0);
	float noiseTrigger = rand(float2(time() * 8.543,2.658));
	spots = (noiseTrigger < NoiseAmount) ? spots : float(1.).xxxx;
	return sepia(bwc,1.0)*(1.0-grain) * spots;
}

float4 film(float2 uv) {
    float wm = 0.5 + (filmWidth-1.0)/4.0;
    float ww = (filmWidth-1.0)*0.1;
    float ax = abs(uv.x);
	float sprc = (sprocket3) ? 2.0 : 4.0;
    if (ax > filmWidth/2.0 || (ax > wm-ww && ax < wm+ww && fmod(floor((uv.y+sprocket2)*sprockets),sprc) == 1.0))
	    return float4(float(1.0).xxx, 1.0);

    uv.x *= 2000.10 ;
    uv.y *= 5.;
    float disw = worley2(uv/164.0, floor(CTIME * 10.389) * 50.124);
    float3 cw = lerp(float(1.0).xxx, float(-30.6).xxx, disw);
    cw = clamp(1.0-cw*cw,0.0,1.0);
    float scratchTrigger = rand(float2(time() * 2.543,0.823));
	cw = (scratchTrigger < ScratchAmount) ? cw : float(0.).xxx;
	return float4(cw * 2.0, (cw.x < 0.5) ? 0.0 : 1.0);
}


float4 final(float2 uv, float aspect) {
    float smallJitterTrigger = rand(float2(time(),0.125));
    float largeJitterTrigger = rand(float2(time(),0.122));
    float2 juv = uv;
	juv.x -= 0.5;
    juv += ((smallJitterTrigger > smallJitterProbability) ? float(0.).xx : jitter(uv, smallJitterDisplacement,0.01));
    juv += ((largeJitterTrigger > largeJitterProbability) ? float(0.).xx : jitter(uv, largeJitterDisplacement,0.01));

    float rotationTrigger = rand(float2(time(),0.123));
	juv = (rotationTrigger > angleProbability) ? juv : rot(juv, (rand(float2(time(),0.14))-0.5)*angleJitter);
    float2 fuv = float2(juv.x*aspect, (fmod(juv.y+1.705,separation)-0.5));
	float4 flm = film(float2(juv.x*aspect,juv.y+100.0));
	if (flm.a == 1.0) return frame(fuv, juv.y)  + flm;
	else {
		float4 cout = float4((1.0 - frame(fuv, juv.y).rgb)  +  (flm.rgb * 2.0), 0.0);
		return 1.0 - cout;
	}
}

float4 mainImage1( float2 fragCoord : TEXCOORD0) : COLOR
{
	// Normalized pixel coordinates (from 0 to 1)
	float scl = (scale * 1.05) + 0.75;
    float2 uv = float2(fragCoord.x - 0.5, fragCoord.y + 0.0);
    float2 vuv = uv;
	uv.y -= 0.5;
    uv *= float2(1.0,_OutputAspectRatio);
    uv /= scl;

    // Output to screen
    float4 fragColor = final(float2(uv.x, uv.y + 0.695) + 0.5, _OutputAspectRatio);
	return fragColor;
}


float4 mainImage2( float2 fragCoord : TEXCOORD0) : COLOR
{
    float2 uv = fragCoord.xy;
    float4 c = tex2D(FilmSampler, uv);
	float i;
	for (i=0.25; i<2.0; i=i+0.25) {
        c += tex2D(FilmSampler, uv + float2(0.,i/_OutputHeight));
        c += tex2D(FilmSampler, uv - float2(0.,i/_OutputHeight));
        c += tex2D(FilmSampler, uv + float2(i/_OutputWidth,0.));
        c += tex2D(FilmSampler, uv - float2(i/_OutputWidth,0.));
    }
	float4 fragColor = (c/29.0) * vignette(uv-0.5,2.0);
	return float4(fragColor.rgb,1.0);
}

//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------

technique SampleFxTechnique
{

   pass pass_one
   <
      string Script = "RenderColorTarget0 = Film;";
   >
   {
      PixelShader = compile PROFILE mainImage1();
   }


   pass pass_two
   {
      PixelShader = compile PROFILE mainImage2();
   }
}

