// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2018-04-04
// @see https://www.lwks.com/media/kunena/attachments/6375/DX_Slice_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Slice.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_Slice.fx
//
// This transition splits the outgoing image into strips which then move off either
// horizontally or vertically to reveal the incoming image.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Slice transition";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fgd;
texture Bgd;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fgd>;
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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Mode
<
   string Description = "Strip type";
   string Enum = "Mode A,Mode B";
> = 0;

int SetTechnique
<
   string Description = "Strip direction";
   string Enum = "Right to left,Left to right,Top to bottom,Bottom to top";
> = 1;

float StripNumber
<
   string Description = "Strip number";
   float MinVal = 5.0;
   float MaxVal = 20.0;
> = 10.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY  (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool fn_islegal (float2 uv)
{
   return (uv.x >= 0.0) && (uv.y >= 0.0) && (uv.x <= 1.0) && (uv.y <= 1.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_right (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float strips   = max (2.0, round (StripNumber));
   float amount_1 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);
   float amount_2 = pow (Amount, 3.0);

   float2 uv = xy1;

   uv.x += (Mode == 1) ? (ceil (uv.y * strips) * amount_1) + amount_2
                       : (ceil ((1.0 - uv.y) * strips) * amount_1) + amount_2;

   float4 Fgnd = fn_islegal (uv) ? tex2D (s_Foreground, uv) : EMPTY;

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

float4 ps_left (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float strips   = max (2.0, round (StripNumber));
   float amount_1 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);
   float amount_2 = pow (Amount, 3.0);

   float2 uv = xy1;

   uv.x -= (Mode == 1) ? (ceil (uv.y * strips) * amount_1) + amount_2
                       : (ceil ((1.0 - uv.y) * strips) * amount_1) + amount_2;

   float4 Fgnd = fn_islegal (uv) ? tex2D (s_Foreground, uv) : EMPTY;

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

float4 ps_top (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float strips   = max (2.0, round (StripNumber));
   float amount_1 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);
   float amount_2 = pow (Amount, 3.0);

   float2 uv = xy1;

   uv.y -= (Mode == 1) ? (ceil (uv.x * strips) * amount_1) + amount_2
                       : (ceil ((1.0 - uv.x) * strips) * amount_1) + amount_2;

   float4 Fgnd = fn_islegal (uv) ? tex2D (s_Foreground, uv) : EMPTY;

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

float4 ps_bottom (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float strips   = max (2.0, round (StripNumber));
   float amount_1 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);
   float amount_2 = pow (Amount, 3.0);

   float2 uv = xy1;

   uv.y += (Mode == 1) ? (ceil (uv.x * strips) * amount_1) + amount_2
                       : (ceil ((1.0 - uv.x) * strips) * amount_1) + amount_2;

   float4 Fgnd = fn_islegal (uv) ? tex2D (s_Foreground, uv) : EMPTY;

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dx_Slice_Left
{
   pass P_1
   { PixelShader = compile PROFILE ps_right (); }
}

technique Dx_Slice_Right
{
   pass P_1
   { PixelShader = compile PROFILE ps_left (); }
}

technique Dx_Slice_Top
{
   pass P_1
   { PixelShader = compile PROFILE ps_top (); }
}

technique Dx_Slice_Bottom
{
   pass P_1
   { PixelShader = compile PROFILE ps_bottom (); }
}

