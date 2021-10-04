// @Maintainer jwrl
// @Released 2021-08-30
// @Author khaver
// @Created 2011-06-27
// @see https://www.lwks.com/media/kunena/attachments/6375/Perspective_640.png

/**
 The name of the effect describes what it does.  It's a neat, simple effect for adding
 a perspective illusion to a flat plane.  With resolution independence, the image will
 only wrap to the boundaries of the undistorted image.  If the aspect ratio of the input
 video is such that it doesn't fill the frame, neither will the warped image.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Perspective.fx
//
// Version history:
//
// Update 2021-08-30 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Perspective";
   string Category    = "DVE";
   string SubCategory = "Distortion";
   string Notes       = "A neat, simple effect for adding a perspective illusion to a flat plane";
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

#define WHITE 1.0.xxxx

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, InputSampler);

//-----------------------------------------------------------------------------------------//
// Parameters 
//-----------------------------------------------------------------------------------------//

bool showGrid
<
   string Description = "Show grid";
> = false;

float TLX
<
   string Description = "Top Left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float TLY
<
   string Description = "Top Left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float TRX
<
   string Description = "Top Right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float TRY
<
   string Description = "Top Right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float BLX
<
   string Description = "Bottom Left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float BLY
<
   string Description = "Bottom Left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float BRX
<
   string Description = "Bottom Right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float BRY
<
   string Description = "Bottom Right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

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

// This preamble pass means that we handle rotated video correctly.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   float x1 = lerp (0.1 - TLX, 1.9 - TRX, uv.x);
   float x2 = lerp (0.1 - BLX, 1.9 - BRX, uv.x);
   float y1 = lerp (TLY - 0.9, BLY + 0.9, uv.y);
   float y2 = lerp (TRY - 0.9, BRY + 0.9, uv.y);

   float2 xy;

   xy.x = lerp (x1, x2, uv.y) + (0.5 - ORGX);
   xy.y = lerp (y1, y2, uv.x) + (ORGY - 0.5);

   float2 zoomit = ((xy - 0.5.xx) / Zoom) + 0.5.xx;

   float4 color = GetPixel (InputSampler, zoomit);

   if (showGrid) {
      xy = frac (uv * 10.0);

      if (any (xy <= 0.02) || any (xy >= 0.98))
         color = WHITE - color;
   }

   return saturate (color);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Perspective
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pass1 ExecuteShader (ps_main)
}

