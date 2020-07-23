// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-06-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_DryBrush_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_DryBrush.mp4

/**
 This mimics the Photoshop angled brush stroke effect to reveal or remove a title.  The
 stroke length and angle can be independently adjusted, and can be keyframed while the
 transition happens to make the effect more dynamic.

 Alpha levels are boosted to support Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DryBrush_Ax.fx
//
// Version history:
//
// Modified 2020-07-23 jwrl:
// Changed Transition to Transition position.
// Reworded Boost text to match requirements for 2020.1 and up.
// Implemented Boost as a separate pass ahead of the main code to avoid the function call
// overhead while applying the blur.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed name.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dry brush mix (alpha)";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "Mimics the Photoshop angled brush stroke effect to reveal or remove a title";
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

sampler s_Key = sampler_state
{
   Texture   = <Key>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
> = 0;

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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY  (0.0).xxxx

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

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
{
   float stroke = (Length * 0.1) + 0.02;
   float angle  = radians (Angle + 135.0);

   float2 xy1 = frac (sin (dot ((uv - 0.5.xx), float2 (12.9898, 78.233))) * 43758.5453);
   float2 xy, xy2;

   xy1 *= stroke * (1.0 - Amount);
   sincos (angle, xy2.x, xy2.y);

   xy.x = xy1.x * xy2.x + xy1.y * xy2.y;
   xy.y = xy1.y * xy2.x - xy1.x * xy2.y;

   xy += uv;

   float4 Fgnd = ((xy.x < 0.0) || (xy.y < 0.0) || (xy.x > 1.0) || (xy.y > 1.0))
               ? EMPTY : tex2D (s_Key, xy);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   float stroke = (Length * 0.1) + 0.02;
   float angle  = radians (Angle + 135.0);

   float2 xy1 = frac (sin (dot ((uv - 0.5.xx), float2 (12.9898, 78.233))) * 43758.5453);
   float2 xy, xy2;

   xy1 *= stroke * Amount;
   sincos (angle, xy2.x, xy2.y);

   xy.x = xy1.x * xy2.x + xy1.y * xy2.y;
   xy.y = xy1.y * xy2.x - xy1.x * xy2.y;

   xy += uv;

   float4 Fgnd = ((xy.x < 0.0) || (xy.y < 0.0) || (xy.x > 1.0) || (xy.y > 1.0))
               ? EMPTY : tex2D (s_Key, xy);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_DryBrush_0
{
   pass P_0 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_1
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Ax_DryBrush_1
{
   pass P_0 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_1
   { PixelShader = compile PROFILE ps_main_O (); }
}
