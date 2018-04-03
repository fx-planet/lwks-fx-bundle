// @Maintainer jwrl
// @Released 2018-03-31
// @Author unknown
//--------------------------------------------------------------
// alpha unpremultiply  
//
// Bug fix 26 July 2017 by jwrl:
// Because Windows and Linux-OS/X have differing defaults for
// undefined samplers they have now been explicitly declared.
//--------------------------------------------------------------

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Unpremultiply";
   string Category    = "Key";               // Changed from "Mix" for consistency with v14 - jwrl
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------
// Inputs
//--------------------------------------------------------------
texture FG;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//


sampler FGSampler = sampler_state
{
   Texture = <FG>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};



//--------------------------------------------------------------
// Parameters
//--------------------------------------------------------------





//--------------------------------------------------------------
// Shader
//--------------------------------------------------------------


float4 main (float2 uv : TEXCOORD1) : COLOR 
{
    float4 color = tex2D (FGSampler, uv);

    color.rgb /= color.a;
    
    return color;
}

technique SimpleTechnique
{
pass MainPass

   {
      PixelShader = compile PROFILE main();
   }

}




