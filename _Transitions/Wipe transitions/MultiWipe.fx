// @Maintainer jwrl
// @Released 2024-05-15
// @Author jwrl
// @Created 2024-05-15

/**
 This is a transition that uses a series of zooming and overlapping wipes consisting of
 concentric circular and square shapes.  The term "wipe" is used her for convenience.
 The effect is actually more like a masked transform.

 The wipes can be reversed in order and can also be used to wipe the incoming video in
 or the outgoing video out.  By default the wipe start times are sequential: as one wipe
 ends the next begins.  However up to a 75% overlap can be dialled in, adding to the
 visual complexity effect.  This is strictly range limited.  There is no point in trying
 to manually increase the overlap by typing in a higher percentage.  It will be clamped
 to 75%.

 The wipes fade in with a very smooth non-linear profile, reaching full strength at the
 half way point of each individual wipe.  When the wipe direction is reversed they fade
 out with the same profile.

 They can be used to wipe blended media with exactly the same range of
 adjustment, with one notable exception.  For consistency with other effects that do
 blend transitions, the main direction setting is made inactive when using blend mode.
 Instead the normal "Transition into blend" setting is used for that purpose.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
 If the transition duration is shorter in frames than the number of wipes chosen the
 results will be unpredictable.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MultiWipe.fx
//
// Version history:
//
// Built 2024-05-15 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("MultiWipe", "Mix", "Wipe transitions", "Performs a series of zooming circular or square wipes", "CanSize|HasMinOutputSize|HasMaxOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (CentreX,  "Centre", "Set up", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY,  "Centre", "Set up", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareIntParam (WipeShape,    "Wipe shape",       "Set up", 0, "Circle|Square");
DeclareIntParam (SetTechnique, "Number of shapes", "Set up", 2, "One|Two|Three|Four|Five");

DeclareFloatParam (Overlap, "Overlap", "Set up", "DisplayAsPercentage", 0.0, 0.0, 0.75);

DeclareIntParam (BuildDirection, "Build direction",      "Set up", 0, "Forward|Reverse");
DeclareIntParam (TransDirection, "Transition direction", "Set up", 0, "Incoming|Outgoing");

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image key or title without input");

DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);

DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);

DeclareBoolParam (ShowKey,    "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources",        "Blend settings", false);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI 1.5708
#define SQUARE  1

// Wipe scale factors.  These are symmetrical.

float _scale[] = { 1.625, 1.625,                               // Wipe scales       0 - 1
                   1.5,   1.25,  1.5,                          // Two wipe scales   2 - 4
                   1.75,  1.625, 1.625, 1.75,                  // Three wipe scales 5 - 8
                   1.875, 1.25,  1.625, 1.25,  1.875,          // Four wipe scales  9 - 13
                   1.625, 1.5,   1.25,  1.25,  1.5,   1.625 }; // Five wipe scales 14 - 19

// Wipe boundary presets.

float2 _range[] = { { 0.0,    0.4    }, { 0.4,    2.0    },                      // One
                    { 0.3625, 0.4875 }, { 0.0,    0.3625 }, { 0.4875, 2.0    },  // Two
                    { 0.0,    0.325  }, { 0.45,   0.575  }, { 0.325,  0.45   },  // Three
                    { 0.575,  2.0    },
                    { 0.0,    0.2875 }, { 0.5375, 0.6625 }, { 0.2875, 0.4125 },  // Four
                    { 0.6625, 2.0    }, { 0.4125, 0.5375 },
                    { 0.0,    0.25   }, { 0.5,    0.625  }, { 0.25,   0.375  },  // Five
                    { 0.625,  0.75   }, { 0.375,  0.5    }, { 0.75,   2.0    } };

// Wipe displacement values - there are 20 float2 values needed in a pseudo random pattern.

float2 _dsplmnt[] = { {  0.25,  0.25  }, { -0.1,   -0.28  },                     // One
                      {  0.2,   0.3   }, { -0.35,   0.4   }, {  0.25, -0.225 },  // Two
                      { -0.2,   0.4   }, {  0.1,   -0.3   }, { -0.25, -0.225 },  // Three
                      {  0.3,   0.225 },
                      {  0.2,  -0.3   }, { -0.4,   -0.025 }, {  0.4,  -0.25  },  // Four
                      { -0.125, 0.0   }, { -0.075, -0.25  },
                      { -0.48,  0.15  }, {  0.5,    0.25  }, { -0.33, -0.245 },  // Five
                      {  0.42, -0.125 }, { -0.42,   0.45  }, {  0.3,  -0.3   } };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// These next two functions are designed to take care of the source swapping needs of the effect.

float4 initFg (sampler Ff, float2 xy1, sampler Bb, float2 xy2)
{
   if (Blended) { return SwapSource ? ReadPixel (Bb, xy2) : ReadPixel (Ff, xy1); }

   return TransDirection ? ReadPixel (Ff, xy1) : ReadPixel (Bb, xy2);
}

float4 initBg (sampler Ff, float2 xy1, sampler Bb, float2 xy2)
{
   if (Blended) { return SwapSource ? ReadPixel (Ff, xy1) : ReadPixel (Bb, xy2); }

   return TransDirection ? ReadPixel (Bb, xy2) : ReadPixel (Ff, xy1);
}

// This function produces the required foreground key for the blend mode, whether as a simple
// pass through, or as a difference key between foreground and background.

float4 initKey (sampler Ff, sampler Bb, float2 xy)
{
   float4 retval = tex2D (Ff, xy);

   if (Blended && (Source < 2)) {
      if (Source == 1) { retval.a = pow (retval.a, 0.375 + (KeyGain / 2.0)); }
      else retval.a = smoothstep (0.0, KeyGain, distance (tex2D (Bb, xy).rgb, retval.rgb));

      if (retval.a == 0.0) retval = kTransparentBlack;
   }

   return retval;
}

// The mask value is calculated by this function, as are the X-Y coordinates to be used
// to recover the video.  It uses those to wipe and scale the foreground pointed to by
// sampler Ff over the background video in Bgd.

float4 doWipe (float4 Bgd, sampler Ff, float2 xy1, int idx, float amt)
{
   // Initially we set up the various progress parameters.  Because in its raw form it
   // can range in value from -4 to +5 they must be clamped to run from 0 to 1.

   float a = saturate (amt);                       // Range limit the transition amount
   float b = lerp (_scale [idx], 1.0, a);          // Scale factor for video and wipe
   float c = sin (saturate (amt * 2.0) * HALF_PI); // A non-linear fade using a sine curve
   float ref;

   // The video x-y coordinates are now displaced to track the mask shape.

    xy1 += _dsplmnt [idx] * (1.0 - a);

   // The mask centre point is scaled by the aspect ratio as is the mask itself.  The
   // mask centre point is then ramped from true centre to the scaled value.

   float2 xy2 = (float2 ((xy1.x - 0.5) * _OutputAspectRatio, xy1.y - 0.5) / b) + 0.5.xx;
   float2 xy3 = float2 ((CentreX - 0.5) * _OutputAspectRatio, 0.5 - CentreY) + 0.5.xx;
   float2 xy4 = _range [idx];

   xy3 = lerp (0.5.xx, xy3, a);

   // Now the mask shape is determined by finding whether the x-y coordinates fall
   // within the region defined by inside and outside values.

   if (WipeShape == SQUARE) {
      float2 refXY = abs (xy2 - xy3);  // Obtain the X & Y distance from the centre point

      ref = max (refXY.x, refXY.y) * 1.32;   // Makes the square area match the circle
   }
   else ref = distance (xy2, xy3);           // Or get the radius of the circle

   // If the reference point is inside the mask bounds the video level is returned.
   // Otherwise the mask is set to zero.

   float shape_mask = (ref >= xy4.x) && (ref <= xy4.y) ? c : 0.0;

   // The video coordinates are corrected for the aspect ratio adjustment done earlier
   // and used to recover the foreground.

   xy2.x -= 0.5;
   xy2.x /= _OutputAspectRatio;
   xy2.x += 0.5;

   float4 Fgd = tex2D (Ff, xy2);

   // Now we apply the masked foreground over the background and get out.

   return Blended ? lerp (Bgd, Fgd, Fgd.a * shape_mask) : lerp (Bgd, Fgd, shape_mask);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// In these five code blocks, parameters with a common name are passed using a numbered
// reference.  For example, there are five uses of Fg, one for each of the wipe patterns.
// They are numbered from 0 to 4, because this matches the way that the five techniques
// are numbered in SetTechnique.

// The entry points are identified with a label quoting the number of wipes used, which
// will always be one more than the technique number.

//---  One wipe  --------------------------------------------------------------------------//

DeclarePass (F0)
{ return initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg0)
{ return initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Fg0)
{ return initKey (F0, Bg0, uv3); }

DeclareEntryPoint (One_wipe)
{
   float4 Bgnd = tex2D (Bg0, uv3);
   float4 retval, partial;

   // Effect duration is strictly range limited.  In early development this was found to be
   // extremely important.  I'm not sure that it still is, but it does no harm to do it.

   float progress, amount = saturate (Amount);
   float offset = clamp (1.0 - Overlap, 0.25, 1.0);   // Clamped for a maximum 75% overlap.

   // Dealing with blends is extremely simple in this effect.  It's a matter of choosing
   // whether we want to just show the key or not, and selecting SwapDir or TransDirection.

   if (Blended) {
      if (ShowKey) {
         float4 Fgnd = tex2D (Fg0, uv3);

         return lerp (kTransparentBlack, Fgnd, Fgnd.a);
      }
      else progress = SwapDir ? amount : 1.0 - amount;
   }
   else progress = TransDirection ? 1.0 - amount : amount;

   // Choose whether the build direction is counting down (reverse) or up (forward) and do
   // the masked transform (wipe) required.

   progress *= 1.0 + offset;

   if (BuildDirection) {
      partial = doWipe (Bgnd,    Fg0, uv3, 1, progress);
      retval  = doWipe (partial, Fg0, uv3, 0, progress - offset);
   }
   else {
      partial = doWipe (Bgnd,    Fg0, uv3, 0, progress);
      retval  = doWipe (partial, Fg0, uv3, 1, progress - offset);
   }

   return retval;
}

//---  Two shapes  ------------------------------------------------------------------------//

DeclarePass (F1)
{ return initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg1)
{ return initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Fg1)
{ return initKey (F1, Bg1, uv3); }

DeclareEntryPoint (Two_wipes)
{
   float4 Bgnd = tex2D (Bg1, uv3);
   float4 retval, partial;

   float progress, amount = saturate (Amount);
   float offset = clamp (1.0 - Overlap, 0.25, 1.0);

   if (Blended) {
      if (ShowKey) {
         float4 Fgnd = tex2D (Fg1, uv3);

         return lerp (kTransparentBlack, Fgnd, Fgnd.a);
      }
      else progress = SwapDir ? amount : 1.0 - amount;
   }
   else progress = TransDirection ? 1.0 - amount : amount;

   progress *= (2.0 * offset) + 1.0;

   if (BuildDirection) {
      retval    = doWipe (Bgnd,   Fg1,  uv3, 4, progress);
      progress -= offset;
      partial   = doWipe (retval, Fg1,  uv3, 3, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg1, uv3, 2, progress);
   }
   else {
      retval    = doWipe (Bgnd,   Fg1,  uv3, 2, progress);
      progress -= offset;
      partial   = doWipe (retval, Fg1,  uv3, 3, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg1, uv3, 4, progress);
   }

   return retval;
}

//---  Three shapes  ----------------------------------------------------------------------//

DeclarePass (F2)
{ return initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg2)
{ return initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Fg2)
{ return initKey (F2, Bg2, uv3); }

DeclareEntryPoint (Three_wipes)
{
   float4 Bgnd = tex2D (Bg2, uv3);
   float4 retval, partial;

   float progress, amount = saturate (Amount);
   float offset = clamp (1.0 - Overlap, 0.25, 1.0);

   if (Blended) {
      if (ShowKey) {
         float4 Fgnd = tex2D (Fg2, uv3);

         return lerp (kTransparentBlack, Fgnd, Fgnd.a);
      }
      else progress = SwapDir ? amount : 1.0 - amount;
   }
   else progress = TransDirection ? 1.0 - amount : amount;

   progress *= (3.0 * offset) + 1.0;

   if (BuildDirection) {
      partial   = doWipe (Bgnd,    Fg2, uv3, 8, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg2, uv3, 7,  progress);
      progress -= offset;
      partial   = doWipe (retval,  Fg2, uv3, 6,  progress);
      progress -= offset;
      retval    = doWipe (partial, Fg2, uv3, 5,  progress);
   }
   else {
      partial   = doWipe (Bgnd,    Fg2, uv3, 5, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg2, uv3, 6, progress);
      progress -= offset;
      partial   = doWipe (retval,  Fg2, uv3, 7, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg2, uv3, 8, progress);
   }

   return retval;
}

//---  Four shapes  -----------------------------------------------------------------------//

DeclarePass (F3)
{ return initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg3)
{ return initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Fg3)
{ return initKey (F3, Bg3, uv3); }

DeclareEntryPoint (Four_wipes)
{
   float4 Bgnd = tex2D (Bg3, uv3);
   float4 retval, partial;

   float progress, amount = saturate (Amount);
   float offset = clamp (1.0 - Overlap, 0.25, 1.0);

   if (Blended) {
      if (ShowKey) {
         float4 Fgnd = tex2D (Fg3, uv3);

         return lerp (kTransparentBlack, Fgnd, Fgnd.a);
      }
      else progress = SwapDir ? amount : 1.0 - amount;
   }
   else progress = TransDirection ? 1.0 - amount : amount;

   progress *= (4.0 * offset) + 1.0;

   if (BuildDirection) {
      retval    = doWipe (Bgnd,    Fg3, uv3, 13, progress);
      progress -= offset;
      partial   = doWipe (retval,  Fg3, uv3, 12, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg3, uv3, 11, progress);
      progress -= offset;
      partial   = doWipe (retval,  Fg3, uv3, 10, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg3, uv3, 9,  progress);
   }
   else {
      retval    = doWipe (Bgnd,    Fg3, uv3, 9,  progress);
      progress -= offset;
      partial   = doWipe (retval,  Fg3, uv3, 10, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg3, uv3, 11, progress);
      progress -= offset;
      partial   = doWipe (retval,  Fg3, uv3, 12, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg3, uv3, 13, progress);
   }

   return retval;
}

//---  Five shapes  -----------------------------------------------------------------------//

DeclarePass (F4)
{ return initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg4)
{ return initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Fg4)
{ return initKey (F4, Bg4, uv3); }

DeclareEntryPoint (Five_wipes)
{
   float4 Bgnd = tex2D (Bg4, uv3);
   float4 retval, partial;

   float progress, amount = saturate (Amount);
   float offset = clamp (1.0 - Overlap, 0.25, 1.0);

   if (Blended) {
      if (ShowKey) {
         float4 Fgnd = tex2D (Fg4, uv3);

         return lerp (kTransparentBlack, Fgnd, Fgnd.a);
      }
      else progress = SwapDir ? amount : 1.0 - amount;
   }
   else progress = TransDirection ? 1.0 - amount : amount;

   progress *= (5.0 * offset) + 1.0;

   if (BuildDirection) {
      partial   = doWipe (Bgnd,    Fg4, uv3, 19, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg4, uv3, 18, progress);
      progress -= offset;
      partial   = doWipe (retval,  Fg4, uv3, 17, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg4, uv3, 16, progress);
      progress -= offset;
      partial   = doWipe (retval,  Fg4, uv3, 15, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg4, uv3, 14, progress);
   }
   else {
      partial   = doWipe (Bgnd,    Fg4, uv3, 14, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg4, uv3, 15, progress);
      progress -= offset;
      partial   = doWipe (retval,  Fg4, uv3, 16, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg4, uv3, 17, progress);
      progress -= offset;
      partial   = doWipe (retval,  Fg4, uv3, 18, progress);
      progress -= offset;
      retval    = doWipe (partial, Fg4, uv3, 19, progress);
   }

   return retval;
}

