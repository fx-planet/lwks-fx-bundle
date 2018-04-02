// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect AdjBlend.fx
//
// Created by LW user jwrl 25 October 2017.
// @Author jwrl
// @CreationDate "25 October 2017"
//
// This is a quick way of blending when the alpha channel may
// not quite be as required.  The alpha channel may be inverted
// or scaled, the video may be premultiplied, and transparency
// and opacity may be adjusted.  Unlike the blend effect there
// are no Photoshop-style blending modes.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Adjustable blend";
   string Category    = "Key";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgdSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

bool Invert
<
   string Description = "Invert alpha";
> = false;

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int SetTechnique
<
   string Group = "Fine tuning";
   string Description = "Premultiply foreground";
   string Enum = "Yes,No"; 
> = 1;

float Transparency
<
   string Group = "Fine tuning";
   string Description = "Transparency";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Boost_alpha
<
   string Group = "Fine tuning";
   string Description = "Alpha linearity";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main_0 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (FgdSampler, uv);
   float4 Bgd = tex2D (BgdSampler, uv);

   if (Invert) Fgd.a = 1.0 - Fgd.a;

   float scale = (abs (Boost_alpha) * 9.0) + 1.0;

   if (Boost_alpha < 0.0) { Fgd.a = pow (Fgd.a, scale); }
   else if (Boost_alpha > 0.0) { Fgd.a = 1.0 - pow (1.0 - Fgd.a, scale); }

   Fgd.rgb *= Fgd.a;
   Fgd.a = lerp (1.0, Fgd.a, Transparency);

   return lerp (Bgd, Fgd, Fgd.a * Amount);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (FgdSampler, uv);
   float4 Bgd = tex2D (BgdSampler, uv);

   if (Invert) Fgd.a = 1.0 - Fgd.a;

   float scale = (abs (Boost_alpha) * 9.0) + 1.0;

   if (Boost_alpha < 0.0) { Fgd.a = pow (Fgd.a, scale); }
   else if (Boost_alpha > 0.0) { Fgd.a = 1.0 - pow (1.0 - Fgd.a, scale); }

   Fgd.a = lerp (1.0, Fgd.a, Transparency);

   return lerp (Bgd, Fgd, Fgd.a * Amount);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique AdjBlend_0
{
   pass P_1 { PixelShader = compile PROFILE ps_main_0 (); }
}

technique AdjBlend_1
{
   pass P_1 { PixelShader = compile PROFILE ps_main_1 (); }
}

