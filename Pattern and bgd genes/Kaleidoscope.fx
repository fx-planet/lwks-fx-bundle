// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Version 14.5 update 24 March 2018 by jwrl.
//
// Legality checking has been added to correct for a bug
// in XY sampler addressing on Linux and OS-X platforms.
// This effect should now function correctly when used with
// all current and previous Lightworks versions.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Kaleidoscope";        // The title
   string Category    = "Stylize";            // Governs the category that the effect appears in in Lightworks
   string SubCategory = "Patterns";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

texture Input;

texture Tex1 : RenderColorTarget;
texture Tex2 : RenderColorTarget;
texture Tex3 : RenderColorTarget;
texture Tex4 : RenderColorTarget;

sampler InputSampler = sampler_state
{
   Texture   = <Input>;
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

sampler Samp3 = sampler_state
{
   Texture   = <Tex3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp4 = sampler_state
{
   Texture   = <Tex4>;
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

int SetTechnique
<
   string Description = "Complexity";
   string Enum = "One,Two,Three,Four";
> = 0;

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

#define EMPTY    (0.0).xxxx

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

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
	float2 xy = uv;
   float2 zoomit = ((xy - 0.5.xx) / Zoom) + 0.5.xx;
   zoomit.x = zoomit.x + (0.5f-ORGX);
   zoomit.y = zoomit.y + (ORGY-0.5f);

   float4 color = fn_illegal (zoomit) ? EMPTY : tex2D (InputSampler, zoomit);

   if (zoomit.x < 0.0 || zoomit.x > 1.0) color = 0.0.xxxx;
   if (zoomit.y < 0.0 || zoomit.y > 1.0) color = 0.0.xxxx;
   return saturate(color);
}

float4 main2( float2 uv : TEXCOORD1 ) : COLOR
{
   float4 color = tex2D (Samp1, abs (uv - 0.5.xx));
   return saturate(color);
}

float4 main3( float2 uv : TEXCOORD1 ) : COLOR
{
   float4 color = tex2D (Samp2, abs ((uv * 2.0) - 1.0.xx));
   return saturate(color);
}

float4 main4( float2 uv : TEXCOORD1 ) : COLOR
{
   float4 color = tex2D(Samp3, abs ((uv * 2.0) - 1.0.xx));
   return saturate(color);
}

float4 main5( float2 uv : TEXCOORD1 ) : COLOR
{
   float4 color = tex2D (Samp4, abs ((uv * 2.0) - 1.0.xx));
   return saturate(color);
}

//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique One
{
   pass Pass1
   <
   string Script = "RenderColorTarget0 = Tex1;";
   >
   {
      PixelShader = compile PROFILE main1();
   }
   pass Pass2
   {
      PixelShader = compile PROFILE main2();
   }
}

technique Two
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

technique Three
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
   <
   string Script = "RenderColorTarget0 = Tex3;";
   >
   {
      PixelShader = compile PROFILE main3();
   }
   pass Pass4
   {
      PixelShader = compile PROFILE main4();
   }
}

technique Four
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
   <
   string Script = "RenderColorTarget0 = Tex3;";
   >
   {
      PixelShader = compile PROFILE main3();
   }
   pass Pass4
   <
   string Script = "RenderColorTarget0 = Tex4;";
   >
   {
      PixelShader = compile PROFILE main4();
   }
   pass Pass5
   {
      PixelShader = compile PROFILE main5();
   }
}
