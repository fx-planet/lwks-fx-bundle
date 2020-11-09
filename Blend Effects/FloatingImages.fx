// @Maintainer jwrl
// @Released 2020-11-08
// @Author jwrl
// @Created 2016-11-11
// @see https://www.lwks.com/media/kunena/attachments/6375/FloatImages_640.png

/**
 "Floating images" generates up to four floating coloured outlines from a foreground
 image.  The foreground may have an alpha channel, a bad alpha channel or no alpha
 channel at all, the effect will still work.  The colour, position and size of the
 floating outlines are fully adjustable.

 The original effect came about because of a need to create a custom title treatment
 in production.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FloatingImages.fx
//
// Version history:
//
// Update 2020-11-08 jwrl.
// Added CanSize switch for 2021 support.
//
// Update 23 December 2018 jwrl.
// Converted to version 14.5 and up.
// Modified Windows version to compile as ps_3_0.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified 25 November 2018 jwrl.
// Changed category to "Mix".
// Changed subcategory to "Blend Effects".
//
// Modified 30 August 2018 jwrl.
// Added notes to header.
//
// Modified 23 June 2018 jwrl.
// Added unpremultiply to the alpha channel procesing for Lightworks titles.  Moved the
// alpha test into its own function, which simplifies ps_main() considerably.
//
// Modified 5 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14.5 update 24 March 2018
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.  This effect should now function correctly when used with
// current and previous Lightworks versions.
//
// Bug fix 26 July 2017
// Because Windows and Linux-OS/X have differing defaults for undefined samplers they
// have now been explicitly declared.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Floating images";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Generates up to four coloured outlines from a foreground graphic";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Bg_1 : RenderColorTarget;
texture Bg_2 : RenderColorTarget;
texture Bg_3 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

sampler s_Fgnd    = sampler_state {
   Texture   = <Fg>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s_Bgnd    = sampler_state {
   Texture   = <Bg>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s_Bgnd_1  = sampler_state {
   Texture   = <Bg_1>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s_Bgnd_2  = sampler_state {
   Texture   = <Bg_2>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s_Bgnd_3  = sampler_state {
   Texture   = <Bg_3>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int KeyMode
<
   string Group = "Disconnect the video input to Lightworks titles if used.";
   string Description = "Type of foreground layer";
   string Enum = "Solid video,Video with alpha channel,Lightworks title or effect";
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
   float MinVal = 0.0001;
   float MaxVal = 10.00;
> = 1.0;

float A_Xc
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float A_Yc
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
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
   float MinVal = 0.0001;
   float MaxVal = 10.00;
> = 1.0;

float B_Xc
<
   string Group = "Overlay 2";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float B_Yc
<
   string Group = "Overlay 2";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
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
   float MinVal = 0.0001;
   float MaxVal = 10.00;
> = 1.0;

float C_Xc
<
   string Group = "Overlay 3";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float C_Yc
<
   string Group = "Overlay 3";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
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
   float MinVal = 0.0001;
   float MaxVal = 10.00;
> = 1.0;

float D_Xc
<
   string Group = "Overlay 4";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float D_Yc
<
   string Group = "Overlay 4";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define A_On  true

#define SOLID  0
#define NORMAL 0

#define EMPTY  (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   float4 retval = tex2D (Vsample, uv);

   if (KeyMode == NORMAL) return retval;
   else if (KeyMode == SOLID) return float4 (retval.rgb, 1.0);

   retval.a = pow (retval.a, 0.5);

   return float4 (retval.rgb / retval.a, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1, uniform sampler img,
                uniform float Opac, uniform float Zoom,
                uniform float Xc, uniform float Yc,
                uniform bool use_it) : COLOR
{
   float4 bgdImage = tex2D (img, xy);

   if (!use_it) return bgdImage;

   float scale = 1.0 / max (Zoom, 0.0001);

   float2 zoomCentre = float2 (1.0 - Xc, Yc);
   float2 uv = ((xy - zoomCentre) * scale) + zoomCentre;

   float4 fgdImage = fn_tex2D (s_Fgnd, uv);

   return lerp (bgdImage, fgdImage, fgdImage.a * Opac);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FloatingImages
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bg_1;"; >
   { PixelShader = compile PROFILE ps_main (s_Bgnd, D_Opac, D_Zoom, D_Xc, D_Yc, D_On); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bg_2;"; >
   { PixelShader = compile PROFILE ps_main (s_Bgnd_1, C_Opac, C_Zoom, C_Xc, C_Yc, C_On); }

   pass P_3
   < string Script = "RenderColorTarget0 = Bg_3;"; >
   { PixelShader = compile PROFILE ps_main (s_Bgnd_2, B_Opac, B_Zoom, B_Xc, B_Yc, B_On); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (s_Bgnd_3, A_Opac, A_Zoom, A_Xc, A_Yc, A_On); }
}
