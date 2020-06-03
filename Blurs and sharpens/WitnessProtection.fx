// @Maintainer jwrl
// @Released 2020-06-03
// @Author jwrl
// @Created 2020-06-03
// @see https://www.lwks.com/media/kunena/attachments/6375/WitnessProtection_640.png

/**
 This is a witness protection-style blurred or mosaic image obscuring pattern.  It can be
 adjusted in area and position and can be keyframed.  The blur amount can be varied using
 the strength control, and the mosaic size can also be varied with that same control.

 Because the crop and position adjustment is done before the blur or mosaic generation,
 the edges of the blur will always blend smoothly into the background image.  For the same
 reason, mosaic tiles will never be partially cut at the edges.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WitnessProtection.fx
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Witness protection";
   string Category    = "Stylize";
   string SubCategory = "Blurs and sharpens";
   string Notes       = "A classic witness protection effect.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Crop : RenderColorTarget;
texture Blur : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Cropped = sampler_state
{
   Texture   = <Crop>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blurred = sampler_state
{
   Texture   = <Blur>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Protection style";
   string Enum = "Blur,Mosaic"; 
> = 1;

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float MasterSize
<
   string Group = "Mask size";
   string Description = "Master";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float SizeX
<
   string Group = "Mask size";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float SizeY
<
   string Group = "Mask size";
   string Description = "Height";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosX
<
   string Description = "Mask position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosY
<
   string Description = "Mask position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY   (0.0).xxxx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 xy)
{
   float2 xy1 = abs (xy - 0.5.xx);

   if ((xy1.x > 0.5) || (xy1.y > 0.5)) return EMPTY;

   return tex2D (s_Sampler, xy);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy  = float2 (PosX, 1.0 - PosY);
   float2 xy0 = MasterSize * float2 (SizeX, SizeY * _OutputAspectRatio) * 0.5;
   float2 xy1 = xy - xy0;
   float2 xy2 = xy + xy0;

   float4 retval = fn_tex2D (s_Input, uv);

   if ((uv.x < xy1.x) || (uv.y < xy1.y) || (uv.x > xy2.x) || (uv.y > xy2.y)) retval.a = 0.0;

   return retval;
}

float4 ps_blur_sub (float2 uv : TEXCOORD1) : COLOR
{
   if (Strength <= 0.0) return EMPTY;

   float4 retval = tex2D (s_Cropped, uv);

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Strength * 0.00386;

   for (int i = 0; i < 12; i++) {
      sincos ((i * 0.2617993878), xy.x, xy.y);
      xy *= radius;
      retval += fn_tex2D (s_Cropped, uv + xy);
      retval += fn_tex2D (s_Cropped, uv - xy);
      xy += xy;
      retval += fn_tex2D (s_Cropped, uv + xy);
      retval += fn_tex2D (s_Cropped, uv - xy);
   }

   return retval / 49.0;
}

float4 ps_blur_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgd = tex2D (s_Input, uv);

   if (Strength <= 0.0) return Bgd;

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Strength * 0.00965;

   float4 retval = tex2D (s_Blurred, uv);

   for (int i = 0; i < 12; i++) {
      sincos ((i * 0.2617993878), xy.x, xy.y);
      xy *= radius;
      retval += fn_tex2D (s_Blurred, uv + xy);
      retval += fn_tex2D (s_Blurred, uv - xy);
      xy += xy;
      retval += fn_tex2D (s_Blurred, uv + xy);
      retval += fn_tex2D (s_Blurred, uv - xy);
   }

   retval /= 49.0;

   return lerp (Bgd, retval, retval.a);
}

float4 ps_mosaic_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgd = tex2D (s_Input, uv);

   if (Strength <= 0.0) return Bgd;

   float2 xy = Strength * float2 (1.0, _OutputAspectRatio) * 0.015;

   xy = (floor ((uv - 0.5.xx) / xy) * xy) + 0.5.xx;

   float4 Fgd = tex2D (s_Cropped, xy);

   return lerp (Bgd, Fgd, Fgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WitnessProtection_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Crop;"; > 
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Blur;"; > 
   { PixelShader = compile PROFILE ps_blur_sub (); }

   pass P_3
   { PixelShader = compile PROFILE ps_blur_main (); }
}

technique WitnessProtection_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Crop;"; > 
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   { PixelShader = compile PROFILE ps_mosaic_main (); }
}

