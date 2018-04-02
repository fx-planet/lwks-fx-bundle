// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Lower3rd_F.fx
// Created by LW user jwrl 17 March 2018
// @Author jwrl
// @CreationDate "17 March 2018"
//
// This effect does a twist of a text overlay over a standard
// ribbon with adjustable opacity.  The direction of the twist
// can be set to wipe on or wipe off.  "Wipe on" gives a left
// to right transition on, and "Wipe off" gives a left to right
// transition off.  As a result when setting the transition
// range in "Wipe off" it's necessary to set the transition to
// zero, unlike the usual 100%.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third F";
   string Category    = "Text";
   string SubCategory = "Lower Third Tools";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture In1;
texture In2;

texture Text : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler s_Text = sampler_state
{
   Texture   = <In1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <In2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_TextProc = sampler_state
{
   Texture   = <Text>;
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

float TransRange
<
   string Group = "Set this so the effect just ends when Transition reaches 100%";
   string Description = "Transition range";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

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
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float TxtPosY
<
   string Group = "Text settings";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

int SetTechnique
<
   string Group = "Twist settings";
   string Description = "Direction";
   string Enum = "Wipe on,Wipe off";
> = 0;

float TwistAmount
<
   string Group = "Twist settings";
   string Description = "Amount";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float TwistSoft
<
   string Group = "Twist settings";
   string Description = "Softness";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float RibbonWidth
<
   string Group = "Ribbon settings";
   string Description = "Width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.33333333;

float RibbonL
<
   string Group = "Ribbon settings";
   string Description = "Crop left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float RibbonR
<
   string Group = "Ribbon settings";
   string Description = "Crop right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float RibbonY
<
   string Group = "Ribbon settings";
   string Description = "Vertical position";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.15;

float4 RibbonColour
<
   string Group = "Ribbon settings";
   string Description = "Colour";
> = { 0.0, 0.0, 1.0, 0.0 };

float RibbonOpacity_TL
<
   string Group = "Ribbon opacity";
   string Description = "Upper left";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.75;

float RibbonOpacity_BL
<
   string Group = "Ribbon opacity";
   string Description = "Lower left";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

float RibbonOpacity_TR
<
   string Group = "Ribbon opacity";
   string Description = "Upper right";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float RibbonOpacity_BR
<
   string Group = "Ribbon opacity";
   string Description = "Lower right";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = -0.25;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define TWISTS   4.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define MODULATE 10.0

#define R_WIDTH  0.125
#define R_LIMIT  0.005

#define EMPTY    (0.0).xxxx

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//
// These two functions are designed as replacements for all ()
// and any ().  fn_outRange (xy, range) returns false if all of
// xy falls inside range.xy - range.zw, while fn_illegal (xy)
// returns false if all of xy is inside 0.0 - 1.0 inclusive.
//--------------------------------------------------------------//

bool fn_outRange (float2 xy, float4 range)
{
   return ((xy.x < range.x) || (xy.y < range.y)
         || (xy.x > range.z) || (xy.y > range.w));
}

bool fn_illegal (float2 xy)
{
   return ((xy.x < 0.0) || (xy.x > 1.0)
          || (xy.y < 0.0) || (xy.y > 1.0));
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_text_pos (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - float2 (TxtPosX, -TxtPosY);

   if (fn_illegal (xy)) return EMPTY;

   float4 Txt = tex2D (s_Text, xy);

   return float4 (Txt.rgb, (TxtAlpha == 0) ? Txt.a : pow (Txt.a, 0.5));
}

float4 ps_main_0 (float2 uv : TEXCOORD1) : COLOR
{
   float ribbon = 1.0 - RibbonY;
   float range  = max (0.0, TwistSoft * SOFTNESS) + OFFSET;
   float maxVis = (Transition * (range + 1.0) * TransRange) - uv.x;
   float T_Axis = uv.y - ribbon;

   float amount = saturate (maxVis / range);
   float modltn = max (0.0, MODULATE * (range - maxVis));
   float twists = cos (modltn * TwistAmount * TWISTS);

   float2 xy = float2 (uv.x, ribbon + (T_Axis / twists));

   float4 Bgd = tex2D (s_Background, uv);
   float4 Txt = fn_illegal (xy) ? EMPTY : lerp (EMPTY, tex2D (s_TextProc, xy), amount);

   float width = max (RibbonWidth * R_WIDTH, R_LIMIT);

   float2 xy1 = float2 (RibbonL, ribbon - width);
   float2 xy2 = float2 (RibbonR, ribbon + width);

   if (fn_outRange (uv, float4 (xy1, xy2)))
      return lerp (Bgd, Txt, Txt.a * Opacity);

   float length = max (0.0, RibbonR - RibbonL);
   float grad_H = max (uv.x - RibbonL, 0.0) / length;
   float grad_V = (uv.y - xy1.y) / (width * 2.0);

   float alpha   = lerp (RibbonOpacity_TL, RibbonOpacity_TR, grad_H);
   float alpha_1 = lerp (RibbonOpacity_BL, RibbonOpacity_BR, grad_H);

   alpha = max (0.0, lerp (alpha, alpha_1, grad_V));

   float4 Fgd = lerp (float4 (RibbonColour.rgb, alpha), Txt, Txt.a);

   return lerp (Bgd, Fgd, Fgd.a * Opacity);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float ribbon = 1.0 - RibbonY;
   float range  = max (0.0, TwistSoft * SOFTNESS) + OFFSET;
   float maxVis = uv.x + range + ((Transition - 1.0) * (range + 1.0) * TransRange);
   float T_Axis = uv.y - ribbon;

   float amount = saturate (maxVis / range);
   float modltn = max (0.0, MODULATE * (range - maxVis));
   float twists = cos (modltn * TwistAmount * TWISTS);

   float2 xy = float2 (uv.x, ribbon + (T_Axis / twists));

   float4 Bgd = tex2D (s_Background, uv);
   float4 Txt = fn_illegal (xy) ? EMPTY : lerp (EMPTY, tex2D (s_TextProc, xy), amount);

   float width = max (RibbonWidth * R_WIDTH, R_LIMIT);

   float2 xy1 = float2 (RibbonL, ribbon - width);
   float2 xy2 = float2 (RibbonR, ribbon + width);

   if (fn_outRange (uv, float4 (xy1, xy2)))
      return lerp (Bgd, Txt, Txt.a * Opacity);

   float length = max (0.0, RibbonR - RibbonL);
   float grad_H = max (uv.x - RibbonL, 0.0) / length;
   float grad_V = (uv.y - xy1.y) / (width * 2.0);

   float alpha   = lerp (RibbonOpacity_TL, RibbonOpacity_TR, grad_H);
   float alpha_1 = lerp (RibbonOpacity_BL, RibbonOpacity_BR, grad_H);

   alpha = max (0.0, lerp (alpha, alpha_1, grad_V));

   float4 Fgd = lerp (float4 (RibbonColour.rgb, alpha), Txt, Txt.a);

   return lerp (Bgd, Fgd, Fgd.a * Opacity);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Lower3rd_F_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Text;"; > 
   { PixelShader = compile PROFILE ps_text_pos (); }

   pass P_2 { PixelShader = compile PROFILE ps_main_0 (); }
}

technique Lower3rd_F_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Text;"; > 
   { PixelShader = compile PROFILE ps_text_pos (); }

   pass P_2 { PixelShader = compile PROFILE ps_main_1 (); }
}

