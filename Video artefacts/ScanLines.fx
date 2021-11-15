// @Maintainer jwrl
// @Released 2021-11-15
// @Author jwrl
// @Created 2021-11-15
// @see https://forum.lwks.com/attachments/scanlines_640-png.39684/

/**
 This creates a scan line overlay over any input video.  The number of lines created
 are adjustable, as is the opacity of those lines.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ScanLines.fx
//
// Version history:
//
// Created 2021-11-15 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Scanlines";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "This creates an adjustable scan line overlay on the input video";
   bool CanSize       = false;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define PI 3.1415926536

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Lines
<
   string Description = "Scanline count";
   float MinVal = 50.0;
   float MaxVal = 600.0;
> = 250.0;

float Strength
<
   string Description = "Scanline strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = GetPixel (s_Input, uv);

   retval.rgb *= lerp (1.0, (sin (PI * uv.y * Lines) + 1.0) * 0.5, Strength);
   retval.rgb += retval.rgb * Strength * 0.375;

   return saturate (retval);
}

//-----------------------------------------------------------------------------------------//
//  Techniques
//-----------------------------------------------------------------------------------------//

technique ScanLines { pass P_1 ExecuteShader (ps_main) }

