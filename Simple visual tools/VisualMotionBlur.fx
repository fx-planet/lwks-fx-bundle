// @Maintainer jwrl
// @Released 2020-07-10
// @Author jwrl
// @Created 2020-07-09
// @see https://www.lwks.com/media/kunena/attachments/6375/VisMotionBlur_640.png

/**
 A directional blur that can be used to simulate fast motion, whip pans and the like.  This
 differs from other blur effects in that it is set up by visually dragging a central pin
 point in the record viewer to adjust the angle and strength of the blur.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VisualMotionBlur.fx
//
// Version history:
//
// Modified 2020-07-10 jwrl.
// Corrected cross-platform discrepancy in float/float2 calculation in distance().
// Fully commented the effect (finally!!!)
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Visual motion blur";
   string Category    = "Stylize";
   string SubCategory = "Simple visual tools";
   string Notes       = "A directional blur that can be quickly set up by visually dragging a central pin point.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state {
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
    string Description = "Blur amount";
    float MinVal = 0.0;
    float MaxVal = 1.0;
> = 1.0;

float Blur_X
<
   string Description = "Blur";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Blur_Y
<
   string Description = "Blur";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Lightworks version must be 14.5 or better
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define EMPTY   0.0.xxxx
#define XY      1.0.xx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv)
{
   // This in conjunction with Mirror addressing guarantees that edge pixels repeat.
   // This is necessary because Mirror addressing alone can result in wrap around.
   // Clamp/ClampToEdge UV addressing can create unpredictable edge artefacts too.

   return tex2D (s, saturate (uv));
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Input, uv);

   // Centre the cursor X-Y coordiantes around zero.

   float2 xy0 = float2 (0.5 - Blur_X, (Blur_Y - 0.5) * _OutputAspectRatio);

   // If the amount is zero or less, or if xy0 is zero quit without doing anything.

   if ((Amount <= 0.0) || (distance (0.0.xx, xy0) == 0.0)) return Fgnd;

   // Initialise the mix value, initial pixel address and blur sample.

   float mix = 0.0327868852;
   float2 xy1 = uv;
   float4 Blur = Fgnd * mix;

   // Scale xy0 so that the derived blur length is reasonable and easily controlled.

   xy0 *= 0.005;

   // Do a directional blur by progressively sampling pixels at 60 deep, offset more
   // and more, and reducing their mix amount to zero linearly to fade the blur out.

   for (int i = 0; i < 60; i++) {
      mix -= 0.0005464481;
      xy1 += xy0;
      Blur += fn_tex2D (s_Input, xy1) * mix;
   }

   // Finally mix the blur back into the original foreground video.

   return lerp (Fgnd, Blur, Amount);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique VisualMotionBlur
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

