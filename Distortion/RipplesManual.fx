// @Maintainer jwrl
// @Released 2023-01-08
// @Author schrauber
// @Created 2016-03-25

/**
 There are two related effects, "Ripples (automatic expansion)" and this version
 "Ripples (manual expansion)".  This is the simple version, which is the one to use
 when you want to control the wave expansion via keyframes.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RipplesManual.fx
//
// Version history:
//
// Updated 2023-01-08 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Ripples (manual expansion)", "DVE", "Distortion", "Radiating ripples are produced under full user control", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (enable_timing, "Enable expansion setting", kNoGroup, true);

DeclareFloatParam (expansionSetting, "Expansion", kNoGroup, kNoFlags, 0.4, 0.0, 1.0);

DeclareFloatParam (Xcentre, "Effect centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre, "Effect centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (zoom_lin, "Wave depth", "waveform", kNoFlags, 0.3, 0.0, 1.0);
DeclareFloatParam (Frequency, "Frequency", "waveform", kNoFlags, 100.0, 0.0, 1000.0);
DeclareFloatParam (phase_shift, "Phase", "waveform", kNoFlags, 0.0, -12.0, 12.0);

DeclareBoolParam (pulsing, "Pulsation on", "waveform", false);
DeclareBoolParam (pulse_negative, "Invert pulses", "waveform", false);

DeclareFloatParam (speed, "Wave dynamics", kNoGroup, kNoFlags, 100.0, -5000.0, 5000.0);

DeclareBoolParam (Flip_edge, "Flip edge", kNoGroup, true);

DeclareFloatParam (_InputWidthNormalised);
DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 MirrorEdge (sampler S, float2 uv)
{
   float2 xy = 1.0.xx - abs (2.0 * (frac (uv / 2.0) - 0.5.xx));

   return tex2D (S, xy);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (RipplesManual)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;    // If we fall outside the original limits we don't see anything, so processing empty media is pointless - jwrl.

   float2 XYc = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1 = XYc - uv1;
   float2 pos_zoom = float2 (xy1.x, xy1.y / _OutputAspectRatio);

   float _distance = distance ((0.0).xx, pos_zoom) / _InputWidthNormalised;    // Partially corrects distance scale - jwrl
   float freq = Frequency;
   float phase = 0;
   float damping, distortion, duration, expansion, zoom;

   if (pulsing || pulse_negative) freq = Frequency / 2.0;       // Frequency adjustment, when the waveform was changed. ___________German: Frequenzanpassung, wenn die Wellenfom geÃ¤ndert wurde.

   // ............ Effect without expansion rate...............

   if (!enable_timing) {
      zoom = 0.05 * pow ((zoom_lin * 2.4), 3.0);
      phase = (sin (phase_shift - (_Progress * speed) + (freq * _distance)));    // Create a wave.
      distortion = zoom * phase / _distance;         //  Wave height ____________ German: WellenhÃ¶he
      distortion = distortion / (_distance + 2.86);         // WellenhÃ¶he distanzabhÃ¤ngige Einstellungen

      if (pulsing) distortion = sqrt (distortion) / 3.0;        // Edit waveform ___________German:  Wellenfom Ã¤ndern (ggf. auch fÃ¼r Druckwelle geeignet?)

      if (pulse_negative) distortion = -sqrt (distortion) / 3.0;       // Edit waveform ___________German:  Wellenfom Ã¤ndern (ggf. auch fÃ¼r Druckwelle geeignet?)
   }
   else { // ............ Effect with expansion rate ...........
      damping = pow (expansionSetting * 3.0, 3.0) + 0.696;
      expansion = damping;
      zoom = pow ((zoom_lin * 0.001), 2.0) / pow (expansion, 3.6);

      if (expansion < 0.7) zoom = 0;   // Optimize the zoom setting characteristic, and expansion characteristic of the wave. (partly determined by tests)

      phase = (sin (phase_shift - (_Progress * speed) + (freq * _distance))) ;     // Create a wave.
      distortion = zoom * phase / (1.0 + _distance);        // Wave height  ___________German: WellenhÃ¶he
      duration = pow (_distance, damping);          // Time behavior of the wave ___________German: Zeitverhalten des Wellenlaufes
      distortion = distortion / (pow (duration, 4.0) + 28561E-12);      //   Wave height, time-dependent attenuation. (Mainly through experiments determined) ___________German:  WellenhÃ¶he, zeitabhÃ¤ngige DÃ¤mpfung. (Ã¼berwiegend durch Versuche ermittelt)

      if (pulsing) distortion = sqrt (distortion) / 3.0;        // Edit waveform ___________German:  Wellenfom Ã¤ndern (ggf. auch fÃ¼r Druckwelle geeignet?)

      if (pulse_negative) distortion = -sqrt (distortion) / 3.0;       // Edit waveform ___________German:  Wellenfom Ã¤ndern (ggf. auch fÃ¼r Druckwelle geeignet?)
   }

   // ..........................................................

   xy1 = distortion * xy1 + uv1;

   if (!Flip_edge && IsOutOfBounds (xy1)) return kTransparentBlack;

   return MirrorEdge (Input, xy1);
}

