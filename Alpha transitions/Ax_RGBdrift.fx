// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_RGBdrift_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_RGBdrift.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_RGBdrift.fx
//
// This transitions a title in or out using different curves for each of red, green and
// blue.  One colour and alpha is always linear, and the other two can be set using the
// colour profile selection.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha RGB drifter";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Transitions a title in or out using different curves for each of red, green and blue";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Super = sampler_state { Texture = <Sup>; };
sampler s_Video = sampler_state { Texture = <Vid>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "If using a Lightworks text effect disconnect its input and set this first";
   string Enum = "Crawl/Roll/Titles,Video/External image";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Ttype
<
   string Description = "Transition";
   string Enum = "Fade in,Fade out";
> = 0;

int SetTechnique
<
   string Description = "Select colour profile";
   string Enum = "Red to blue,Blue to red,Red to green,Green to red,Green to blue,Blue to green"; 
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define CURVE   4.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   float4 retval = tex2D (Vsample, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_R_B (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd  = fn_tex2D (s_Super, uv);
   float4 Bgnd  = tex2D (s_Video, uv);
   float4 vidIn = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval;

   float amount = Ttype == 0 ? Amount : 1.0 - Amount;
   float amt_R  = pow (1.0 - amount, CURVE);
   float amt_B  = pow (amount, CURVE);

   retval.ga = lerp (Bgnd.ga, vidIn.ga, amount);
   retval.r  = lerp (vidIn.r, Bgnd.r, amt_R);
   retval.b  = lerp (Bgnd.b, vidIn.b, amt_B);
   Fgnd.a    = Fgnd.a > 0.0 ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_B_R (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd  = fn_tex2D (s_Super, uv);
   float4 Bgnd  = tex2D (s_Video, uv);
   float4 vidIn = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval;

   float amount = Ttype == 0 ? Amount : 1.0 - Amount;
   float amt_R  = pow (amount, CURVE);
   float amt_B  = pow (1.0 - amount, CURVE);

   retval.ga = lerp (Bgnd.ga, vidIn.ga, amount);
   retval.r  = lerp (Bgnd.r, vidIn.r, amt_R);
   retval.b  = lerp (vidIn.b, Bgnd.b, amt_B);
   Fgnd.a    = Fgnd.a > 0.0 ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_R_G (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd  = fn_tex2D (s_Super, uv);
   float4 Bgnd  = tex2D (s_Video, uv);
   float4 vidIn = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval;

   float amount = Ttype == 0 ? Amount : 1.0 - Amount;
   float amt_R  = pow (1.0 - amount, CURVE);
   float amt_G  = pow (amount, CURVE);

   retval.ba = lerp (Bgnd.ba, vidIn.ba, amount);
   retval.r  = lerp (vidIn.r, Bgnd.r, amt_R);
   retval.g  = lerp (Bgnd.g, vidIn.g, amt_G);
   Fgnd.a    = Fgnd.a > 0.0 ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_G_R (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd  = fn_tex2D (s_Super, uv);
   float4 Bgnd  = tex2D (s_Video, uv);
   float4 vidIn = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval;

   float amount = Ttype == 0 ? Amount : 1.0 - Amount;
   float amt_R  = pow (amount, CURVE);
   float amt_G  = pow (1.0 - amount, CURVE);

   retval.ba = lerp (Bgnd.ba, vidIn.ba, amount);
   retval.r  = lerp (Bgnd.r, vidIn.r, amt_R);
   retval.g  = lerp (vidIn.g, Bgnd.g, amt_G);
   Fgnd.a    = Fgnd.a > 0.0 ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_G_B (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd  = fn_tex2D (s_Super, uv);
   float4 Bgnd  = tex2D (s_Video, uv);
   float4 vidIn = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval;

   float amount = Ttype == 0 ? Amount : 1.0 - Amount;
   float amt_G  = pow (1.0 - amount, CURVE);
   float amt_B  = pow (amount, CURVE);

   retval.ra = lerp (Bgnd.ra, vidIn.ra, amount);
   retval.g  = lerp (vidIn.g, Bgnd.g, amt_G);
   retval.b  = lerp (Bgnd.b, vidIn.b, amt_B);
   Fgnd.a    = Fgnd.a > 0.0 ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_B_G (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd  = fn_tex2D (s_Super, uv);
   float4 Bgnd  = tex2D (s_Video, uv);
   float4 vidIn = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval;

   float amount = Ttype == 0 ? Amount : 1.0 - Amount;
   float amt_G  = pow (amount, CURVE);
   float amt_B  = pow (1.0 - amount, CURVE);

   retval.ra = lerp (Bgnd.ra, vidIn.ra, amount);
   retval.g  = lerp (Bgnd.g, vidIn.g, amt_G);
   retval.b  = lerp (vidIn.b, Bgnd.b, amt_B);
   Fgnd.a    = Fgnd.a > 0.0 ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_RGBdrifter_R_B
{
   pass P_1 { PixelShader = compile PROFILE ps_main_R_B (); }
}

technique Ax_RGBdrifter_B_R
{
   pass P_1 { PixelShader = compile PROFILE ps_main_B_R (); }
}

technique Ax_RGBdrifter_R_G
{
   pass P_1 { PixelShader = compile PROFILE ps_main_R_G (); }
}

technique Ax_RGBdrifter_G_R
{
   pass P_1 { PixelShader = compile PROFILE ps_main_G_R (); }
}

technique Ax_RGBdrifter_G_B
{
   pass P_1 { PixelShader = compile PROFILE ps_main_G_B (); }
}

technique Ax_RGBdrifter_B_G
{
   pass P_1 { PixelShader = compile PROFILE ps_main_B_G (); }
}

