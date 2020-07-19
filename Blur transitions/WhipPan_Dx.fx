// @Maintainer jwrl
// @Released 2020-07-19
// @Author jwrl
// @Created 2020-07-19
// @see https://www.lwks.com/media/kunena/attachments/6375/WhipPan_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/WhipPan.mp4

/**
 This effect performs a whip pan style transition between two sources.  Unlike the blur
 dissolve effect, this also pans the incoming and outgoing vision sources.  It also is
 limited to vertical and horizontal whips only.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhipPan_Dx.fx
//
// Version history:
//
// Built 2020-07-19 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Whip pan";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Uses a directional blur to simulate a whip pan between two sources";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Inp : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{ 
   Texture   = <Fg>;
   AddressU  = Wrap;
   AddressV  = Wrap;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Wrap;
   AddressV  = Wrap;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Input = sampler_state
{ 
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Whip direction";
   string Enum = "Left to right,Right to left,Top to bottom,Bottom to top";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define L_R       0
#define R_L       1
#define T_B       2
#define B_T       3

#define HORIZ     true
#define VERT      false

#define PI        3.1415926536

#define SAMPLES   60
#define SAMPSCALE 61.0

#define STRENGTH  0.005

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_preset (float2 uv : TEXCOORD1, uniform int path) : COLOR
{
   float amount = 1.5 - (cos (Amount * PI) * 1.5);
   float Mix    = saturate (amount - 1.0);

   float2 xy = (path == L_R) ? uv - float2 (amount, 0.0)
             : (path == R_L) ? uv + float2 (amount, 0.0)
             : (path == T_B) ? uv - float2 (0.0, amount) : uv + float2 (0.0, amount);

   return lerp (tex2D (s_Foreground, xy), tex2D (s_Background, xy), Mix);
}

float4 ps_main (float2 uv : TEXCOORD1, uniform bool mode) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   float amount = 1.0 - cos (clamp ((0.5 - abs (Amount - 0.5)) * 4.0, 0.0, 0.5) * PI);

   if ((amount == 0.0) || (Strength <= 0.0)) return retval;

   float2 xy1 = uv;
   float2 xy2 = mode ? float2 (amount, 0.0) : float2 (0.0, amount * _OutputAspectRatio);

   xy2 *= Strength * STRENGTH;

   for (int i = 0; i < SAMPLES; i++) {
      retval += tex2D (s_Input, xy1);
      xy1 -= xy2;
   }

   return retval / SAMPSCALE;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WhipPan_Dx_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Inp;"; >
   { PixelShader = compile PROFILE ps_preset (L_R); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (HORIZ); }
}

technique WhipPan_Dx_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Inp;"; >
   { PixelShader = compile PROFILE ps_preset (R_L); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (HORIZ); }
}

technique WhipPan_Dx_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Inp;"; >
   { PixelShader = compile PROFILE ps_preset (T_B); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (VERT); }
}

technique WhipPan_Dx_3
{
   pass P_1
   < string Script = "RenderColorTarget0 = Inp;"; >
   { PixelShader = compile PROFILE ps_preset (B_T); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (VERT); }
}

