// @Maintainer jwrl
// @Released 2018-04-30
// @Author jwrl
// @Created 2016-09-01
// @see https://www.lwks.com/media/kunena/attachments/6375/SimpleCkey_1.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect SimpleCkey.fx
//
// This is a simple keyer that I started work on prior to my "Chromakey plus".  In fact
// it was going to be the chromakey section of that effect, but I never quite got it to
// the point where I was happy with it.  It has only five adjustments, the key colour,
// key clip, key gain and the defringe controls.  Defringing can either use the standard
// desaturate technique, or can replace the key colour with the background image either
// in colour or monochrome.  Finally, the key can be faded in and out by adjusting the
// opacity setting.
//
// The creation date is a guess only, because I couldn't find the original version.
// This is a reconstruction from several experimental fragments.  It was really more of
// an intellectual challenge to create a chromakey and defringe entirely in the RGB
// domain rather than using the more common HSL approach.  I dare say that if there was
// anyone interested enough to work with it, it could be made more sophisticated.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Simple chromakey";
   string Category    = "Key";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_0 (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);

   float fLuma = dot (Fgnd.rgb, LUMACONV);
   float cDiff = distance (Colour.rgb, Fgnd.rgb);
   float alpha = cDiff * (1.0 + (9.0 * max (0.0, Clip)));

   alpha = max (0.0, min (alpha - (Gain * 2.0), Fgnd.a));

   float cMask;

   if (Colour.g > max (Colour.r, Colour.b)) {
      cMask = saturate (Fgnd.g - lerp (Fgnd.r, Fgnd.b, DeFringe));
      Fgnd.g -= cMask;
   }
   else if (Colour.b > max (Colour.r, Colour.g)) {
      cMask = saturate (Fgnd.b - lerp (Fgnd.r, Fgnd.g, DeFringe));
      Fgnd.b -= cMask;
   }
   else {
      cMask = saturate (Fgnd.r - lerp (Fgnd.g, Fgnd.b, DeFringe));
      Fgnd.r -= cMask;
   }

   Fgnd.rgb = lerp (Fgnd.rgb, Fgnd.rgb + (fLuma.xxx * cMask), DeFringeAmt);
   Fgnd.a = alpha * Amount;

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

float4 ps_main_1 (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float bLuma = dot (Bgnd.rgb, LUMACONV);
   float cDiff = distance (Colour.rgb, Fgnd.rgb);
   float alpha = cDiff * (1.0 + (9.0 * max (0.0, Clip)));

   alpha = max (0.0, min (alpha - (Gain * 2.0), Fgnd.a));

   float cMask;

   if (Colour.g > max (Colour.r, Colour.b)) {
      cMask = saturate (Fgnd.g - lerp (Fgnd.r, Fgnd.b, DeFringe));
      Fgnd.g -= cMask;
   }
   else if (Colour.b > max (Colour.r, Colour.g)) {
      cMask = saturate (Fgnd.b - lerp (Fgnd.r, Fgnd.g, DeFringe));
      Fgnd.b -= cMask;
   }
   else {
      cMask = saturate (Fgnd.r - lerp (Fgnd.g, Fgnd.b, DeFringe));
      Fgnd.r -= cMask;
   }

   Fgnd.rgb = lerp (Fgnd.rgb, Fgnd.rgb + (bLuma.xxx * cMask), DeFringeAmt);
   Fgnd.a = alpha * Amount;

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_main_2 (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float cDiff = distance (Colour.rgb, Fgnd.rgb);
   float alpha = cDiff * (1.0 + (9.0 * max (0.0, Clip)));

   alpha = max (0.0, min (alpha - (Gain * 2.0), Fgnd.a));

   float cMask;

   if (Colour.g > max (Colour.r, Colour.b)) {
      cMask = saturate (Fgnd.g - lerp (Fgnd.r, Fgnd.b, DeFringe));
      Fgnd.g -= cMask;
   }
   else if (Colour.b > max (Colour.r, Colour.g)) {
      cMask = saturate (Fgnd.b - lerp (Fgnd.r, Fgnd.g, DeFringe));
      Fgnd.b -= cMask;
   }
   else {
      cMask = saturate (Fgnd.r - lerp (Fgnd.g, Fgnd.b, DeFringe));
      Fgnd.r -= cMask;
   }

   Fgnd.rgb = lerp (Fgnd.rgb, Fgnd.rgb + (Bgnd.rgb * cMask), DeFringeAmt);
   Fgnd.a = alpha * Amount;

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SimpleCkey_0
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_0 (); }
}

technique SimpleCkey_1
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_1 (); }
}

technique SimpleCkey_2
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_2 (); }
}

