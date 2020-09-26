// @Maintainer jwrl
// @Released 2018-09-26
// @Author rhinox202
// @Created 2012-11-21
// @see https://www.lwks.com/media/kunena/attachments/6375/Border_640.png

/**
 Border creates a coloured hard border over a cropped image.  The border is created
 inside the image being bordered, meaning that some of the image content will be lost.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BorderFx.fx
//
// Version history:
//
// Update 2020-09-26 jwrl.
// Reformatted header block.
//
// Modified 23 December 2018 jwrl.
// Changed category and subcategory.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified 22 November 2018 jwrl.
// Fixed a bug that meant that the border was always transparent.  Transparency can now
// be set by adjusting the alpha value of "Color".
//
// Modified 5 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Bug fix 21 July 2017 by jwrl:
// This addresses a cross platform issue which may have caused the effect not to behave
// as needed on Linux and Mac systems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Border";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "Creates a coloured hard border over a cropped image.  The border is created inside the image being bordered";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Input;

sampler2D TextureSampler = sampler_state {
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float4 BorderC
<
   string Description = "Color";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 1.0, 1.0 };

float BorderM
<
   string Description = "Master";
   float MinVal = 0.00;
   float MaxVal = 5.0;
> = 1.0;

float BorderT
<
   string Description = "Top";
   float MinVal = 0.00;
   float MaxVal = 5.0;
> = 0.5;

float BorderR
<
   string Description = "Right";
   float MinVal = 0.00;
   float MaxVal = 5.0;
> = 0.5;

float BorderB
<
   string Description = "Bottom";
   float MinVal = 0.00;
   float MaxVal = 5.0;
> = 0.5;

float BorderL
<
   string Description = "Left";
   float MinVal = 0.00;
   float MaxVal = 5.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio; // The project aspect ratio

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1) : COLOR
{
   float4 ret = tex2D (TextureSampler, xy1);
   
   float Border_T = BorderM * BorderT / 10.0;
   float Border_R = 1.0 - (BorderM * BorderR / (_OutputAspectRatio * 10.0));
   float Border_B = 1.0 - (BorderM * BorderB / 10.0);
   float Border_L = BorderM * BorderL / (_OutputAspectRatio * 10.0);
   
   if ((xy1.y <= Border_T) || (xy1.x >= Border_R) || (xy1.y >=  Border_B) || (xy1.x <= Border_L))
   {
      return BorderC;
   }
   
   return ret;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Border { pass Single_Pass { PixelShader = compile PROFILE ps_main (); } }
