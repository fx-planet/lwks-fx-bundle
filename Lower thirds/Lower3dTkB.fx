//--------------------------------------------------------------//
// Lightworks user effect Lower3dTkB.fx
// Created by LW user jwrl 15 March 2018
//
// This is a general purpose toolkit designed to build lower
// thirds.  It's designed to create an edged, coloured ribbon
// gradient with an overlaid floating bordered flat colour box.
// Any component can be completely hidden if required and all
// are fully adjustable.
//
// This is a three input effect.  It uses In1 for an optional
// logo or other graphical component, In2 for optional text
// and Bgd as a background-only layer.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower 3rd toolkit B";
   string Category    = "Text";
   string SubCategory = "Lower Third Tools";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture In1;
texture In2;
texture Bgd;

texture Ribn : RenderColorTarget;
texture Comp : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler s_Input_1 = sampler_state
{
   Texture   = <In1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Input_2 = sampler_state
{
   Texture   = <In2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Composite = sampler_state
{
   Texture   = <Comp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Ribbon = sampler_state
{
   Texture   = <Ribn>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int SetTechnique
<
   string Group = "Text settings";
   string Description = "Text source";
   string Enum = "Before / Using In1 for logo and In2 for text,Before / Using In1 for text and In2 for background,After / Using In1 for logo and In2 for background,After this effect - use In1 as only source";
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

float LogoSize
<
   string Group = "Logo settings";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float LogoPosX
<
   string Group = "Logo settings";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float LogoPosY
<
   string Group = "Logo settings";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

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

float RibbonY
<
   string Group = "Ribbon";
   string Description = "Vertical position";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.15;

float4 RibbonColourA
<
   string Group = "Ribbon";
   string Description = "Left colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float4 RibbonColourB
<
   string Group = "Ribbon";
   string Description = "Right colour";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 1.0, 0.0 };

float TbarWidth
<
   string Group = "Upper line";
   string Description = "Width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.33333333;

float TbarL
<
   string Group = "Upper line";
   string Description = "Crop left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float TbarR
<
   string Group = "Upper line";
   string Description = "Crop right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float4 TbarColour
<
   string Group = "Upper line";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.11, 0.11, 0.52, 1.0 };

float BbarWidth
<
   string Group = "Lower line";
   string Description = "Width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.33333333;

float BbarL
<
   string Group = "Lower line";
   string Description = "Crop left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float BbarR
<
   string Group = "Lower line";
   string Description = "Crop right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float4 BbarColour
<
   string Group = "Lower line";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.07, 0.33, 0.33, 1.0 };

bool BarGrad
<
   string Group = "Lower line";
   string Description = "Use line colours as gradients for both lines";
> = false;

float BoxWidth
<
   string Group = "Inset box";
   string Description = "Width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float BoxHeight
<
   string Group = "Inset box";
   string Description = "Height";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float BoxLine
<
   string Group = "Inset box";
   string Description = "Border width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float Box_X
<
   string Group = "Inset box";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Box_Y
<
   string Group = "Inset box";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float4 BoxColourA
<
   string Group = "Inset box";
   string Description = "Line colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

float4 BoxColourB
<
   string Group = "Inset box";
   string Description = "Fill colour";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 0.0, 1.0 };

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

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define EMPTY   (0.0).xxxx

float _OutputAspectRatio;

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

float4 ps_ribbon (float2 uv : TEXCOORD0) : COLOR
{
   float4 retval = EMPTY;

   float colour_grad, length;
   float width  = 0.01 + (RibbonWidth * 0.25);

   float2 xy1 = float2 (RibbonL, 1.0 - RibbonY - (width * 0.5));
   float2 xy3, xy2 = float2 (RibbonR, xy1.y + width);

   if (fn_inRange (uv, float4 (xy1, xy2))) {
      length = max (0.0, RibbonR - RibbonL);
      colour_grad = max (uv.x - RibbonL, 0.0) / length;
      retval = lerp (RibbonColourA, RibbonColourB, colour_grad);
   }

   float y = xy1.y - (TbarWidth * 0.02);

   if (fn_inRange (uv, float4 (TbarL, y, TbarR, xy1.y))) {
      if (BarGrad) {
         length = max (0.0, TbarR - TbarL);
         colour_grad = max (uv.x - TbarL, 0.0) / length;
         retval = lerp (TbarColour, BbarColour, colour_grad);
      }
      else retval = TbarColour;
   }

   y = xy2.y + (BbarWidth * 0.02);

   if (fn_inRange (uv, float4 (BbarL, xy2.y, BbarR, y))) {
      if (BarGrad) {
         length = max (0.0, BbarR - BbarL);
         colour_grad = max (uv.x - BbarL, 0.0) / length;
         retval = lerp (TbarColour, BbarColour, colour_grad);
      }
      else retval = BbarColour;
   }

   xy2  = float2 (Box_X, 1.0 - Box_Y);
   xy3  = float2 (BoxWidth, BoxHeight * _OutputAspectRatio) * 0.1;
   xy1  = xy2 - xy3;
   xy2 += xy3;

   if (fn_inRange (uv, float4 (xy1, xy2))) retval = BoxColourA;

   xy3  = float2 (1.0, _OutputAspectRatio) * BoxLine * 0.012;
   xy1 += xy3;
   xy2 -= xy3;

   if (fn_inRange (uv, float4 (xy1, xy2))) return BoxColourB;

   return retval;
}

