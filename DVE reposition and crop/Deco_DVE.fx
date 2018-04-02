// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Deco_DVE.fx
//
// Created by LW user jwrl 27 April 2017
// @Author jwrl
// @CreationDate "27 April 2017"
//
// This is an Art Deco take on the classic DVE effect.  It
// produces two independently adjustable borders around the
// foreground image.  It also produces corner flash lines
// inside the crop which are adjustable.
//
// It allows the foreground image to be resized and
// positioned inside the crop window, as well as allowing
// the foreground composite with borders to be scaled and
// positioned.  Finally, as the composite is zoomed out the
// user can choose to have a single instance on screen or
// multiples.
//
// Although this uses four passes to perform its magic, they
// are either very simple or use simple mathematics.  As a
// result it should be capable of real time speeds on even
// minimal systems.
//
// Cross platform compatibility check 31 July 2017 jwrl.
//
// Explicitly defined float2 and float4 variables to address
// behavioural differences between the D3D and Cg compilers.
//
// Inverted the position settings.  They originally worked
// backwards. i.e., from the camera point of view.
//
// Version 14.5 update 24 March 2018 by jwrl.
//
// Legality checking has been added to correct for a bug
// in XY sampler addressing on Linux and OS-X platforms.
// This effect should now function correctly when used with
// all current and previous Lightworks versions.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Deco DVE";
   string Category    = "DVE";
   string SubCategory = "Crop Presets";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fgd;
texture Bgd;

