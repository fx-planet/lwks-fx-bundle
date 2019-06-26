// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2016-09-01
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
// Original release 2018-04-30:
// The creation date is a guess only, because I couldn't find the original version.
// This is a reconstruction from several experimental fragments.  It was really more of
// an intellectual challenge to create a chromakey and defringe entirely in the RGB
// domain rather than using the more common HSL approach.  I dare say that if there
// was anyone interested enough to work with it, it could be made into a much more
// sophisticated keyer.
//
// Modified 2018-05-01:
// Added feathering to the key, which operates entirely within the key boundaries.  Also
// picked up on the fact that I had failed to credit baopao, on who's KeyDespill.fx I
// based my defringing routines.  The rest of the work is very definitely all my own.
//
// Modified 2018-07-06:
// Made feathering resolution-independent.
//
// Modified 29 September 2018 jwrl.
// Added notes to header.
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
   string Description = "Simple chromakey";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "An extremely simple chromakeyer with feathering and spill reduction";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Key_1 : RenderColorTarget;
texture Key_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Key_1 = sampler_state
{
   Texture   = <Key_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Key_2 = sampler_state
{
   Texture   = <Key_2>;
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
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.0;

float Gain
<
   string Description = "Key gain";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float Size
<
   string Description = "Feather";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

int SetTechnique
<
   string Description = "Defringe technique";
   string Enum = "Desaturate fringe,Use background (monochrome),Use background (colour)";
> = 0;

float DeFringeAmt
<
   string Description = "Defringe amount";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.0;

float DeFringe
<
   string Description = "Defringe depth";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LUMACONV float3(0.2989, 0.5866, 0.1145)

#define LOOP   12
#define DIVIDE 24

#define RADIUS 0.002
#define ANGLE  0.2617993878

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_key_gen (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, uv);

   float cDiff = distance (Colour.rgb, Fgnd.rgb);
   float alpha = smoothstep (Clip, Clip + Gain, cDiff);

   return float2 (alpha, Fgnd.a).xxxy;
}

float4 ps_feather (float2 uv : TEXCOORD) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, uv);
   float4 retval = tex2D (s_Key_1, uv);

   float alpha = retval.r;

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Size * RADIUS;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      alpha += tex2D (s_Key_1, uv + xy).r;
      alpha += tex2D (s_Key_1, uv - xy).r;
      xy += xy;
      alpha += tex2D (s_Key_1, uv + xy).r;
      alpha += tex2D (s_Key_1, uv - xy).r;
   }

   alpha = saturate ((alpha / DIVIDE) - 1.0);
   Fgnd.a = min (Fgnd.a, alpha);

   return Fgnd;
}

float4 ps_main_0 (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Key_2, xy1);

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

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

float4 ps_main_1 (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Key_2, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

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

float4 ps_main_2 (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Key_2, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

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
   pass P_1
   < string Script = "RenderColorTarget0 = Key_1;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Key_2;"; >
   { PixelShader = compile PROFILE ps_feather (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_0 (); }
}

technique SimpleChromakey_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key_1;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Key_2;"; >
   { PixelShader = compile PROFILE ps_feather (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_1 (); }
}

technique SimpleChromakey_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key_1;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Key_2;"; >
   { PixelShader = compile PROFILE ps_feather (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_2 (); }
}
