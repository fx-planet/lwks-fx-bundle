// @Maintainer jwrl
// @Released 2021-09-09
// @Author jwrl
// @Created 2021-09-09
// @see https://www.lwks.com/media/kunena/attachments/6375/Deco_DVE_640.png

/**
 This is an Art Deco take on the classic DVE effect.  It produces two independently
 adjustable borders around the foreground image.  It also produces corner flash lines
 inside the crop which are independently adjustable.  This version is a complete
 rebuild of DecoDVE to support the effects resolution independence available with
 Lightworks v2021 and higher.

 A consequence of that is that it is in no way directly interchangeable with that
 effect.  This version crops, scales and positions in the same way as a standard DVE,
 rather than using the unusual double scale and position technique of the earlier
 version.  Scaling uses a square law function to make size reduction more easily
 controlled.  The range covered is the same as the standard 2D DVE.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ArtDecoDVE.fx
//
// Version history:
//
// Updated jwrl 2021-09-09.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Art Deco DVE";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "Art Deco flash lines are included in the 2D DVE borders";
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

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define InRange(XY,TL,BR) (all (XY >= TL) && all (BR >= XY))

#define CENTRE 0.5.xx

float _OutputAspectRatio;
float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_Background);

DefineTarget (RawFg, s_Foreground);
DefineTarget (Crop, s_Cropped);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float PosX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float PosY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float MasterScale
<
   string Description = "Master";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float XScale
<
   string Description = "X";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float YScale
<
   string Description = "Y";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float CropL
<
   string Description = "Left";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropT
<
   string Description = "Top";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropR
<
   string Description = "Right";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropB
<
   string Description = "Bottom";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Border_1
<
   string Group = "Border settings";
   string Description = "Border width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float BorderGap
<
   string Group = "Border settings";
   string Description = "Outer gap";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

int GapFill
<
   string Group = "Border settings";
   string Description = "Outer gap fill";
   string Enum = "Background,Foreground,Black";
> = 0;

float Border_2
<
   string Group = "Border settings";
   string Description = "Outer bdr width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float InnerSpace
<
   string Group = "Flash line settings";
   string Description = "Gap";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float InnerWidth
<
   string Group = "Flash line settings";
   string Description = "Line width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

int InnerPos
<
   string Group = "Flash line settings";
   string Description = "Line position";
   string Enum = "Top left / bottom right,Top right / bottom left";
> = 0;

float Inner_L
<
   string Group = "Flash line settings";
   string Description = "Upper flash A";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float Inner_T
<
   string Group = "Flash line settings";
   string Description = "Upper flash B";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float Inner_R
<
   string Group = "Flash line settings";
   string Description = "Lower flash A";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.125;

float Inner_B
<
   string Group = "Flash line settings";
   string Description = "Lower flash B";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.125;

float4 Colour
<
   string Description = "Border colour";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 1.0, -1.0 };

int Repeats
<
   string Description = "Foreground images shown";
   string Enum = "Display one image when zoomed out,Display multiple images when zoomed out";
> = 0;

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Background
<
   string Description = "Background";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int Blanking
<
   string Description = "Crop foreground to background";
   string Enum = "No,Yes";
> = 1;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return Overflow (uv) ? BLACK : tex2D (s_RawFg, uv); }

float4 ps_crop (float2 uv : TEXCOORD3) : COLOR
{
   float border  = max (Border_1, 1.0e-6);
   float BorderH = border * 0.0125;
   float BorderV = BorderH * _OutputAspectRatio;

   float gapFctr = BorderGap / border;
   float linFctr = Border_2 * 1.5 / border;
   float insFctr = InnerSpace / border;
   float inwFctr = InnerWidth / border;

   float spaceH = BorderH * gapFctr;
   float spaceV = BorderV * gapFctr;
   float H_fix  = 0.5 / _OutputWidth;
   float V_fix  = 0.5 / _OutputHeight;

   float Rcrop = 1.0 - saturate (CropR) + H_fix;
   float Lcrop = saturate (CropL) - H_fix;
   float Tcrop = saturate (CropT) - V_fix;
   float Bcrop = 1.0 - saturate (CropB) + V_fix;
   float cropR, cropL, cropT, cropB;

   float4 retval;

   if (InRange (uv, float2 (Lcrop, Tcrop), float2 (Rcrop, Bcrop))) {

      cropR = Rcrop - BorderH; cropL = Lcrop + BorderH;
      cropT = Tcrop + BorderV; cropB = Bcrop - BorderV;

      retval = InRange (uv, float2 (cropL, cropT), float2 (cropR, cropB))
             ? GetPixel (s_Foreground, uv) : float4 (Colour.rgb, 1.0);
   }
   else {
      cropR = Rcrop + spaceH; cropL = Lcrop - spaceH;
      cropT = Tcrop - spaceV; cropB = Bcrop + spaceV;

      if (InRange (uv, float2 (cropL, cropT), float2 (cropR, cropB))) {
         retval = (GapFill == 2) ? BLACK
                : (GapFill == 0) ? EMPTY : GetPixel (s_Foreground, uv);
      }
      else {
         spaceH = BorderH * linFctr; spaceV = BorderV * linFctr;
         cropR += spaceH; cropL -= spaceH; cropT -= spaceV; cropB += spaceV;

         retval = InRange (uv, float2 (cropL, cropT), float2 (cropR, cropB))
                ? float4 (Colour.rgb, 1.0) : EMPTY;
      }
   }

   spaceH = BorderH * insFctr; spaceV = BorderV * insFctr;
   cropR = Rcrop - BorderH - spaceH; cropL = Lcrop + BorderH + spaceH;
   cropT = Tcrop + BorderV + spaceV; cropB = Bcrop - BorderV - spaceV;

   spaceH = BorderH * inwFctr; spaceV = BorderV * inwFctr;
   Rcrop = cropR - spaceH; Lcrop = cropL + spaceH;
   Tcrop = cropT + spaceV; Bcrop = cropB - spaceV;

   if (!InRange (uv, float2 (Lcrop, Tcrop), float2 (Rcrop, Bcrop))) {

      if (InRange (uv, float2 (cropL, cropT), float2 (cropR, cropB))) {

         float2 xy = float2 ((InnerPos) ? 1.0 - uv.x : uv.x, uv.y);

         Lcrop = (cropR - cropL); Tcrop = (cropB - cropT);
         Rcrop = Lcrop * Inner_R; Bcrop = Tcrop * Inner_B;
         Lcrop *= Inner_L; Tcrop *= Inner_T;
         Lcrop += cropL; Tcrop += cropT;
         Rcrop = cropR - Rcrop; Bcrop = cropB - Bcrop;

         if (InRange (xy, 0.0.xx, float2 (Lcrop, Tcrop)) ||
             InRange (xy, float2 (Rcrop, Bcrop), 1.0.xx)) retval = float4 (Colour.rgb, 1.0);
      }
   }

   return retval;
}

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float scaleX = MasterScale * MasterScale;
   float scaleY = max (1.0e-6, scaleX * YScale * YScale);

   scaleX = max (1.0e-6, scaleX * XScale * XScale);

   float2 xy1 = ((uv3 - float2 (PosX, 1.0 - PosY)) / float2 (scaleX, scaleY)) + 0.5.xx;

   if (Repeats) xy1 = frac (xy1);

   float4 Fgnd = Blanking && Overflow (uv2) ? EMPTY : GetPixel (s_Cropped, xy1);
   float4 Bgnd = lerp (BLACK, GetPixel (s_Background, uv2), Background);

   return lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ArtDecoDVE
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = Crop;"; > ExecuteShader (ps_crop)
   pass P_2 ExecuteShader (ps_main)
}

