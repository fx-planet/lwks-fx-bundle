// @Maintainer jwrl
// @Released 2018-05-31
// @Author jwrl
// @Created 2018-03-15
// @see https://www.lwks.com/media/kunena/attachments/6375/Lower3rdD_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdD_1.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/LowerthirdD_2.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rd_D.fx
//
// This effect pushes a text block on from the edge of frame to reveal the lower third
// text.  The block has a coloured edge which can be adjusted in widthe, and which
// vanishes as the block reaches its final position.
//
// Modified by LW user jwrl 16 March 2018
// Cosmetic change only: "Transition" has been moved to the top of the parameters,
// giving it higher priority than "Opacity".
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Bugfix 31 May 2018 jwrl.
// Corrected X direction sense of TxtPosX.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lower third D";
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

sampler s_Input_2 = sampler_state { Texture = <In_2>; };

sampler s_Ribbon = sampler_state
{
   Texture   = <Ribn>;
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
   string Description = "Direction";
   string Enum = "Bottom up,Top down,Left to right,Right to left";
> = 0;

int Masking
<
   string Description = "Masking";
   string Enum = "Show text and edge for setup,Mask controlled by transition";
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
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float TxtPosY
<
   string Group = "Text setting";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float BlockLimit
<
   string Group = "Block setting";
   string Description = "Limit of travel";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float BlockCrop_A
<
   string Group = "Block setting";
   string Description = "Crop A";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.08;

float BlockCrop_B
<
   string Group = "Block setting";
   string Description = "Crop B";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.35;

float4 BlockColour
<
   string Group = "Block setting";
   string Description = "Fill colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.98, 0.9, 1.0 };

float EdgeWidth
<
   string Group = "Edge setting";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 EdgeColour
<
   string Group = "Edge setting";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.73, 0.51, 0.84, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY   (0.0).xxxx

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//
// This function returns true if any of xy is outside 0.0-1.0.
//-----------------------------------------------------------------------------------------//

bool fn_illegal (float2 xy)
{
   return (xy.x < 0.0) || (xy.x > 1.0) || (xy.y < 0.0) || (xy.y > 1.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_block (float2 uv : TEXCOORD0) : COLOR
{
   float limit = 1.0 - (BlockLimit * 0.32);
   float width = limit - (EdgeWidth * 0.125);

   if ((uv.x < BlockCrop_A) || (uv.x > BlockCrop_B) || (uv.y < width)) return EMPTY;

   return uv.y < limit ? EdgeColour : BlockColour;
}

float4 ps_main_V1 (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float trans = 0.995 - sin (Transition * HALF_PI);
   float mask  = BlockLimit * 0.32;
   float range = ((EdgeWidth * 0.125) + mask) * trans;

   float2 uv = xy1;
   float2 xy = xy1 - float2 (TxtPosX, range - TxtPosY);

   mask  = (Masking == 0) ? 0.0 : 1.0 - mask;
   uv.y -= range;

   float4 L3rd = (xy2.y < mask) || fn_illegal (uv) ? EMPTY : tex2D (s_Ribbon, uv);
   float4 Fgnd = fn_illegal (xy) ? EMPTY : tex2D (s_Input_1, xy);

   if (TxtAlpha == 1) Fgnd.a = pow (Fgnd.a, 0.5);

   Fgnd = lerp (L3rd, Fgnd, Fgnd.a);

   return lerp (tex2D (s_Input_2, xy2), Fgnd, Fgnd.a * Opacity);
}

float4 ps_main_V2 (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float trans = 0.995 - sin (Transition * HALF_PI);
   float mask  = BlockLimit * 0.32;
   float range = ((EdgeWidth * 0.125) + mask) * trans;

   float2 uv = float2 (xy1.x, 1.0 - xy1.y - range);
   float2 xy = xy1 + float2 (-TxtPosX, TxtPosY + range);

   mask = (Masking == 0) ? 1.0 : mask - 0.001;

   float4 L3rd = (xy2.y > mask) || fn_illegal (uv) ? EMPTY : tex2D (s_Ribbon, uv);
   float4 Fgnd = fn_illegal (xy) ? EMPTY : tex2D (s_Input_1, xy);

   if (TxtAlpha == 1) Fgnd.a = pow (Fgnd.a, 0.5);

   Fgnd = lerp (L3rd, Fgnd, Fgnd.a);

   return lerp (tex2D (s_Input_2, xy2), Fgnd, Fgnd.a * Opacity);
}

float4 ps_main_H1 (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float trans = 0.995 - sin (Transition * HALF_PI);
   float mask  = BlockLimit * 0.32;
   float range = ((EdgeWidth * 0.125) + mask) * trans;

   float2 uv = float2 (xy1.y, 1.0 - xy1.x - range);
   float2 xy = xy1 - float2 (TxtPosX + range, -TxtPosY);

   mask = (Masking == 0) ? 1.0 : mask - 0.001;

   float4 L3rd = (xy2.x > mask) || fn_illegal (uv) ? EMPTY : tex2D (s_Ribbon, uv);
   float4 Fgnd = (xy1.x > mask) || fn_illegal (xy) ? EMPTY : tex2D (s_Input_1, xy);

   if (TxtAlpha == 1) Fgnd.a = pow (Fgnd.a, 0.5);

   Fgnd = lerp (L3rd, Fgnd, Fgnd.a);

   return lerp (tex2D (s_Input_2, xy2), Fgnd, Fgnd.a * Opacity);
}

float4 ps_main_H2 (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float trans = 0.995 - sin (Transition * HALF_PI);
   float mask  = BlockLimit * 0.32;
   float range = ((EdgeWidth * 0.125) + mask) * trans;

   float2 uv = xy1.yx;
   float2 xy = xy1 + float2 (range - TxtPosX, TxtPosY);

   mask  = (Masking == 0) ? 0.0 : 1.0 - mask;
   uv.y -= range;

   float4 L3rd = (xy2.x < mask) || fn_illegal (uv) ? EMPTY : tex2D (s_Ribbon, uv);
   float4 Fgnd = (xy1.x < mask) || fn_illegal (xy) ? EMPTY : tex2D (s_Input_1, xy);

   if (TxtAlpha == 1) Fgnd.a = pow (Fgnd.a, 0.5);

   Fgnd = lerp (L3rd, Fgnd, Fgnd.a);

   return lerp (tex2D (s_Input_2, xy2), Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Lower3rd_D_V1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Ribn;"; > 
   { PixelShader = compile PROFILE ps_block (); }

   pass P_2 { PixelShader = compile PROFILE ps_main_V1 (); }
}

technique Lower3rd_D_V2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Ribn;"; > 
   { PixelShader = compile PROFILE ps_block (); }

   pass P_2 { PixelShader = compile PROFILE ps_main_V2 (); }
}

technique Lower3rd_D_H1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Ribn;"; > 
   { PixelShader = compile PROFILE ps_block (); }

   pass P_2 { PixelShader = compile PROFILE ps_main_H1 (); }
}

technique Lower3rd_D_H2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Ribn;"; > 
   { PixelShader = compile PROFILE ps_block (); }

   pass P_2 { PixelShader = compile PROFILE ps_main_H2 (); }
}
