// @Maintainer jwrl
// @Released 2018-04-08
// @Author jwrl
// @Created 2018-03-15
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdA_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdA_1.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdA_2.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rd_A.fx
//
// This moves a coloured bar on from one side of the screen then lowers or raises it to
// reveal an alpha image connected to the input In_1.  To remove the effect, the bar
// can be moved up to hide the text again and then moved off.  This combination move is
// all done in one operation using the Transition parameter.
//
// This completely replaces Lower3rd_1.fx, which has now been withdrawn.  While that
// version is still quite useable, the significant user interface changes in this
// version have made this a much better proposition.
//
// Modified by LW user jwrl 16 March 2018
// Cosmetic change only: "Transition" has been moved to the top of the parameters,
// giving it higher priority than "Opacity".
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third A";
   string Category    = "Text";
   string SubCategory = "Lower Third Tools";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture In_1;
texture In_2;

texture Bar : RenderColorTarget;

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

sampler s_Bar = sampler_state
{
   Texture   = <Bar>;
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

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int SetTechnique
<
   string Group = "Text setting";
   string Description = "Direction";
   string Enum = "Visible above bar,Visible below bar"; 
> = 0;

int TxtAlpha
<
   string Group = "Text setting";
   string Description = "Text type";
   string Enum = "Video layer or image effect,Lightworks title effect";
> = 0;

float TxtPosX
<
   string Group = "Text setting";
   string Description = "Displacement";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float TxtPosY
<
   string Group = "Text setting";
   string Description = "Displacement";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float BarWidth
<
   string Group = "Line setting";
   string Description = "Width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.05;

float BarLength
<
   string Group = "Line setting";
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float Bar_X
<
   string Group = "Line setting";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.05;

float Bar_Y
<
   string Group = "Line setting";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float4 BarColour
<
   string Group = "Line setting";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

float BarPosX
<
   string Group = "Line movement";
   string Description = "Displacement";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float BarPosY
<
   string Group = "Line movement";
   string Description = "Displacement";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY   (0.0).xxxx

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

float4 ps_bar (float2 uv : TEXCOORD0) : COLOR
{
   float _width = 0.005 + (BarWidth * 0.1);

   float2 xy1 = float2 (Bar_X, 1.0 - Bar_Y - (_width * 0.5));
   float2 xy2 = xy1 + float2 (BarLength, _width);

   if (fn_inRange (uv, float4 (xy1, xy2))) return BarColour;

   return EMPTY;
}

float4 ps_main_0 (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float trans_1 = 1.0 - min (1.0, Transition * 5.0 / 3.0);
   float trans_2 = 1.0 - max (0.0, (Transition * 4.0) - 3.0);

   float2 uv = float2 (BarPosX * trans_1, -BarPosY * trans_2);
   float2 xy = xy1 + float2 (TxtPosX, TxtPosY);

   float y = 1.0 - Bar_Y + uv.y;

   float4 bar = EMPTY, Fgd = EMPTY;

   if (fn_legal (xy1)) {
      uv = xy1 - uv;
      bar = fn_legal (uv) ? tex2D (s_Bar, uv) : EMPTY;
      Fgd = xy1.y < y ? tex2D (s_Input_1, xy) : EMPTY;

      if (TxtAlpha == 1) Fgd.a = pow (Fgd.a, 0.5);

      Fgd = lerp (Fgd, bar, bar.a);
   }

   return lerp (tex2D (s_Input_2, xy2), Fgd, Fgd.a * Opacity);
}

float4 ps_main_1 (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float trans_1 = 1.0 - min (1.0, Transition * 5.0 / 3.0);
   float trans_2 = 1.0 - max (0.0, (Transition * 4.0) - 3.0);

   float2 uv = float2 (BarPosX * trans_1, -BarPosY * trans_2);
   float2 xy = xy1 + float2 (TxtPosX, TxtPosY);

   float y = 1.0 - Bar_Y + uv.y;

   float4 bar = EMPTY, Fgd = EMPTY;

   if (fn_legal (xy1)) {
      uv = xy1 - uv;
      bar = fn_legal (uv) ? tex2D (s_Bar, uv) : EMPTY;
      Fgd = xy1.y > y ? tex2D (s_Input_1, xy) : EMPTY;
 
      if (TxtAlpha == 1) Fgd.a = pow (Fgd.a, 0.5);

     Fgd = lerp (Fgd, bar, bar.a);
   }

   return lerp (tex2D (s_Input_2, xy2), Fgd, Fgd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Lower3rd_A_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bar;"; > 
   { PixelShader = compile PROFILE ps_bar (); }

   pass P_2 { PixelShader = compile PROFILE ps_main_0 (); }
}

technique Lower3rd_A_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bar;"; > 
   { PixelShader = compile PROFILE ps_bar (); }

   pass P_2 { PixelShader = compile PROFILE ps_main_1 (); }
}
