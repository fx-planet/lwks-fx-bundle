// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_ColourFlat_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_ColourFlat.mp4

/**
 This is a modified version of my "Dissolve through colour" but is very much simpler to
 use.  Apply it as you would a dissolve, adjust the percentage of the dissolve that you
 want to be colour and set the colour to what you want.  It defaults to a black colour
 with a colour duration of 10% of the total effect duration, for a quick dissolve through
 black.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlatColour_Dx.fx
//
// Version history:
//
// Rewrite 2021-07-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dissolve thru flat colour";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Dissolves to a flat user defined colour then from that to the incoming image";
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

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

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

float cDuration
<
   string Group = "Colour setup";
   string Description = "Duration";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float4 Colour
<
   string Group = "Colour setup";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float mix_bgd = min (1.0, (1.0 - Amount) * 2.0);
   float mix_fgd = min (1.0, Amount * 2.0);

   if (cDuration < 1.0) {
      float duration = 1.0 - cDuration;

      mix_bgd = min (1.0, mix_bgd / duration);
      mix_fgd = min (1.0, mix_fgd / duration);
   }
   else {
      mix_bgd = 1.0;
      mix_fgd = 1.0;
   }

   float4 retval = lerp (GetPixel (s_Foreground, uv1), Colour, mix_fgd);

   return lerp (GetPixel (s_Background, uv2), retval, mix_bgd);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique FlatColour_Dx
{
   pass P_1 ExecuteShader (ps_main)
}

