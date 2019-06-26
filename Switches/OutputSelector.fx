// @Maintainer jwrl
// @Released 2018-12-27
// @Author baopao
// @Created 2014-02-06
// @see https://www.lwks.com/media/kunena/attachments/6375/OutputSelect_640.png

/**
This effect is a simple device to select from up to four different outputs.  It was designed
for, and is extremely useful on complex effects builds to check the output of masking or
cropping, the DVE setup, colour correction pass or whatever else you may need.

Since it has very little overhead it may be safely left in situ when the effects setup
process is complete.
*/
//-----------------------------------------------------------------------------------------//
// Lightworks user effect OutputSelector.fx
//
// Created by baopao (http://www.alessandrodallafontana.com/).
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 6 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Output selector";
   string Category    = "User";
   string SubCategory = "Switches";
   string Notes       = "A simple effect to select from up to four different outputs for monitoring purposes";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp_Out_1;
texture Inp_Out_2;
texture Inp_Out_3;
texture Inp_Out_4;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler2D Out_1_sampler = sampler_state {
   Texture = <Inp_Out_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler2D Out_2_sampler = sampler_state {
   Texture = <Inp_Out_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler2D Out_3_sampler = sampler_state {
   Texture = <Inp_Out_3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler2D Out_4_sampler = sampler_state {
   Texture = <Inp_Out_4>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Output";
   string Enum = "Out_1,Out_2,Out_3,Out_4";
> = 0;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 OutputSelect_1 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (Out_1_sampler, uv);
}

float4 OutputSelect_2 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (Out_2_sampler, uv);
}

float4 OutputSelect_3 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (Out_3_sampler, uv);
}

float4 OutputSelect_4 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D(Out_4_sampler, uv);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Out_1
{
pass Single_Pass { PixelShader = compile PROFILE OutputSelect_1(); }
}

technique Out_2
{
pass Single_Pass { PixelShader = compile PROFILE OutputSelect_2(); }
}

technique Out_3
{
pass Single_Pass { PixelShader = compile PROFILE OutputSelect_3(); }
}

technique Out_4
{
pass Single_Pass { PixelShader = compile PROFILE OutputSelect_4(); }
}
