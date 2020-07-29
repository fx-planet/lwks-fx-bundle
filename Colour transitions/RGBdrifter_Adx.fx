// @Maintainer jwrl
// @Released 2020-07-29
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_RGBdrift_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_RGBdrift.mp4

/**
 This transitions a delta key in or out using different curves for each of red, green and
 blue.  One colour and alpha is always linear, and the other two can be set using the
 colour profile selection.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBdrifter_Adx.fx
//
// Version history:
//
// Modified 2020-07-29 jwrl:
// Rolled unfolded effects into transition position.
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//
// Modified jwrl 2018-12-23
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RGB drifter (delta)";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Separates foreground from background then mixes it in or out using different curves for each of red, green and blue";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Key : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Key = sampler_state { Texture = <Key>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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
   string Enum = "At start of clip,At end of clip,At start (unfolded)";
> = 0;

int SetTechnique
<
   string Description = "Select colour profile";
   string Enum = "Red to blue,Blue to red,Red to green,Green to red,Green to blue,Blue to green"; 
> = 0;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define CURVE   4.0

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd;
   float3 Bgd;

   if (Ttype == 0) {
      Fgd = tex2D (s_Foreground, xy1).rgb;
      Bgd = tex2D (s_Background, xy2).rgb;
   }
   else {
      Bgd = tex2D (s_Foreground, xy1).rgb;
      Fgd = tex2D (s_Background, xy2).rgb;
   }

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_main_R_B (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (Ttype == 1) ? 1.0 - Amount : Amount;
   float amt_R  = pow (1.0 - amount, CURVE);
   float amt_B  = pow (amount, CURVE);

   float4 Fgnd   = tex2D (s_Key, uv);
   float4 Bgnd   = (Ttype == 0) ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r  = lerp (vidIn.r, Bgnd.r, amt_R);
   retval.b  = lerp (Bgnd.b, vidIn.b, amt_B);
   Fgnd.a    = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_B_R (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (Ttype == 1) ? 1.0 - Amount : Amount;
   float amt_R  = pow (amount, CURVE);
   float amt_B  = pow (1.0 - amount, CURVE);

   float4 Fgnd   = tex2D (s_Key, uv);
   float4 Bgnd   = (Ttype == 0) ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (Bgnd.r, vidIn.r, amt_R);
   retval.b = lerp (vidIn.b, Bgnd.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_R_G (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (Ttype == 1) ? 1.0 - Amount : Amount;
   float amt_R  = pow (1.0 - amount, CURVE);
   float amt_G  = pow (amount, CURVE);

   float4 Fgnd   = tex2D (s_Key, uv);
   float4 Bgnd   = (Ttype == 0) ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (vidIn.r, Bgnd.r, amt_R);
   retval.g = lerp (Bgnd.g, vidIn.g, amt_G);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_G_R (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (Ttype == 1) ? 1.0 - Amount : Amount;
   float amt_R  = pow (amount, CURVE);
   float amt_G  = pow (1.0 - amount, CURVE);

   float4 Fgnd   = tex2D (s_Key, uv);
   float4 Bgnd   = (Ttype == 0) ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (Bgnd.r, vidIn.r, amt_R);
   retval.g = lerp (vidIn.g, Bgnd.g, amt_G);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_G_B (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (Ttype == 1) ? 1.0 - Amount : Amount;
   float amt_G  = pow (1.0 - amount, CURVE);
   float amt_B  = pow (amount, CURVE);

   float4 Fgnd   = tex2D (s_Key, uv);
   float4 Bgnd   = (Ttype == 0) ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.g = lerp (vidIn.g, Bgnd.g, amt_G);
   retval.b = lerp (Bgnd.b, vidIn.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_B_G (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (Ttype == 1) ? 1.0 - Amount : Amount;
   float amt_G  = pow (amount, CURVE);
   float amt_B  = pow (1.0 - amount, CURVE);

   float4 Fgnd   = tex2D (s_Key, uv);
   float4 Bgnd   = (Ttype == 0) ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);
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

technique RGBdrifter_Adx_R_B
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_R_B (); }
}

technique RGBdrifter_Adx_B_R
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_B_R (); }
}

technique RGBdrifter_Adx_R_G
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_R_G (); }
}

technique RGBdrifter_Adx_G_R
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_G_R (); }
}

technique RGBdrifter_Adx_G_B
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_G_B (); }
}

technique RGBdrifter_Adx_B_G
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_B_G (); }
}
