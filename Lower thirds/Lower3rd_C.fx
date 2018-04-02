// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Lower3rd_C.fx
// Created by LW user jwrl 15 March 2018
// @Author jwrl
// @CreationDate "15 March 2018"
//
// This effect opens a text ribbon in a lower third position
// to reveal the lower third text.  That's all there is to it
// really.
//
// Modified by LW user jwrl 16 March 2018
// Cosmetic change only: "Transition" has been moved to the
// top of the parameters, giving it higher priority than
// "Opacity".
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third C";
   string Category    = "Text";
   string SubCategory = "Lower Third Tools";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture In_1;
texture In_2;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler s_Input_1 = sampler_state
{
   Texture   = <In_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Input_2 = sampler_state
{
   Texture = <In_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Transition
<
   string Description = "Transition";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int ArtAlpha
<
   string Group = "Text setting";
   string Description = "Text type";
   string Enum = "Video layer or image effect,Lightworks title effect";
> = 0;

float ArtPosX
<
   string Group = "Text setting";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ArtPosY
<
   string Group = "Text setting";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float RibbonWidth
<
   string Group = "Ribbon setting";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.3;

float RibbonLength
<
   string Group = "Ribbon setting";
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float4 RibbonColourA
<
   string Group = "Ribbon setting";
   string Description = "Left colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float4 RibbonColourB
<
   string Group = "Ribbon setting";
   string Description = "Right colour";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 1.0, 1.0 };

float Ribbon_X
<
   string Group = "Ribbon setting";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Ribbon_Y
<
   string Group = "Ribbon setting";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.15;

float LineWidth
<
   string Group = "Line setting";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1 ;

float4 LineColourA
<
   string Group = "Line setting";
   string Description = "Left colour";
   bool SupportsAlpha = true;
> = { 0.07, 0.07, 0.49, 1.0 };

float4 LineColourB
<
   string Group = "Line setting";
   string Description = "Right colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.27, 0.47, 1.0 };

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define EMPTY   (0.0).xxxx

//--------------------------------------------------------------//
// Functions
//
// This function returns true if all of xy is inside 0.0-1.0.
//--------------------------------------------------------------//

bool fn_legal (float2 xy)
{
   return !((xy.x < 0.0) || (xy.x > 1.0)
          || (xy.y < 0.0) || (xy.y > 1.0));
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD0, float2 xy : TEXCOORD1) : COLOR
{
   float lWidth  = LineWidth * 0.0625;
   float rWidth = lerp (-lWidth, (RibbonWidth + 0.02) * 0.25, Transition);

   lWidth = max (0.0, lWidth + min (0.0, rWidth));
   rWidth = max (0.0, rWidth);

   float2 xy0 = xy + float2 (ArtPosX, ArtPosY);
   float2 xy1 = float2 (Ribbon_X, 1.0 - Ribbon_Y - (rWidth * 0.5));
   float2 xy2 = xy1 + float2 (RibbonLength, rWidth);

   float colour_grad = max (uv.x - Ribbon_X, 0.0) / RibbonLength;

   float4 lColour = lerp (LineColourA, LineColourB, colour_grad);
   float4 retval  = lerp (RibbonColourA, RibbonColourB, colour_grad);
   float4 artwork = fn_legal (xy0) ? tex2D (s_Input_1, xy0) : EMPTY;

   if (ArtAlpha == 1) artwork.a = pow (artwork.a, 0.5);

   retval = (uv.y < xy1.y) || (uv.y > xy2.y) ? EMPTY : lerp (retval, artwork, artwork.a);

   xy0 = float2 (xy1.y - lWidth, xy2.y + lWidth);

   if (((uv.y >= xy0.x) && (uv.y <= xy1.y)) || ((uv.y >= xy2.y) && (uv.y <= xy0.y)))
      retval = lColour;

   if ((uv.x < xy1.x) || (uv.x > xy2.x)) retval = EMPTY;

   return lerp (tex2D (s_Input_2, xy), retval, retval.a * Opacity);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Lower3rd_C
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

