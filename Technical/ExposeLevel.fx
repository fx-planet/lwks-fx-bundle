// @Maintainer jwrl
// @Released 2023-01-11
// @Author khaver
// @Created 2011-06-10

/**
 This exposure levelling effect is designed to correct fairly static shots where the
 exposure varies over time.  To use it select a frame that has the best exposure and
 create a reference frame either by freezing or export/import.  Add that frame to the
 sequence on a track under the video for the entire duration of the clip to be treated.
 Add the effect and check the box to view the sample frame then adjust the E1, E2, and
 E3 points to areas where there is minimal movement in the video clip.  The only
 constraint is that the chosen points must not be in pure black or white areas.

 If there is camera movement uncheck "Use Example Points for Video" and keyframe the V1,
 V2 and V3 points so they track the E1, E2 and E3 points.  Uncheck "Show Example Frame"
 and the exposure in the video clip should stay close to the sample frame's exposure.
 Further fine tuning can be done with the "Tune" slider.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ExposeLevel.fx
//
// Version history:
//
// Updated 2023-01-11 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Exposure leveller", "User", "Technical", "This corrects the levels of shots where the exposure varies over time", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Input, Frame);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (TUNE, "Tune", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (BLUR, "Blur Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (SWAP, "Swap Tracks", kNoGroup, false);
DeclareBoolParam (ShowE, "Show Example Frame", kNoGroup, false);
DeclareBoolParam (ShowVB, "Show Video Blur", kNoGroup, false);
DeclareBoolParam (ShowFB, "Show Example Blur", kNoGroup, false);
DeclareBoolParam (COMBINE, "Use Example Points for Video", kNoGroup, true);

DeclareFloatParam (F1X, "E1", "Example Samples", "SpecifiesPointX", 0.25, 0.0, 1.0);
DeclareFloatParam (F1Y, "E1", "Example Samples", "SpecifiesPointY", 0.75, 0.0, 1.0);

DeclareFloatParam (F2X, "E2", "Example Samples", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (F2Y, "E2", "Example Samples", "SpecifiesPointY", 0.75, 0.0, 1.0);

DeclareFloatParam (F3X, "E3", "Example Samples", "SpecifiesPointX", 0.75, 0.0, 1.0);
DeclareFloatParam (F3Y, "E3", "Example Samples", "SpecifiesPointY", 0.75, 0.0, 1.0);

DeclareFloatParam (V1X, "V1", "Video Samples", "SpecifiesPointX", 0.25, 0.0, 1.0);
DeclareFloatParam (V1Y, "V1", "Video Samples", "SpecifiesPointY", 0.25, 0.0, 1.0);

DeclareFloatParam (V2X, "V2", "Video Samples", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (V2Y, "V2", "Video Samples", "SpecifiesPointY", 0.25, 0.0, 1.0);

DeclareFloatParam (V3X, "V3", "Video Samples", "SpecifiesPointX", 0.75, 0.0, 1.0);
DeclareFloatParam (V3Y, "V3", "Video Samples", "SpecifiesPointY", 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 circle (float angle)
{
   float2 xy;

   sincos (angle, xy.y, xy.x);

   return xy / 1.5;
}

float colorsep (sampler samp, float2 xy)
{
   float3 col = ReadPixel (samp, xy).rgb;

   return (col.r + col.g + col.b) / 3.0;
}

float4 GrowablePoissonDisc13FilterRGBA (sampler tSource, float2 texCoord, int run)
{
   float2 halfpix = float2 (0.5 / _OutputWidth, 0.5 / _OutputHeight);
   float2 coord;

   float discRadius = BLUR * 500.0;
   float angle = run * 0.0873;      // multiply run by 5 degrees in radians

   float4 cOut = tex2D (tSource, texCoord + halfpix);

   for (int tap = 0; tap < 12; tap++) {
      coord = texCoord + (halfpix * circle (angle) * discRadius);
      cOut += tex2D (tSource, coord);
      angle += 0.5236;              // increment angle by 30 degrees in radians
   }

   return IsOutOfBounds (texCoord) ? kTransparentBlack : cOut / 13.0;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fg)
{ return ReadPixel (Input, uv1); }

DeclarePass (Bg)
{ return ReadPixel (Frame, uv2); }

DeclarePass (IPass_0)
{ return GrowablePoissonDisc13FilterRGBA (Fg, uv3, 0); }

DeclarePass (IPass_1)
{ return GrowablePoissonDisc13FilterRGBA (IPass_0, uv3, 1); }

DeclarePass (IPass_2)
{ return GrowablePoissonDisc13FilterRGBA (IPass_1, uv3, 2); }

DeclarePass (IPass_3)
{ return GrowablePoissonDisc13FilterRGBA (IPass_2, uv3, 3); }

DeclarePass (IPass_4)
{ return GrowablePoissonDisc13FilterRGBA (IPass_3, uv3, 4); }

DeclarePass (IPass_5)
{ return GrowablePoissonDisc13FilterRGBA (IPass_4, uv3, 5); }

DeclarePass (FPass_0)
{ return GrowablePoissonDisc13FilterRGBA (Bg, uv3, 0); }

DeclarePass (FPass_1)
{ return GrowablePoissonDisc13FilterRGBA (FPass_0, uv3, 1); }

DeclarePass (FPass_2)
{ return GrowablePoissonDisc13FilterRGBA (FPass_1, uv3, 2); }

DeclarePass (FPass_3)
{ return GrowablePoissonDisc13FilterRGBA (FPass_2, uv3, 3); }

DeclarePass (FPass_4)
{ return GrowablePoissonDisc13FilterRGBA (FPass_3, uv3, 4); }

DeclarePass (FPass_5)
{ return GrowablePoissonDisc13FilterRGBA (FPass_4, uv3, 5); }

DeclareEntryPoint (ExposureLeveller)
{
   float4 video, frame, cout;

   if (SWAP) {
      video = ReadPixel (Bg, uv3);
      frame = ReadPixel (Fg, uv3);
   }
   else {
      video = ReadPixel (Fg, uv3);
      frame = ReadPixel (Bg, uv3);
   }

   if  (ShowE) return frame;

   float2 fp1 = float2 (F1X, 1.0 - F1Y);
   float2 fp2 = float2 (F2X, 1.0 - F2Y);
   float2 fp3 = float2 (F3X, 1.0 - F3Y);
   float2 vp1 = float2 (V1X, 1.0 - V1Y);
   float2 vp2 = float2 (V2X, 1.0 - V2Y);
   float2 vp3 = float2 (V3X, 1.0 - V3Y);

   if (COMBINE) {
      vp1 = fp1;
      vp2 = fp2;
      vp3 = fp3;
   }

   float va = video.a;
   float tune = pow (TUNE + 1.0, 0.1);
   float flum1, flum2, flum3, vlum1, vlum2, vlum3;

   if (SWAP) {
      if (ShowVB) return tex2D (FPass_5, uv3);
      if (ShowFB) return tex2D (IPass_5, uv3);

      flum1 = colorsep (IPass_5, fp1);
      flum2 = colorsep (IPass_5, fp2);
      flum3 = colorsep (IPass_5, fp3);
      vlum1 = colorsep (FPass_5, vp1);
      vlum2 = colorsep (FPass_5, vp2);
      vlum3 = colorsep (FPass_5, vp3);
   }
   else {
      if (ShowVB) return tex2D (IPass_5, uv3);
      if (ShowFB) return tex2D (FPass_5, uv3);

      flum1 = colorsep (FPass_5, fp1);
      flum2 = colorsep (FPass_5, fp2);
      flum3 = colorsep (FPass_5, fp3);
      vlum1 = colorsep (IPass_5, vp1);
      vlum2 = colorsep (IPass_5, vp2);
      vlum3 = colorsep (IPass_5, vp3);
   }

   float flumav = (flum1 + flum2 + flum3) / 3.0;
   float vlumav = (vlum1 + vlum2 + vlum3) / 3.0;
   float ldiff  = 1.0 /  (vlumav / (flumav / tune));

   cout = video;

   float ldiff1 = pow (ldiff, 0.5);
   float ldiff2 = pow (ldiff, 0.5);

   cout.rgb *= ldiff1;
   cout.rgb = pow (cout.rgb, 1.0 / ldiff2);
   cout.a = va;

   return cout;
}

