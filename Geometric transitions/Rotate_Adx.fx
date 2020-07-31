// @Maintainer jwrl
// @Released 2020-07-31
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Rotate_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Rotate.mp4

/**
 This rotates a delta key out or in.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rotate_Adx.fx
//
// Version history:
//
// Modified 2020-07-31 jwrl.
// Moved folded effect support into "Transition position".
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
   string Description = "Rotate (delta)";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Separates foreground from background then rotates it in or out";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Super : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Super = sampler_state
{
   Texture   = <Super>;
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
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip,At start (unfolded)";
> = 0;

int SetTechnique
<
   string Description = "Transition type";
   string Enum = "Rotate Right,Rotate Down,Rotate Left,Rotate Up";
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

#define HALF_PI 1.5707963268

#define EMPTY   (0.0).xxxx

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
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return (Ttype == 0) ? float4 (Bgd, smoothstep (0.0, KeyGain, kDiff))
                       : float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_rotate_right (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd;

   float2 xy;

   if (Ttype == 1) {
      xy = (Amount == 1.0) ? float2 (2.0, uv.y)
         : float2 ((uv.x - 1.0) / (1.0 - Amount) - (Amount * 0.2) + 1.0, ((uv.y - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv.y) * uv.x * sin (Amount * HALF_PI));
      Bgnd = fn_tex2D (s_Background, uv);
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv.y)
         : float2 ((uv.x / Amount) - ((1.0 - Amount) * 0.2), ((uv.y - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv.y) * uv.x * cos (Amount * HALF_PI));
      Bgnd = (Ttype == 0) ? fn_tex2D (s_Foreground, uv) : fn_tex2D (s_Background, uv);
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_rotate_left (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd;

   float2 xy;

   if (Ttype == 1) {
      xy = (Amount == 1.0) ? float2 (2.0, uv.y)
         : float2 (uv.x / (1.0 - Amount) + (Amount * 0.2), ((uv.y - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv.y) * (1.0 - uv.x) * sin (Amount * HALF_PI));
      Bgnd = fn_tex2D (s_Background, uv);
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv.y)
         : float2 ((uv.x - 1.0) / Amount + 1.0 + ((1.0 - Amount) * 0.2), ((uv.y - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv.y) * (1.0 - uv.x) * cos (Amount * HALF_PI));
      Bgnd = (Ttype == 0) ? fn_tex2D (s_Foreground, uv) : fn_tex2D (s_Background, uv);
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_rotate_down (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd;

   float2 xy;

   if (Ttype == 1) {
      xy = (Amount == 1.0) ? float2 (2.0, uv.y)
         : float2 (((uv.x - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv.x) * uv.y * sin (Amount * HALF_PI), (uv.y - 1.0) / (1.0 - Amount) - (Amount * 0.2) + 1.0);
      Bgnd = fn_tex2D (s_Background, uv);
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv.y)
         : float2 (((uv.x - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv.x) * uv.y * cos (Amount * HALF_PI), (uv.y / Amount) - ((1.0 - Amount) * 0.2));
      Bgnd = (Ttype == 0) ? fn_tex2D (s_Foreground, uv) : fn_tex2D (s_Background, uv);
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_rotate_up (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd;

   float2 xy;

   if (Ttype == 1) {
      xy = (Amount == 1.0) ? float2 (2.0, uv.y)
         : float2 (((uv.x - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv.x) * (1.0 - uv.y) * sin (Amount * HALF_PI), uv.y / (1.0 - Amount) + (Amount * 0.2));
      Bgnd = fn_tex2D (s_Background, uv);
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv.y)
         : float2 (((uv.x - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv.x) * (1.0 - uv.y) * cos (Amount * HALF_PI), (uv.y - 1.0) / Amount + 1.0 + ((1.0 - Amount) * 0.2));
      Bgnd = (Ttype == 0) ? fn_tex2D (s_Foreground, uv) : fn_tex2D (s_Background, uv);
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_Rotate_right
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_rotate_right (); }
}

technique Adx_Rotate_down
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_rotate_down (); }
}

technique Adx_Rotate_left
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_rotate_left (); }
}

technique Adx_Rotate_up
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_rotate_up (); }
}
