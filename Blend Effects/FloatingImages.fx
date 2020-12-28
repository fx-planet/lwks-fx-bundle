// @Maintainer jwrl
// @Released 2020-12-28
// @Author jwrl
// @Created 2020-12-28
// @see https://www.lwks.com/media/kunena/attachments/6375/FloatImages_640.png

/**
 "Floating images" generates up to four floating images from a single foreground
 image.  The foreground may have an alpha channel, a bad alpha channel or no alpha
 channel at all, the effect will still work.  The position, size and density of the
 floating images are fully adjustable.

 Unlike the earlier version, the size adjustment now follows a square law.  Range
 settings are from zero to the square root of ten (a little over three) but the scale
 facor is actually from zero to ten.  This has been done to make size adjustment more
 readily controllable.

 NOTE:  This effect is resolution independent but the overlay positions will not
 necessarily track.  This is deliberate - during testing with differing image sizes
 and resolutions the overlayed images jumped as we played across cuts.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FloatingImages.fx
//
// Version history:
//
// Rewrite 2020-12-28 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Floating images";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Generates up to four overlayed images from a foreground graphic";
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

#define EMPTY  (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Source
<
   string Group = "Disconnect the video input to titles and image keys if used.";
   string Description = "Source selection";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image,Extracted foreground";
> = 1;

float A_Opac
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float A_Zoom
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float A_Xc
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float A_Yc
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool B_On
<
   string Group = "Overlay 2";
   string Description = "Enabled";
> = false;

float B_Opac
<
   string Group = "Overlay 2";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float B_Zoom
<
   string Group = "Overlay 2";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float B_Xc
<
   string Group = "Overlay 2";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float B_Yc
<
   string Group = "Overlay 2";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool C_On
<
   string Group = "Overlay 3";
   string Description = "Enabled";
> = false;

float C_Opac
<
   string Group = "Overlay 3";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float C_Zoom
<
   string Group = "Overlay 3";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float C_Xc
<
   string Group = "Overlay 3";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float C_Yc
<
   string Group = "Overlay 3";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool D_On
<
   string Group = "Overlay 4";
   string Description = "Enabled";
> = false;

float D_Opac
<
   string Group = "Overlay 4";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float D_Zoom
<
   string Group = "Overlay 4";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float D_Xc
<
   string Group = "Overlay 4";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float D_Yc
<
   string Group = "Overlay 4";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   return (max (xy.x, xy.y) > 0.5) ? EMPTY : tex2D (s, uv);
}

float4 fn_key2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   if (max (xy.x, xy.y) > 0.5) return EMPTY;

   float4 Fgd = tex2D (s, uv);

   if (Fgd.a == 0.0) return EMPTY;

   if (Source == 0) {
      Fgd.a    = pow (Fgd.a, 0.5);
      Fgd.rgb /= Fgd.a;

      return Fgd;
   }

   if (Source == 1) return Fgd;

   float4 Bgd = fn_tex2D (s_Background, uv);

   float kDiff = distance (Fgd.g, Bgd.g);

   kDiff = max (kDiff, distance (Fgd.r, Bgd.r));
   kDiff = max (kDiff, distance (Fgd.b, Bgd.b));

   Fgd.a = smoothstep (0.0, 0.25, kDiff);
   Fgd.rgb *= Fgd.a;

   return Fgd;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd, Bgnd = fn_tex2D (s_Background, uv2);
   float2 xy;

   if (D_On) {
      xy = ((uv1 - float2 (D_Xc, 1.0 - D_Yc)) / (D_Zoom *  D_Zoom)) + 0.5.xx;

      Fgnd = fn_key2D (s_Foreground, xy);
      Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * D_Opac);
   }

   if (C_On) {
      xy = ((uv1 - float2 (C_Xc, 1.0 - C_Yc)) / (C_Zoom *  C_Zoom)) + 0.5.xx;

      Fgnd = fn_key2D (s_Foreground, xy);
      Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * C_Opac);
   }

   if (B_On) {
      xy = ((uv1 - float2 (B_Xc, 1.0 - B_Yc)) / (B_Zoom *  B_Zoom)) + 0.5.xx;

      Fgnd = fn_key2D (s_Foreground, xy);
      Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * B_Opac);
   }

   xy = ((uv1 - float2 (A_Xc, 1.0 - A_Yc)) / (A_Zoom *  A_Zoom)) + 0.5.xx;

   Fgnd = fn_key2D (s_Foreground, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a * A_Opac);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FloatingImages
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
