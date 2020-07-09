// @Maintainer jwrl
// @Released 2020-07-09
// @Author jwrl
// @Created 2020-07-09
// @see https://www.lwks.com/media/kunena/attachments/6375/VisualMotionBlur_640.png

/**
 A directional blur that can be used to simulate fast motion, whip pans and the like.  This
 differs from other blur effects in that it is set up by visually dragging a central pin
 point in the record viewer to adjust the angle and strength of the blur.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VisualMotionBlur.fx
//
// Version history:
//
// Created 2020-07-09 by jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Visual motion blur";
   string Category    = "Stylize";
   string SubCategory = "Simple tools";
   string Notes       = "A directional blur that can be quickly set up by visually dragging a central pin point.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state {
   Texture   = <Inp>;
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
    string Description = "Blur mount";
    float MinVal = 0.0;
    float MaxVal = 1.0;
> = 1.0;

float Blur_X
<
   string Description = "Blur";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Blur_Y
<
   string Description = "Blur";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Lightworks version must be 14.5 or better
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define EMPTY   0.0.xxxx
#define XY      1.0.xx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// fUNCTIONS
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv)
{
   // This is necessary because mirroring alone can result in wrap around.  It cannot
   // simply replace mirroring because clamping can give unpredictable results too.

   return tex2D (s, saturate (uv));
}

//-----------------------------------------------------------------------------------------//
// ShaderS
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Input, uv);

   float2 xy0 = float2 (Blur_X - 0.5, (0.5 - Blur_Y) * _OutputAspectRatio);

   if ((Amount <= 0.0) || (distance (0.0, xy0) == 0.0)) return Fgnd;

   xy0 *= 0.01;

   float2 xy1 = uv - xy0;

   float4 Blur = fn_tex2D (s_Input, xy1);

   for (int i = 0; i < 60; i++) {
      xy1 -= xy0;
      Blur += fn_tex2D (s_Input, xy1);
   }

   Blur /= 61.0;

   return lerp (Fgnd, Blur, Amount);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique VisualMotionBlur
{
   pass P_1
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
