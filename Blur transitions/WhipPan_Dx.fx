// @Maintainer jwrl
// @Released 2021-06-11
// @Author jwrl
// @Created 2021-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/WhipPan_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/WhipPan.mp4

/**
 This effect performs a whip pan style of transition between two sources.  Unlike the
 blur dissolve effect, this also pans the incoming and outgoing vision sources.  It's
 limited to vertical and horizontal whips, so if you need an angled whip your only
 option is to use the blur dissolve.

 To better handle varying aspect ratios masking has been provided to limit the blur
 range to the input frame boundaries.  This changes as the effect progresses to allow
 for differing incoming and outgoing media aspect ratios.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhipPan_Dx.fx
//
// Version history:
//
// Complete rebuild 2021-06-11 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Whip pan";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Uses a directional blur to simulate a whip pan between two sources";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define EMPTY 0.0.xxxx

#define IsOutOfBounds(XY) any(saturate(XY) - XY)

#define DeclareInput( TEXTURE, SAMPLER ) \
                                         \
   texture TEXTURE;                      \
                                         \
   sampler SAMPLER = sampler_state       \
   {                                     \
      Texture   = <TEXTURE>;             \
      AddressU  = Mirror;                \
      AddressV  = Mirror;                \
      MinFilter = Linear;                \
      MagFilter = Linear;                \
      MipFilter = Linear;                \
   }

#define CompileShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define PI        3.1415926536

#define STRENGTH  0.005

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg, s_Foreground);
DeclareInput (Bg, s_Background);

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
// Functions
//-----------------------------------------------------------------------------------------//

float fn_mix (float2 xy1, float2 xy2, out float Mask, out float Whip)
{
   float Fkey = IsOutOfBounds (xy1);
   float Bkey = IsOutOfBounds (xy2);

   Mask = lerp (Fkey, Bkey, Amount);
   Whip = 1.5 - (cos (Amount * PI) * 1.5);

   return saturate (Whip - 1.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_L_R (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float mask, whip;
   float Mix = fn_mix (uv1, uv2, mask, whip);

   float2 xy1 = float2 (-whip, 0.0);
   float2 xy2 = float2 (1.0 + uv2.x, uv2.y) + xy1;

   xy1 += uv1;

   float4 retval = tex2D (s_Foreground, xy1);

   float amount = 1.0 - cos (clamp ((0.5 - abs (Amount - 0.5)) * 4.0, 0.0, 0.5) * PI);

   if ((amount > 0.0) && (Strength > 0.0)) {

      float4 Bgnd = tex2D (s_Background, xy2);
      float4 Fgnd = retval;

      float2 xy0 = float2 (amount * Strength * STRENGTH, 0.0);

      for (int i = 0; i < 60; i++) {
         xy1 += xy0;
         xy2 -= xy0;
         Fgnd += tex2D (s_Foreground, xy1);
         Bgnd += tex2D (s_Background, xy2);
      }

      retval = lerp (Fgnd, Bgnd, Mix) / 61;
   }

   return lerp (retval, EMPTY, mask);
}

float4 ps_main_R_L (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float mask, whip;
   float Mix = fn_mix (uv1, uv2, mask, whip);

   float2 xy1 = float2 (whip, 0.0);
   float2 xy2 = float2 (1.0 + uv2.x, uv2.y) + xy1;

   xy1 += uv1;

   float4 retval = tex2D (s_Foreground, xy1);

   float amount = 1.0 - cos (clamp ((0.5 - abs (Amount - 0.5)) * 4.0, 0.0, 0.5) * PI);

   if ((amount > 0.0) && (Strength > 0.0)) {

      float4 Bgnd = tex2D (s_Background, xy2);
      float4 Fgnd = retval;

      float2 xy0 = float2 (amount * Strength * STRENGTH, 0.0);

      for (int i = 0; i < 60; i++) {
         xy1 -= xy0;
         xy2 += xy0;
         Fgnd += tex2D (s_Foreground, xy1);
         Bgnd += tex2D (s_Background, xy2);
      }

      retval = lerp (Fgnd, Bgnd, Mix) / 61;
   }

   return lerp (retval, EMPTY, mask);
}

float4 ps_main_T_B (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float mask, whip;
   float Mix = fn_mix (uv1, uv2, mask, whip);

   float2 xy1 = float2 (0.0, -whip);
   float2 xy2 = float2 (uv2.x, 1.0 + uv2.y) + xy1;

   xy1 += uv1;

   float4 retval = tex2D (s_Foreground, xy1);

   float amount = 1.0 - cos (clamp ((0.5 - abs (Amount - 0.5)) * 4.0, 0.0, 0.5) * PI);

   if ((amount > 0.0) && (Strength > 0.0)) {

      float4 Bgnd = tex2D (s_Background, xy2);
      float4 Fgnd = retval;

      float2 xy0 = float2 (0.0, amount * Strength * STRENGTH / _OutputAspectRatio);

      for (int i = 0; i < 60; i++) {
         xy1 += xy0;
         xy2 -= xy0;
         Fgnd += tex2D (s_Foreground, xy1);
         Bgnd += tex2D (s_Background, xy2);
      }

      retval = lerp (Fgnd, Bgnd, Mix) / 61;
   }

   return lerp (retval, EMPTY, mask);
}

float4 ps_main_B_T (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float mask, whip;
   float Mix = fn_mix (uv1, uv2, mask, whip);

   float2 xy1 = float2 (0.0, whip);
   float2 xy2 = float2 (uv2.x, 1.0 + uv2.y) + xy1;

   xy1 += uv1;

   float4 retval = tex2D (s_Foreground, xy1);

   float amount = 1.0 - cos (clamp ((0.5 - abs (Amount - 0.5)) * 4.0, 0.0, 0.5) * PI);

   if ((amount > 0.0) && (Strength > 0.0)) {

      float4 Bgnd = tex2D (s_Background, xy2);
      float4 Fgnd = retval;

      float2 xy0 = float2 (0.0, amount * Strength * STRENGTH / _OutputAspectRatio);

      for (int i = 0; i < 60; i++) {
         xy1 -= xy0;
         xy2 += xy0;
         Fgnd += tex2D (s_Foreground, xy1);
         Bgnd += tex2D (s_Background, xy2);
      }

      retval = lerp (Fgnd, Bgnd, Mix) / 61;
   }

   return lerp (retval, EMPTY, mask);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WhipPan_Dx_0 { pass P_1 CompileShader (ps_main_L_R) }

technique WhipPan_Dx_1 { pass P_1 CompileShader (ps_main_R_L) }

technique WhipPan_Dx_2 { pass P_1 CompileShader (ps_main_T_B) }

technique WhipPan_Dx_3 { pass P_1 CompileShader (ps_main_B_T) }
