// @ReleaseDate 2018-03-31
// @Author jwrl
// @CreationDate "11 November 2016"
//--------------------------------------------------------------//
// Lightworks user effect FloatImage.fx
//
// This version by LW user jwrl 11 November 2016
//
// The original version of this effect (now withdrawn) was
// called floating graphics.  It was subsequently thought
// necessary to add the ability to deal with non-alpha media
// or media with an unwanted alpha channel.  This effect is
// the final result.
//
// The original effect came about because of a need to create
// a custom title treatment in production.
//
// Bug fix 26 July 2017 by jwrl:
// Because Windows and Linux-OS/X have differing defaults for
// undefined samplers they have now been explicitly declared.
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
   string Description = "Floating images";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture Bg_1 : RenderColorTarget;
texture Bg_2 : RenderColorTarget;
texture Bg_3 : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int enhanceKey
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

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define A_On  true

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

bool fn_illegal (float2 xy)
{
   return (xy.x < 0.0) || (xy.y < 0.0) || (xy.x > 1.0) || (xy.y > 1.0);
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

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

   if (fn_illegal (uv)) { return bgdImage; }

   float4 fgdImage = tex2D (s_Fgnd, uv);

   if (enhanceKey == 0) fgdImage.a = 1.0;

   if (enhanceKey == 2) fgdImage.a = pow (fgdImage.a, 0.5);

   return lerp (bgdImage, fgdImage, fgdImage.a * Opac);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique ZoomDissolveOut
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
