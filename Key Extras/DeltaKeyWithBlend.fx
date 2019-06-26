// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-10-18
// @see https://www.lwks.com/media/kunena/attachments/6375/DeltaKeyBlend_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DeltaKeyBlend.mp4

/**
This delta key (difference matte) effect is designed to easily create a key based on
the difference between the foreground and the reference image.  That key can then be
applied to a background layer or used with external blends or DVEs.

The reference and background images can be independently selected from either In1 or
In2, and the background can be blanked to allow use with external blend and/or DVE
effects.  For setup purposes the masked foreground or the alpha channel can be shown,
and in those modes the opacity is set to 100% and the alpha channel is turned fully
on.  This ensures that when used with downstream effects either mode will still work.

Key clip, gain, erosion, expansion and feathering can all be adjusted.  The opacity
of the key over the background can also be adjusted, allowing fades out and/or in to
be created.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DeltaKeyWithBlend.fx
//
// Modified 26 Nov 2018 by user schrauber:
// Changed subcategory from "User Effects" to "Key Extras".
//
// Modified 23 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Delta key with blend";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "Keys using the difference between foreground and reference.  Also supports external blends and/or DVEs";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;

texture In1;
texture In2;

texture Bg : RenderColorTarget;
texture Ref : RenderColorTarget;

texture Erode : RenderColorTarget;
texture Key : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };

sampler s_Input_1 = sampler_state { Texture = <In1>; };
sampler s_Input_2 = sampler_state { Texture = <In2>; };

sampler s_Background = sampler_state { Texture = <Bg>; };
sampler s_Reference = sampler_state { Texture = <Ref>; };

sampler s_Erode = sampler_state
{
   Texture   = <Erode>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int SetTechnique
<
   string Group = "Key settings";
   string Description = "Assign channels";
   string Enum = "Reference: In2 / Background: In1,Reference and background: In1,Reference: In1 / Blank background,Reference: In1 / Background: In2,Reference and background: In2,Reference: In2 / Blank background";
> = 0;

float Clip
<
   string Group = "Key settings";
   string Description = "Clip";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Gain
<
   string Group = "Key settings";
   string Description = "Gain";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.95;

float ErodeExpand
<
   string Group = "Key settings";
   string Description = "Erode/expand";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.1;

float Feather
<
   string Group = "Key settings";
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

int ShowKey
<
   string Group = "Key settings";
   string Description = "Operating mode";
   string Enum = "Output difference key,Display Fg masked by key,Display key signal only";
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY  0.0.xxxx

#define LOOP   12
#define DIVIDE 24

#define RADIUS 0.002
#define ANGLE  0.2617993878

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_blank (float2 uv : TEXCOORD) : COLOR
{
   return EMPTY;
}

float4 ps_set_in1 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (s_Input_1, uv);
}

float4 ps_set_in2 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (s_Input_2, uv);
}

float4 ps_key_gen (float2 uv : TEXCOORD1) : COLOR
{
   float3 Fgnd = tex2D (s_Foreground, uv).rgb;
   float3 Bgnd = tex2D (s_Reference, uv).rgb;

   float cDiff = distance (Bgnd, Fgnd);

   float2 alpha = smoothstep (Clip, Clip - Gain + 1.0, cDiff).xx;

   alpha.y = 1.0 - alpha.y;

   return alpha.xyxy;
}

float4 ps_erode (float2 uv : TEXCOORD1) : COLOR
{
   float2 radius = float2 (1.0, _OutputAspectRatio) * abs (ErodeExpand) * RADIUS;
   float2 xy, alpha = tex2D (s_Erode, uv).xy;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      alpha = max (alpha, tex2D (s_Erode, uv + xy).xy);
      alpha = max (alpha, tex2D (s_Erode, uv - xy).xy);
   }

   if (ErodeExpand < 0.0) alpha.x = (1.0 - alpha.y);

   return alpha.xxxx;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, uv);

   float alpha = tex2D (s_Key, uv).a;

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Feather * RADIUS;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      alpha += tex2D (s_Key, uv + xy).a;
      alpha += tex2D (s_Key, uv - xy).a;
      xy += xy;
      alpha += tex2D (s_Key, uv + xy).a;
      alpha += tex2D (s_Key, uv - xy).a;
   }

   alpha = saturate ((alpha / DIVIDE) - 1.0);
   Fgnd.a = min (Fgnd.a, alpha);

   if (ShowKey == 2) return float4 (Fgnd.aaa, 1.0);

   if (Fgnd.a == 0.0) Fgnd = EMPTY;

   if (ShowKey == 1) return float4 (Fgnd.rgb, 1.0);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DeltaKeyWithBlend_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_set_in1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Ref;"; >
   { PixelShader = compile PROFILE ps_set_in2 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Erode;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_erode (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

technique DeltaKeyWithBlend_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_set_in1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Ref;"; >
   { PixelShader = compile PROFILE ps_set_in1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Erode;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_erode (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

technique DeltaKeyWithBlend_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_blank (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Ref;"; >
   { PixelShader = compile PROFILE ps_set_in1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Erode;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_erode (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

technique DeltaKeyWithBlend_3
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_set_in2 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Ref;"; >
   { PixelShader = compile PROFILE ps_set_in1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Erode;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_erode (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

technique DeltaKeyWithBlend_4
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_set_in2 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Ref;"; >
   { PixelShader = compile PROFILE ps_set_in2 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Erode;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_erode (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

technique DeltaKeyWithBlend_5
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_blank (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Ref;"; >
   { PixelShader = compile PROFILE ps_set_in2 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Erode;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_erode (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

