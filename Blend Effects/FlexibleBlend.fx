// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2017-12-23
// @see https://www.lwks.com/media/kunena/attachments/6375/FlexiBlend_640.png

/**
"Flexible blend" is a simple blend utility with the ability to adjust the position, size
and rotation of the image being matted and crop it.  If needed the alpha channel can also
be inverted to support the less common inverted alpha logic used by some utilities.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlexibleBlend.fx
//
// This code bypasses the recently discovered D3D - Cg bug where "Clamp" addressing
// behaves differently in the two shader languages.  To do this code has been added to
// set RGBA to zero if 0.0-1.0 addresses are exceeded.
//
// Modified 5 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 23 June 2018 jwrl.
// Amended the address range check section.  Previously the any() function was used, and
// this has been found to be buggy in the way that it has been implemented in Cg.
//
// Modified 30 July 2018 jwrl.
// Added alpha channel boost for Lightworks titles and a descriptive note.
// Added X and Y rotation and pivot points.
//
// Update 23 December 2018 jwrl.
// Changed subcategory to "Blend Effects".
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Flexible blend";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "A blend utility which can adjust position, size, rotation and cropping";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Sup : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Super = sampler_state
{
   Texture   = <Sup>;
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
   string Description = "If using a Lightworks text effect disconnect its input and set this first";
   string Enum = "Crawl/Roll/Titles,Video/External image";
> = 0;

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool InvertAlpha
<
   string Description = "Invert alpha";
> = false;

float Scale
<
   string Group = "Geometry";
   string Description = "Scale";
   float MinVal = -1.0;
   float MaxVal = 1.00;
> = 0.0;

float RotateX
<
   string Group = "Geometry";
   string Description = "X rotation";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

float PivotX
<
   string Group = "Geometry";
   string Description = "X axis";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float RotateY
<
   string Group = "Geometry";
   string Description = "Y rotation";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

float PivotY
<
   string Group = "Geometry";
   string Description = "Y axis";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float RotateZ
<
   string Group = "Geometry";
   string Description = "Z rotation";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

float CentreX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float CentreY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Crop_L
<
   string Description = "Top left crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.0;

float Crop_T
<
   string Description = "Top left crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.0;

float Crop_R
<
   string Description = "Bottom right crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.0;

float Crop_B
<
   string Description = "Bottom right crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

#define EMPTY  (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   float4 retval = tex2D (Vsample, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, uv);

   float alpha = InvertAlpha ? 1.0 - Fgd.a : Fgd.a;

   if ((uv.x < Crop_L) || (uv.x > Crop_R) || (uv.y > (1.0 - Crop_B)) || (uv.y < (1.0 - Crop_T))) alpha = 0.0;

   return float4 (Fgd.rgb, alpha);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 Pxy = float2 (PivotX, 1.0 - PivotY);
   float2 Rxy = cos (radians (float2 (RotateX, RotateY)));
   float2 xy  = uv - float2 (CentreX, 1.0 - CentreY);

   float cos_Z, sin_Z, scale = 1.0 + (Scale * 0.5);

   sincos (radians (RotateZ), sin_Z, cos_Z);
   scale = pow (scale, 8.0);

   if (Rxy.x == 0.0) Rxy.x = 0.0000000001;
   if (Rxy.y == 0.0) Rxy.y = 0.0000000001;

   float2 xy1 = float2 (xy.y / _OutputAspectRatio, -xy.x * _OutputAspectRatio) * sin_Z;

   xy *= cos_Z;
   xy += xy1;
   xy /= scale;
   xy += 0.5.xx - Pxy;
   xy /= Rxy;
   xy += Pxy;

   float4 Fgd = fn_tex2D (s_Super, xy);
   float4 Bgd = tex2D (s_Background, uv);

   float alpha = Fgd.a * Amount;

   return float4 (lerp (Bgd.rgb, Fgd.rgb, alpha), max (alpha, Bgd.a));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FlexibleBlend
{
   pass P_1
   < string Script = "RenderColorTarget0 = Sup;"; > 
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2 { PixelShader = compile PROFILE ps_main (); }
}
