// @Maintainer jwrl
// @Released 2018-06-04
// @Author jwrl
// @Created 2018-06-04
// @see https://www.lwks.com/media/kunena/attachments/6375/AnamorphicFx_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect AnamorphicFx.fx
//
// This effect is a comprehensive toolbox to support anamorphic video.  It automatically
// pillarboxes or letterboxes, depending on the aspect ratio selected.  It also has the
// ability to pan and scan - in that mode there is no pillarbox or letterbox.  Instead
// the frame is filled and the pan and scan control is used to pan or tilt within the
// corrected frame.  That control will never overrun the frame boundary, and will always
// be scaled to work across the full control range.  This ensures that maximum precision
// for pan and scan positioning is always available.
//
// Finally, a letterbox function is provided to clean up anything unwanted.  This is
// applied after everything else, and cannot be zoomed or positioned. A comprehensive
// range of preset aspect ratios is provided, but if they don't meet the need custom
// aspect ratios from 1:2 (0.5:1) to 4:1 can be set manually.
//
// NOTE:  Where letterbox or pillarbox boundaries are exceeded the alpha channel will be
// set to zero.  That means that the output of this effect can be blended with background
// layers using Blend, DVEs and the like.
//
// Modified 2018-06-04 jwrl.
// Range limited CustomAspect and CustomLetterbox to prevent divide by zero.  I also
// realised that I didn't need a second pass to perform the letterbox, so I removed it.
// It won't make a huge difference, but it should execute slightly more efficiently.
//
// Modified 2018-06-05 jwrl.
// Re-ordered parameters, added the ability to correct non-full frame anamorphs.
//
// Modified 2018-06-16 jwrl.
// Explicitly defined addressing modes to avoid a flicker on frame boundaries.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Anamorphic tools";
   string Category    = "DVE";
   string SubCategory = "Custom";
   string Note        = "A general purpose toolkit for dealing with anamorphic footage";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY (0.0).xxxx

float _OutputAspectRatio;

float _aspect [] = { 0.0, 1.33333333, 1.375, 1.5, 1.66666667, 1.77777778,
                     1.85, 1.8962963, 2.2, 2.35, 2.39, 2.76, 3.5, 0.0 };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int InputFormat
<
   string Group = "Anamorphic correction";
   string Description = "Frame format";
   string Enum = "Full frame input (pan and scan allowed),Squeezed and boxed (pan and scan unavailable)";
> = 0;

int AspectRatio
<
   string Group = "Anamorphic correction";
   string Description = "Aspect ratio";
   string Enum = "Bypass,1.33:1 (SD 4:3),1.375:1 (Classic academy),1.5:1 (VistaVision),1.66:1 (Super 16),1.78:1 (HD 16:9),1.85:1 (US widescreen),1.9:1 (2K),2.2:1 (70 mm/Todd-AO),2.35:1 (pre-1970 Cinemascope),2.39:1 (Panavision),2.76:1 (Ultra Panavision),3.5:1 (Ultra Wide Screen),Custom";
> = 0;

float CustomAspect
<
   string Group = "Anamorphic correction";
   string Description = "Custom aspect";
   float MinVal = 0.5;
   float MaxVal = 4.0;
> = 1.78;

bool PanAndScan
<
   string Group = "Anamorphic correction";
   string Description = "Pan and scan";
> = false;

float PanPosition
<
   string Group = "Anamorphic correction";
   string Flags = "Pan";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Zoom
<
   string Group = "Scale and position";
   string Description = "Zoom";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float PosX
<
   string Group = "Scale and position";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float PosY
<
   string Group = "Scale and position";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

int Letterbox
<
   string Group = "Letterbox";
   string Description = "Aspect ratio";
   string Enum = "Bypass,1.33:1 (SD 4:3),1.375:1 (Classic academy),1.5:1 (VistaVision),1.66:1 (Super 16),1.78:1 (HD 16:9),1.85:1 (US widescreen),1.9:1 (2K),2.2:1 (70 mm/Todd-AO),2.35:1 (pre-1970 Cinemascope),2.39:1 (Panavision),2.76:1 (Ultra Panavision),3.5:1 (Ultra Wide Screen),Custom";
> = 0;

float CustomLetterbox
<
   string Group = "Letterbox";
   string Description = "Custom aspect";
   float MinVal = 0.5;
   float MaxVal = 4.0;
> = 1.78;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float zoom = max (Zoom + 1.0, 0.0001);
   float size = AspectRatio == 0 ? _OutputAspectRatio : _aspect [AspectRatio];

   if (size == 0.0) size = max (CustomAspect, 0.0001);

   float ratio = size / _OutputAspectRatio;

   float2 xy1 = uv - 0.5.xx;

   if (InputFormat == 1) {
      if (ratio < 1.0) xy1.x *= ratio;
      else xy1.y /= ratio;
   }
   else if (PanAndScan) {
      if (ratio < 1.0) {
         xy1.y *= ratio;
         xy1.y -= PanPosition * (ratio - 1.0) * 0.5;
      }
      else {
         xy1.x /= ratio;
         xy1.x -= PanPosition * (size - _OutputAspectRatio) * 0.5 / size;
      }
   }
   else if (ratio < 1.0) xy1.x /= ratio;
   else xy1.y *= ratio;

   xy1 /= zoom;
   xy1 -= float2 (PosX, -PosY);

   float2 xy2 = abs (xy1);

   xy1 += 0.5.xx;

   float4 retval = max (xy2.x, xy2.y) > 0.5 ? EMPTY : tex2D (s_Input, xy1);

   if (Letterbox != 0) {
      xy2 = abs (uv - 0.5.xx);
      ratio = _aspect [Letterbox];

      if (ratio == 0.0) ratio = max (CustomLetterbox, 0.0001);

      ratio /= _OutputAspectRatio;

      if (ratio < 1.0) xy2.x /= ratio;
      else xy2.y *= ratio;

      if (max (xy2.x, xy2.y) > 0.5) return EMPTY;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Anamorphic
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
