// @Maintainer jwrl
// @Released 2018-04-08
// @Author jwrl
// @Created 2018-03-15
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdKit_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdKit_A.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3dTkA.fx
//
// This is a general purpose toolkit designed to build lower thirds.  It can optionally
// be fed with a graphics layer or other external image or effect.  It's designed to
// produce a flat coloured ribbon with two overlaid floating flat colour boxes. They
// can be used to generate borders, other graphical components, or even be completely
// hidden.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower 3rd toolkit A";
   string Category    = "Text";
   string SubCategory = "Lower Third Tools";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture In_1;
texture In_2;

texture Ribn : RenderColorTarget;

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

sampler s_Input_2 = sampler_state
{
   Texture   = <In_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Ribbon  = sampler_state
{
   Texture = <Ribn>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int InpMode
<
   string Group = "Text settings";
   string Description = "Text source";
   string Enum = "Before - uses In_1 for text / In_2 as background,After - uses In_1 as background with external text";
> = 0;

int TxtAlpha
<
   string Group = "Text settings";
   string Description = "Text type";
   string Enum = "Video layer or image effect,Lightworks title effect";
> = 0;

float TxtPosX
<
   string Group = "Text settings";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float TxtPosY
<
   string Group = "Text settings";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float RibbonWidth
<
   string Group = "Ribbon";
   string Description = "Width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.33333333;

float RibbonL
<
   string Group = "Ribbon";
   string Description = "Crop left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float RibbonR
<
   string Group = "Ribbon";
   string Description = "Crop right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Ribbon_Y
<
   string Group = "Ribbon";
   string Description = "Vertical position";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.15;

float4 RibbonColour
<
   string Group = "Ribbon";
   string Description = "Left colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float BoxA_Width
<
   string Group = "Box A";
   string Description = "Width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float BoxA_L
<
   string Group = "Box A";
   string Description = "Crop left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float BoxA_R
<
   string Group = "Box A";
   string Description = "Crop right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

float BoxA_Y
<
   string Group = "Box A";
   string Description = "Vertical position";
   float MinVal = 0.000;
   float MaxVal = 1.000;
> = 0.212;

float4 BoxAcolour
<
   string Group = "Box A";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 0.0, 1.0 };

float BoxB_Width
<
   string Group = "Box B";
   string Description = "Width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.15;

float BoxB_L
<
   string Group = "Box B";
   string Description = "Crop left";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.35;

float BoxB_R
<
   string Group = "Box B";
   string Description = "Crop right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float BoxB_Y
<
   string Group = "Box B";
   string Description = "Vertical position";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.085;

float4 BoxBcolour
<
   string Group = "Box B";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

float MasterScale
<
   string Group = "Master size and position";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Master_X
<
   string Group = "Master size and position";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Master_Y
<
   string Group = "Master size and position";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//
// These two functions are designed as replacements for all ()
// and any ().  fn_inRange (xy, range) returns true if all of
// xy falls inside range.xy - range.zw, while fn_legal (xy)
// returns true if all of xy is inside 0.0 - 1.0 inclusive.
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_ribbon (float2 uv : TEXCOORD0, float2 xy : TEXCOORD1) : COLOR
{
   float y0 = (RibbonWidth + 0.0001) * 0.142;
   float y1 = 1.0 - Ribbon_Y;
   float y2 = y1 + y0;

   y1 -= y0;

   float4 retval = fn_inRange (uv, float4 (RibbonL, y1, RibbonR, y2))
                 ? RibbonColour : EMPTY;

   y0  = (BoxA_Width + 0.0001) * 0.142;
   y1  = 1.0 - BoxA_Y;
   y2  = y1 + y0;
   y1 -= y0;

   if (fn_inRange (uv, float4 (BoxA_L, y1, BoxA_R, y2)))
      retval = BoxAcolour;

   y0  = (BoxB_Width + 0.0001) * 0.142;
   y1  = 1.0 - BoxB_Y;
   y2  = y1 + y0;
   y1 -= y0;

   if (fn_inRange (uv, float4 (BoxB_L, y1, BoxB_R, y2)))
      retval = BoxBcolour;

   if (InpMode == 1) return retval;

   float2 xy1 = xy + float2 (0.5 - TxtPosX, TxtPosY - 0.5);

   float4 Fgnd = fn_legal (xy1) ? tex2D (s_Input_1, xy1) : EMPTY;

   if (TxtAlpha == 1) Fgnd.a = pow (Fgnd.a, 0.5);

   return lerp (retval, Fgnd, Fgnd.a);
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float2 uv = (xy1 - float2 (0.5, 0.5)) / max (0.000001, MasterScale * 2.0);

   uv += float2 (0.5 - Master_X, 0.5 + Master_Y);

   float4 Fgnd = fn_legal (uv) ? tex2D (s_Ribbon, uv) : EMPTY;
   float4 Bgnd = (InpMode == 1) ? tex2D (s_Input_1, xy1) : tex2D (s_Input_2, xy2);

   return lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Lower3rd_A
{
   pass P_1
   < string Script = "RenderColorTarget0 = Ribn;"; > 
   { PixelShader = compile PROFILE ps_ribbon (); }

   pass P_2 { PixelShader = compile PROFILE ps_main (); }
}
