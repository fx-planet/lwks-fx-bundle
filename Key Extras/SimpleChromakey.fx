// @Maintainer jwrl
// @Released 2021-10-06
// @Author jwrl
// @Created 2021-10-06
// @see https://www.lwks.com/media/kunena/attachments/6375/SimpleCkey_640.png

/**
 This is a simple keyer that has only five adjustments, the key colour, key clip, key
 gain and the defringe controls.  Defringing can either use the standard desaturate
 technique, or can replace the key colour with the background image either in colour
 or monochrome.  Finally, the key can be faded in and out by adjusting the opacity.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SimpleChromakey.fx
//
// Version history:
//
// Rewrite 2021-10-06 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Simple chromakey";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "An extremely simple chromakeyer with feathering and spill reduction";
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
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define LUMACONV float3(0.2989, 0.5866, 0.1145)

#define LOOP   12
#define DIVIDE 24

#define RADIUS 0.002
#define ANGLE  0.2617993878

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Key_1, s_Key_1);
DefineTarget (Key_2, s_Key_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float4 Colour
<
   string Description = "Key colour";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 0.0, 1.0 };

float Clip
<
   string Description = "Key clip";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Gain
<
   string Description = "Key gain";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Size
<
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Defringe technique";
   string Enum = "Desaturate fringe,Use background (monochrome),Use background (colour)";
> = 0;

float DeFringeAmt
<
   string Description = "Defringe amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float DeFringe
<
   string Description = "Defringe depth";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_key_gen (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv);

   float cDiff = distance (Colour.r, Fgnd.r);

   cDiff = max (cDiff, distance (Colour.g, Fgnd.g));
   cDiff = max (cDiff, distance (Colour.b, Fgnd.b));

   float alpha = smoothstep (Clip, Clip + Gain, cDiff);

   return float4 (alpha.xxx, Fgnd.a);
}

float4 ps_feather (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);
   float4 retval = tex2D (s_Key_1, uv3);

   float alpha = retval.r;

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Size * RADIUS;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      alpha += tex2D (s_Key_1, uv3 + xy).r;
      alpha += tex2D (s_Key_1, uv3 - xy).r;
      xy += xy;
      alpha += tex2D (s_Key_1, uv3 + xy).r;
      alpha += tex2D (s_Key_1, uv3 - xy).r;
   }

   alpha = saturate ((alpha / DIVIDE) - 1.0);
   Fgnd.a = min (Fgnd.a, alpha);

   return Overflow (uv1) ? EMPTY : Fgnd;
}

float4 ps_main_0 (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = tex2D (s_Key_2, uv3);

   float3 Frng = Fgnd.rgb;

   float fLuma = dot (Fgnd.rgb, LUMACONV);
   float cMask;

   if (Colour.g >= max (Colour.r, Colour.b)) {
      cMask = saturate (Frng.g - lerp (Frng.r, Frng.b, DeFringe));
      Frng.g -= cMask;
   }
   else if (Colour.b >= max (Colour.r, Colour.g)) {
      cMask = saturate (Frng.b - lerp (Frng.r, Frng.g, DeFringe));
      Frng.b -= cMask;
   }
   else {
      cMask = saturate (Frng.r - lerp (Frng.g, Frng.b, DeFringe));
      Frng.r -= cMask;
   }

   Frng += fLuma.xxx * cMask;

   Fgnd.rgb = lerp (Fgnd.rgb, Frng, DeFringeAmt);
   Fgnd.a  *= Amount;

   return lerp (BdrPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

float4 ps_main_1 (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd = BdrPixel (s_Background, uv2);
   float4 Fgnd = tex2D (s_Key_2, uv3);

   float3 Frng = Fgnd.rgb;

   float bLuma = dot (Bgnd.rgb, LUMACONV);
   float cMask;

   if (Colour.g >= max (Colour.r, Colour.b)) {
      cMask = saturate (Frng.g - lerp (Frng.r, Frng.b, DeFringe));
      Frng.g -= cMask;
   }
   else if (Colour.b >= max (Colour.r, Colour.g)) {
      cMask = saturate (Frng.b - lerp (Frng.r, Frng.g, DeFringe));
      Frng.b -= cMask;
   }
   else {
      cMask = saturate (Frng.r - lerp (Frng.g, Frng.b, DeFringe));
      Frng.r -= cMask;
   }

   Frng += bLuma.xxx * cMask;

   Fgnd.rgb = lerp (Fgnd.rgb, Frng, DeFringeAmt);
   Fgnd.a  *= Amount;

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_main_2 (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd = BdrPixel (s_Background, uv2);
   float4 Fgnd = tex2D (s_Key_2, uv3);

   float3 Frng = Fgnd.rgb;

   float cMask;

   if (Colour.g >= max (Colour.r, Colour.b)) {
      cMask = saturate (Frng.g - lerp (Frng.r, Frng.b, DeFringe));
      Frng.g -= cMask;
   }
   else if (Colour.b >= max (Colour.r, Colour.g)) {
      cMask = saturate (Frng.b - lerp (Frng.r, Frng.g, DeFringe));
      Frng.b -= cMask;
   }
   else {
      cMask = saturate (Frng.r - lerp (Frng.g, Frng.b, DeFringe));
      Frng.r -= cMask;
   }

   Frng += Bgnd.rgb * cMask;

   Fgnd.rgb = lerp (Fgnd.rgb, Frng, DeFringeAmt);
   Fgnd.a  *= Amount;

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SimpleChromakey_0
{
   pass P_1 < string Script = "RenderColorTarget0 = Key_1;"; > ExecuteShader (ps_key_gen)
   pass P_2 < string Script = "RenderColorTarget0 = Key_2;"; > ExecuteShader (ps_feather)
   pass P_3 ExecuteShader (ps_main_0)
}

technique SimpleChromakey_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Key_1;"; > ExecuteShader (ps_key_gen)
   pass P_2 < string Script = "RenderColorTarget0 = Key_2;"; > ExecuteShader (ps_feather)
   pass P_3 ExecuteShader (ps_main_1)
}

technique SimpleChromakey_2
{
   pass P_1 < string Script = "RenderColorTarget0 = Key_1;"; > ExecuteShader (ps_key_gen)
   pass P_2 < string Script = "RenderColorTarget0 = Key_2;"; > ExecuteShader (ps_feather)
   pass P_3 ExecuteShader (ps_main_2)
}

