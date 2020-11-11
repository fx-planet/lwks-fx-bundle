// @Maintainer jwrl
// @Released 2020-11-11
// @Author khaver
// @Created 2011-06-27
// @see https://www.lwks.com/media/kunena/attachments/6375/Perspective_640.png

/**
 The name of the effect describes what it does.  It's a neat, simple effect for adding
 a perspective illusion to a flat plane.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Perspective.fx
//
// Version history:
//
// Update 2020-11-11 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 23 December 2018 jwrl.
// Added creation date.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14.1 update 5 December 2017 by jwrl.
// Added LINUX and MAC test to allow support for changing "Clamp" to "ClampToEdge" on
// those platforms.  It will now function correctly when used with Lightworks versions
// 14.5 and higher under Linux or OS-X and fixes a bug associated with using this effect
// with transitions on those platforms.  The bug still exists when using older versions
// of Lightworks.
//
// Cross platform compatibility check 31 July 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Fully defined float2 and float4 variables to address the behavioural difference
// between the D3D and Cg compilers when this is not done.
//
// Version 14 update 21 May 2017 by jwrl: Changed category to DVE and added subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Perspective";
   string Category    = "DVE";
   string SubCategory = "Distortion";
   string Notes       = "A neat, simple effect for adding a perspective illusion to a flat plane";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;
texture Tex1 : RenderColorTarget;
texture Tex2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef MAC
#define Clamp ClampToEdge
#endif

sampler InputSampler = sampler_state
{
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp1 = sampler_state
{
   Texture   = <Tex1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp2 = sampler_state
{
   Texture   = <Tex2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters 
//-----------------------------------------------------------------------------------------//

bool Grid
<
	string Description = "Show grid";
> = false;

float TLX
<
   string Description = "Top Left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float TLY
<
   string Description = "Top Left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float TRX
<
   string Description = "Top Right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float TRY
<
   string Description = "Top Right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float BLX
<
   string Description = "Bottom Left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float BLY
<
   string Description = "Bottom Left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float BRX
<
   string Description = "Bottom Right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float BRY
<
   string Description = "Bottom Right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float ORGX
<
   string Description = "Pan";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float ORGY
<
   string Description = "Pan";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Zoom
<
	string Description = "Zoom";
   float MinVal = 0.00;
   float MaxVal = 2.00;
> = 1.0;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 main2( float2 uv : TEXCOORD1 ) : COLOR
{
   float4  color = tex2D(Samp1,uv);
   if (Grid) {
   	if (
   		(uv.x >= 0.099f && uv.x <= 0.101)
   		|| (uv.x >= 0.199f && uv.x <= 0.201)
   		|| (uv.x >= 0.299f && uv.x <= 0.301)
   		|| (uv.x >= 0.399f && uv.x <= 0.401)
   		|| (uv.x >= 0.499f && uv.x <= 0.501)
   		|| (uv.x >= 0.599f && uv.x <= 0.601)
   		|| (uv.x >= 0.699f && uv.x <= 0.701)
   		|| (uv.x >= 0.799f && uv.x <= 0.801)
   		|| (uv.x >= 0.899f && uv.x <= 0.901)
   		)
   		color = 1.0.xxxx - color;
   }
   return color;
}

float4 main3( float2 uv : TEXCOORD1 ) : COLOR
{
   float4  color = tex2D(Samp2,uv);
   if (Grid) {
   	if (
   		(uv.y >= 0.099f && uv.y <= 0.101)
   		|| (uv.y >= 0.199f && uv.y <= 0.201)
   		|| (uv.y >= 0.299f && uv.y <= 0.301)
   		|| (uv.y >= 0.399f && uv.y <= 0.401)
   		|| (uv.y >= 0.499f && uv.y <= 0.501)
   		|| (uv.y >= 0.599f && uv.y <= 0.601)
   		|| (uv.y >= 0.699f && uv.y <= 0.701)
   		|| (uv.y >= 0.799f && uv.y <= 0.801)
   		|| (uv.y >= 0.899f && uv.y <= 0.901)
   		)
   		color = 1.0.xxxx - color;
   }
   return color;
}

float4 main1( float2 uv : TEXCOORD1 ) : COLOR
{
   float deltaxtl = 0.1f - TLX;
   float deltaxtr = TRX - 0.9f;
   float deltaxbl = 0.1f - BLX;
   float deltaxbr = BRX - 0.9f;
   float deltaytl = TLY - 0.9f;
   float deltaybl = TRY - 0.9f;
   float deltaytr = 0.1f - BLY;
   float deltaybr = 0.1f - BRY;
   float2 xy;
   float x1 = lerp(0.0f+deltaxtl,1.0f-deltaxtr,uv.x);
   float x2 = lerp(0.0f+deltaxbl,1.0f-deltaxbr,uv.x);
   float y1 = lerp(0.0f+deltaytl,1.0f-deltaytr,uv.y);
   float y2 = lerp(0.0f+deltaybl,1.0f-deltaybr,uv.y);
   xy.x = lerp(x1, x2, uv.y)+(0.5f-ORGX);
   xy.y = lerp(y1, y2, uv.x)+(ORGY-0.5f);
   float2 zoomit = ((xy-0.5.xx)/Zoom)+0.5.xx;
   float4  color = tex2D(InputSampler,zoomit);
   if (zoomit.x < 0.0 || zoomit.x > 1.0) color = 0.0.xxxx;
   if (zoomit.y < 0.0 || zoomit.y > 1.0) color = 0.0.xxxx;
   return saturate(color);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Perspective
{
   pass Pass1
   <
   string Script = "RenderColorTarget0 = Tex1;";
   >
   {
      PixelShader = compile PROFILE main1();
   }
   pass Pass2
   <
   string Script = "RenderColorTarget0 = Tex2;";
   >
   {
      PixelShader = compile PROFILE main2();
   }
   pass Pass3
   {
      PixelShader = compile PROFILE main3();
   }
}
