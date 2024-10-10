// @Maintainer jwrl
// @Released 2024-10-10
// @Author jwrl
// @Created 2024-07-31

/**
 Quad split with transform is designed as a single effect replacement for Lightworks'
 quad split template.  It has been enhanced to help in the creation of these often
 used multiscreen effects.  This version is a complete rewrite of the original 2024
 January 28 version and the July 23 revision.

 So what does the effect have?  First, a downstream transform effect similar to the
 Lightworks transform effect is included.  This means that all in the one effect you
 can build a quad split, then resize, position and mask it over a background layer.
 While very similar to the Lightworks transform, this part of the effect does not
 include cropping.  It would be simplicity itself to add it to the master transform,
 but it was felt that the settings were complex enough without it and that masking
 also provided it.  Masking is applied before the drop shadow is generated, so that
 the masked area of the foregound is tracked by the shadow.

 The individual quad split settings default to give a standard quad split when first
 applied. They provide positioning, scaling and masking.  The order of priority of
 the video layers in the quad is V1 is on top of everything else and that layer
 defaults to the top left of the screen.  Next is V2 at top right, then V3 at bottom
 left, and finally V4 at bottom right.  There is enough adjustment range to move any
 or all to whatever quadrant you need.  Edge softness can then be applied to those
 four images.

 Finally, the background can be zoomed.  The same range of adjustment that the
 Lightworks zoom provides is available.  Unfortunately it is not possible to match
 the on-screen zoom scaling and positioning that the Lightworks effect has because
 there will inevitably be conflicts with the quad split centre and corner pins.
 Instead a switch has been provided to help set zoom up.

 Zoom setup mode greys the background outside the zoom and position bounds.  It also
 hides any quad split, and the Lightworks masks (if any) are bypassed.  You can't drag
 the framing on screen as you can with the Lightworks zoom.  In setup mode the sense
 of any position adjustments are as you would expect, but that means that in working
 mode their movement is inverted vertically.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadSplitTransform.fx
//
// Version history:
//
// Updated 2024-10-10 jwrl.
// Fixed drop shadow transparency.  Fading it up previously caused increased opacity.
// Corrected foreground opacity seeming to fade through black when a drop shadow is used.
//
// Updated 2024-07-31 jwrl.
// Second rewrite to FINALLY fix edge softness properly.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Quad split with transform", "DVE", "Transform plus", "A quad split with master transform and background zoom", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

// The four foreground layers are designed to mirror when the address overflows so
// that when we soften any of those frames we will have video available to fill the
// soft edges even when the whole frame is used.

DeclareInput (V1, Linear, Mirror);
DeclareInput (V2, Linear, Mirror);
DeclareInput (V3, Linear, Mirror);
DeclareInput (V4, Linear, Mirror);

DeclareInput (Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Xpos, "Position", kNoGroup, "SpecifiesPointX|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (Ypos, "Position", kNoGroup, "SpecifiesPointY|DisplayAsPercentage", 0.5, -1.0, 2.0);

DeclareFloatParam (MasterScale, "Master", "Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (XScale, "X Scale", "Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (YScale, "Y Scale", "Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);

DeclareFloatParam (Transparency, "Transparency", "Shadow", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (ShadeX, "X offset", "Shadow", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (ShadeY, "Y offset", "Shadow", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (OpacityV1, "Opacity", "Video 1", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Xpos1, "Position", "Video 1", "SpecifiesPointX", 0.25, 0.0, 1.0);
DeclareFloatParam (Ypos1, "Position", "Video 1", "SpecifiesPointY", 0.75, 0.0, 1.0);

DeclareFloatParam (FullScale1, "Master", "Video 1 > Scale", "DisplayAsPercentage", 0.5, 0.0, 10.0);
DeclareFloatParam (XScale1, "X scale", "Video 1 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (YScale1, "Y scale", "Video 1 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);

DeclareFloatParam (Tcrop1, "Top", "Video 1 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Lcrop1, "Left", "Video 1 > Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Rcrop1, "Right", "Video 1 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Bcrop1, "Bottom", "Video 1 > Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (OpacityV2, "Opacity", "Video 2", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Xpos2, "Position", "Video 2", "SpecifiesPointX", 0.75, 0.0, 1.0);
DeclareFloatParam (Ypos2, "Position", "Video 2", "SpecifiesPointY", 0.75, 0.0, 1.0);

DeclareFloatParam (FullScale2, "Master", "Video 2 > Scale", "DisplayAsPercentage", 0.5, 0.0, 10.0);
DeclareFloatParam (XScale2, "X scale", "Video 2 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (YScale2, "Y scale", "Video 2 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);

DeclareFloatParam (Tcrop2, "Top", "Video 2 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Lcrop2, "Left", "Video 2 > Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Rcrop2, "Right", "Video 2 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Bcrop2, "Bottom", "Video 2 > Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (OpacityV3, "Opacity", "Video 3", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Xpos3, "Position", "Video 3", "SpecifiesPointX", 0.25, 0.0, 1.0);
DeclareFloatParam (Ypos3, "Position", "Video 3", "SpecifiesPointY", 0.25, 0.0, 1.0);

DeclareFloatParam (FullScale3, "Master", "Video 3 > Scale", "DisplayAsPercentage", 0.5, 0.0, 10.0);
DeclareFloatParam (XScale3, "X scale", "Video 3 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (YScale3, "Y scale", "Video 3 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);

DeclareFloatParam (Tcrop3, "Top", "Video 3 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Lcrop3, "Left", "Video 3 > Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Rcrop3, "Right", "Video 3 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Bcrop3, "Bottom", "Video 3 > Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (OpacityV4, "Opacity", "Video 4", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Xpos4, "Position", "Video 4", "SpecifiesPointX", 0.75, 0.0, 1.0);
DeclareFloatParam (Ypos4, "Position", "Video 4", "SpecifiesPointY", 0.25, 0.0, 1.0);

DeclareFloatParam (FullScale4, "Master", "Video 4 > Scale", "DisplayAsPercentage", 0.5, 0.0, 10.0);
DeclareFloatParam (XScale4, "X scale", "Video 4 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (YScale4, "Y scale", "Video 4 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);

DeclareFloatParam (Tcrop4, "Top", "Video 4 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Lcrop4, "Left", "Video 4 > Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Rcrop4, "Right", "Video 4 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Bcrop4, "Bottom", "Video 4 > Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (ShowBounds, "Show bounds", "Background", false);
DeclareFloatParam (BgZoom, "Zoom", "Background", kNoFlags, 1.0, 1.0, 10.0);
DeclareFloatParam (BgXpos, "Position", "Background", "SpecifiesPointX", 0.5, -5.0, 5.0);
DeclareFloatParam (BgYpos, "Position", "Background", "SpecifiesPointY", 0.5, -5.0, 5.0);

DeclareFloatParam (Soften, "Soften borders", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// getCrop inverts the sense of Y axis cropping to match sampler addressing.  Any
// crop overlap is limited and the X and Y parameters are returned as float2 values.

float2 getCrop (float L, float T, float R, float B, out float2 xy)
{
   xy = float2 (R, 1.0 - B);

   return min (float2 (L, 1.0 - T), xy);
}

// setScale limits the minimum scale parameters so that divide by zero errors can't
// occur when scaling the video.  The X and Y scale factors are returned in a float2.

float2 setScale (float Sm, float Sx, float Sy)
{
   float X_scale = max (Sx * Sm, 1.0e-6);
   float Y_scale = max (Sy * Sm, 1.0e-6);

   return float2 (X_scale, Y_scale);
}

// This function combines global and local scale factors and global and local
// position parameters.  This is done in such a way that local scale adjustment
// will always be centred around the local position offset by the global value.
// Scaling is returned by the function itself and position is returned in xy.

float2 init (float scale, float sclX, float sclY, float2 Mscale,
             float2 posM, float posX, float posY, out float2 xy)
{
   float2 sc = Mscale;

   xy  = sc * float2 (posX - 0.5, 0.5 - posY);
   xy += posM;

   return sc * setScale (scale, sclX, sclY);
}

// ReadVideo recovers the scaled, cropped and positioned foreground and combines
// it with the other foreground components supplied in Bgnd.  At the same time
// it sets the video level required by the opacity setting and adds edge softness.

float4 ReadVideo (sampler Fg, float2 uv, float amount, float4 Bgnd, float2 LT,
                  float2 RB,  float2 softness, float2 position, float2 Scale)
{
   uv -= position;
   uv /= Scale;
   uv += 0.5.xx;

   // Recover the video and the masking

   float4 Fgnd = tex2D (Fg, uv);

   // Apply the inner bounds of softness to the crop values.

   float2 lt = LT + softness;
   float2 rb = RB - softness;

   // Apply the outer bounds of softness as well.

   LT -= softness;
   RB += softness;

   // If uv falls outside the crop area simply set amount to zero, otherwise check
   // if it's inside the softness area.  If it is, apply the softness gradient to
   // the amount.

   if ((uv.x < LT.x) || (uv.y < LT.y) || (uv.x > RB.x) || (uv.y > RB.y)) { amount = 0.0; }
   else if ((uv.x < lt.x) || (uv.y < lt.y) || (uv.x > rb.x) || (uv.y > rb.y)) {
      float amtX_1 = smoothstep (LT.x, lt.x, uv.x);
      float amtY_1 = smoothstep (LT.y, lt.y, uv.y);
      float amtX_2 = smoothstep (RB.x, rb.x, uv.x);
      float amtY_2 = smoothstep (RB.y, rb.y, uv.y);

     amount *= min (min (amtX_1, amtY_1), min (amtX_2, amtY_2));
   }

   // If we already have foreground transparency we need to preserve it.

   float key = min (Fgnd.a, amount);

   // If the key value is zero there's no mix so we need do nothing.

   if (key == 0.0) return Bgnd;

   // Mix the foreground with the background, compensating for any level change due
   // to the overlap.

   float mixfix = lerp (key, 0.0, Bgnd.a);

   Bgnd += lerp (_TransparentBlack, Fgnd, mixfix);

   return lerp (Bgnd, Fgnd, key);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Bgd)
{
   float4 retval;

   float2 xy;

   if (ShowBounds) {

      // This section is used when we want to show the masked area of the background
      // that we will be zooming.  To do that we show the actual size video with a
      // grey overlay showing the area that will fall outside the active screen area.

      xy = ((uv5 - 0.5.xx) * max (BgZoom, 1.0)) + float2 (1.0 - BgXpos, BgYpos);
      retval = ReadPixel (Bg, uv2);

      if (IsOutOfBounds (xy)) {
         retval.rgb *= 0.666667;
         retval.rgb += 0.166667.xxx;
      }
   }
   else {

      // This calculates the zoom factor and applies it to the background video.

      xy = ((uv2 - float2 (1.0 - BgXpos, BgYpos)) / max (BgZoom, 1.0)) + 0.5.xx;
      retval = ReadPixel (Bg, xy);
   }

   return retval;
}

DeclarePass (Fgd)
{
   // This is the main quad split engine.  The order in which the video layers are
   // processed are the reverse of the layer priority.  This is done so that V1 is
   // the top layer when processed and V4 is the bottom.  The first components that
   // we need to produce are the global values of position, softness and scale.

   float2 Mpos = float2 (Xpos, 1.0 - Ypos);
   float2 soft = float2 (1.0, _OutputAspectRatio) * Soften * 0.125;
   float2 Mscl = setScale (MasterScale, XScale, YScale);

   // The individual crop settings plus position and scale factors are obtained for
   // V4, along with its opacity setting combined with the global opacity.

   float2 cBR, cTL = getCrop (Lcrop4, Tcrop4, Rcrop4, Bcrop4, cBR);
   float2 pos, scl = init (FullScale4, XScale4, YScale4, Mscl, Mpos, Xpos4, Ypos4, pos);

   // It's now just a matter of using ReadVideo() to recover V4, scaled, cropped
   // and positioned as needed, and applied to a transparent black background.
   // We also get the foreground video mask for later use.

   float4 Vn    = ReadVideo (V4, uv4, OpacityV4, _TransparentBlack, cTL, cBR, soft, pos, scl);
   float4 Vmask = ReadPixel (Mask, uv6);

   // Repeat the process for the remaining video layers, using Vn instead of black.

   cTL = getCrop (Lcrop3, Tcrop3, Rcrop3, Bcrop3, cBR);
   scl = init (FullScale3, XScale3, YScale3, Mscl, Mpos, Xpos3, Ypos3, pos);

   Vn = ReadVideo (V3, uv3, OpacityV3, Vn, cTL, cBR, soft, pos, scl);

   cTL = getCrop (Lcrop2, Tcrop2, Rcrop2, Bcrop2, cBR);
   scl = init (FullScale2, XScale2, YScale2, Mscl, Mpos, Xpos2, Ypos2, pos);

   Vn = ReadVideo (V2, uv2, OpacityV2, Vn, cTL, cBR, soft, pos, scl);

   cTL = getCrop (Lcrop1, Tcrop1, Rcrop1, Bcrop1, cBR);
   scl = init (FullScale1, XScale1, YScale1, Mscl, Mpos, Xpos1, Ypos1, pos);

   // Because we're getting the last layer we also apply any masking that we need.
   // Doing it here means that the drop shadow will include the mask.

   return ReadVideo (V1, uv1, OpacityV1, Vn, cTL, cBR, soft, pos, scl) * Vmask.x;
}

DeclareEntryPoint (QuadSplitTransform)
{
   // We first recover the background and check whether we just need to show the
   // zoom settings.  If so we can quit.

   float4 Bgnd = ReadPixel (Bgd, uv6);

   if (ShowBounds) return Bgnd;

   // Now we create the drop shadow offset and put that in xy, correcting it for
   // the output aspect ratio.

   float2 xy = uv6 - float2 (ShadeX / _OutputAspectRatio, -ShadeY);

   // Now recover the foreground and the drop shadow and combine their alpha values.

   float4 Fgnd = ReadPixel (Fgd, uv6);

   Fgnd.a = max (Fgnd.a, lerp (ReadPixel (Fgd, xy).a, 0.0, Transparency));

   // The foreground and drop shadow is now combined with the background and we quit.

   return lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
}

