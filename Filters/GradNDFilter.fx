// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Original effect by khaver, cross platform compatibility
// check 1 August 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Fully defined float3 variables and constants to address
// behavioural differences between the D3D and Cg compilers.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Graduated ND Filter";        // The title
   string Category    = "Stylize";            // Governs the category that the effect appears in in Lightworks
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

texture Input;

sampler InputSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Define parameters here.
//
// The Lightworks application will automatically generate
// sliders/controls for all parameters which do not start
// with a a leading '_' character
//--------------------------------------------------------------//

int Direction
<
        string Description = "Direction";
        string Enum = "Vertical,Horizontal";
> = 0;

bool Flip
<
	string Description = "Flip";
> = false;

int Mode
<
        string Description = "Blend mode";
        string Enum = "Add,Subtract,Multiply,Screen,Overlay,Soft Light,Hard Light,Exclusion,Lighten,Darken,Difference,Burn";
> = 2;

float4 Tint
<
	string Description = "Tint";
> = { 0.0, 0.0, 0.0, 1.0 };

float Mixit
<
	string Description = "Strength";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float SX
<
   string Description = "Start";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float SY
<
   string Description = "Start";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float EX
<
   string Description = "End";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float EY
<
   string Description = "End";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;


#pragma warning ( disable : 3571 )

//--------------------------------------------------------------
// Pixel Shader
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//
// Note that pixels are processed out of order, in parallel.
// Using shader model 2.0, so there's a 64 instruction limit -
// use multple passes if you need more.
//--------------------------------------------------------------


float4 main1( float2 uv : TEXCOORD1 ) : COLOR
{
   float top =1.0;
   float v1 = 1.0-SY;
   float v2 = 1.0-EY;
   float bottom = 0.0;
   float left = 0.0;
   float h1 = SX;
   float h2 = EX;
   float right = 1.0;
   float4 orig = tex2D(InputSampler,uv);
   float3 newc, fg, bg;
   bg = orig.rgb;
   fg = Tint.rgb;
   if (Mode == 0) newc = saturate(bg + fg);	//Add

   if (Mode == 1) newc = saturate(bg - fg);	//Subtract

   if (Mode == 2) newc = bg * fg;		//Multiply

   if (Mode == 3) newc = 1.0.xxx - ((1.0.xxx - fg) * (1.0 - bg));	//Screen

   if (Mode == 4) {						//Overlay
	if (bg.r < 0.5) newc.r = 2.0 * fg.r * bg.r;
	else newc.r = 1.0 - (2.0 * ( 1.0 - fg.r) * ( 1.0 - bg.r));
	
	if (bg.g < 0.5) newc.g = 2.0 * fg.g * bg.g;
	else newc.g = 1.0 - (2.0 * ( 1.0 - fg.g) * ( 1.0 - bg.g));
	
	if (bg.b < 0.5) newc.b = 2.0 * fg.b * bg.b;
	else newc.b = 1.0 - (2.0 * ( 1.0 - fg.b) * ( 1.0 - bg.b));
  }

   if (Mode == 5) newc = ( 1.0.xxx - bg) * (fg * bg) + (bg * (1.0.xxx - ((1.0.xxx - bg) * (1.0.xxx - fg)))); //Soft Light

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

   if (Mode == 11) newc = saturate(1.0.xxx - (( 1.0.xxx - fg) / bg));	//Burn

   float3 outc;
   float deltv = abs(EY - SY);
   float delth = abs(EX - SX);
   if (Flip) {
   if (Direction == 0) {
	if (uv.y < v1)  outc = bg;
	if (uv.y >= v1 && uv.y <= v2) outc = lerp(newc, bg, (v2 - uv.y) / deltv);
	if (uv.y > v2) outc = newc;
   }
   if (Direction == 1) {
	if (uv.x < h1)  outc = bg;
	if (uv.x >= h1 && uv.x <= h2) outc = lerp(bg, newc, (uv.x - h1) / delth);
	if (uv.x > h2) outc = newc;
   }
   }
  else {
   if (Direction == 0) {
	if (uv.y < v1)  outc = newc;
	if (uv.y >= v1 && uv.y <= v2) outc = lerp(bg, newc, (v2 - uv.y) / deltv);
	if (uv.y > v2) outc = bg;
   }
   if (Direction == 1) {
	if (uv.x < h1)  outc = newc;
	if (uv.x >= h1 && uv.x <= h2) outc = lerp(newc, bg, (uv.x - h1) / delth);
	if (uv.x > h2) outc = bg;
   }
   }
   return lerp(orig, float4(outc, orig.a), Mixit);
	
}

//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------

technique SampleFxTechnique
{
   pass Pass1
   {
      PixelShader = compile PROFILE main1();
   }
}

