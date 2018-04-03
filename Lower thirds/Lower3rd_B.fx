// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Lower3rd_B.fx
// Created by LW user jwrl 15 March 2018
// @Author jwrl
// @Created "15 March 2018"
//
// This effect consists of a line with an attached bar.  The
// bar can be locked at either end of the line or made to move
// from right to left or left to right as the transition is
// adjusted.  It can also be locked to either end of the line.
//
// External text can be input to In_1, and can wipe on or off
// in sync with, or against the moving block.
//
// Modified by LW user jwrl 16 March 2018
// Cosmetic change only: "Transition" has been moved to the
// top of the parameters, giving it higher priority than
// "Opacity".
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third B";
   string Category    = "Text";
   string SubCategory = "Lower Third Tools";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture In_1;
texture In_2;

texture Ribn : RenderColorTarget;

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

sampler s_Ribbon = sampler_state
{
   Texture   = <Ribn>;
   AddressU  = Mirror;
   AddressV  = Mirror;
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

int ArtWipe
<
   string Group = "Text setting";
   string Description = "Visibility";
   string Enum = "Always visible,Wipe at left edge of block,Wipe at right edge of block"; 
> = 1;

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

float LineWidth
<
   string Group = "Line setting";
   string Description = "Width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.05;

float LineLength
<
   string Group = "Line setting";
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float Line_X
<
   string Group = "Line setting";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.05;

float Line_Y
<
   string Group = "Line setting";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float4 LineColour
<
   string Group = "Line setting";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

int BlockMode
<
   string Group = "Block setting";
   string Description = "Movement";
   string Enum = "Move from left to right,Move from right to left,Anchor to left end of line,Anchor to right end of line"; 
> = 0;

float BlockWidth
<
   string Group = "Block setting";
   string Description = "Width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.05;

float BlockLength
<
   string Group = "Block setting";
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float4 BlockColour
<
   string Group = "Block setting";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define EMPTY   (0.0).xxxx

//--------------------------------------------------------------//
// Functions
//
// These two functions are designed as replacements for all ()
// and any ().  fn_inRange (xy, range) returns true if all of
// xy falls inside range.xy - range.zw, while fn_legal (xy)
// returns true if all of xy is inside 0.0 - 1.0 inclusive.
//--------------------------------------------------------------//

bool fn_inRange (float2 xy, float4 range)
{
   return !((xy.x < range.x) || (xy.y < range.y)
         || (xy.x > range.z) || (xy.y > range.w));
}

bool fn_legal (float2 xy)
{
   return !((xy.x < 0.0) || (xy.x > 1.0)
          || (xy.y < 0.0) || (xy.y > 1.0));
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_bar (float2 uv : TEXCOORD0) : COLOR
{
   float lWidth  = 0.005 + (LineWidth * 0.01);
   float bLength = BlockLength * LineLength;
   float bWidth  = BlockWidth * 0.2;
   float bTrans  = BlockMode == 0 ? Transition : BlockMode == 1
                                  ? 1.0 - Transition : BlockMode == 2
                                  ? 0.0 : 1.0;
   float bOffset = (LineLength - bLength) * bTrans;

   float2 xy1 = float2 (Line_X, 1.0 - Line_Y - (lWidth * 0.5));
   float2 xy2 = xy1 + float2 (LineLength, lWidth);
   float2 xy3 = float2 (xy1.x + bOffset, xy2.y);
   float2 xy4 = xy3 + float2 (bLength, bWidth);

   float4 retval = fn_inRange (uv, float4 (xy1, xy2))
                 ? LineColour : EMPTY;

   if (fn_inRange (uv, float4 (xy3, xy4)))
      retval = BlockColour;

   return retval;
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float aTrans = ArtWipe == 0 ? LineLength : LineLength * (1.0 - BlockLength);

   float2 uv = xy1 + float2 (ArtPosX, ArtPosY);

   float4 Fgnd = tex2D (s_Ribbon, xy1);
   float4 Text = fn_legal (uv) ? tex2D (s_Input_1, uv) : EMPTY;

   if (ArtAlpha == 1) Text.a = pow (Text.a, 0.5);

   if (ArtWipe >= 1) {
      if (BlockMode == 0) {
         aTrans *= Transition;
         aTrans += ArtWipe == 1 ? Line_X : LineLength * BlockLength + Line_X;

         if (uv.x > aTrans) Text = EMPTY;
      }
      else if (BlockMode == 1) {
         aTrans *= 1.0 - Transition;
         aTrans += ArtWipe == 1 ? Line_X : LineLength * BlockLength + Line_X;

         if (uv.x < aTrans) Text = EMPTY;
      }
   }

   Text = lerp (Text, Fgnd, Fgnd.a);

   return lerp (tex2D (s_Input_2, xy2), Text, Text.a * Opacity);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Lower3rd_B
{
   pass P_1
   < string Script = "RenderColorTarget0 = Ribn;"; > 
   { PixelShader = compile PROFILE ps_bar (); }

   pass P_2 { PixelShader = compile PROFILE ps_main (); }
}

