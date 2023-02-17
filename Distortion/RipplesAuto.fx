// @Maintainer jwrl
// @Released 2023-02-17
// @Author schrauber
// @Created 2016-03-25


/**
 This is one of two related effects, "Ripples (manual expansion)" and this version "Ripples
 (automatic expansion)".  This version automatically controls the waves.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RipplesAuto.fx
//
// Version history:
//
// Updated 2023-02-17 jwrl
// Corrected header.
//
// Updated 2023-01-08 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Ripples (automatic expansion)", "DVE", "Distortion", "Radiating ripples are produced under semi-automatic control", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (enable_cycles, "Cyclic ripples", "Timeline", true);

DeclareFloatParam (cycle_length, "Cycle time", "Timeline", kNoFlags, 0.05, 0.0, 1.0);
DeclareFloatParam (expansionRate, "Expansion rate", "Timeline", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (expansionLimit, "Expansion limit", "Timeline", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (start_time, "Start time", "Timeline", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (start_fine, "Fine tuning", "Timeline", kNoFlags, 0.0, -10.0, +10.0);

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

DeclareEntryPoint (RipplesAuto) 
{ 
   if (IsOutOfBounds (uv1)) return kTransparentBlack;    // If we fall outside the original limits we don't see anything, so processing empty media is pointless - jwrl.

   float2 XYc = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1 = XYc - uv1;
   float2 pos_zoom = float2 (xy1.x, xy1.y / _OutputAspectRatio);

   float _distance = distance ((0.0).xx, pos_zoom) / _InputWidthNormalised;    // Partially corrects distance scale - jwrl
   float expansion_Rate = pow ((expansionRate * 10.0), 2.0);
   float expansion_limit = expansionLimit * 10.0;
   float freq = Frequency;
   float phase = 0.0;
   float damping, distortion, duration, expansion, zoom;

   if ((pulsing) || (pulse_negative)) freq = Frequency / 2.0;   // Frequency adjustment, when the waveform was changed. ___________German: Frequenzanpassung, wenn die Wellenfom geÃ¤ndert wurde.

   float progress = _Progress - start_time - (start_fine * 0.001); if (progress < 0) progress = 0.0; // set start time of the first wave. ___________German: Startzeitpunkt der 1. Welle festlegen
   float cycles = progress / cycle_length;   // Calculation of previously launched wave cycles ___________German:  Berechnung der bereits eingeleiteten Wellenzyklen
   int cycles_int = cycles;                  // Integer; Starting point of the current cycle ___________German: Ganzzahl; Startpunkt des aktuellen Zyklus
   float progress_cycles = cycles - cycles_int;   // Position on the timeline in the current wave cycle ___________German: Position auf der zeitleiste im aktuellen Wellenzyklus

   if (enable_cycles) { damping = (expansion_Rate * progress_cycles) + 0.696; }   // Attenuation of the wave height. The number 0696 adjusts the wave start to the time 0 to (was determined attempts). ___________German: DÃ¤mpfung der WellhÃ¶he. Die Zahl 0.696 passt den Wellenstart an den Zeitpunkt 0 an (wurde durch Versuche ermittelt).
   else damping = (expansion_Rate * 20 * progress) + 0.696;

   expansion = damping;

   if (expansion > expansion_limit) damping = expansion_limit;

   zoom = pow ((zoom_lin * 0.001), 2.0) / pow (expansion, 3.6);

   if (expansion < 0.7) zoom = 0.0;     // Optimize the zoom setting characteristic, and expansion characteristic of the wave. (partly determined by tests)

   phase = (sin (phase_shift - (_Progress * speed) + (freq * _distance)));   // Create a wave.

   distortion = zoom * phase / (1.0 + _distance);                            // Wave height  ___________German: WellenhÃ¶he

   duration = pow (_distance, damping);            // Time behavior of the wave ___________German: Zeitverhalten des Wellenlaufes
   distortion = distortion / (pow (duration, 4.0) + 28561E-12);    // Wave height, time-dependent attenuation. (Mainly through experiments determined) ___________German:  WellenhÃ¶he, zeitabhÃ¤ngige DÃ¤mpfung. (Ã¼berwiegend durch Versuche ermittelt)

   if (pulsing) distortion = sqrt (distortion) / 3.0;          // Edit waveform ___________German:  Wellenfom Ã¤ndern (ggf. auch fÃ¼r Druckwelle geeignet?)
   if (pulse_negative) distortion = sqrt (distortion) / -3.0;  // Edit waveform ___________German:  Wellenfom Ã¤ndern (ggf. auch fÃ¼r Druckwelle geeignet?)

   xy1 = distortion * xy1 + uv1;

   if (!Flip_edge && IsOutOfBounds (xy1)) return kTransparentBlack;

   return MirrorEdge (Input, xy1); 
}

