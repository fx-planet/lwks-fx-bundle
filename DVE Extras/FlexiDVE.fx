// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2023-02-17

/**
 Flexible 2D DVE is built around the Lightworks mask effect to emulate a 2D DVE.
 In addition, antialiasing may be applied to the image as it is scaled.  This
 gives a more natural image softening as the image is enlarged, rather than the
 jagged edges that may sometimes appear.  It can also smooth the image during
 reduction.  Note that it isn't designed to remove aliasing already present in
 your video, only to reduce any aliasing contributed by the DVE.  That said,
 even though it's not designed to fix image aliassing, it may help.

 There is also a difference in the way that the drop shadow is produced.  Instead
 of being derived from the cropped edges of the frame as it is in the Lightworks
 2D DVE the masked foreground alpha channel is used.  This means that the drop
 shadow will only appear where it should and not just at the edge of frame, as it
 does with the Lightworks effect.

 Finally, Z-axis rotation has been added.  Because I don't have access to the
 widgets that Lightworks uses for rotation I have had to use faders to set that.
 It is at best a workaround, and has the unfortunate side effect that complete
 revolutions can't be set as integer values.  If you need that degree of accuracy
 you must type in the number of revolutions that you need manually.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlexiDVE.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Flexible 2D DVE", "DVE", "DVE Extras", "A flexible masked 2D DVE with Z-axis rotation", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Xpos, "Pos", "Position", "SpecifiesPointX|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (Ypos, "Pos", "Position", "SpecifiesPointY|DisplayAsPercentage", 0.5, -1.0, 2.0);

DeclareFloatParam (Degrees, "Degrees", "Rotation", kNoFlags, 0.0, -360.0, 360.0);
DeclareFloatParam (Revolutions, "Revolutions", "Rotation", kNoFlags, 0.0, -20.0, 20.0);

DeclareFloatParam (MasterScale, "Master", "Scaling", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (XScale, "Scale X", "Scaling", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (YScale, "Scale Y", "Scaling", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (Antialias, "Antialiasing", "Scaling", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (ShadowOpacity, "Opacity", "Shadow", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (ShadeX, "X Offset", "Shadow", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (ShadeY, "Y Offset", "Shadow", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define RADIUS 0.0005
#define ANGLE  0.7853981633

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Bgd)
// We now first map the background coordinates to the sequence geometry.
{ return ReadPixel (Bg, uv2); }

DeclarePass (Fgd)
// By performing the masking ahead of anything else we can compensate for image
// rotation and scaling without impacting the rest of the effect in any way.
{
   float4 Fgnd = lerp (kTransparentBlack, ReadPixel (Fg, uv1), tex2D (Mask, uv3).x);

   return lerp (kTransparentBlack, Fgnd, tex2D (Mask, uv3).x);
}

DeclarePass (Dve)
// Because we have mapped the foreground onto the sequence coordinates we no
// longer need to correct for resolution and aspect ratio differences.
{
   // First we recover the raw scale factors.

   float xScale = max (0.0001, MasterScale * XScale);
   float yScale = max (0.0001, MasterScale * YScale);

   // Now we adjust the foreground position (xy1) and from that calculate the
   // drop shadow offset and put that in xy2.  The values of both are centred
   // around the screen midpoint.

   float2 xy1 = uv3 + float2 (0.5 - Xpos, Ypos - 0.5);
   float2 xy2 = xy1 - float2 (ShadeX, ShadeY);

   // We now perform the scaling of the foreground coordinates, allowing for
   // the aspect ratio.  The drop shadow offset is scaled to match to the
   // foreground scaling.

   xy1.x = (xy1.x - 0.5) * _OutputAspectRatio / xScale;
   xy1.y = (xy1.y - 0.5) / yScale;
   xy2.x = lerp (xy1.x, (xy2.x - 0.5) * _OutputAspectRatio / xScale, xScale);
   xy2.y = lerp (xy1.y, (xy2.y - 0.5) / yScale, yScale);

   // The rotation is now calculated using matrix multiplication.

   float c, s, angle = radians ((Revolutions * 360.0) + Degrees);

   sincos (angle, s, c);
   xy1 = mul (float2x2 (c, s, -s, c), xy1);
   xy2 = mul (float2x2 (c, s, -s, c), xy2);

   // Aspect ratio adjustment and centring is now removed for xy1 and xy2.

   xy1.x /= _OutputAspectRatio; xy1 += 0.5.xx;
   xy2.x /= _OutputAspectRatio; xy2 += 0.5.xx;

   // Recover the background, foreground and raw drop shadow data.

   float4 Fgnd = ReadPixel (Fgd, xy1);
   float4 Bgnd = ReadPixel (Bgd, uv3);

   float Shdw = ReadPixel (Fgd, xy2).a;

   // Create the drop shadow over the background.  Throughout the rest of this
   // process the background RGB data is retained, but the background is
   // transparent.  This improves the look of the antialiassed edges later on.

   Bgnd = lerp (Bgnd, kTransparentBlack, Shdw * ShadowOpacity);

   // Now add the cropped foreground and return.

   Fgnd.rgb = lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a);
   Fgnd.a   = max (Fgnd.a, Shdw);

   return Fgnd;
}

DeclareEntryPoint (FlexiDVE)
{
   // Recover the DVE processed foreground and the background

   float4 Fgnd = tex2D (Dve, uv3);
   float4 Bgnd = ReadPixel (Bgd, uv3);

   // Now antialias the foreground

   float2 xy1, xy2, scale = float2 (1.0, _OutputAspectRatio) * Antialias * RADIUS;

   float angle = 0.0;

   // The antialias is an eight by 45 degree rotary blur at three samples deep.  The outer
   // loop achieves eight steps in 4 passes by using both positive and negative offsets.

   for (int i = 0; i < 4; i++) {
      sincos (angle, xy1.x, xy1.y);
      xy1 *= scale;
      xy2 = xy1;

      for (int j = 0; j < 3; j++) {
         Fgnd += tex2D (Dve, uv3 + xy1);
         Fgnd += tex2D (Dve, uv3 - xy1);
         xy1 += xy2;
      }

      angle += ANGLE;
   }

   Fgnd /= 25.0;

   // Return the foreground, drop shadow and background composite

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

