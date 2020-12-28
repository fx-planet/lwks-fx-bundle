// @Maintainer jwrl
// @Released 2020-12-28
// @Author jwrl
// @Created 2020-12-28
// @see https://www.lwks.com/media/kunena/attachments/6375/Lissajou_640.png

/**
 Lissajou sparkles is based on Sinusoidal lights, a semi-abstract pattern generator created
 for Mac and Linux systems by Lightworks user baopao.  This version adds either external
 video or a colour gradient background to the pattern.  That has meant that the range and
 type of some parameters were changed from baopao's original to allow their interactive
 adjustment in the edit viewer.

 Because backgrounds are newly created media they are produced at the sequence resolution.
 This means that any background video will also be locked to that resolution.

 NOTE: Backgrounds are newly created  media and will be produced at the sequence resolution.
 This means that any background video will also be locked at that resolution.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LissajouSparkles.fx
//
// Lissajou sparkles is based on the Lissajou code at http://glslsandbox.com/e#9996.0
//
// Version history:
//
// Rewrite 2020-12-28 jwrl.
// Complete rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lissajou sparkles";
   string Category    = "Matte";
   string SubCategory = "Backgrounds";
   string Notes       = "A pattern generator that creates coloured stars in Lissajou curves over a coloured background";
   bool CanSize       = false;
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

float _Progress;
float _Length;

float _OutputAspectRatio;

#define EMPTY    (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float StarNumber
<
   string Description = "Star number";
   string Group = "Pattern";
   float MinVal = 0.0;
   float MaxVal = 400;
> = 200;

float Speed
<
   string Description = "Speed";
   string Group = "Pattern";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

float Scale
<
   string Description = "Scale";
   string Group = "Pattern";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.33;

float Level
<
   string Description = "Glow intensity";
   string Group = "Pattern";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

float CentreX
<
   string Description = "Position";
   string Group = "Pattern";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CentreY
<
   string Description = "Position";
   string Group = "Pattern";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float ResX
<
   string Description = "Size";
   string Group = "Pattern";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.01;
   float MaxVal = 2.0;
> = 0.4;

float ResY
<
   string Description = "Size";
   string Group = "Pattern";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.01;
   float MaxVal = 2.0;
> = 0.4;

float SineX
<
   string Description = "Frequency";
   string Group = "Pattern";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 12.0;
> = 4.00;

float SineY
<
   string Description = "Frequency";
   string Group = "Pattern";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 12.0;
> = 8.00;

float4 fgdColour
<
   string Description = "Colour";
   string Group = "Pattern";
   bool SupportsAlpha = false;
> = { 0.85, 0.75, 0.0, -1.0 };

float extBgd
<
   string Description = "External Video";
   string Group = "Background";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.00;

float4 topLeft
<
   string Description = "Top Left";
   string Group = "Background";
   bool SupportsAlpha = false;
> = { 0.375, 0.5, 0.75, -1.0 };

float4 topRight
<
   string Description = "Top Right";
   string Group = "Background";
   bool SupportsAlpha = false;
> = { 0.375, 0.375, 0.75, -1.0 };

float4 botLeft
<
   string Description = "Bottom Left";
   string Group = "Background";
   bool SupportsAlpha = false;
> = { 0.375, 0.625, 0.75, -1.0 };

float4 botRight
<
   string Description = "Bottom Right";
   string Group = "Background";
   bool SupportsAlpha = false;
> = { 0.375, 0.5625, 0.75, -1.0 };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   return (max (xy.x, xy.y) > 0.5) ? EMPTY : tex2D (s, uv);
}

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv0 : TEXCOORD0, float2 uv1 : TEXCOORD1) : COLOR
{
   float4 fgdPat = float4 (fgdColour.rgb, 1.0);

   float2 position, xy = uv0;

   if (_OutputAspectRatio <= 1.0) {
      xy.x = (xy.x - CentreX) * _OutputAspectRatio;
      xy.y += CentreY - 0.5;

      if (_OutputAspectRatio < 1.0) {
         xy.y -= 0.5;
         xy   *= _OutputAspectRatio;
         xy.y += 0.5;
      }

      xy.x += 0.5;
   }
   else {
      xy.x -= CentreX;
      xy.y = (xy.y + CentreY - 1.0) / _OutputAspectRatio;

      if (_OutputAspectRatio < 1.0) xy /= _OutputAspectRatio;

      xy.x += 0.5;
      xy.y += 0.5;
   }

   float scale_X    = Scale * 3.0;
   float scale_Y    = scale_X * ResY;
   float sum        = 0.0;
   float time       = _Progress * (1.0 - Speed) * _Length;
   float Curve      = SineX * 12.5;
   float keyClip    = scale_X / ((19.0 - (Level * 14.0)) * 100.0);
   float curve_step = 0.0;
   float time_step;

   scale_X *= ResX;

   for (int i = 0; i < StarNumber; ++i) {
      time_step = (float (i) + time) / 5.0;

      position.x = sin (SineY * time_step + curve_step) * scale_X;
      position.y = sin (time_step) * scale_Y;

      sum += keyClip / length (xy - position - 0.5.xx);
      curve_step += Curve;
      }

   fgdPat.rgb *= sum;
   sum = saturate ((sum * 1.5) - 0.25);

   float4 topRow = lerp (topLeft, topRight, uv0.x);
   float4 botRow = lerp (botLeft, botRight, uv0.x);
   float4 cField = float4 (lerp (topRow, botRow, uv0.y).rgb, 1.0);
   float4 Bgnd   = lerp (cField, fn_tex2D (s_Input, uv1), extBgd);

   return lerp (Bgnd, fgdPat, sum);
}

//-----------------------------------------------------------------------------------------//
//  Techniques
//-----------------------------------------------------------------------------------------//

technique LissajouSparkles
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
