// @ReleaseDate 2018-03-31
// @Author khaver
//--------------------------------------------------------------//
// Anamorphic Lens Flare
//
// Originally written by khaver, modified by jwrl to add a V14
// subcategory February 18, 2017.
//
// Cross platform compatibility check 31 July 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Explicitly defined float4 variables to avoid the difference
// in behaviour between the D3D and Cg compilers.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Anamorphic Lens Flare";
   string Category    = "Stylize";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Params
//--------------------------------------------------------------//

float BlurAmount
<
   string Description = "Length";
   float MinVal = 0.0f;
   float MaxVal = 50.0f;
> = 12.0f;

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0f;
   float MaxVal = 1.0f;
> = 0.75f;

float adjust
<
   string Description = "Threshold";
   float MinVal = 0.0f;
   float MaxVal = 1.0f;
> = 0.25f;

float Hue
<
   string Description = "Hue";
   float MinVal = -0.5f;
   float MaxVal = 0.5f;
> = 0.0f;

bool flare
<
   string Description = "Show Flare";
> = false;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//
texture Input;
texture Sample1 : RenderColorTarget;
texture Sample2 : RenderColorTarget;
texture Sample3 : RenderColorTarget;
texture Sample4 : RenderColorTarget;
texture Sample5 : RenderColorTarget;

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
   Texture = <Sample1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp2 = sampler_state
{
   Texture = <Sample2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp3 = sampler_state
{
   Texture = <Sample3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp4 = sampler_state
{
   Texture = <Sample4>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp5 = sampler_state
{
   Texture = <Sample5>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Code
//--------------------------------------------------------------//
float _OutputWidth;//  = 1.0;
float _OutputHeight;// = 1.0;

float4 ps_adjust ( float2 xy : TEXCOORD1 ) : COLOR {
   float4 Color = tex2D( InputSampler, xy);
   float red = Color.r; float green = Color.g; float blue = Color.b; float alpha = Color.a;
   float rhue = 0.1f;
   float ghue = 0.1f;
   float bhue = 1.2f;
   if (Hue < 0.0f) rhue += abs (Hue);
   if (Hue > 0.0f) ghue += Hue;
   if ((red+green+blue)/3.0f < 1.0f-adjust) {
      red = 0.0f; green = 0.0f; blue = 0.0f;
   }
   return float4(red*rhue,green*ghue,blue*bhue,alpha);
}

float4 ps_blur1( float2 xy1 : TEXCOORD1 ) : COLOR {
   float pixel = 1.0f / _OutputWidth;
   float bluramount = pixel;
   float4 ret=0.0.xxxx;
   float2 offset;
   float MapAngle = 0.0f * 6.3500;
   sincos(MapAngle, offset.y, offset.x);
   offset *= bluramount;

   for (int count = 0; count < 24; count++) {
   ret += tex2D( Samp1, xy1 - offset * count);
   }
   ret = ret / 24.0f;
   return float4(ret.rgb,1.0f);
}

float4 ps_blur2( float2 xy1 : TEXCOORD1 ) : COLOR {
   float pixel = 1.0f / _OutputWidth;
   float bluramount = pixel;
   float4 ret=0.0.xxxx;
   float2 offset;
   float MapAngle = 0.0f * 6.3500;
   sincos(MapAngle, offset.y, offset.x);
   offset *= bluramount;

   for (int count = 0; count < 24; count++) {
   ret += tex2D( Samp1, xy1 + offset * count);
   }
   ret = ret / 24.0f;
   return float4(ret.rgb,1.0f);
}


float4 ps_blur3( float2 xy1 : TEXCOORD1 ) : COLOR {
   float pixel = 1.0f / _OutputWidth;
   float bluramount = BlurAmount * pixel;
   float4 ret=0.0.xxxx;
   float2 offset;
   float MapAngle = 0.0f * 6.3500;
   sincos(MapAngle, offset.y, offset.x);
   offset *= bluramount;

   for (int count = 0; count < 24; count++) {
   ret += tex2D( Samp3, xy1 - offset * count);
   }
   ret = ret / 12.0f;
   return float4(ret.rgb,1.0f);
}

float4 ps_blur4( float2 xy1 : TEXCOORD1 ) : COLOR {
   float pixel = 1.0f / _OutputWidth;
   float bluramount = BlurAmount * pixel;
   float4 ret=0.0.xxxx;
   float2 offset;
   sincos(0.0f, offset.y, offset.x);
   offset *= bluramount;

   for (int count = 0; count < 24; count++) {
   ret += tex2D( Samp4, xy1 + offset * count);
   }
   ret = ret / 12.0f;
   return float4(ret.rgb,1.0f);
}


float4 ps_combine( float2 xy : TEXCOORD1 ) : COLOR {
   float3 blr = tex2D( Samp5, xy).rgb;
   float4 source = tex2D( InputSampler, xy);
   float4 comb = saturate(float4(source.rgb + blr.rgb,source.a));
   if (!flare) return lerp(source,comb,Strength);
   else return float4(blr.rgb*Strength*2.0f,source.a);
}
   

technique Blur
{
   pass Pass1
   <
      string Script = "RenderColorTarget0 = Sample1;";
   >
   {
      PixelShader = compile PROFILE ps_adjust();
   }

   pass Pass2
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_blur1();
   }

   pass Pass3
   <
      string Script = "RenderColorTarget0 = Sample3;";
   >
   {
      PixelShader = compile PROFILE ps_blur2();
   }

   pass Pass4
   <
      string Script = "RenderColorTarget0 = Sample4;";
   >
   {
      PixelShader = compile PROFILE ps_blur3();
   }

   pass Pass5
   <
      string Script = "RenderColorTarget0 = Sample5;";
   >
   {
      PixelShader = compile PROFILE ps_blur4();
   }

   pass Pass6
   {
      PixelShader = compile PROFILE ps_combine();
   }
}

 		 	   		  
