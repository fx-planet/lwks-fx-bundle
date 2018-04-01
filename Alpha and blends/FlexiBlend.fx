//--------------------------------------------------------------//
// Lightworks user effect FlexiBlend.fx
//
// Created by LW user jwrl 23 December 2017
//
// This is a simple blend utility with the ability to adjust
// the position, size and rotation of the image being matted
// and crop it.  The alpha channel can also be inverted if
// needed to support the less common inverted alpha logic.
//
// This code bypasses the recently discovered D3D - Cg bug
// where "Clamp" addressing behaves differently in the two
// shader languages.  To do this code has been added to set
// RGBA to zero if 0.0-1.0 addresses are exceeded.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Flexi-blend";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture _Crop : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state { Texture = <Fg>; };
sampler BgSampler = sampler_state { Texture = <Bg>; };

sampler CropSampler = sampler_state { Texture = <_Crop>; };

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

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

float Rotation
<
   string Group = "Geometry";
   string Description = "Rotation";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

float Scale
<
   string Group = "Geometry";
   string Description = "Scale";
   float MinVal = -1.0;
   float MaxVal = 1.00;
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

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

float _OutputAspectRatio;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (FgSampler, uv);

   float alpha = InvertAlpha ? 1.0 - Fgd.a : Fgd.a;

   if ((uv.x < Crop_L) || (uv.x > Crop_R) || (uv.y > (1.0 - Crop_B)) || (uv.y < (1.0 - Crop_T))) alpha = 0.0;

   return float4 (Fgd.rgb, alpha);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - float2 (CentreX, 1.0 - CentreY);

   float cosR, sinR, scale = 1.0 + (Scale * 0.5);

   sincos (radians (Rotation), sinR, cosR);
   scale = pow (scale, 8.0);

   float2 xy1 = float2 (xy.y / _OutputAspectRatio, -xy.x * _OutputAspectRatio) * sinR;

   xy *= cosR;
   xy += xy1;
   xy /= scale;
   xy += 0.5.xx;

   float4 Fgd = (any (xy < 0.0) || any (xy > 1.0)) ? 0.0.xxxx : tex2D (CropSampler, xy);
   float4 Bgd = tex2D (BgSampler, uv);

   float alpha = Fgd.a * Amount;

   return float4 (lerp (Bgd.rgb, Fgd.rgb, alpha), max (alpha, Bgd.a));
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique FastBlend
{
   pass P_1
   < string Script = "RenderColorTarget0 = _Crop;"; > 
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2 { PixelShader = compile PROFILE ps_main (); }
}