float4 ps_comp_0 (float2 uv : TEXCOORD1) : COLOR
{
   float size = max (0.00001, LogoSize);

   float2 xy1 = ((uv - 0.5.xx) / size) - float2 (LogoPosX, -LogoPosY) + 0.5.xx;
   float2 xy2 = uv - float2 (TxtPosX, -TxtPosY);

   float4 Logo = fn_legal (xy1) ? tex2D (s_Input_1, xy1) : EMPTY;
   float4 Text = fn_legal (xy2) ? tex2D (s_Input_2, xy2) : EMPTY;

   if (TxtAlpha == 1) Text.a = pow (Text.a, 0.5);

   float4 Fgnd = lerp (tex2D (s_Ribbon, uv), Text, Text.a);

   return lerp (Fgnd, Logo, Logo.a);
}

float4 ps_comp_1 (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - float2 (TxtPosX, -TxtPosY);

   float4 Text = fn_legal (xy) ? tex2D (s_Input_1, xy) : EMPTY;

   if (TxtAlpha == 1) Text.a = pow (Text.a, 0.5);

   return lerp (tex2D (s_Ribbon, uv), Text, Text.a);
}

float4 ps_comp_2 (float2 uv : TEXCOORD1) : COLOR
{
   float size = max (0.001, LogoSize);

   float2 xy = ((uv - 0.5.xx) / size) - float2 (LogoPosX, -LogoPosY) + 0.5.xx;

   float4 Logo = fn_legal (xy) ? tex2D (s_Input_1, xy) : EMPTY;

   return lerp (tex2D (s_Ribbon, uv), Logo, Logo.a);
}

float4 ps_comp_3 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (s_Ribbon, uv);
}

float4 ps_main_0 (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = (uv - float2 (0.5, 0.5)) / max (0.000001, MasterScale * 2.0);

   xy += float2 (0.5 - Master_X, 0.5 + Master_Y);

   float4 Fgnd = fn_legal (xy) ? tex2D (s_Composite, xy) : EMPTY;

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Opacity);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = (uv - float2 (0.5, 0.5)) / max (0.000001, MasterScale * 2.0);

   xy += float2 (0.5 - Master_X, 0.5 + Master_Y);

   float4 Fgnd = fn_legal (xy) ? tex2D (s_Composite, xy) : EMPTY;

   return lerp (tex2D (s_Input_2, uv), Fgnd, Fgnd.a * Opacity);
}

float4 ps_main_3 (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = (uv - float2 (0.5, 0.5)) / max (0.000001, MasterScale * 2.0);

   xy += float2 (0.5 - Master_X, 0.5 + Master_Y);

   float4 Fgnd = fn_legal (xy) ? tex2D (s_Composite, xy) : EMPTY;

   return lerp (tex2D (s_Input_1, uv), Fgnd, Fgnd.a * Opacity);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique L3rdTb_B_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Ribn;"; > 
   { PixelShader = compile PROFILE ps_ribbon (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Comp;"; > 
   { PixelShader = compile PROFILE ps_comp_0 (); }

   pass P_3 { PixelShader = compile PROFILE ps_main_0 (); }
}

technique L3rdTb_B_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Ribn;"; > 
   { PixelShader = compile PROFILE ps_ribbon (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Comp;"; > 
   { PixelShader = compile PROFILE ps_comp_1 (); }

   pass P_3 { PixelShader = compile PROFILE ps_main_1 (); }
}

technique L3rdTb_B_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Ribn;"; > 
   { PixelShader = compile PROFILE ps_ribbon (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Comp;"; > 
   { PixelShader = compile PROFILE ps_comp_2 (); }

   pass P_3 { PixelShader = compile PROFILE ps_main_1 (); }
}

technique L3rdTb_B_3
{
   pass P_1
   < string Script = "RenderColorTarget0 = Ribn;"; > 
   { PixelShader = compile PROFILE ps_ribbon (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Comp;"; > 
   { PixelShader = compile PROFILE ps_comp_3 (); }

   pass P_3 { PixelShader = compile PROFILE ps_main_3 (); }
}

