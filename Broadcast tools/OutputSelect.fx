// @ReleaseDate 2018-03-31
//OutputSelect
//http://www.alessandrodallafontana.com/

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "OutputSelect";
   string Category    = "User";
   string SubCategory = "Technical";
> = 0;

//--------------------------------------------------------------//
// Params
//--------------------------------------------------------------//

int SetTechnique
<
   string Description = "Output";
   string Enum = "Out_1,Out_2,Out_3,Out_4";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Inp_Out_1;
texture Inp_Out_2;
texture Inp_Out_3;
texture Inp_Out_4;

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


#pragma warning ( disable : 3571 )

//code

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
