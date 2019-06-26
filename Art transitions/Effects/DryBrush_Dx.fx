// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-05-06
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_DryBrush_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_DryBrush.mp4

/**
This mimics the Photoshop angled brush stroke effect to transition between two shots.
The stroke length and angle can be independently adjusted, and can be keyframed while
the transition happens to make the effect more dynamic.  To minimise edge of frame
problems mirror addressing has been used for both sources.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DryBrush_Dx.fx
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dry brush mix";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "Uses an angled brush stroke effect to transition between two shots";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
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

float Length
<
   string Description = "Stroke length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Angle
<
   string Description = "Stroke angle";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 45.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_rnd (float2 uv)
{
   return frac (sin (dot (uv, float2 (12.9898, 78.233))) * 43758.5453);
}

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float stroke = (Length * 0.1) + 0.02;
   float angle  = radians (Angle + 135.0);

   float2 uv = fn_rnd (xy1 - 0.5.xx) * stroke * Amount;
   float2 uv1, uv2, xy;

   sincos (angle, xy.x, xy.y);

   uv1.x = uv.x * xy.x + uv.y * xy.y;
   uv1.y = uv.y * xy.x - uv.x * xy.y;

   uv = fn_rnd (xy2 - 0.5.xx) * stroke * (1.0 - Amount);

   uv2.x = uv.x * xy.x + uv.y * xy.y;
   uv2.y = uv.y * xy.x - uv.x * xy.y;

   float4 Fgnd = tex2D (s_Foreground, xy1 + uv1);
   float4 Bgnd = tex2D (s_Background, xy2 + uv2);

   return lerp (Fgnd, Bgnd, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dx_DryBrush
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

