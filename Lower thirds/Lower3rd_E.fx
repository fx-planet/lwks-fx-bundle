//--------------------------------------------------------------//
// Lightworks user effect Lower3rd_E.fx
// Created by LW user jwrl 15 March 2018
// @Author: jwrl
// @CreationDate: "15 March 2018"
//
// This effect does a page turn type of text overlay over a
// standard ribbon with adjustable opacity.  The direction of
// the page turn can be set to wipe on or wipe off.  "Wipe on"
// gives a left > right transition, and "Wipe off" reverses it. 
//
// Modified by LW user jwrl 16 March 2018
// Cosmetic change only: "Transition" has been moved to the
// top of the parameters, giving it higher priority than
// "Opacity".
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third E";
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

float TxtDistort
<
   string Group = "Text settings";
   string Description = "Distortion";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float TxtRipple
<
   string Group = "Text settings";
   string Description = "Ripple amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

int SetTechnique
<
   string Group = "Text settings";
   string Description = "Effect direction";
   string Enum = "Wipe on,Wipe off";
> = 0;

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
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.5;

float RibbonOpacity_TR
<
   string Group = "Ribbon opacity";
   string Description = "Upper right";
   float MinVal = -1.00;
   float MaxVal = 1.00;
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

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05

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
   float range  = max (0.0, TxtDistort * SOFTNESS) + OFFSET;
   float T_Axis = uv.y - RibbonY;
   float maxVis = range + uv.x - (TransRange * Transition * (1.0 + range));

   float amount = saturate (maxVis / range);
   float ripple = max (0.0, RIPPLES * maxVis);
   float width  = (0.01 + (RibbonWidth * 0.25));

   float modulate = pow (max (0.0, TxtRipple), 5.0) * ripple;

   float offset = sin (modulate) * ripple * width;
   float twists = cos (modulate * 4.0);

   float2 xy = float2 (uv.x, RibbonY + (T_Axis / twists) - offset);

   float4 Txt = fn_illegal (xy) ? EMPTY : lerp (tex2D (s_TextProc, xy), EMPTY, amount);
   float4 Bgd = tex2D (s_Background, uv);

   float2 xy1 = float2 (RibbonL, 1.0 - RibbonY - (width * 0.5));
   float2 xy2 = float2 (RibbonR, xy1.y + width);

   if (fn_outRange (uv, float4 (xy1, xy2)))
      return lerp (Bgd, Txt, Txt.a * Opacity);

   float length = max (0.0, RibbonR - RibbonL);
   float grad   = max (uv.x - RibbonL, 0.0) / length;

   float alpha_1 = lerp (RibbonOpacity_TL, RibbonOpacity_TR, grad);
   float alpha_2 = lerp (RibbonOpacity_BL, RibbonOpacity_BR, grad);

   grad = (uv.y - xy1.y) / width;

   float alpha = max (0.0, lerp (alpha_1, alpha_2, grad));

   float4 Fgd = lerp (float4 (RibbonColour.rgb, alpha), Txt, Txt.a);

   return lerp (Bgd, Fgd, Fgd.a * Opacity);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float range  = max (0.0, TxtDistort * SOFTNESS) + OFFSET;
   float minVis = TransRange * (1.0 - Transition) * (1.0 + range) - uv.x;
   float T_Axis = uv.y - RibbonY;
   float maxVis = range - minVis;

   float amount = saturate (maxVis / range);
   float ripple = max (0.0, RIPPLES * minVis);
   float width  = (0.01 + (RibbonWidth * 0.25));

   float modulate = pow (max (0.0, TxtRipple), 5.0) * ripple;

   float offset = sin (modulate) * ripple * width;
   float twists = cos (modulate * 4.0);

   float2 xy = float2 (uv.x, RibbonY + (T_Axis / twists) - offset);

   float4 Txt = fn_illegal (xy) ? EMPTY : lerp (EMPTY, tex2D (s_TextProc, xy), amount);
   float4 Bgd = tex2D (s_Background, uv);

   float2 xy1 = float2 (RibbonL, 1.0 - RibbonY - (width * 0.5));
   float2 xy2 = float2 (RibbonR, xy1.y + width);

   if (fn_outRange (uv, float4 (xy1, xy2)))
      return lerp (Bgd, Txt, Txt.a * Opacity);

   float length = max (0.0, RibbonR - RibbonL);
   float grad   = max (uv.x - RibbonL, 0.0) / length;

   float alpha_1 = lerp (RibbonOpacity_TL, RibbonOpacity_TR, grad);
   float alpha_2 = lerp (RibbonOpacity_BL, RibbonOpacity_BR, grad);

   grad = (uv.y - xy1.y) / width;

   float alpha = max (0.0, lerp (alpha_1, alpha_2, grad));

   float4 Fgd = lerp (float4 (RibbonColour.rgb, alpha), Txt, Txt.a);

   return lerp (Bgd, Fgd, Fgd.a * Opacity);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Lower3rd_E_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Text;"; > 
   { PixelShader = compile PROFILE ps_text_pos (); }

   pass P_2 { PixelShader = compile PROFILE ps_main_0 (); }
}

technique Lower3rd_E_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Text;"; > 
   { PixelShader = compile PROFILE ps_text_pos (); }

   pass P_2 { PixelShader = compile PROFILE ps_main_1 (); }
}

