//--------------------------------------------------------------//
// Lightworks user effect FractalMagic1.fx
//
// Created by LW user jwrl 14 May 2016.
//  LW 14+ version by jwrl 12 February 2017
//  Category changed from "Generators" to "Mattes"
//  SubCategory "Patterns" added.
//
// Lissajou stars is based on SineLights, a semi-abstract
// pattern generator created for Mac and Linux systems by
// Lightworks user baopao.  That was in turn based on the
// Lissajou code code at http://glslsandbox.com/e#9996.0
//
// Windows conversion and further modification to add either
// external video or a gradient background and colour to the
// pattern was carried out by Lighworks user jwrl.  In the
// process the range and type of some parameters were changed
// to allow interactive adjustment on the edit viewer.
//
// Unlike the original which installed into the "Video, Mattes"
// category, this version installs into the user-created class
// "Video, Generators".
//
// Note: under Windows this must compile as ps_3.0 or better.
//       This is automatically taken care of in versions of LW
//       higher than 14.5.  If using an older version under
//       Windows the Legacy version must be used.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lissajou stars";
   string Category    = "Mattes";
   string SubCategory = "Patterns";
> = 0;


//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture bg : RenderColorTarget;                 // Gradient target

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler inSampler = sampler_state {
   Texture   = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler bgSampler = sampler_state {
   Texture   = <bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Num
<
   string Description = "Number";
   string Group = "Pattern";
   float MinVal = 0.0;
   float MaxVal = 400;
> = 200;

float Speed
<
   string Description = "Speed";
   string Group = "Pattern";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.50;

float Scale
<
   string Description = "Scale";
   string Group = "Pattern";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.33;

float Level
<
   string Description = "Intensity";
   string Group = "Pattern";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.50;

float CentreX
<
   string Description = "Position";
   string Group = "Pattern";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float CentreY
<
   string Description = "Position";
   string Group = "Pattern";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
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
> = (0.0, 0.0, 0.0, 1.0);

float extBgd
<
   string Description = "External Video";
   string Group = "Background";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.00;

float4 topLeft
<
   string Description = "Top Left";
   string Group = "Background";
   bool SupportsAlpha = false;
> = (0.0, 0.25, 0.75, 0.5);

float4 topRight
<
   string Description = "Top Right";
   string Group = "Background";
   bool SupportsAlpha = false;
> = (0.5, 0.5, 0.0, 0.5);

float4 botLeft
<
   string Description = "Bottom Left";
   string Group = "Background";
   bool SupportsAlpha = false;
> = (0.5, 0.0, 0.5, 0.5);

float4 botRight
<
   string Description = "Bottom Right";
   string Group = "Background";
   bool SupportsAlpha = false;
> = (0.0, 0.75, 0.25, 0.5);

float _Progress;
float _OutputWidth;
float _OutputHeight;

//--------------------------------------------------------------//
// Shader
//--------------------------------------------------------------//

float4 doBackground (float2 xy : TEXCOORD0) : COLOR
{
   float4 bgdVid = tex2D (inSampler, xy);

   float4 topRow = lerp (topLeft, topRight, xy.x);
   float4 botRow = lerp (botLeft, botRight, xy.x);
   float4 cField = lerp (topRow, botRow, xy.y);

   return lerp (cField, bgdVid, extBgd);
}

float4 ps_main (float2 xy : TEXCOORD, float2 xy1 : TEXCOORD1) : COLOR
{
   float time_step, curve_step = 0.0;
   float2 position;

   float4 fgdPat = fgdColour;

   float2 centre_XY = float2 (CentreX, CentreY);

   float sc      = Scale * 3;
   float sum     = 0.0;
   float time    = _Progress * Speed * 10;
   float Curve   = SineX * 12.5;
   float keyClip = sc / ((19 - (Level * 14)) * 100);

   centre_XY = (centre_XY * 2) - 1.00;

   for (int i = 0; i < Num; ++i) {
      time_step = (float (i) + time) / 5.0;

      position.x = (sin (SineY * time_step + curve_step) * sc * ResX) + 0.5;
      position.y = (sin (time_step) * sc * ResY) + 0.5;

      sum += keyClip / length (xy + centre_XY - position);
      curve_step += Curve;
      }

   fgdPat.rgb *= sum;
   sum = saturate ((sum * 1.5) - 0.25);

   float4 bgd = tex2D (bgSampler, xy1);

   return lerp (bgd, fgdPat, sum);
}

//--------------------------------------------------------------//
//  Technique
//--------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

technique TwoPass
{
   pass First_Pass
   <
      string Script = "RenderColorTarget0 = bg;";
   >
   {
      PixelShader = compile PROFILE doBackground ();
   }

   pass Second_Pass
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

