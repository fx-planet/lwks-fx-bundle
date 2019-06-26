// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Push_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Push.mp4

/**
This mimics the Lightworks push effect but supports titles by means of a delta key operation.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Push_Adx.fx
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Push transition (delta)";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Separates foreground from background then pushes it on or off screen horizontally or vertically";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Title = sampler_state
{
   Texture   = <Title>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
   string Description = "Transition mode";
   string Enum = "Delta key in,Delta key out";
> = 0;

int SetTechnique
<
   string Description = "Type";
   string Enum = "Push Right,Push Down,Push Left,Push Up";
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

#define FX_OUT  1

#define HALF_PI 1.5707963268

#define EMPTY   0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (s_Sampler, uv);
}

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
      Fgd = tex2D (s_Background, xy2).rgb;
      Bgd = tex2D (s_Foreground, xy1).rgb;
   }

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_push_right (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd;

   float2 xy;

   if (Ttype == 0) {
      Bgnd = tex2D (s_Foreground, uv);
      xy = float2 (saturate (uv.x - sin (HALF_PI * Amount) + 1.0), uv.y);
   }
   else {
      Bgnd = tex2D (s_Background, uv);
      xy = float2 (saturate (uv.x + cos (HALF_PI * Amount) - 1.0), uv.y);
   }

   float4 Fgnd = fn_tex2D (s_Title, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_push_left (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd;

   float2 xy;

   if (Ttype == 0) {
      Bgnd = tex2D (s_Foreground, uv);
      xy = float2 (saturate (uv.x + sin (HALF_PI * Amount) - 1.0), uv.y);
   }
   else {
      Bgnd = tex2D (s_Background, uv);
      xy = float2 (saturate (uv.x - cos (HALF_PI * Amount) + 1.0), uv.y);
   }

   float4 Fgnd = fn_tex2D (s_Title, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_push_down (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd;

   float2 xy;

   if (Ttype == 0) {
      Bgnd = tex2D (s_Foreground, uv);
      xy = float2 (uv.x, saturate (uv.y - sin (HALF_PI * Amount) + 1.0));
   }
   else {
      Bgnd = tex2D (s_Background, uv);
      xy = float2 (uv.x, saturate (uv.y + cos (HALF_PI * Amount) - 1.0));
   }

   float4 Fgnd = fn_tex2D (s_Title, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_push_up (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd;

   float2 xy;

   if (Ttype == 0) {
      Bgnd = tex2D (s_Foreground, uv);
      xy = float2 (uv.x, saturate (uv.y + sin (HALF_PI * Amount) - 1.0));
   }
   else {
      Bgnd = tex2D (s_Background, uv);
      xy = float2 (uv.x, saturate (uv.y - cos (HALF_PI * Amount) + 1.0));
   }

   float4 Fgnd = fn_tex2D (s_Title, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Push_right
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_push_right (); }
}

technique Push_down
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_push_down (); }
}

technique Push_left
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_push_left (); }
}

technique Push_up
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_push_up (); }
}
