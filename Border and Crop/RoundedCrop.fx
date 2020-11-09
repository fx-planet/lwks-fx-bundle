// @Maintainer jwrl
// @Released 2020-11-09
// @Author jwrl
// @Created 2020-05-16
// @see https://www.lwks.com/media/kunena/attachments/6375/RoundedCrop_640.png

/**
 This is a bordered crop that produces rounding at the corners of the crop shape.  The
 border can be feathered, and is a mix of two colours.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RoundedCrop.fx
//
// Version history:
//
// Update 2020-11-09 jwrl:
// Added CanSize switch for LW 2021 support.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Rounded crop";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "A bordered, drop shadowed crop with rounded corners.";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Mk : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_MaskShape = sampler_state
{
   Texture   = <Mk>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CropR
<
   string Group = "Crop";
   string Description = "Top right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropT
<
   string Group = "Crop";
   string Description = "Top right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropL
<
   string Group = "Crop";
   string Description = "Bottom left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float CropB
<
   string Group = "Crop";
   string Description = "Bottom left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float BorderWidth
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float CropRadius
<
   string Group = "Border";
   string Description = "Rounding";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float BorderFeather
<
   string Group = "Border";
   string Description = "Edge softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float4 BorderColour_1
<
   string Group = "Border";
   string Description = "Colour 1";
   bool SupportsAlpha = false;
> = { 0.345, 0.655, 0.926, 1.0 };

float4 BorderColour_2
<
   string Group = "Border";
   string Description = "Colour 2";
   bool SupportsAlpha = false;
> = { 0.655, 0.345, 0.926, 1.0 };

float Shadow
<
   string Group = "Shadow";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

float ShadowSoft
<
   string Group = "Shadow";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float ShadowX
<
   string Group = "Shadow";
   string Description = "X offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.25;

float ShadowY
<
   string Group = "Shadow";
   string Description = "Y offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI       1.5707963268

#define EDGE_SCALE    0.075
#define RADIUS_SCALE  0.15

#define SHADOW_DEPTH  0.1
#define SHADOW_SOFT   0.025
#define TRANSPARENCY  0.75

#define MINIMUM       0.0001.xx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool fn_bad (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD0) : COLOR
{
   float adjust = max (0.0, max (CropL - CropR, CropB - CropT));

   float2 aspect  = float2 (1.0, _OutputAspectRatio);
   float2 center  = float2 (CropL + CropR, 2.0 - CropT - CropB) / 2.0;
   float2 border  = max (0.0, BorderWidth * EDGE_SCALE - adjust) * aspect;
   float2 feather = max (0.0, BorderFeather * EDGE_SCALE - adjust) * aspect;
   float2 F_scale = max (MINIMUM, feather * 2.0);
   float2 S_scale = F_scale + max (0.0, ShadowSoft * SHADOW_SOFT - adjust) * aspect;
   float2 outer_1 = float2 (CropR, 1.0 - CropB) - center;
   float2 outer_2 = max (0.0.xx, outer_1 + feather);

   float radius_1 = CropRadius * RADIUS_SCALE;
   float radius_2 = min (radius_1 + feather.x, min (outer_2.x, outer_2.y / _OutputAspectRatio));

   float2 inner = max (0.0.xx, outer_2 - (radius_2 * aspect));
   float2 xy = abs (uv - center);

   float scope = distance ((xy - inner) / aspect, 0.0.xx);

   float4 Mask = 0.0.xxxx;

   if ((xy.x < outer_2.x) && (xy.y < outer_2.y)) {
      Mask.x = min (1.0, min ((outer_2.y - xy.y) / F_scale.y, (outer_2.x - xy.x) / F_scale.x));

      if ((xy.x >= inner.x) && (xy.y >= inner.y)) {
         if (scope < radius_2) { Mask.x = min (1.0, (radius_2 - scope) / F_scale.x); }
         else Mask.x = 0.0;
      }
   }

   outer_1   = max (0.0.xx, outer_1 + border);
   outer_2  += border;
   radius_1  = min (radius_1 + border.x, min (outer_1.x, outer_1.y / _OutputAspectRatio));
   radius_2 += border.x;
   border    = max (MINIMUM, max (border, feather));
   adjust    = sin (min (1.0, CropRadius * 20.0) * HALF_PI);

   if ((xy.x < outer_2.x) && (xy.y < outer_2.y)) {
      Mask.y = min (1.0, min ((outer_1.y - xy.y) / border.y, (outer_1.x - xy.x) / border.x));
      Mask.z = min (1.0, min ((outer_2.y - xy.y) / F_scale.y, (outer_2.x - xy.x) / F_scale.x));
      Mask.w = min (1.0, min ((outer_2.y - xy.y) / S_scale.y, (outer_2.x - xy.x) / S_scale.x));

      if ((xy.x >= inner.x) && (xy.y >= inner.y)) {
         if (scope < radius_2) {
            Mask.y = lerp (Mask.y, min (1.0, (radius_1 - scope) / border.x), adjust);
            Mask.z = lerp (Mask.z, min (1.0, (radius_2 - scope) / F_scale.x), adjust);
            Mask.w = lerp (Mask.w, min (1.0, (radius_2 - scope) / S_scale.x), adjust);
         }
         else Mask.yzw *= 1.0 - adjust;
      }
   }

   Mask.yz *= sin (min (1.0, BorderWidth * 10.0) * HALF_PI);
   Mask.w  *= Shadow * TRANSPARENCY;

   return Mask;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - (float2 (ShadowX / _OutputAspectRatio, -ShadowY) * SHADOW_DEPTH);

   float4 Bgnd = tex2D (s_Background, uv);
   float4 Mask = tex2D (s_MaskShape, uv);

   float3 Shad = fn_bad (xy) ? Bgnd.rgb : Bgnd.rgb * (1.0 - tex2D (s_MaskShape, xy).w);

   float4 Colour = lerp (BorderColour_2, BorderColour_1, Mask.y);
   float4 retval = lerp (float4 (Shad, Bgnd.a), Colour, Mask.z);

   return lerp (retval, tex2D (s_Foreground, uv), Mask.x);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique RoundedCrop
{
   pass P_1
   < string Script = "RenderColorTarget0 = Mk;"; >
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
