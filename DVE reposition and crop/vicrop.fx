// @Maintainer jwrl
// @Released 2018-04-07
// @Author gr00by
// @OriginalAuthor "EditShare EMEA"
// @Created 2016-11-26
// @see https://www.lwks.com/media/kunena/attachments/6375/vicrop1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/vicrop3.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect VisualCrop
//
// Based on DVE.fx created by EditShare, this is a quick simple cropping tool that you
// can set up by dragging corner pins around on the screen.  In effects edit mode, move
// your mouse over your sequence viewer and the pins will appear.  Drag them where you
// need them to visually adjust your cropping.
//
// Modifications for version 14 by jwrl 11 February 2017.
// Category changed and subcategory added.
//
// Bug fix by LW user jwrl 13 July 2017
// This effect didn't work as expected on Linux/Mac platforms.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "VisualCrop";
   string Category    = "DVE";
   string SubCategory = "Crop Presets";
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
