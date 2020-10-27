// @Maintainer jwrl
// @Released 2020-10-28
// @Author jwrl
// @Created 2020-10-27
// @see https://www.lwks.com/media/kunena/attachments/6375/DVEwithBlend_640.png

/**
 This a 2D DVE that performs as the Lightworks version does, but with one major
 difference. Instead of the drop shadow being calculated from the cropped frame edges
 the foreground alpha channel is used to calculate the drop shadow. This means that
 the drop shadow will only appear where it should and not just at the edge of frame,
 as it does with the Lightworks 2D DVE. Since that behaviour in the Lightworks effect
 is unlikely to be changed for backwards compatibility reasons, this DVE is a useful
 alternative.

 The image that leaves the effect has a composite alpha channel built from a combination
 of the background, foreground and drop shadow.  If the background has transparency it
 will be preserved wherever the foreground and/or drop shadow isn't present.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 2dDVEwithBlend.fx
//
// There was a similar user effect called 2D DVE plus alpha in the past for versions of
// Lightworks before 2020.1.  THIS IS NOT THAT EFFECT!!!  This is an effect that is based
// on the post 2020 Lightworks 2D DVE.  It supports the new CanSize switch to preserve
// the input resolution of the media being processed.
//
// Version history:
//
// Modified jwrl 2020-10-28.
// Changed the screen grab example in the header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "2D DVE with blend";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "A 2D DVE that blends transparent images and creates a drop shadow derived from the transparency";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CentreX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float CentreY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float MasterScale
<
   string Description = "Master";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float XScale
<
   string Description = "X";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float YScale
<
   string Description = "Y";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float CropL
<
   string Description = "Left";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropT
<
   string Description = "Top";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropR
<
   string Description = "Right";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropB
<
   string Description = "Bottom";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float ShadowTransparency
<
   string Description = "Transparency";
   string Group = "Shadow";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float ShadowXOffset
<
   string Description = "X Offset";
   string Group = "Shadow";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ShadowYOffset
<
   string Description = "Y Offset";
   string Group = "Shadow";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLACK        float4(0.0.xxx, 1.0)    // Opaque black
#define EMPTY        0.0.xxxx                // Transparent black

#define SHADOW_SCALE 0.2   // Carryover from the Lightworks original to match scaling

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   if ((xy.x > 0.5) || (xy.y > 0.5)) return EMPTY;

   return tex2D (s, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float scaleX = MasterScale * XScale;
   float scaleY = MasterScale * YScale;
   float Rcrop  = 1.0 - CropR;
   float Bcrop  = 1.0 - CropB;

   float2 xy1 = uv1 + float2 (0.5 - CentreX, CentreY - 0.5);

   xy1.x = ((xy1.x - 0.5) / scaleX) + 0.5;
   xy1.y = ((xy1.y - 0.5) / scaleY) + 0.5;

   float2 xy2 = xy1 - (float2 (ShadowXOffset, ShadowYOffset) * SHADOW_SCALE);

   float alpha = fn_tex2D (s_Foreground, xy2).a;

   float4 Fgnd   = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd   = fn_tex2D (s_Background, uv2);
   float4 retval = ((xy2.x >= CropL) && (xy2.x <= Rcrop) && (xy2.y >= CropT) && (xy2.y <= Bcrop))
                 ? lerp (Bgnd, BLACK, ShadowTransparency * alpha) : Bgnd;

   if ((xy1.x >= CropL) && (xy1.x <= Rcrop) && (xy1.y >= CropT) && (xy1.y <= Bcrop)) {
      retval = lerp (retval, Fgnd, Fgnd.a);
      retval = lerp (Bgnd, retval, Opacity);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DVE_blend
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
