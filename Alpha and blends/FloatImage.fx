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

texture Fgd;
texture Bgd;

texture Bg_1 : RenderColorTarget;
texture Bg_2 : RenderColorTarget;
texture Bg_3 : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgdSampler = sampler_state {
        Texture   = <Fgd>;
	AddressU  = Clamp;
	AddressV  = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
        };

sampler BgdSampler = sampler_state {
        Texture   = <Bgd>;
	AddressU  = Clamp;
	AddressV  = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
        };

sampler Bg1Sampler = sampler_state {
        Texture   = <Bg_1>;
	AddressU  = Clamp;
	AddressV  = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
        };

sampler Bg2Sampler = sampler_state {
        Texture = <Bg_2>;
	AddressU  = Clamp;
	AddressV  = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
        };

sampler Bg3Sampler = sampler_state {
        Texture = <Bg_3>;
	AddressU  = Clamp;
	AddressV  = Clamp;
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

float Opac_A
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Zoom_A
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Scale";
   float MinVal = 0.01;
   float MaxVal = 10.00;
> = 1.0;

float Xc_A
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Yc_A
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

bool On_B
<
   string Group = "Overlay 2";
   string Description = "Enabled";
> = false;

float Opac_B
<
   string Group = "Overlay 2";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Zoom_B
<
   string Group = "Overlay 2";
   string Description = "Scale";
   float MinVal = 0.01;
   float MaxVal = 10.00;
> = 1.0;

float Xc_B
<
   string Group = "Overlay 2";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Yc_B
<
   string Group = "Overlay 2";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

bool On_C
<
   string Group = "Overlay 3";
   string Description = "Enabled";
> = false;

float Opac_C
<
   string Group = "Overlay 3";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Zoom_C
<
   string Group = "Overlay 3";
   string Description = "Scale";
   float MinVal = 0.01;
   float MaxVal = 10.00;
> = 1.0;

float Xc_C
<
   string Group = "Overlay 3";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Yc_C
<
   string Group = "Overlay 3";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

bool On_D
<
   string Group = "Overlay 4";
   string Description = "Enabled";
> = false;

float Opac_D
<
   string Group = "Overlay 4";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Zoom_D
<
   string Group = "Overlay 4";
   string Description = "Scale";
   float MinVal = 0.01;
   float MaxVal = 10.00;
> = 1.0;

float Xc_D
<
   string Group = "Overlay 4";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Yc_D
<
   string Group = "Overlay 4";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1, uniform sampler img,
                uniform float Opac, uniform float Zoom,
                uniform float Xc, uniform float Yc,
                uniform bool use_it) : COLOR
{
   float4 fgdImage, bgdImage = tex2D (img, xy);

   if (!use_it) return bgdImage;

   if (Zoom > 0.0) {
      float2 uv;

      float scale = 1.0 / Zoom;

      float2 zoomCentre = float2 (1.0 - Xc, Yc);

      uv = ((xy - zoomCentre) * scale) + zoomCentre;
      fgdImage = tex2D (FgdSampler, uv);
   }
   else fgdImage = tex2D (FgdSampler, xy);

   fgdImage.a = (enhanceKey == 0) ? 1.0 : saturate (fgdImage.a * enhanceKey);

   return lerp (bgdImage, fgdImage, fgdImage.a * Opac);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique ZoomDissolveOut
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = Bg_1;";
   >
   {
      PixelShader = compile PROFILE ps_main (BgdSampler, Opac_D, Zoom_D, Xc_D, Yc_D, On_D);
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = Bg_2;";
   >
   {
      PixelShader = compile PROFILE ps_main (Bg1Sampler, Opac_C, Zoom_C, Xc_C, Yc_C, On_C);
   }

   pass pass_three
   <
      string Script = "RenderColorTarget0 = Bg_3;";
   >
   {
      PixelShader = compile PROFILE ps_main (Bg2Sampler, Opac_B, Zoom_B, Xc_B, Yc_B, On_B);
   }

   pass pass_four
   {
      PixelShader = compile PROFILE ps_main (Bg3Sampler, Opac_A, Zoom_A, Xc_A, Yc_A, true);
   }
}
