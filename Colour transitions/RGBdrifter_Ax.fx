// @Maintainer jwrl
// @Released 2020-07-29
// @Author jwrl
// @Created 2018-06-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_RGBdrift_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_RGBdrift.mp4

/**
 This transitions a title in or out using different curves for each of red, green and
 blue.  One colour and alpha is always linear, and the other two can be set using the
 colour profile selection.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBdrifter_Ax.fx
//
// Version history:
//
// Modified 2020-07-29 jwrl:
// Reworded Boost text to match requirements for 2020.1 and up.
// Moved Boost code from fn_tex2D() to ps_keygen().
// Changed "Transition" to "Transition position".
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RGB drifter (alpha)";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Transitions a title in or out using different curves for each of red, green and blue";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Key : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Sup>; };
sampler s_Background = sampler_state { Texture = <Vid>; };

sampler s_Key = sampler_state { Texture = <Key>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "Lightworks effects: Disconnect the input and select";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image";
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
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

float4 ps_main_R_B (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (Ttype == 0) ? Amount : 1.0 - Amount;
   float amt_R  = pow (1.0 - amount, CURVE);
   float amt_B  = pow (amount, CURVE);

   float4 Fgnd   = tex2D (s_Key, uv);
   float4 Bgnd   = tex2D (s_Background, uv);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (vidIn.r, Bgnd.r, amt_R);
   retval.b = lerp (Bgnd.b, vidIn.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_B_R (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (Ttype == 0) ? Amount : 1.0 - Amount;
   float amt_R  = pow (amount, CURVE);
   float amt_B  = pow (1.0 - amount, CURVE);

   float4 Fgnd   = tex2D (s_Key, uv);
   float4 Bgnd   = tex2D (s_Background, uv);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (Bgnd.r, vidIn.r, amt_R);
   retval.b = lerp (vidIn.b, Bgnd.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_R_G (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (Ttype == 0) ? Amount : 1.0 - Amount;
   float amt_R  = pow (1.0 - amount, CURVE);
   float amt_G  = pow (amount, CURVE);

   float4 Fgnd   = tex2D (s_Key, uv);
   float4 Bgnd   = tex2D (s_Background, uv);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (vidIn.r, Bgnd.r, amt_R);
   retval.g = lerp (Bgnd.g, vidIn.g, amt_G);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_G_R (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (Ttype == 0) ? Amount : 1.0 - Amount;
   float amt_R  = pow (amount, CURVE);
   float amt_G  = pow (1.0 - amount, CURVE);

   float4 Fgnd   = tex2D (s_Key, uv);
   float4 Bgnd   = tex2D (s_Background, uv);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (Bgnd.r, vidIn.r, amt_R);
   retval.g = lerp (vidIn.g, Bgnd.g, amt_G);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_G_B (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (Ttype == 0) ? Amount : 1.0 - Amount;
   float amt_G  = pow (1.0 - amount, CURVE);
   float amt_B  = pow (amount, CURVE);

   float4 Fgnd   = tex2D (s_Key, uv);
   float4 Bgnd   = tex2D (s_Background, uv);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.g = lerp (vidIn.g, Bgnd.g, amt_G);
   retval.b = lerp (Bgnd.b, vidIn.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_B_G (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (Ttype == 0) ? Amount : 1.0 - Amount;
   float amt_G  = pow (amount, CURVE);
   float amt_B  = pow (1.0 - amount, CURVE);

   float4 Fgnd   = tex2D (s_Key, uv);
   float4 Bgnd   = tex2D (s_Background, uv);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.g = lerp (Bgnd.g, vidIn.g, amt_G);
   retval.b = lerp (vidIn.b, Bgnd.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique RGBdrifter_Ax_R_B
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_R_B (); }
}

technique RGBdrifter_Ax_B_R
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_B_R (); }
}

technique RGBdrifter_Ax_R_G
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_R_G (); }
}

technique RGBdrifter_Ax_G_R
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_G_R (); }
}

technique RGBdrifter_Ax_G_B
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_G_B (); }
}

technique RGBdrifter_Ax_B_G
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_B_G (); }
}
