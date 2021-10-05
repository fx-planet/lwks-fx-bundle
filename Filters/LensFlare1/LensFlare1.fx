// @Maintainer jwrl
// @Released 2020-11-12
// @Author khaver
// @Author mu6k
// @Author Icecool
// @Author Yusef28
// @Created 2018-05-16
// @see https://www.lwks.com/media/kunena/attachments/6375/LensFlare_1_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LensFlare_1.mp4

/**
 This effect creates very realistic lens flare patterns.  The file LensFlare_1.png is also
 required, and must be in the Effects Templates folder.

 ***********  WARNING: THIS EFFECT REQUIRES LIGHTWORKS 14.5 OR BETTER  ***********
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LensFlare1.fx
//-----------------------------------------------------------------------------------------//
//
// Original Shadertoy authors:
// mu6k (2013-08-13) https://www.shadertoy.com/view/4sX3Rs
// Icecool (2014-07-06) https://www.shadertoy.com/view/XdfXRX
// Yusef28 (2016-08-19) https://www.shadertoy.com/view/Xlc3D2
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// LensFlare1.fx for Lightworks was adapted by user khaver 16 May 2018 from original
// code by the above authors taken from the Shadertoy website:
// https://www.shadertoy.com/view/4sX3Rs
// https://www.shadertoy.com/view/XdfXRX
// https://www.shadertoy.com/view/Xlc3D2
//
// This adaptation retains the same Creative Commons license shown above.  It cannot be
// used for commercial purposes.
//
// note: code comments are from the original author(s).
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Update 2020-11-12 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified jwrl 2018-12-23:
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//
// Modified jwrl 2018-05-18:
// Cross platform compatibility check and code optimisation.  A total of roughly twenty
// major or minor changes were found.  Additional comments identify those sections, and
// I sincerely hope that I have got them all!
//
// I chose not to do anything to correct the y coordinates, which in Lightworks are the
// inverse of the way that they're used in GLSL.  I simply changed the default CENTERY
// setting from 0.25 to 0.75 to make the flare appear in the upper half of the frame by
// default.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lens Flare #1";
   string Category    = "Stylize";
   string SubCategory = "Filters";
   string Notes       = "Multicolor lens flare with secondary reflections and animated rays";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _Progress;
float _OutputWidth;
float _OutputHeight;
float _OutputAspectRatio;  // jwrl: removed unused _LengthFrames, added _OutputAspectRatio
float _Length = 0;

#define CTIME (_Length*(1.0-_Progress))

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, InputSampler);

// jwrl: At khaver's suggestion, renamed the file below from noise.png to LensFlare_1.png.

texture _Grain < string Resource = "LensFlare_1.png"; >;

sampler GSampler = sampler_state
{
   Texture   = <_Grain>;
   AddressU  = Wrap;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CENTERX
<
   string Description = "Center";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

float CENTERY
<
   string Description = "Center";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float AMOUNT
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float COMPLEX
<
	string Description = "Complexity";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 10.0;

float ZOOM
<
   string Description = "Flare Zoom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float SCATTER
<
   string Description = "Light Scatter";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

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

float GLINT
<
   string Description = "Brightness";
   string Group = "Flare Source";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float RAYS
<
   string Description = "Rays Count";
   string Group = "Flare Source";
   float MinVal = 0.0;
   float MaxVal = 50.0;
> = 12.0;

bool ANIMATE
<
   string Description = "Animate Rays";
   string Group = "Flare Source";
> = true;

int BLADES
<
   string Description = "Shutter Blades";
   string Group = "Secondary Reflections";
   string Enum = "5,6,7,8";
> = 1;

float SHUTTER
<
   string Description = "Shutter Offset";
   string Group = "Secondary Reflections";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float POINTS
<
   string Description = "Points Offset";
   string Group = "Secondary Reflections";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float rnd (float w)
{
   return frac (sin (w) * 1000.0);
}

float noise1 (float t)
{
   return (ANIMATE) ? tex2D (GSampler, float2 (t * 10.0 / _OutputWidth, 0.0)).x : 1.0;
}

float noise2 (float2 t)
{
   return ANIMATE ? tex2D (GSampler,((t * 10.0 / _OutputWidth) + (CTIME * 0.05).xx)).x : 1.0;
}

float vary ()
{
   float pixX = 1.0 / _OutputWidth;
   float pixY = 1.0 / _OutputHeight;

   float2 iMouse = float2 (CENTERX, 1.0 - CENTERY);

   float4 col = tex2D (InputSampler, iMouse);
   col += tex2D (InputSampler, iMouse - float2 (pixX, pixY));     // jwrl: changed from float2(iMouse.x - pixX,iMouse.y - pixY) (simplified mathematics)
   col += tex2D (InputSampler, float2 (iMouse.x, iMouse.y - pixY));
   col += tex2D (InputSampler, iMouse + float2 (pixX, -pixY));    // jwrl: changed from float2(iMouse.x + pixX,iMouse.y - pixY) (simplified mathematics)

   col += tex2D (InputSampler, float2 (iMouse.x - pixX, iMouse.y));
   col += tex2D (InputSampler, float2 (iMouse.x + pixX, iMouse.y));

   col += tex2D (InputSampler, iMouse - float2 (pixX, -pixY));    // jwrl: changed from float2(iMouse.x - pixX,iMouse.y + pixY) (simplified mathematics)
   col += tex2D (InputSampler, float2 (iMouse.x, iMouse.y + pixY));
   col += tex2D (InputSampler, iMouse + float2 (pixX, pixY));     // jwrl: changed from float2(iMouse.x + pixX,iMouse.y + pixY) (simplified mathematics)

   col /= 9.0;

   return dot (col.rgb, float3 (0.33333, 0.33334, 0.33333));
}

float regShape (float2 p, int N)
{
   float a = atan2 (p.x, p.y) + 0.2;
   float b = 6.28319 / float (N);

   return smoothstep (0.5, 0.51, cos (floor (0.5 + a / b) * b - a) * length (p.xy));
}

float3 circle (float2 p, float size, float decay, float3 color, float3 color2, float dist,
               float2 mouse, float i)
{
   float complex = ceil (COMPLEX);
   float po = POINTS / 10.0;

   int blades = BLADES + 5;

   p *= 1.0 - ZOOM;

   // l is used for making rings.I get the length and pass it through a sinwave but
   // I also use a pow function. pow function + sin function , from 0 and up, = a pulse,
   // at least if you return the max of that and 0.0.

   float l = length (p + mouse * (dist * 4.0)) + size / 2.0;

   // l2 is used in the rings as well...somehow...

   float l2 = length (p + mouse * (dist * 4.0)) + size / 3.0;

   // these are circles, big, rings, and  tiny respectively

   float c  = max (0.01-pow (length (p + mouse * dist), size * 1.4), 0.0) * 50.0;
   float c1 = max (0.001 - pow (l - 0.3, 1.0 / 40.0) + sin (l * 30.0), 0.0) * 3.0;
   float c2 = max (0.04 / pow (length (p - mouse * dist / 2.0 + po), 1.0), 0.0) / 20.0;
   float s  = max (0.01 - pow (regShape (p * 5.0 + mouse * dist * 5.0 + SHUTTER, blades), 1.0), 0.0) * 5.0;

   color = cos (float3 (0.44, 0.24, 0.2) * 8.0 + dist * 4.0) * 0.5 + 0.5;

   return (i > complex) ? 0.0.xxx : ((c + c1 + c2 + s) * color) - 0.01.xxx;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 mainImage (float2 fragCoord : TEXCOORD2) : COLOR
{
   float rays = ceil (RAYS);
   float v = vary ();

   if (v < THRESH) v = 0.0;
   if (!AFFECT) v = 1.0;

   float affect = saturate (GLINT - (1.0 - v));

   float3 orig = tex2D (InputSampler, fragCoord).rgb;

   float2 uv = fragCoord - 0.5.xx;
   float2 mm = float2 ((CENTERX - 0.5) * _OutputAspectRatio, 0.5 - CENTERY);

   uv.x *= _OutputAspectRatio;

   float3 circColor = float3 (0.9, 0.2, 0.1);
   float3 circColor2 = float3 (0.3, 0.1, 0.5);

   //now to make the sky not black

    float3 color = (0.0 - 0.52 * sin (CTIME / 0.4) * 0.1 + 0.2).xxx * SCATTER;

    //this calls the function which adds three circle types every time through the loop based on parameters I
    //got by trying things out. rnd i*2000. and rnd i*20 are just to help randomize things more

   for (int i = 0; i < 10; i++) {
      color += circle (uv, pow (rnd (i * 2000.0), 2.0) + 1.41, 0.0, circColor + float (i).xxx, circColor2 + float (i).xxx, rnd (i * 20.0) * 3.0 - 0.3, mm, float (i));
   }

   //get angle and length of the sun (uv - mouse)

   float a = atan2 (uv.y - mm.y, uv.x - mm.x);
   float l = pow (length (uv - mm), 0.1);
   float n = noise2 (float2 ((a - CTIME / 9.0) * 16.0, l * 32.0));

   float bright = 0.1;

   //add the sun with the frill things

   color += (1.0 / (length (uv - mm) * 16.0 + 1.0) * affect).xxx; // jwrl: changed from (1.0/(length(uv-mm)*16.0+1.0) * affect) for float3 arithmetic
   color += (color * (sin ((a + CTIME / 18.0 + noise1 (abs (a) +n / 2.0) * 2.0) * rays) * 0.1 + l * 0.1 + 0.8)) * affect;

   //add another sun in the middle (to make it brighter)  with the color I want, and bright as the numerator.

   color += ((max (bright / pow (length (uv - mm) * 4.0, 0.5), 0.0) * 4.0) * float3 (0.2, 0.21, 0.3) * 4.0) * affect;

   //multiply by the exponetial e^x ? of 1.0-length which kind of masks the brightness more so that
   //there is a sharper roll of of the light decay from the sun.

   color *= exp (1.0 - length (uv - mm)) / 5.0;

   return float4 (saturate (orig + (color * v * AMOUNT)), 1.0);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Scape
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pass1 ExecuteShader (mainImage)
}

