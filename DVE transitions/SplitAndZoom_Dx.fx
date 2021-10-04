// @Maintainer jwrl
// @Released 2021-07-07
// @Author jwrl
// @Created 2021-06-04
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_SplitAndZoom_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/SplitAndZoom.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/SplitAndZoom_2.mp4

/**
 This effect splits the outgoing video horizontally or vertically to reveal the incoming
 shot, which zooms up out of an opaque black background.  It is a rewrite of an earlier
 effect, H split with zoom, which has been withdrawn.  Instead of the colour background
 provided with the earlier effect transparent black has been used.  This gives maximum
 flexibility when using aspect ratios that don't match the sequence.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SplitAndZoom_Dx.fx
//
// Version history:
//
// Built 2021-06-04 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Split and zoom";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Splits the outgoing video to reveal the incoming shot zooming out of black";
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

#define ExecuteShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define EMPTY 0.0.xxxx                // Transparent black

#define Illegal(XY) any(saturate (XY) - XY)
#define GetPixel(SHADER, XY) (Illegal (XY) ? EMPTY : tex2D (SHADER, XY))

#define HALF_PI 1.5707963268

float _FgXScale = 1.0;
float _FgYScale = 1.0;

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

int SetTechnique
<
   string Description = "Split direction";
   string Enum = "Horizontal,Vertical"; 
> = 0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_H (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float pos = Amount / (_FgXScale * 2.0);

   float2 xy1 = uv1;
   float2 xy2 = ((uv2 - 0.5.xx) * (2.0 - sin (Amount * HALF_PI))) + 0.5.xx;

   float4 retval;

   if ((uv1.x < pos + 0.5) && (uv1.x > 0.5 - pos))
      retval = GetPixel (s_Background, xy2);
   else {
      if (uv1.x > 0.5) xy1.x -= pos;
      else xy1.x += pos;

      retval = GetPixel (s_Foreground, xy1);
   }

   return retval;
}

float4 ps_main_V (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float pos = Amount / (_FgYScale * 2.0);

   float2 xy1 = uv1;
   float2 xy2 = ((uv2 - 0.5.xx) * (2.0 - sin (Amount * HALF_PI))) + 0.5.xx;

   float4 retval;

   if ((uv1.y < pos + 0.5) && (uv1.y > 0.5 - pos))
      retval = GetPixel (s_Background, xy2);
   else {
      if (uv1.y > 0.5) xy1.y -= pos;
      else xy1.y += pos;

      retval = GetPixel (s_Foreground, xy1);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SplitAndZoom_Dx_H { pass P_1 ExecuteShader (ps_main_H) }
technique SplitAndZoom_Dx_V { pass P_1 ExecuteShader (ps_main_V) }

