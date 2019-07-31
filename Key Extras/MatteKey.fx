// @Maintainer jwrl
// @Released 2019-07-31
// @Author jwrl
// @Created 2016-02-29
// @see https://www.lwks.com/media/kunena/attachments/6375/MatteKey_640.png

/**
This provides a means of matting a foreground image into a background using a white
on black or black on white matte shape.  The matte can be feathered, or it can be
blurred inside the effect prior to generating the key.

It currently uses reasonably dumb box blurs on the matte shape.  That seems to work
well enough for feathering.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MatteKey.fx
//
// Updates:
// LW 14+ version 11 January 2017
// Subcategory "User Effects" added.
//
// Modified 5 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 4 July 2018
// Improved key tolerance calculation.  It's now symmetrical around clip.
// Removed three redundant samplers.
//
// Modified 30 August 2018 jwrl.
// Added notes to header.
//
// Modified 26 Nov 2018 by user schrauber:
// Changed subcategory from "User Effects" to "Key Extras".
//
// Modified 23 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 31 July 2019 by user jwrl:
// Changed the output mode to provide four options: matte and alpha, foreground and alpha,
// matte over foreground and foreground over background.
// Allowed the opacity adjustment to control the alpha output in all modes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Matte key";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "Mattes a foreground image into a background using a white on black or black on white matte shape";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Mat;
texture Fg;
texture Bg;

texture blurIn1 : RenderColorTarget;
texture blurIn2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Matte = sampler_state { Texture = <Mat>; };
sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Blur_1 = sampler_state
{
   Texture   = <blurIn1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blur_2 = sampler_state
{
   Texture   = <blurIn2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool matteAlpha
<
   string Description = "Use matte alpha channel";
> = false;

bool Invert
<
   string Description = "Invert matte";
> = false;

int SetTechnique
<
   string Description = "Matte feather range";
   string Enum = "Standard (best for anti-aliasing),Extended (best for wipes and masks)";
> = 0;

float preBlur
<
   string Group = "Matte";
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float clipLevel
<
   string Group = "Matte";
   string Description = "Clip level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Slope
<
   string Group = "Matte";
   string Description = "Tolerance";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int AlphaChan
<
   string Description = "Output";
   string Enum = "Matte and alpha only,Foreground and alpha only,Matte over foreground,Foreground over background";
> = 3;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define R_VAL          0.2989
#define G_VAL          0.5866
#define B_VAL          0.1145

#define SAMPLE_1_2     16
#define SAMPLE_3_4     32

#define MAXSAMPLE_1_2  SAMPLE_1_2*4
#define MAXSAMPLE_3_4  SAMPLE_3_4*2

#define BLUR_SCALE_1_2 0.0009765625
#define BLUR_SCALE_3_4 0.00390625

#define BLUR_ROTATE    0.7071067812

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_invert (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Matte, xy);

   if (matteAlpha) { retval = float4 (retval.aaa, 1.0); }
   else { retval = float2 ((retval.r * R_VAL) + (retval.g * G_VAL) + (retval.b * B_VAL), 1.0).xxxy ;};

   return float4 (Invert ? retval : 1.0.xxxx - retval);
}

float4 ps_blur_1 (float2 xy : TEXCOORD1) : COLOR
{
   if (preBlur == 0.0) return tex2D (s_Blur_1, xy);

   float4 retval = 0.0.xxxx;

   float B_R_Factor = preBlur * BLUR_SCALE_1_2 * BLUR_ROTATE;

   float2 offs_1 = float2 (B_R_Factor / _OutputAspectRatio, B_R_Factor);
   float2 offs_2 = float2 (offs_1.x, -B_R_Factor);

   float2 xy1, xy2;

   for (int i = 0; i < SAMPLE_1_2; i++) {
      xy1 = offs_1 * i;
      xy2 = offs_2 * i;
      retval += tex2D (s_Blur_1, xy - xy1);
      retval += tex2D (s_Blur_1, xy + xy1);
      retval += tex2D (s_Blur_1, xy - xy2);
      retval += tex2D (s_Blur_1, xy + xy2);
   }

   retval /= MAXSAMPLE_1_2;

   return retval;
}

float4 ps_blur_2 (float2 xy : TEXCOORD1) : COLOR
{
   if (preBlur == 0.0) return tex2D (s_Blur_2, xy);

   float4 retval = 0.0.xxxx;

   float2 offs_1, offs_2 = float2 (0.0, preBlur * BLUR_SCALE_1_2);
   offs_1.xy = float2 (offs_2 / _OutputAspectRatio).yx;

   float2 xy1, xy2;

   for (int i = 0; i < SAMPLE_1_2; i++) {
      xy1 = offs_1 * i;
      xy2 = offs_2 * i;
      retval += tex2D (s_Blur_2, xy - xy1);
      retval += tex2D (s_Blur_2, xy + xy1);
      retval += tex2D (s_Blur_2, xy - xy2);
      retval += tex2D (s_Blur_2, xy + xy2);
   }

   retval /= MAXSAMPLE_1_2;

   return retval;
}

float4 ps_blur_3 (float2 xy : TEXCOORD1) : COLOR
{
   if (preBlur == 0.0) return tex2D (s_Blur_1, xy);

   float4 retval = 0.0.xxxx;

   float2 offset = float2 (preBlur * BLUR_SCALE_3_4 / _OutputAspectRatio, 0.0);
   float2 xy1;

   for (int i = 0; i < SAMPLE_3_4; i++) {
      xy1 = offset * i;
      retval += tex2D (s_Blur_1, xy - xy1);
      retval += tex2D (s_Blur_1, xy + xy1);
   }

   retval /= MAXSAMPLE_3_4;

   return retval;
}

float4 ps_blur_4 (float2 xy : TEXCOORD1) : COLOR
{
   if (preBlur == 0.0) return tex2D (s_Blur_2, xy);

   float4 retval = 0.0.xxxx;

   float2 offs_2 = float2 (0.0, preBlur * BLUR_SCALE_3_4);
   float2 xy2;

   for (int i = 0; i < SAMPLE_3_4; i++) {
      xy2 = offs_2 * i;
      retval += tex2D (s_Blur_2, xy - xy2);
      retval += tex2D (s_Blur_2, xy + xy2);
   }

   retval /= MAXSAMPLE_3_4;

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = ((AlphaChan == 0) || (AlphaChan == 2)) ? tex2D (s_Matte, uv) : tex2D (s_Foreground, uv);
   float4 Bgnd = (AlphaChan == 2) ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);

   float alpha  = tex2D (s_Blur_1, uv).x;
   float range  = Slope * 0.5;
   float keyMin = max (0.0, clipLevel - range);
   float keyMax = min (1.0, clipLevel + range);

   Fgnd.a = smoothstep (keyMin, keyMax, alpha) * opacity;

   if (AlphaChan < 2) { return Fgnd; };

   Fgnd = lerp (Bgnd, Fgnd, Fgnd.a);

   return float4 (Fgnd.rgb, 1.0);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique standardFeather
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurIn1;"; >
   { PixelShader = compile PROFILE ps_invert (); }

   pass P_2
   < string Script = "RenderColorTarget0 = blurIn2;"; >
   { PixelShader = compile PROFILE ps_blur_1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = blurIn1;"; >
   { PixelShader = compile PROFILE ps_blur_2 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique extendFeather
{
   pass P_1
   < string Script = "RenderColorTarget0 = blurIn1;"; >
   { PixelShader = compile PROFILE ps_invert (); }

   pass P_2
   < string Script = "RenderColorTarget0 = blurIn2;"; >
   { PixelShader = compile PROFILE ps_blur_1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = blurIn1;"; >
   { PixelShader = compile PROFILE ps_blur_2 (); }

   pass P_4
   < string Script = "RenderColorTarget0 = blurIn2;"; >
   { PixelShader = compile PROFILE ps_blur_3 (); }

   pass P_5
   < string Script = "RenderColorTarget0 = blurIn1;"; >
   { PixelShader = compile PROFILE ps_blur_4 (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}
