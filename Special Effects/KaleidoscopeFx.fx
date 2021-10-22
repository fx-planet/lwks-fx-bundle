// @Maintainer jwrl
// @Released 2021-10-22
// @Author khaver
// @Created 2011-06-28
// @see https://www.lwks.com/media/kunena/attachments/6375/Kaleidoscope_640.png

/**
 This kaleidoscope effect varies the number of sides, position and scale.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect KaleidoscopeFx.fx
//
// Version history:
//
// Update 2021-10-22 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 5 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.
//
// LW 14+ version by jwrl 12 February 2017
// SubCategory "Patterns" added.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Kaleidoscope";
   string Category    = "Stylize";
   string SubCategory = "Special Effects";
   string Notes       = "This kaleidoscope effect varies the number of sides, position and scale";
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, s_Input);

DefineTarget (Tex1, Samp1);
DefineTarget (Tex2, Samp2);
DefineTarget (Tex3, Samp3);
DefineTarget (Tex4, Samp4);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Complexity";
   string Enum = "One,Two,Three,Four";
> = 0;

float ORGX
<
   string Description = "Pan";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float ORGY
<
   string Description = "Pan";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Zoom
<
   string Description = "Zoom";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 main1 (float2 uv : TEXCOORD2) : COLOR
{
   float2 zoomit = ((uv - 0.5.xx) / Zoom) + 0.5.xx;

   zoomit += float2 (0.5 - ORGX, ORGY - 0.5);

   return saturate (GetPixel (s_Input, zoomit));
}

float4 main2 (float2 uv : TEXCOORD2) : COLOR
{
   return saturate (tex2D (Samp1, abs (uv - 0.5.xx)));
}

float4 main3 (float2 uv : TEXCOORD2) : COLOR
{
   return saturate (tex2D (Samp2, abs (uv + uv - 1.0.xx)));
}

float4 main4 (float2 uv : TEXCOORD2) : COLOR
{
   return saturate (tex2D (Samp3, abs (uv + uv - 1.0.xx)));
}

float4 main5 (float2 uv : TEXCOORD2) : COLOR
{
   return saturate (tex2D (Samp4, abs (uv + uv - 1.0.xx)));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique One
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Tex1;"; > ExecuteShader (main1)
   pass P_3 ExecuteShader (main2)
}

technique Two
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Tex1;"; > ExecuteShader (main1)
   pass P_3 < string Script = "RenderColorTarget0 = Tex2;"; > ExecuteShader (main2)
   pass P_4 ExecuteShader (main3)
}

technique Three
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Tex1;"; > ExecuteShader (main1)
   pass P_3 < string Script = "RenderColorTarget0 = Tex2;"; > ExecuteShader (main2)
   pass P_4 < string Script = "RenderColorTarget0 = Tex3;"; > ExecuteShader (main3)
   pass P_5 ExecuteShader (main4)
}

technique Four
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Tex1;"; > ExecuteShader (main1)
   pass P_3 < string Script = "RenderColorTarget0 = Tex2;"; > ExecuteShader (main2)
   pass P_4 < string Script = "RenderColorTarget0 = Tex3;"; > ExecuteShader (main3)
   pass P_5 < string Script = "RenderColorTarget0 = Tex4;"; > ExecuteShader (main4)
   pass P_6 ExecuteShader (main5)
}

