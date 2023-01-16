// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect performs a transition between two sources.  During the process it applies a
 rotational blur, the direction, aspect ratio, centring and strength of which can be
 adjusted.

 To better handle varying aspect ratios code has been included to allow the blur to
 exceed the input frame boundaries.  The subjective effect of this changes as the effect
 progresses, thus allowing for differing incoming and outgoing media aspect ratios.

 The blur section is based on a rotational blur converted by Lightworks user windsturm
 from original code created by rakusan - http://kuramo.ch/webgl/videoeffects/

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Spin_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Spin dissolve", "Mix", "Blur transitions", "Uses a rotational blur to transition between two sources", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (CW_CCW, "Rotation direction", "Spin", 1, "Anticlockwise|Clockwise");

DeclareFloatParam (blurLen, "Arc (degrees)", "Spin", kNoFlags, 90.0, 0.0, 180.0);
DeclareFloatParam (aspectRatio, "Aspect 1:x", "Spin", kNoFlags, 1.0, 0.0, 10.0);

DeclareFloatParam (CentreX, "Centre", kNoGroup, "SpecifiesPointX|DisplayAsPercentage", 0.5, -0.5, 1.5);
DeclareFloatParam (CentreY, "Centre", kNoGroup, "SpecifiesPointY|DisplayAsPercentage", 0.5, -0.5, 1.5);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define RANGE_1    24
#define RANGE_2    48
#define RANGE_3    72
#define RANGE_4    96
#define RANGE_5    120

#define SAMPLES    120
#define INC_OFFSET 1.0 / SAMPLES
#define RETSCALE   (SAMPLES + 1) / 2.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_FgBlur (sampler F, float2 uv, int base)
{
   int range = base + RANGE_1;

   float blurAngle, Tcos, Tsin;
   float spinAmt  = (radians (blurLen * saturate (Amount + 0.04))) / SAMPLES;
   float spinOffs = 1.0 - (INC_OFFSET * base);

   float2 blurAspect  = float2 (1.0, aspectRatio * _OutputAspectRatio);
   float2 centreXY    = float2 (CentreX, 1.0 - CentreY);
   float2 angleXY, xy = (uv - centreXY) / blurAspect;

   float4 retval = tex2D (F, uv);
   float4 image  = retval;

   spinAmt = (CW_CCW == 0) ? spinAmt * 2.0 : spinAmt * -2.0;
   blurAngle = spinAmt * base;

   for (int i = base; i < range; i++) {
      sincos (blurAngle, Tsin, Tcos);
      angleXY = (float2 ((xy.x * Tcos - xy.y * Tsin), (xy.x * Tsin + xy.y * Tcos)) * blurAspect) + centreXY;

      retval += (tex2D (F, angleXY) * spinOffs);

      blurAngle += spinAmt;
      spinOffs -= INC_OFFSET;
   }

   return retval /= RETSCALE;
}

float4 fn_BgBlur (sampler B, float2 uv, int base)
{
   int range = base - RANGE_1;

   float blurAngle, Tcos, Tsin;
   float spinAmt  = (radians (blurLen * saturate (0.96 - Amount))) / SAMPLES;
   float spinOffs = 1.0 - (INC_OFFSET * base);

   float2 blurAspect  = float2 (1.0, aspectRatio * _OutputAspectRatio);
   float2 centreXY    = float2 (CentreX, 1.0 - CentreY);
   float2 angleXY, xy = (uv - centreXY) / blurAspect;

   float4 retval = tex2D (B, uv);
   float4 image  = retval;

   spinAmt = (CW_CCW == 0) ? spinAmt * 2.0 : spinAmt * -2.0;
   blurAngle = spinAmt * (1 - base);

   for (int i = base; i > range; i--) {
      sincos (blurAngle, Tsin, Tcos);
      angleXY = (float2 ((xy.x * Tcos - xy.y * Tsin), (xy.x * Tsin + xy.y * Tcos)) * blurAspect) + centreXY;

      retval += (tex2D (B, angleXY) * spinOffs);

      blurAngle += spinAmt;
      spinOffs -= INC_OFFSET;
   }

   return retval /= RETSCALE;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Rot_1)
{ return fn_FgBlur (Fgd, uv3, 0); }

DeclarePass (Rot_2)
{ return fn_FgBlur (Fgd, uv3, RANGE_1); }

DeclarePass (Rot_3)
{ return fn_FgBlur (Fgd, uv3, RANGE_2); }

DeclarePass (Rot_4)
{ return fn_FgBlur (Fgd, uv3, RANGE_3); }

DeclarePass (Fblur)
{ return fn_FgBlur (Fgd, uv3, RANGE_4); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Spin1)
{ return fn_BgBlur (Bgd, uv3, RANGE_5); }

DeclarePass (Spin2)
{ return fn_BgBlur (Bgd, uv3, RANGE_4); }

DeclarePass (Spin3)
{ return fn_BgBlur (Bgd, uv3, RANGE_3); }

DeclarePass (Spin4)
{ return fn_BgBlur (Bgd, uv3, RANGE_2); }

DeclarePass (Bblur)
{ return fn_BgBlur (Bgd, uv3, RANGE_1); }

DeclareEntryPoint (Spin_Dx)
{
   float4 outgoing = tex2D (Fblur, uv3);
   float4 incoming = tex2D (Bblur, uv3);

   outgoing += tex2D (Rot_1, uv3) + tex2D (Rot_2, uv3);
   outgoing += tex2D (Rot_3, uv3) + tex2D (Rot_4, uv3);
   outgoing = lerp (tex2D (Fgd, uv3), outgoing, saturate (Amount * 8.0));

   incoming += tex2D (Spin1, uv3) + tex2D (Spin2, uv3);
   incoming += tex2D (Spin3, uv3) + tex2D (Spin4, uv3);
   incoming = lerp (tex2D (Bgd, uv3), incoming, saturate ((1.0 - Amount) * 8.0));

   float mix = (Amount - 0.5) * 2.0;

   mix = (1.0 + (abs (mix) * mix)) / 2.0;

   return lerp (outgoing, incoming, mix);
}

