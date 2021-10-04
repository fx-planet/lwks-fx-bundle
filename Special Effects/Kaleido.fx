// @Maintainer jwrl
// @Released 2021-10-03
// @Author baopao
// @Author nouanda
// @Author jwrl
// @Created 2013-06-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Kaleido_B_640.png

/**
 Kaleido produces the classic kaleidoscope effect.  The number of sides, the centering,
 scaling and zoom factor are all adjustable.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Kaleido.fx
//
// This effect is a rewrite of Kaleido by baopao (http://www.alessandrodallafontana.com)
// which was based on http://pixelshaders.com/ and corrected for Cg by Lightworks user
// nouanda.  Further modifications by jwrl corrected some divide by zero errors.
//
// This rewrite of 17 November 2018 by jwrl addresses several bugs that were introduced
// during compatibility fixing and other adjustments.  A trigonometric bug caused by the
// use of atan2() instead of atan() has been found and corrected.  A modulo bug caused
// by replacing GLSL's mod() with Cg's fmod() has also been addressed.  The way that the
// two functions handled negative values was different enough to cause problems.  In the
// debug process it was found that values of uv.x equal to PosX could have caused divide
// by zero errors so that has been corrected.  For the same reason, the Sides parameter
// has been range limited.  This means that setting Sides to zero can no longer fill the
// screen with a single pixel (Windows) or black (Linux).  Instead an oval pattern will
// be displayed.
//
// A slight user interface improvement is the change of the "Input" node to "Inp".
// This should make routing displays clearer.  Also aimed at improving the interface,
// the removal of the original uv.x inversion and replacing it with PosY inversion now
// allows dragging of the centre point of the pattern with the mouse in "Settings" mode.
//
// Finally, the original creation date was found and added here.
//
// Version history:
//
// Update 2021-10-03 jwrl.
// Rename from Kaleido B to Kaleido.
// Added macros for common effects needs.
//
// Update 2020-11-15 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 5 December 2018 jwrl.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Kaleido";
   string Category    = "Stylize";
   string SubCategory = "Special Effects";
   string Notes       = "The number of sides in this kaleidoscope, the centering, scaling and zoom factor are all adjustable";
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
texture TEXTURE;                      \
                                      \
sampler SAMPLER = sampler_state       \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = Mirror;                \
   AddressV  = Mirror;                \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define TWO_PI  6.2831853072

#define MINIMUM 0.0000000001

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Side
<
   string Description = "Sides";
   float MinVal = 0.0;
   float MaxVal = 50.0;
> = 5.0;

float Scale
<
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Zoom
<
   string Description = "Zoom";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float PosX
<
   string Description = "Pan";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosY
<
   string Description = "Pan";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 PosXY = float2 (PosX, 1.0 - PosY);
   float2 xy = uv - PosXY;

   float sides = max (MINIMUM, Side);
   float scale = max (MINIMUM, Scale);
   float zoom  = max (MINIMUM, Zoom);
   float radius = length (xy);
   float p = max (MINIMUM, abs (xy.x));

   xy.x = xy.x < 0.0 ? -p : p;

   float angle = atan (xy.y / xy.x);

   p = TWO_PI / sides;
   angle -= p * floor (angle / p);
   angle = abs (angle - (p * 0.5));

   sincos (angle, xy.y, xy.x);
   xy = ((xy * radius / zoom) + PosXY) / scale;

   return tex2D (s_Input, xy);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Kaleido { pass P_1 ExecuteShader (ps_main) }

