// @Maintainer jwrl
// @Released 2021-10-06
// @Author jwrl
// @Created 2021-10-06
// @see https://www.lwks.com/media/kunena/attachments/6375/DeltaKeyBlend_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DeltaKeyBlend.mp4

/**
 This delta key (difference matte) effect is designed to easily create a key based on
 the difference between the foreground and the reference image.  That key can then be
 applied to a background layer or used with external blends or DVEs.

 The reference image can be derived from either Bg or Ref, and the background can be
 blanked to allow use with external blend and/or DVE effects.  For setup purposes the
 masked foreground or the alpha channel can be shown, and in those modes the opacity
 is set to 0% and the alpha channel is turned fully off.  This ensures that when used
 with downstream effects either mode will still work.

 Key clip, gain, erosion, expansion and feathering can all be adjusted.  The opacity
 of the key over the background can also be adjusted, allowing fades out and/or in to
 be created.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DeltaKeyWithBlend.fx
//
// Version history:
//
// Rewrite 2021-10-06 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Delta key with blend";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "Keys using the difference between foreground and reference.  Also supports external blends and/or DVEs";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define LOOP   12
#define DIVIDE 24

#define RADIUS 0.002
#define ANGLE  0.2617993878

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Input_1);
DefineInput (Ref, s_Input_2);

DefineTarget (In1, s_Background);
DefineTarget (In2, s_Reference);

DefineTarget (Erode, s_Erode);
DefineTarget (Key, s_Key);

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
   string Description = "Assign reference";
   string Enum = "Use Ref input,Use Bg input";
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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_set_in1 (float2 uv : TEXCOORD2) : COLOR
{
   return Overflow (uv) ? BLACK : tex2D (s_Input_1, uv);
}

float4 ps_set_in2 (float2 uv : TEXCOORD3) : COLOR { return GetPixel (s_Input_2, uv); }

float4 ps_key_gen (float2 uv1 : TEXCOORD1, float2 uv4 : TEXCOORD4) : COLOR
{
   float3 Fgnd = GetPixel (s_Foreground, uv1).rgb;
   float3 Bgnd = tex2D (s_Reference, uv4).rgb;

   float cDiff = distance (Bgnd, Fgnd);

   float2 alpha = smoothstep (Clip, Clip - Gain + 1.0, cDiff).xx;

   alpha.y = 1.0 - alpha.y;

   return alpha.xyxy;
}

float4 ps_erode (float2 uv : TEXCOORD4) : COLOR
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

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv4 : TEXCOORD4) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, uv1);

   float alpha = tex2D (s_Key, uv4).a;

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Feather * RADIUS;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      alpha += tex2D (s_Key, uv4 + xy).a;
      alpha += tex2D (s_Key, uv4 - xy).a;
      xy += xy;
      alpha += tex2D (s_Key, uv4 + xy).a;
      alpha += tex2D (s_Key, uv4 - xy).a;
   }

   alpha = saturate ((alpha / DIVIDE) - 1.0);
   Fgnd.a = min (Fgnd.a, alpha);

   if (ShowKey == 2) return float4 (Fgnd.aaa, 1.0);

   if (Fgnd.a == 0.0) Fgnd = EMPTY;

   if (ShowKey == 1) return float4 (Fgnd.rgb, 1.0);

   return lerp (tex2D (s_Background, uv4), Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DeltaKeyWithBlend_0
{
   pass P_1 < string Script = "RenderColorTarget0 = Bg;"; > ExecuteShader (ps_set_in1)
   pass P_2 < string Script = "RenderColorTarget0 = Ref;"; > ExecuteShader (ps_set_in2)
   pass P_3 < string Script = "RenderColorTarget0 = Erode;"; > ExecuteShader (ps_key_gen)
   pass P_4 < string Script = "RenderColorTarget0 = Key;"; > ExecuteShader (ps_erode)
   pass P_5 ExecuteShader (ps_main)
}

technique DeltaKeyWithBlend_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Bg;"; > ExecuteShader (ps_set_in1)
   pass P_2 < string Script = "RenderColorTarget0 = Ref;"; > ExecuteShader (ps_set_in1)
   pass P_3 < string Script = "RenderColorTarget0 = Erode;"; > ExecuteShader (ps_key_gen)
   pass P_4 < string Script = "RenderColorTarget0 = Key;"; > ExecuteShader (ps_erode)
   pass P_5 ExecuteShader (ps_main)
}

