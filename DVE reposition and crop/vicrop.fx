// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// VisualCrop by gr00by
// based on DVE.fx created by EditShare
// 26 Nov 2016
//
// Modifications for version 14 by jwrl 11 February 2017.
// Category changed and subcategory added.
//
// Bug fix by LW user jwrl 13 July 2017 - this effect didn't
// work as expected on Linux/Mac platforms.  It now does.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "VisualCrop";
   string Category    = "DVE";
   string SubCategory = "Crop Presets";
> = 0;

float _OutputAspectRatio;

//--------------------------------------------------------------//
// Params
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//
texture Fg;
texture Bg;

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

//--------------------------------------------------------------//
// Code
//--------------------------------------------------------------//
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

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//
technique DVE { pass Single_Pass { PixelShader = compile PROFILE ps_main(); } }
