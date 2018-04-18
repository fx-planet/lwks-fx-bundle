// @Maintainer jwrl
// @Released 2018-04-07
// @Author khaver
// @see https://www.lwks.com/media/kunena/attachments/6375/GlassTiles.png
// @see https://www.youtube.com/watch?v=O55QTV0gjmQ
//-----------------------------------------------------------------------------------------//
// Lightworks user effect GlassTiles.fx
//
// Breaks the image into glass tiles.
//
// Added subcategory for LW14 - jwrl 18 Feb 2017
//
// Bug fix 13 July 2017 by jwrl:
// This addresses a cross platform issue which may have caused the effect not to behave
// as expected on either Linux or Mac systems.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// GitHub-relevant modification, 18 April 2018 schrauber
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Glass Tiles";
   string Category    = "Stylize";
   string SubCategory = "Distortion";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and shader
//-----------------------------------------------------------------------------------------//

texture Input;

sampler FgSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Tiles
<
   string Description = "Tiles";
   float MinVal       = 0.0f;
   float MaxVal       = 200.0f;
> = 15.0; // Default value

float BevelWidth
<
   string Description = "Bevel Width";
   float MinVal       = 0.0f;
   float MaxVal       = 200.0f;
> = 15.0; // Default value

float Offset
<
   string Description = "Offset";
   float MinVal       = 0.0f;
   float MaxVal       = 200.0f;
> = 0.0; // Default value

float4 GroutColor
<
   string Description = "Grout Color";
   bool SupportsAlpha = true;
> = { 0.0f, 0.0f, 0.0f, 0.0f };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputWidth;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

half4 GtilesPS(float2 uv : TEXCOORD1) : COLOR {
	float2 newUV1;
	newUV1.xy = uv.xy + tan((Tiles*2.5)*(uv.xy-0.5f) + Offset)*(BevelWidth/_OutputWidth);
	float4 c1 = tex2D(FgSampler, newUV1);
	if(newUV1.x<0 || newUV1.x>1 || newUV1.y<0 || newUV1.y>1)
	{
	c1 = GroutColor;
	}
	c1.a=1;
	return c1;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass p0
   {
      PixelShader = compile PROFILE GtilesPS();
   }
}