texture FgdAdj   : RenderColorTarget;
texture FgdCrop  : RenderColorTarget;
texture Multiple : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InSampler = sampler_state
{
   Texture = <Fgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture = <Bgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FgSampler = sampler_state
{
   Texture   = <FgdAdj>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FcSampler = sampler_state
{
   Texture   = <FgdCrop>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FmSampler = sampler_state
{
   Texture   = <Multiple>;
   AddressU  = Wrap;
   AddressV  = Wrap;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float FgdZ
<
   string Group = "Foreground DVE";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float FgdX
<
   string Group = "Foreground DVE";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float FgdY
<
   string Group = "Foreground DVE";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CropZ
<
   string Group = "Foreground crop";
   string Description = "Master size";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float CropX
<
   string Group = "Foreground crop";
   string Description = "Scale";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropY
<
   string Group = "Foreground crop";
   string Description = "Scale";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropPosX
<
   string Group = "Foreground crop";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CropPosY
<
   string Group = "Foreground crop";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Border_1
<
   string Group = "Foreground border";
   string Description = "Border width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float BorderGap
<
   string Group = "Foreground border";
   string Description = "Outer gap";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

int GapFill
<
   string Group = "Foreground border";
   string Description = "Outer gap fill";
   string Enum = "Background,Foreground";
> = 0;

float Border_2
<
   string Group = "Foreground border";
   string Description = "Outer line width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float InnerSpace
<
   string Group = "Foreground border";
   string Description = "Inner gap";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float InnerWidth
<
   string Group = "Foreground border";
   string Description = "Inner line width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

int InnerPos
<
   string Group = "Foreground border";
   string Description = "Inner line position";
   string Enum = "Top left / bottom right,Top right / bottom left";
> = 0;

float Inner_TL
<
   string Group = "Foreground border";
   string Description = "Inner length A";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float Inner_BR
<
   string Group = "Foreground border";
   string Description = "Inner length B";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.125;

float4 Colour_1
<
   string Group = "Foreground border";
   string Description = "Border colour";
> = { 1.0, 1.0, 1.0, 1.0 };

int SetTechnique
<
   string Group = "Master DVE";
   string Description = "Foreground images shown";
   string Enum = "Display multiple versions when zoomed out,Display only one when zoomed out";
> = 1;

float OverlayOpacity
<
   string Group = "Master DVE";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float OverlayZ
<
   string Group = "Master DVE";
   string Description = "Zoom";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float OverlayX
<
   string Group = "Master DVE";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float OverlayY
<
   string Group = "Master DVE";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define BLACK  float4(0.0.xxx,1.0)
#define EMPTY  0.0.xxxx

#define CENTRE 0.5.xx

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

bool fn_inRange (float2 uv, float2 r1, float2 r2)
{
   return (uv.x >= r1.x) && (uv.y >= r1.y) && (uv.x <= r2.x) && (uv.y <= r2.y);
}

bool fn_outRange (float2 uv, float2 r1, float2 r2)
{
   return (uv.x < r1.x) || (uv.y < r1.y) || (uv.x > r2.x) || (uv.y > r2.y);
}

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//--------------------------------------------------------------//
// Shader
//--------------------------------------------------------------//

float4 ps_scale_fgd (float2 uv : TEXCOORD1) : COLOR
{
   float  scale = max (FgdZ, 0.0001);
   float2 xy = ((uv - 0.5.xx) / scale) + float2 (1.0 - FgdX, FgdY);

   return fn_illegal (xy) ? BLACK : tex2D (InSampler, xy);
}

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (FgSampler, uv);

   float2 brdrEdge = (0.05 * Border_1).xx;
   float2 gap_Edge = brdrEdge + (0.05 * BorderGap).xx;
   float2 outrEdge = gap_Edge + (0.05 * Border_2).xx;

   brdrEdge.y *= _OutputAspectRatio;
   gap_Edge.y *= _OutputAspectRatio;
   outrEdge.y *= _OutputAspectRatio;

   float2 cropTL = saturate (CENTRE - (float2 (CropX, CropY) / 2.0)) - CENTRE;

   cropTL *= CropZ;

   float2 cropBR = abs (cropTL) + float2 (CropPosX, 1.0 - CropPosY);

   cropTL += float2 (CropPosX, 1.0 - CropPosY);

   float2 bordTL = saturate (cropTL - outrEdge);
   float2 bordBR = saturate (cropBR + outrEdge);

   float4 retval = fn_inRange (uv, bordTL, bordBR) ? Colour_1 : EMPTY;

   bordTL = saturate (cropTL - gap_Edge);
   bordBR = saturate (cropBR + gap_Edge);

   if (fn_inRange (uv, bordTL, bordBR)) { retval = (GapFill == 1) ? Fgnd : EMPTY; }

   bordTL = saturate (cropTL - brdrEdge);
   bordBR = saturate (cropBR + brdrEdge);

   if (fn_inRange (uv, bordTL, bordBR)) { retval = Colour_1; }

   return fn_inRange (uv, cropTL, cropBR) ? Fgnd : retval;
}

float4 ps_flash (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (FcSampler, uv);
   float4 innerEdge, outerEdge;

   outerEdge.xy  = saturate (CENTRE - (float2 (CropX, CropY) / 2.0)) - CENTRE;
   outerEdge.xy *= CropZ;

   outerEdge.xy += float2 (1.0, _OutputAspectRatio) * InnerSpace * 0.05;
   innerEdge.xy  = outerEdge.xy + (float2 (1.0, _OutputAspectRatio) * InnerWidth * 0.05);

   outerEdge.zw = abs (outerEdge.xy);
   innerEdge.zw = abs (innerEdge.xy);

   outerEdge += float2 (CropPosX, 1.0 - CropPosY).xyxy;
   innerEdge += float2 (CropPosX, 1.0 - CropPosY).xyxy;

   if (fn_outRange (uv, outerEdge.xy, outerEdge.zw) ||
       fn_inRange (uv, innerEdge.xy, innerEdge.zw)) return Fgnd;

   float4 retval = Colour_1;

   float2 xy  = uv;
   float2 xy1 = float2 (outerEdge.z - outerEdge.x, outerEdge.w - outerEdge.y);
   float2 xy2 = outerEdge.zw - (xy1 * Inner_BR);

   if (InnerPos == 1) { xy.x = 1.0 - uv.x; }

   xy1 *= Inner_TL;
   xy1 += outerEdge.xy;

   if ((((xy.x > xy1.x) || (xy.y > xy1.y)) &&
        ((xy.x < innerEdge.x) || (xy.y < innerEdge.y))) ||
       (((xy.x > innerEdge.z) || (xy.y > innerEdge.w)) &&
        ((xy.x < xy2.x) || (xy.y < xy2.y)))) return Fgnd;

   return retval;
}

float4 ps_main_multiple (float2 uv : TEXCOORD1) : COLOR
{
   float  scale = max (OverlayZ, 0.0001);

   float2 xy = ((uv - CENTRE) / scale) + float2 (1.0 - OverlayX, OverlayY);

   float4 Fgnd = tex2D (FmSampler, xy);
   float4 Bgnd = tex2D (BgSampler, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a * OverlayOpacity);
}

float4 ps_main_single (float2 uv : TEXCOORD1) : COLOR
{
   float  scale = max (OverlayZ, 0.0001);

   float2 xy = ((uv - CENTRE) / scale) + float2 (1.0 - OverlayX, OverlayY);

   float4 Fgnd = fn_illegal (xy) ? EMPTY : tex2D (FgSampler, xy);
   float4 Bgnd = tex2D (BgSampler, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a * OverlayOpacity);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique crop_multiple
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = FgdAdj;";
   >
   {
      PixelShader = compile PROFILE ps_scale_fgd ();
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = FgdCrop;";
   >
   {
      PixelShader = compile PROFILE ps_crop ();
   }

   pass pass_three
   <
      string Script = "RenderColorTarget0 = Multiple;";
   >
   {
      PixelShader = compile PROFILE ps_flash ();
   }

   pass pass_four
   {
      PixelShader = compile PROFILE ps_main_multiple ();
   }
}

technique crop
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = FgdAdj;";
   >
   {
      PixelShader = compile PROFILE ps_scale_fgd ();
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = FgdCrop;";
   >
   {
      PixelShader = compile PROFILE ps_crop ();
   }

   pass pass_three
   <
      string Script = "RenderColorTarget0 = FgdAdj;";
   >
   {
      PixelShader = compile PROFILE ps_flash ();
   }

   pass pass_four
   {
      PixelShader = compile PROFILE ps_main_single ();
   }
}

