// @Maintainer jwrl
// @Released 2021-09-01
// @Author jwrl
// @Created 2021-09-01
// @see https://www.lwks.com/media/kunena/attachments/6375/SimpleCrop_640.png

/**
 This is a quick simple cropping tool.  You can also use it to blend images without
 using a blend effect.  It provides a simple border and the "sense" of the effect can
 be swapped so that background becomes foreground and vice versa.  With its extended
 alpha support you can also use it to crop and overlay two images with alpha channels
 over another background.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Simple_crop.fx
//
// Version history:
//
// Rewrite 2021-09-01 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Simple crop";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "A simple crop tool with blend.";
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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define BLACK float4(0.0.xxx,1.0)

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fgd, s_RawFg);
DefineInput (Bgd, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CropLeft
<
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float CropTop
<
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropRight
<
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropBottom
<
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

bool Swap
<
   string Description = "Swap background and foreground";
> = false;

int AlphaMode
<
   string Description = "Alpha channel output";
   string Enum = "Ignore alpha,Background only,Cropped foreground,Combined alpha,Overlaid alpha";
> = 3;

float Border
<
   string Group = "Border";
   string Description = "Thickness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float4 Colour
<
   string Group = "Border";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 1.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

// These two passes map the foreground and background clips to TEXCOORD3, so that
// variations in clip geometry and rotation are handled without too much effort.

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return Overflow (uv) ? BLACK : tex2D (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgnd, Bgnd;
   float2 brdrEdge = (Border * 0.05).xx;

   brdrEdge.y *= _OutputAspectRatio;

   float2 cropTL = float2 (CropLeft, 1.0 - CropTop);
   float2 cropBR = float2 (CropRight, 1.0 - CropBottom);
   float2 bordTL = saturate (cropTL - brdrEdge);
   float2 bordBR = saturate (cropBR + brdrEdge);

   if (Swap) {
      Bgnd = GetPixel (s_Foreground, uv);
      Fgnd = GetPixel (s_Background, uv);
   }
   else {
      Fgnd = GetPixel (s_Foreground, uv);
      Bgnd = GetPixel (s_Background, uv);
   }

   if (all (uv > bordTL) && all (uv < bordBR)) { Bgnd = Colour; }
   else if (AlphaMode == 4) Bgnd.a = 0.0;

   if (any (uv < cropTL) || any (uv > cropBR)) { Fgnd = EMPTY; }

   float alpha = (AlphaMode == 0) ? 1.0
               : (AlphaMode == 1) ? Bgnd.a
               : (AlphaMode == 2) ? Fgnd.a : max (Bgnd.a, Fgnd.a);

   return float4 (lerp (Bgnd, Fgnd, Fgnd.a).rgb, alpha);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Simple_crop
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_main)
}

