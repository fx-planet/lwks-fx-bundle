// @ReleaseDate 2018-03-31
// @Author "Alessandro Dalla Fontana"
//--------------------------------------------------------------
// KeyDespiil  Despill Background Based
// http://www.alessandrodallafontana.com/ 
//
// Version 14 update 19 Feb 2017 jwrl.
//
// Changed category from "Keying" to "Key", added subcategory
// to effect header.
//
// Cross platform compatibility check 1 August 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//--------------------------------------------------------------

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "KeyDespill";
   string Category    = "Key";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------
// Inputs
//--------------------------------------------------------------

texture Fg;
texture Bg;

sampler FgSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------
// Parameters
//--------------------------------------------------------------

int SetTechnique
<
   string Description = "Key";
   string Enum = "Green,Blue";
> = 0;

float RedAmount
<
   string Description = "RedAmount";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.5;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------
// Shader
//--------------------------------------------------------------

float4 Green(float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
    float4 color = tex2D(FgSampler, xy1);
    float4 Back = tex2D(BgSampler, xy2);

    float mask = clamp(color.g-lerp (color.r, color.b, RedAmount), 0, 1);
    color.g = color.g-mask;
    color += Back * mask; 

    return color;
}

float4 Blue(float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
    float4 color = tex2D(FgSampler, xy1);
    float4 Back = tex2D(BgSampler, xy2);

    float mask = clamp(color.b-lerp (color.r, color.g, RedAmount), 0, 1);
    color.b = color.b-mask;
    color += Back * mask;

    return color;
}

///----------------------------------------------------
///  Technique  //////
///----------------------------------------------------

technique GreenDespill
{
   pass p0
   {
      PixelShader = compile PROFILE Green();
   }
}

technique BlueDespill
{
   pass p0
   {
      PixelShader = compile PROFILE Blue();
   }
}

