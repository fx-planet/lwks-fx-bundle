// @Maintainer jwrl
// @Released 2020-07-31
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Bars_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Bars.mp4

/**
 This is a delta key transition that moves the strips of a delta key together from off-screen
 either horizontally or vertically or splits the delta key into strips then blows them apart
 either horizontally or vertically.  Useful for applying transitions to titles.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Bars_Adx.fx
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
// Modified jwrl 2018-12-28
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bar wipe (delta)";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Separates foreground from background and splits it into strips which separate horizontally or vertically";
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
   string Description = "Transition direction";
   string Enum = "Horizontal,Vertical";
> = 0;

float Width
<
   string Description = "Bar width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define WIDTH  50
#define OFFSET 1.2

#define EMPTY  (0.0).xxxx

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

float4 ps_horiz (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float dsplc  = (OFFSET - Width) * WIDTH;

   float2 offset = float2 (0.0, floor (xy1.y * dsplc));
   float2 xy = (Ttype == 1) ? xy1 + ((ceil (frac (offset / 2.0)) * 2.0) - 1.0.xx) * Amount
                            : xy1 + (1.0.xx - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);

   float4 Fgnd = fn_tex2D (s_Super, xy);
   float4 Bgnd = (Ttype == 0) ? fn_tex2D (s_Foreground, xy2) : fn_tex2D (s_Background, xy2);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_vert (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float dsplc  = (OFFSET - Width) * WIDTH;

   float2 offset = float2 (floor (xy1.x * dsplc), 0.0);
   float2 xy = (Ttype == 1) ? xy1 + ((ceil (frac (offset / 2.0)) * 2.0) - 1.0.xx) * Amount
                            : xy1 + (1.0.xx - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);

   float4 Fgnd = fn_tex2D (s_Super, xy);
   float4 Bgnd = (Ttype == 0) ? fn_tex2D (s_Foreground, xy2) : fn_tex2D (s_Background, xy2);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Bars_Adx_H
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_horiz (); }
}

technique Bars_Adx_V
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_vert (); }
}
