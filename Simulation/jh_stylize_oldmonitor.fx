// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------
// 
// JH Stylize Vignette v1.0 - Juha Hartikainen - juha@linearteam.org
// - Emulates old hercules monitor
//
// Version 14 update 18 Feb 2017 jwrl.
// Added "Simulation" subcategory to effect header.
//
// Cross platform compatibility check 3 August 2017 jwrl.
// Explicitly defined FgSampler so we aren't bitten by cross
// platform default sampler state differences.
// 
//--------------------------------------------------------------
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "JH Old Monitor";      
   string Category    = "Stylize";
   string SubCategory = "Simulation";
> = 0;


//--------------------------------------------------------------
// Inputs
//--------------------------------------------------------------
texture Input;

sampler FgSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};


//--------------------------------------------------------------
// Parameters
//--------------------------------------------------------------
float4 LineColor
<
   string Description = "Scanline Color";
   bool SupportsAlpha = false;
> = { 1.0f, 1.0f, 1.0f, 1.0f };

float LineCount
<
   string Description = "Scanline Count";
   float MinVal       = 100.0f;
   float MaxVal       = 1080.0f;
> = 300.0f;

#pragma warning ( disable : 3571 )


//--------------------------------------------------------------
// Shader
//--------------------------------------------------------------
static const float _PI = 3.14159265f;

float4 OldMonitorPS(float2 xy : TEXCOORD1) : COLOR {
    float4 color;
	float intensity;
	float multiplier;
	float oldalpha;
	
    color = tex2D(FgSampler, xy);
	oldalpha = color.a;
	
	intensity = (color.r+color.g+color.b)/3;
   
    multiplier = (sin(_PI*xy.y*LineCount)+1.0f)/2.0f;
   
    color = LineColor*intensity*multiplier;
	color.a = oldalpha;
   
    return color;
}

technique SampleFxTechnique
{
   pass p0
   {
      PixelShader = compile PROFILE OldMonitorPS();
   }
}

