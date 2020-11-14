// @Maintainer jwrl
// @Released 2020-11-14
// @Author gr00by
// @OriginalAuthor LWKS Software Ltd
// @Created 2016-11-26
// @see https://www.lwks.com/media/kunena/attachments/6375/vicrop_640.png

/**
 Based on the crop section of DVE.fx as created for Lightworks, this is a quick simple cropping
 tool that you can set up by dragging corner pins around on the screen.  In effects settings mode,
 move your mouse over your edit viewer and two diagonally opposing corner pins will appear.  Just
 click on them and drag and the crop will follow.  Done.  It's one of those "why did no-one think
 of this sooner" tools.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VisualCrop.fx
//
// Version history:
//
// Updated 2020-11-14 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 8 January 2020 jwrl.
// Changed subcategory (again)!
// Changed the markup text to match the on-line description.
//
// Modified 23 December 2018 jwrl.
// Changed subcategory.
// Changed name from vicrop.fx to VisualCrop.fx.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modifications for version 14 by jwrl 11 February 2017.
// Category changed and subcategory added.
//
// Bug fix by LW user jwrl 13 July 2017
// This effect didn't work as expected on Linux/Mac platforms.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Visual crop";
   string Category    = "DVE";
   string SubCategory = "Simple visual tools";
   string Notes       = "This is a quick simple cropping tool that you can set up by dragging corner pins around on the screen";
   bool CanSize       = true;
> = 0;

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CropLeft
<
   string Description = "Top-Left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.0;

float CropTop
<
   string Description = "Top-Left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1;

float CropRight
<
   string Description = "Bottom-Right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1;

float CropBottom
<
   string Description = "Bottom-Right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

float _FgNormWidth = 1.0;
float _FgWidth  = 10.0;
float _FgHeight = 10.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float croppedL      = CropLeft;
   float croppedT      = 1.0-CropTop;
   float croppedR      = CropRight;
   float croppedB      = 1.0-CropBottom;

   if ((xy1.x < croppedL) ||  (xy1.x > croppedR) || (xy1.y < croppedT) || (xy1.y > croppedB)) return tex2D( BgSampler, xy2 );

   float2 texAddressAdjust = float2( 0.5 / _FgWidth, 0.5 / _FgHeight );
   float2 fgPos = xy1;

   // Remember that the texCoords for the FG may not be 0 -> 1

   fgPos.x *= _FgNormWidth;
   fgPos += texAddressAdjust;

   return tex2D( FgSampler, fgPos );
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DVE { pass Single_Pass { PixelShader = compile PROFILE ps_main(); } }
