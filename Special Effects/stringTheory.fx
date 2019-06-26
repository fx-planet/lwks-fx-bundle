// @Maintainer jwrl
// @Released 2018-12-27
// @Author khaver
// @Created 2018-08-01
// @OriginalAuthor Martijn Steinrucken 2018
// @see https://www.lwks.com/media/kunena/attachments/6375/StringTheory_640.png

/**
This effect is impossible to describe.  Try it to see what it does.

***********  WARNING: THIS EFFECT REQUIRES LIGHTWORKS 14.5 OR BETTER  ***********

*/

//-----------------------------------------------------------------------------------------//
// The Universe Within - by Martijn Steinrucken aka BigWings 2018
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------------------------------------------//
// stringTheory.fx for Lightworks was adapted by user khaver 1 Aug 2018 for use with Lightworks
// version 14.5 and higher from original code by the above licensee taken from the Shadertoy
// website (https://www.shadertoy.com/view/lscczl).
//
// This adaptation retains the same Creative Commons license shown above.
// It cannot be used for commercial purposes.
//
// Modified 5 December 2018 jwrl.
// Changed subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "String Theory";
   string Category    = "Matte";
   string SubCategory = "Special Effects";
   string Notes       = "You really have to try this to see what it does";
> = 0;

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float3 baseCol = float3(1.,1.,1.);

float Brightness
<
   string Description = "Brightness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Glow
<
   string Description = "Glow";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Sparkle
<
   string Description = "Sparkle";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

bool negate
<
	string Description = "Negative";
> = false;

int Layers
<
   string Description = "Layers";
   string Enum = "1,2,3,4,5,6,7,8";
> = 5;

float CENTERX
<
   string Description = "Center";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float CENTERY
<
   string Description = "Center";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Rotation
<
   string Description = "Rotation";
   float MinVal = 0.0;
   float MaxVal = 360.0;
> = 180.0;

float Size
<
   string Description = "Zoom";
   float MinVal = 0.0;
   float MaxVal = 100.0;
> = 1.0;

float Zoom
<
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 50.0;
> = 15.0;

float Speed
<
   string Description = "Linear Speed";
   float MinVal = -20.0;
   float MaxVal = 20.0;
> = 0.0;

float Jumble
<
   string Description = "Motion Speed";
   float MinVal = 0.0;
   float MaxVal = 100.0;
> = 5.0;

float Thinness
<
   string Description = "String Density";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float Irregularity
<
   string Description = "Irregularity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//--------------------------------------------------------------//
// Common
//--------------------------------------------------------------//

float _Progress;
float _OutputWidth;
float _OutputHeight;
float _OutputAspectRatio;
float _LengthFrames = 0;
float _Length = 0;


//#define iFrame (_LengthFrames*_Progress)
#define iTime (_Length*_Progress+20.0)
#define S(a, b, t) smoothstep(a, b, t)
#define NUM_LAYERS 4.

float N21(float2 p)
{	// Dave Hoskins - https://www.shadertoy.com/view/4djSRW
	float3 p3  = frac(float3(p.xyx) * float3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

float2 GetPos(float2 id, float2 offs, float t) {
    float n = N21(id+offs);
    float n1 = frac(n*10.);
    float n2 = frac(n*100.);
    float a = t+n;
    return offs + float2(sin(a*n1), cos(a*n2))*(Irregularity*0.45);
}

float df_line( in float2 a, in float2 b, in float2 p)
{
    float2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa,ba) / dot(ba,ba), 0., 1.);
	return length(pa - ba * h);
}

float lines(float2 a, float2 b, float2 uv) {
    float r1 = .03;
    float r2 = .001;

    float d = df_line(a, b, uv);
    float d2 = length(a-b);
    float fade = S(Thinness+0.0001, 0.00, d2);

    fade += S(.05, .001, abs(d2-.75));
    return S(r1, r2, d)*fade;
}

float NetLayer(float2 st, float n, float t) {
	float jumble = Jumble + 0.001;
    float2 id = floor(st)+n;

    st = frac(st)-.5;

    float2 p[9];
    int i=0;
    for(float y=-1.; y<=1.; y++) {
    	for(float x=-1.; x<=1.; x++) {
            p[i++] = GetPos(id, float2(x,y), t/float(Layers+1));
    	}
    }

    float m = 0.;
    float sparkle = 0.;

    for(int i=0; i<9; i++) {
        m += lines(p[4], p[i], st);

        float d = length(st-p[i]);

        float s = (.005/(d*d));
        s *= S(1., .7, d);
        float pulse = sin((frac(p[i].x)+frac(p[i].y)+(t/jumble))*5.)*.4+.6;
        pulse = pow(pulse, 20.);

        s *= pulse;
        sparkle += s;
    }

    m += lines(p[1], p[3], st);
	m += lines(p[1], p[5], st);
    m += lines(p[7], p[5], st);
    m += lines(p[7], p[3], st);

    m += sparkle * Sparkle;

    return m;
}

float4 mainImage(float2 fragCoord : TEXCOORD0) : COLOR
{
	float jumble = Jumble + 0.001;
	float layers = 1.0 + float(Layers);

    float2 uv = fragCoord - 0.5;
	//uv.y += 0.5;
	float2 M = float2(CENTERX,1.0-CENTERY) * 10.0;
	M -= 5.0;
	uv.x *= _OutputAspectRatio;

    float t = iTime*.1*Speed;
	t += 1e-10;
	uv *= Size;

    float s = sin(radians(Rotation));
    float c = cos(radians(Rotation));
    float2x2 rot = float2x2(c, -s, s, c);
    float2 st = mul(uv,rot);
	M = mul(M,mul(rot,2.));

    float m = 0.;
    for(float i=0.; i<1.; i+=1./8.) {
		if (i > float(Layers) / 8.) break;
        float z = frac(t+i);
        float size = lerp(Zoom, 1., z);
        float fade = S(0., .6, z)*S(1., .8, z);

        m += fade * NetLayer(st*size-M*z, i, iTime*jumble);
    }
	float glow  = Glow * 2.;

    float3 col = baseCol*m;
    col += baseCol*glow;

    col *= 1.-dot(uv,uv);
	col = saturate(col*Brightness*2.0);
	if (negate) col = 1.0 - col;

    float4 fragColor = float4(col,1.0);
	return fragColor;
}



//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique StringTheory
{
   pass Pass1
   {
      PixelShader = compile PROFILE mainImage ();
   }
}
