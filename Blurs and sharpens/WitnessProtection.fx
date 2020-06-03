// @Maintainer jwrl
// @Released 2020-06-03
// @Author jwrl
// @Created 2020-06-03
// @see https://www.lwks.com/media/kunena/attachments/6375/WitnessProtection_640.png

/**
 This is a witness protection-style blurred or mosaic image obscuring pattern.  It can be
 adjusted in area and position and can be keyframed.  The blur amount can be varied using
 the "Blur strength" control, and the mosaic size can be independently varied with the
 "Mosaic size" control.  This gives you the ability to have any mixture of the two that
 you could want.  The "Master pattern" control simultaneously adjusts both.

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
texture Mos  : RenderColorTarget;
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

sampler s_Mosaic = sampler_state
{
   Texture   = <Mos>;
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

float Mosaic
<
   string Group = "Protection mask";
   string Description = "Mosaic size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Blurriness
<
   string Group = "Protection mask";
   string Description = "Blur strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Master
<
   string Group = "Protection mask";
   string Description = "Master pattern";
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

float4 ps_mosaic (float2 uv : TEXCOORD1) : COLOR
{
   float amount = Master * Mosaic;

   float2 xy;

   if (amount > 0.0) {
      xy = amount * float2 (1.0, _OutputAspectRatio) * 0.03;
      xy = (floor ((uv - 0.5.xx) / xy) * xy) + 0.5.xx;
   }
   else xy = uv;

   return tex2D (s_Cropped, xy);
}

float4 ps_blur_sub (float2 uv : TEXCOORD1) : COLOR
{
   float amount = Master * Blurriness * 0.00772;

   if (amount <= 0.0) return EMPTY;

   float4 retval = tex2D (s_Mosaic, uv);

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * amount;

   for (int i = 0; i < 12; i++) {
      sincos ((i * 0.2617993878), xy.x, xy.y);
      xy *= radius;
      retval += fn_tex2D (s_Mosaic, uv + xy);
      retval += fn_tex2D (s_Mosaic, uv - xy);
      xy += xy;
      retval += fn_tex2D (s_Mosaic, uv + xy);
      retval += fn_tex2D (s_Mosaic, uv - xy);
   }

   return retval / 49.0;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgd = tex2D (s_Input, uv);
   float4 retval;

   float amount = Master * Blurriness * 0.0193;

   if (amount <= 0.0) {
      if  ((Master * Mosaic) <= 0.0) return Bgd;

      retval = fn_tex2D (s_Mosaic, uv);
   }
   else {
      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * amount;

      retval = tex2D (s_Blurred, uv);

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
   }

   return lerp (Bgd, retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WitnessProtection
{
   pass P_1
   < string Script = "RenderColorTarget0 = Crop;"; > 
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Mos;"; > 
   { PixelShader = compile PROFILE ps_mosaic (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Blur;"; > 
   { PixelShader = compile PROFILE ps_blur_sub (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}
