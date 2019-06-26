// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2017-06-01
// @see https://www.lwks.com/media/kunena/attachments/6375/SoftSpinBlur_640.png

/**
During the development of this effect particular attention has been given to the blur
sample rate.  The effect achieves 108 samples by using three consecutive passes of
36 samples each at finer and finer pitch.  This is an oversampling technique which
results in a theoretical sample rate of greater than 45,000.  As a result a full 180
degrees of arc can be blurred without the sampling becoming too obvious even if the
blur centre is at the corner of the frame.

The blur arc method used is bi-directional and produces a symmetrical blur.  For
example, a 30 degree arc is produced by applying dual 15 degree clockwise and anti-
clockwise blurs.  A level tracking parameter has been included to compensate for the
inevitable upward drift in blacks and downward drift in whites that such a strong
blur can cause.

Blur density reduces the blur effect to zero.  Blur aspect ratio is set in percentage
change values and swings between 1:5 and 5:1.  The blur centring can be set either by
means of the sliders or by dragging with the mouse in the edit sequence viewer.  Blurs
cannot be dragged off screen, but manually entering values will allow this if desired.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftSpinBlur.fx
//
// The impetus to develop this spin blur effect was triggered by windsturm's effect,
// FxSpinBlur.  Since this was written from the ground up any similarity to that work
// is entirely coincidental.  In the interests of interface consistency an attempt was
// made to match the parameters in that effect.  Due to other design decisions that has
// not been completely possible.
//
// Re-arranged the user interface 6 July 2017.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
//
// Modified by LW user jwrl 23 December 2018.
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Soft spin blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This effect uses a bidirectional blur to give an extremely smooth spin blur";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture blur_1 : RenderColorTarget;
texture blur_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InpSampler = sampler_state {
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler b1_Sampler = sampler_state {
   Texture   = <blur_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler b2_Sampler = sampler_state {
   Texture   = <blur_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Arc
<
   string Description = "Blur arc degrees";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 45.0;

float Amount
<
   string Description = "Blur density";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Aspect
<
   string Description = "Aspect ratio";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CentreX
<
   string Description = "Blur centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CentreY
<
   string Description = "Blur centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Tracking
<
   string Description = "Level tracking";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define STEPS   18
#define DIVISOR 18.975

#define SCALE_1 36
#define SCALE_2 108
#define SCALE_3 324

#define WEIGHT  1.0
#define WT_DIFF 0.0555556

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_blur (float2 uv : TEXCOORD1, uniform sampler blurSampler, uniform int scale) : COLOR
{
   if ((Amount == 0.0) || (Arc == 0.0)) return tex2D (InpSampler, uv);

   float4 retval = 0.0.xxxx;

   float spin   = radians (Arc) / scale;
   float weight = WEIGHT;
   float angle  = 0.0;
   float C, S;

   float2 blur_aspect  = float2 (1.0, (1.0 - (max (Aspect, 0.0) * 0.8) - (min (Aspect, 0.0) * 4.0)) * _OutputAspectRatio);
   float2 fxCentre     = float2 (CentreX, 1.0 - CentreY);
   float2 xy1, xy2, xy = (uv - fxCentre) / blur_aspect;
   float2 xyC, xyS;

   for (int i = 0; i < STEPS; i++) {
      sincos (angle, S, C);

      xyC = xy * C;
      xyS = float2 (xy.y, -xy.x) * S;
      xy1 = (xyC + xyS) * blur_aspect + fxCentre;
      xy2 = (xyC - xyS) * blur_aspect + fxCentre;

      retval += ((tex2D (blurSampler, xy1) + tex2D (blurSampler, xy2)) * weight);

      weight -= WT_DIFF;
      angle  += spin;
   }

   return retval / DIVISOR;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float offset = 0.7 - (Arc / 600.0);
   float adjust = 1.0 + (Arc / 270.0);

   float4 retval = tex2D (b1_Sampler, uv);
   float4 repair = float4 (((retval.rgb - offset.xxx) * adjust) + offset.xxx, retval.a);

   retval = lerp (retval, repair, Tracking);

   return lerp (tex2D (InpSampler, uv), retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SoftSpinBlur
{
   pass P_1
   < string Script = "RenderColorTarget0 = blur_1;"; >
   { PixelShader = compile PROFILE ps_blur (InpSampler, SCALE_1); }

   pass P_2
   < string Script = "RenderColorTarget0 = blur_2;"; >
   { PixelShader = compile PROFILE ps_blur (b1_Sampler, SCALE_2); }

   pass P_3
   < string Script = "RenderColorTarget0 = blur_1;"; >
   { PixelShader = compile PROFILE ps_blur (b2_Sampler, SCALE_3); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}
