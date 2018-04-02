// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------
// 
// JH Analysis Show Hi/Lo v1.0 - Juha Hartikainen - juha@linearteam.org
// - Blinks extreme darks/highlights
// 
// Modified to sit in user category "Analysis" for version 14.
// This will actually show as category "User", subcategory
// "Analysis" in 14 and as category "User" in earlier versions.
//--------------------------------------------------------------
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "JH Show Hi/Lo";
   string Category    = "User";
   string SubCategory = "Analysis";
> = 0;

//--------------------------------------------------------------
// Inputs
//--------------------------------------------------------------
texture Input;

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};


//--------------------------------------------------------------
// Parameters
//--------------------------------------------------------------
float LoLimit
<
   string Description = "Low Limit";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float HiLimit
<
   string Description = "High Limit";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.95;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------
// Shader
//--------------------------------------------------------------

float _Progress = 1.0;

half4 MainPS(float2 xy : TEXCOORD1) : COLOR
{
   float weight, flash;

   float4 color = tex2D(FgSampler, xy);

   weight=(color.r+color.g+color.b)/3.0;

   if ((weight <= LoLimit) || (weight >= HiLimit)) {
      if (frac(_Progress*50)>0.5) {
         flash = 1.0;
      } else flash = 0.0;

      color.r = color.g = color.b = flash;
   }

   return color;
}

technique SampleFxTechnique
{
   pass p0
   {
      PixelShader = compile PROFILE MainPS();
   }
}

