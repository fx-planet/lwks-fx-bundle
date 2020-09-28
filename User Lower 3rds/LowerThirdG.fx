// @Maintainer jwrl
// @Released 2020-09-28
// @Author jwrl
// @Created 2018-03-19
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdG_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdG.mp4

/**
 This uses a clock wipe to wipe on a box around text.  The box can wipe on clockwise or
 anticlockwise, and start from the top or the bottom.  Once the box is almost complete a
 fill colour dissolves in, along with the text.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LowerThirdG.fx
//
// Version history:
//
// Update 2020-09-28 jwrl.
// Revised header block.
//
// Modified 26 December 2018 jwrl.
// Formatted description for md.
//
// Modified 5 December 2018 jwrl.
// Change subcategory.
//
// Modified 29 September 2018 jwrl.
// Added notes to header.
//
// Bugfix 31 May 2018 jwrl.
// Corrected X direction sense of ArtPosX.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third G";
   string Category    = "Text";
   string SubCategory = "User Lower 3rds";
   string Notes       = "This uses a clock wipe to wipe on a box which then reveals the text";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture In_1;
texture In_2;

texture Wipe : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input_1 = sampler_state
{
   Texture   = <In_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Input_2 = sampler_state { Texture = <In_2>; };

sampler s_Wipe = sampler_state
{
   Texture   = <Wipe>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Transition
<
   string Description = "Transition";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int Direction
<
   string Description = "Transition direction";
   string Enum = "Clockwise top,Anticlockwise top,Clockwise bottom,Anticlockwise bottom";
> = 0;

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

Float BoxWidth
<
   string Group = "Surround";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

Float BoxHeight
<
   string Group = "Surround";
   string Description = "Height";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

Float LineWidth
<
   string Group = "Surround";
   string Description = "Line weight";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float CentreX
<
   string Group = "Surround";
   string Description = "Origin";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreY
<
   string Group = "Surround";
   string Description = "Origin";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreZ
<
   string Group = "Surround";
   string Description = "Origin";
   string Flags = "SpecifiesPointZ";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float4 LineColour
<
   string Group = "Surround";
   string Description = "Line colour";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 1.0, 1.0 };

float4 FillColour
<
   string Group = "Surround";
   string Description = "Fill colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.2, 0.8, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY   (0.0).xxxx

#define TWO_PI  6.2831853072
#define HALF_PI 1.5707963268

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//
// This function returns true if all of xy is inside 0.0-1.0.
//-----------------------------------------------------------------------------------------//

bool fn_legal (float2 xy)
{
   return !((xy.x < 0.0) || (xy.x > 1.0) || (xy.y < 0.0) || (xy.y > 1.0));
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_prelim (float2 uv : TEXCOORD0) : COLOR
{
   float2 xy = (uv - 0.5.xx);
   float2 az = abs (xy);
   float2 cz = float2 (BoxWidth, BoxHeight) * 0.5;

   float trans = max ((Transition - 0.75) * 4.0, 0.0);

   float4 out_ln = (cz.x < az.x) || (cz.y < az.y) ? LineColour : EMPTY;
   float4 retval = (az.x < cz.x) && (az.y < cz.y) ? lerp (EMPTY, FillColour, trans) : EMPTY;

   cz += float2 (1.0, _OutputAspectRatio) * LineWidth * 0.025;

   if ((az.x > cz.x) || (az.y > cz.y)) out_ln = EMPTY;

   float x, y;
   float scale = distance (xy, 0.0);

   trans = sin ((1.0 - min (Transition * 1.25, 1.0)) * HALF_PI);
   sincos (trans * TWO_PI, x, y);

   xy  = float2 (x, y) * scale;
   xy += 0.5.xx;

   if (trans < 0.25) {
      if ((uv.x > 0.5) && (uv.x < xy.x) && (uv.y < xy.y)) out_ln = EMPTY;
   }
   else if (trans < 0.5) {
      if ((uv.x > 0.5) && (uv.y < 0.5)) out_ln = EMPTY;
      if ((uv.x > xy.x) && (uv.y > xy.y)) out_ln = EMPTY;
   }
   else if (trans < 0.75) {
      if ((uv.x > 0.5) || ((uv.x > xy.x) && (uv.y > xy.y))) out_ln = EMPTY;
   }
   else if ((uv.x > 0.5) || (uv.y > 0.5) || ((uv.x < xy.x) && (uv.y < xy.y))) out_ln = EMPTY;

   return lerp (retval, out_ln, out_ln.a);
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float scale = pow (max ((CentreZ + 1.0) * 0.5, 0.0001) + 0.5, 4.0);
   float trans = max ((Transition - 0.75) * 4.0, 0.0);

   float2 pos, uv;
   float2 xy = xy1 - float2 (ArtPosX, -ArtPosY);

   if (Direction < 2) {
      uv = xy1 - 0.5.xx;
      pos = float2 (-CentreX, CentreY);
   }
   else {
      uv = 0.5.xx - xy1;
      pos = float2 (CentreX, -CentreY);
   }

   if ((Direction == 0) || (Direction == 2)) {
      uv.x = -uv.x;
      pos.x = -pos.x;
   }

   uv = (uv / scale) + pos + 0.5.xx;

   float4 Mask = fn_legal (uv) ? tex2D (s_Wipe, uv) : EMPTY;
   float4 Bgnd = tex2D (s_Input_2, xy2);
   float4 Text = fn_legal (xy) ? tex2D (s_Input_1, xy) : EMPTY;

   if (ArtAlpha == 1) Text.a = pow (Text.a, 0.5);

   Mask = lerp (Mask, Text, Text.a * trans);

   return lerp (Bgnd, Mask, Mask.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LowerThirdG
{
   pass P_1
   < string Script = "RenderColorTarget0 = Wipe;"; > 
   { PixelShader = compile PROFILE ps_prelim (); }

   pass P_2 { PixelShader = compile PROFILE ps_main (); }
}
