// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2017-04-27
// @see https://www.lwks.com/media/kunena/attachments/6375/Deco_DVE_640.png

/**
This is an Art Deco take on the classic DVE effect.  It produces two independently
adjustable borders around the foreground image.  It also produces corner flash lines
inside the crop which are adjustable.

It allows the foreground image to be resized and positioned inside the crop window,
as well as allowing the foreground composite with borders to be scaled and positioned.
Finally, as the composite is zoomed out the user can choose to have a single instance
on screen or multiples.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DecoDVE.fx
//
// Although this uses four passes to perform its magic, they are either very simple or
// use simple mathematics.  As a result it should be capable of real time speeds on even
// minimal systems.
//
// Cross platform compatibility check 31 July 2017 jwrl.
// Explicitly defined float2 and float4 variables to address behavioural differences
// between the D3D and Cg compilers.
// Inverted the position settings.  They originally worked backwards. i.e., from the
// camera point of view.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.  This effect will function correctly when used with all
// current and previous Lightworks versions.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 6 July 2018 jwrl.
// Added a note to describe the function of the effect.
// Cleaned up border generation code so that it's much clearer what's going on.
// Reformatted the sampler definitions to be consistent with my other effects.
//
// Modified jwrl 2018-12-23:
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Deco DVE";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "Art Deco flash lines are overlaid over a DVE effect, which uses a second DVE to resize the result.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fgd;
texture Bgd;

texture FgdAdj   : RenderColorTarget;
texture FgdCrop  : RenderColorTarget;
texture Multiple : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Fgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state { Texture = <Bgd>; };

sampler s_Foreground = sampler_state
{
   Texture   = <FgdAdj>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_CroppedFgd = sampler_state
{
   Texture   = <FgdCrop>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_MultipleFgd = sampler_state
{
   Texture   = <Multiple>;
   AddressU  = Wrap;
   AddressV  = Wrap;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLACK  float4(0.0.xxx,1.0)
#define EMPTY  0.0.xxxx

#define CENTRE 0.5.xx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool fn_inRange (float2 uv, float2 r1, float2 r2)
{
   return (uv.x >= r1.x) && (uv.y >= r1.y) && (uv.x <= r2.x) && (uv.y <= r2.y);
}

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_scale_fgd (float2 uv : TEXCOORD1) : COLOR
{
   float  scale = max (FgdZ, 0.0001);
   float2 xy = ((uv - 0.5.xx) / scale) + float2 (1.0 - FgdX, FgdY);

   return fn_illegal (xy) ? BLACK : tex2D (s_Input, xy);
}

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, uv);

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
   float4 Fgnd = tex2D (s_CroppedFgd, uv);

   float2 outerEdgeTL = saturate (CENTRE - (float2 (CropX, CropY) / 2.0)) - CENTRE;

   outerEdgeTL *= CropZ;
   outerEdgeTL += float2 (1.0, _OutputAspectRatio) * InnerSpace * 0.05;

   float2 cropMidPnt  = float2 (CropPosX, 1.0 - CropPosY);
   float2 innerEdgeTL = outerEdgeTL + (float2 (1.0, _OutputAspectRatio) * InnerWidth * 0.05);
   float2 outerEdgeBR = abs (outerEdgeTL) + cropMidPnt;
   float2 innerEdgeBR = abs (innerEdgeTL) + cropMidPnt;

   outerEdgeTL += cropMidPnt;
   innerEdgeTL += cropMidPnt;

   if (!fn_inRange (uv, outerEdgeTL, outerEdgeBR) ||
        fn_inRange (uv, innerEdgeTL, innerEdgeBR)) return Fgnd;

   float4 retval = Colour_1;

   float2 xy  = uv;
   float2 xy1 = outerEdgeBR - outerEdgeTL;
   float2 xy2 = outerEdgeBR - (xy1 * Inner_BR);

   if (InnerPos == 1) { xy.x = 1.0 - uv.x; }

   xy1 *= Inner_TL;
   xy1 += outerEdgeTL;

   if ((((xy.x > xy1.x) || (xy.y > xy1.y)) &&
        ((xy.x < innerEdgeTL.x) || (xy.y < innerEdgeTL.y))) ||
       (((xy.x > innerEdgeBR.x) || (xy.y > innerEdgeBR.y)) &&
        ((xy.x < xy2.x) || (xy.y < xy2.y)))) return Fgnd;

   return retval;
}

float4 ps_main_multiple (float2 uv : TEXCOORD1) : COLOR
{
   float  scale = max (OverlayZ, 0.0001);

   float2 xy = ((uv - CENTRE) / scale) + float2 (1.0 - OverlayX, OverlayY);

   float4 Fgnd = tex2D (s_MultipleFgd, xy);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * OverlayOpacity);
}

float4 ps_main_single (float2 uv : TEXCOORD1) : COLOR
{
   float  scale = max (OverlayZ, 0.0001);

   float2 xy = ((uv - CENTRE) / scale) + float2 (1.0 - OverlayX, OverlayY);

   float4 Fgnd = fn_illegal (xy) ? EMPTY : tex2D (s_Foreground, xy);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * OverlayOpacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique crop_multiple
{
   pass P_1
   < string Script = "RenderColorTarget0 = FgdAdj;"; >
   { PixelShader = compile PROFILE ps_scale_fgd (); }

   pass P_2
   < string Script = "RenderColorTarget0 = FgdCrop;"; >
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Multiple;"; >
   { PixelShader = compile PROFILE ps_flash (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_multiple (); }
}

technique crop
{
   pass P_1
   < string Script = "RenderColorTarget0 = FgdAdj;"; >
   { PixelShader = compile PROFILE ps_scale_fgd (); }

   pass P_2
   < string Script = "RenderColorTarget0 = FgdCrop;"; >
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_3
   < string Script = "RenderColorTarget0 = FgdAdj;"; >
   { PixelShader = compile PROFILE ps_flash (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_single (); }
}
