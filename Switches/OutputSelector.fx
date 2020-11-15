// @Maintainer jwrl
// @Released 2020-11-15
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
// Version history:
//
// Update 2020-11-15 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 6 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Output selector";
   string Category    = "User";
   string SubCategory = "Switches";
   string Notes       = "A simple effect to select from up to four different outputs for monitoring purposes";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture In_1;
texture In_2;
texture In_3;
texture In_4;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler2D In_1_sampler = sampler_state {
   Texture = <In_1>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler2D In_2_sampler = sampler_state {
   Texture = <In_2>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler2D In_3_sampler = sampler_state {
   Texture = <In_3>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler2D In_4_sampler = sampler_state {
   Texture = <In_4>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
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
   string Enum = "In_1,In_2,In_3,In_4";
> = 0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 OutputSelect_1 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In_1_sampler, uv);
}

float4 OutputSelect_2 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In_2_sampler, uv);
}

float4 OutputSelect_3 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In_3_sampler, uv);
}

float4 OutputSelect_4 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D(In_4_sampler, uv);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Input_1
{
   pass Single_Pass { PixelShader = compile PROFILE OutputSelect_1(); }
}

technique Input_2
{
   pass Single_Pass { PixelShader = compile PROFILE OutputSelect_2(); }
}

technique Input_3
{
   pass Single_Pass { PixelShader = compile PROFILE OutputSelect_3(); }
}

technique Input_4
{
   pass Single_Pass { PixelShader = compile PROFILE OutputSelect_4(); }
}
