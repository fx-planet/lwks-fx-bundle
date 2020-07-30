// @Maintainer jwrl
// @Released 2020-07-30
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Squeeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Squeeze.mp4

/**
 This mimics the Lightworks squeeze effect but fades delta keys in or out.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Squeeze_Adx.fx
//
// Version history:
//
// Modified 2020-07-30 jwrl.
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
   string Description = "Squeeze transition (delta)";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Separates foreground from background then mimics the Lightworks squeeze effect with it";
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
   string Description = "Type";
   string Enum = "Squeeze Right,Squeeze Down,Squeeze Left,Squeeze Up";
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

#define EMPTY (0.0).xxxx

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
      Bgd = tex2D (s_Foreground, xy1).rgb;
      Fgd = tex2D (s_Background, xy2).rgb;
   }

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_squeeze_right (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;

   if (Ttype == 1) {
      xy = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 ((uv.x - 1.0) / (1.0 - Amount) + 1.0, uv.y);
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 (uv.x / Amount, uv.y);
   }

   float4 Bgnd = (Ttype == 0) ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);
   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_squeeze_left (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;

   if (Ttype == 1) {
      xy = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 (uv.x  / (1.0 - Amount), uv.y);
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 ((uv.x - 1.0) / Amount + 1.0, uv.y);
   }

   float4 Bgnd = (Ttype == 0) ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);
   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_squeeze_down (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;

   if (Ttype == 1) {
      xy = (Amount == 1.0) ? float2 (uv.x, 2.0) : float2 (uv.x, (uv.y - 1.0) / (1.0 - Amount) + 1.0);
   }
   else {
      xy = (Amount == 0.0) ? float2 (uv.x, 2.0) : float2 (uv.x, uv.y / Amount);
   }

   float4 Bgnd = (Ttype == 0) ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);
   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_squeeze_up (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;

   if (Ttype == 1) {
      xy = (Amount == 1.0) ? float2 (uv.x, 2.0) : float2 (uv.x, uv.y  / (1.0 - Amount));
   }
   else {
      xy = (Amount == 0.0) ? float2 (uv.x, 2.0) : float2 (uv.x, (uv.y - 1.0) / Amount + 1.0);
   }

   float4 Bgnd = (Ttype == 0) ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);
   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_Squeeze_right
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_squeeze_right (); }
}

technique Adx_Squeeze_down
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_squeeze_down (); }
}

technique Adx_Squeeze_left
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_squeeze_left (); }
}

technique Adx_Squeeze_up
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_squeeze_up (); }
}
