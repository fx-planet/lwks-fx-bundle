// @Maintainer jwrl
// @Released 2018-03-31
// @Author khaver
// @Created "February 2013"
//--------------------------------------------------------------//
// Rays.fx created by Gary Hango (khaver) February 2013.
//
// Cross platform conversion by jwrl May 2 2016.
//
// Cross platform compatibility check 1 August 2017 jwrl.
//
// Explicitly defined float2 and float4 variables to address
// behavioural differences between the D3D and Cg compilers.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Rays";
   string Category    = "Stylize";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture Partial : RenderColorTarget;
texture Mask    : RenderColorTarget;

sampler InputSampler = sampler_state {
	Texture = <Input>;
	AddressU = Clamp;
	AddressV = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler M1 = sampler_state {
	Texture = <Mask>;
	AddressU = Clamp;
	AddressV = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler M2 = sampler_state {
	Texture = <Partial>;
	AddressU = Clamp;
	AddressV = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float CX
<
   string Description = "Center";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.50;
   float MaxVal = 2.50;
> = 0.5;

float CY
<
   string Description = "Center";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.50;
   float MaxVal = 2.50;
> = 0.5;

float BlurAmount
<
   string Description = "Length";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float Radius
<
   string Description = "Radius";
   float MinVal = 0.00;
   float MaxVal = 2.00;
> = 2.0;

float RThreshold
<
   string Description = "Red Threshold";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.8;

float GThreshold
<
   string Description = "Green Threshold";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.8;

float BThreshold
<
   string Description = "Blue Threshold";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.8;

float Mix
<
   string Description = "Brightness";
   float MinVal = 0.00;
   float MaxVal = 10.00;
> = 2.0;

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 main (float2 uv : TEXCOORD1) : COLOR
{
   float4 color = 0.0.xxxx;
   float2 Center = float2 (CX, 1 - CY) - 0.5.xx;
   float2 xy = uv - 0.5.xx;

   xy.x *= _OutputAspectRatio;

   float factor = 2.0 - distance (xy, Center);

   if (2.0 - factor > Radius) factor = 0.0;

   float4 rays = tex2D (InputSampler, uv);

   if (rays.r >= RThreshold) color.r = rays.r;

   if (rays.g >= GThreshold) color.g = rays.g;

   if (rays.b >= BThreshold) color.b = rays.b;

   return color * factor;
}

float4 prebuild (float2 uv : TEXCOORD1) : COLOR
{
   float4 c = 0.0.xxxx;
   float2 xy, Center = float2 (CX, 1 - CY);
   float scale;

   xy = uv - Center;

   for (int i = 0; i < 25; i++) {
      scale = 1.0 - BlurAmount * ((float) i / 40.0);
      c += tex2D (M1, xy * scale + Center) * ((40.0 - (float) i) / 60.0);
   }

   c /= 41;

   return c;
}

float4 combine (float2 uv : TEXCOORD1) : COLOR
{
   float4 c = 0.0.xxxx;
   float2 xy, Center = float2 (CX, 1 - CY);
   float scale;

   xy = uv - Center;

   for (int i = 25; i < 41; i++) {
      scale = 1.0 - BlurAmount * ((float) i / 40.0);
      c += tex2D (M1, xy * scale + Center) * ((40.0 - (float) i) / 60.0);
   }

   c /= 41;

   float4 base  = tex2D (InputSampler, uv);
   float4 pre_c = tex2D (M2, uv);
   float4 blend = (pre_c + (c * (1.0.xxxx - pre_c))) * Mix;

   return (base + blend * (1.0.xxxx - base));
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique SampleFxTechnique
{
   pass Pass0
   <
      string Script = "RenderColorTarget0 = Mask;";
   >
   {
      PixelShader = compile PROFILE main ();
   }

   pass Pass1
   <
      string Script = "RenderColorTarget0 = Partial;";
   >
   {
      PixelShader = compile PROFILE prebuild ();
   }

   pass Pass2
   {
      PixelShader = compile PROFILE combine ();
   }
}

