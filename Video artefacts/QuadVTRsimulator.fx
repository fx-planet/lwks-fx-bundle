// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2018-09-07

/**
 This effect emulates the faults that could occur with Quadruplex videotape playback.
 Tip penetration and guide height are both emulated, and chroma timebase errors are
 also simulated.  A range of Ampex VTR types and modes can be emulated, as well as a
 generic RCA videotape recorder.

 NOTE 1: the alpha channel is turned fully on with this effect.  Also, because this
 needs to be able to precisely set line widths no matter what the original clip size
 or aspect ratio is it has not been possible to make it truly resolution independent.
 What it does is lock the clip resolution to sequence resolution instead.

 NOTE 2:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadVTRsimulator.fx
//
// Possible future projects:
// Add noise-driven horizontal displacement when build up occurs.
// Work out a convincing way to make the image lose lock as it would with severe build up.
// Create tracking errors.  That might just be one for the "too hard" basket.
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-26 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Quad VTR simulator", "Stylize", "Video artefacts", "Emulates the faults that could occur with Quadruplex videotape playback", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Mode, "Television standard", kNoGroup, 1, "525 line|625 line");
DeclareIntParam (VTRmode, "VTR mode", kNoGroup, 0, "Low band (valve)|Low band (solid state)|High band");

DeclareBoolParam (Crop, "Crop frame to 4x3 aspect ratio", kNoGroup, true);

DeclareFloatParam (Tip, "Tip penetration", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Guide, "Guide height", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

DeclareIntParam (SetTechnique, "Colour format", kNoGroup, 2, "Black and white|NTSC colour (Ampex)|PAL colour (Ampex)|PAL with Hanover bars (Ampex)|Colour offset (RCA)");

DeclareFloatParam (Phase, "Chroma errors", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Brush, "Brush noise", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (Head_1, "Head 1", "Oxide build up", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Head_2, "Head 2", "Oxide build up", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Head_3, "Head 3", "Oxide build up", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Head_4, "Head 4", "Oxide build up", kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (HeadSwitch, "Show head switching dots (Ampex VR-1000)", kNoGroup, false);

DeclareFloatParam (_Progress);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy
#define WHITE      1.0.xxxx

#define B_W        float3(0.3, 0.59, 0.11)

#define SQRT_2     0.7071067812

#define TV_525     0

#define PAL        14.6944
#define PAL_OFFS   0.0063
#define PAL_T_ADJ  0.019845
#define PAL_G_ADJ  0.0067

#define NTSC       14.72
#define NTSC_OFFS  0.0060619048
#define NTSC_T_ADJ 0.02031
#define NTSC_G_ADJ 0.0067116725

#define TIP        0.02
#define GUIDE      0.02125

#define HALF_PI    1.5707963268

#define N_1        12.1053
#define N_2        13.7838
#define N_3        75.7143
#define N_4        75.4545

#define S_1        51538.462
#define S_2        53846.153

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_sharpen (sampler S, float2 uv)
{
   float4 retval = ReadPixel (S, uv);

   float setband = (Mode == TV_525) ? 483.0 : 576.0;

   setband *= (VTRmode * 0.5) + 1.0;

   float2 xy1 = float2 (1.0 / _OutputAspectRatio, 1.0) / setband;
   float2 xy2 = float2 (0.0, xy1.y);
   float2 xy3 = float2 (xy1.x, -xy1.y);
   float2 xy4 = float2 (xy1.x, 0.0);

   setband = max (VTRmode - 1.5, 0.0);

   float sharpen = 0.25 - (setband * 0.125);

   retval *= 3.0 - setband;
   retval -= tex2D (S, uv - xy1) * sharpen;
   retval -= tex2D (S, uv - xy2) * sharpen;
   retval -= tex2D (S, uv + xy3) * sharpen;
   retval -= tex2D (S, uv - xy4) * sharpen;
   retval -= tex2D (S, uv + xy4) * sharpen;
   retval -= tex2D (S, uv - xy3) * sharpen;
   retval -= tex2D (S, uv + xy2) * sharpen;
   retval -= tex2D (S, uv + xy1) * sharpen;

   return IsOutOfBounds (uv) ? kTransparentBlack : retval;
}

float4 fn_main (sampler S1, sampler S2, float2 uv) : COLOR
{
   float4 retval = tex2D (S1, uv);

   float head, x = abs (uv.x - 0.5);

   if (Crop) x *= _OutputAspectRatio * 0.75;

   if (x > 0.5) { return kTransparentBlack; }

   bool head_sw;

   float head_idx [] = { Head_2, Head_3, Head_4, Head_1, Head_2, Head_3, Head_4,
                 Head_1, Head_2, Head_3, Head_4, Head_1, Head_2, Head_3, Head_4 };
   float2 xy;

   if (Mode == TV_525) {
      head_sw = (modf (NTSC * (uv.y + NTSC_OFFS), head) > 0.96) && (uv.x > 0.5) && HeadSwitch;
      xy = floor (uv * 483.0) / 483.0;
   }
   else {
      head_sw = (modf (PAL * (uv.y + PAL_OFFS), head) > 0.96) && (uv.x > 0.5) && HeadSwitch;
      xy = floor (uv * 574.0) / 574.0;
   }

   if ((x > 0.496) && head_sw) {
      head++;
      retval.rgb = tex2D (S2, uv).rgb;

      if (retval.a == 0.0) retval = dot (retval.rgb, B_W).xxxx;
   }

   head = head_idx [head] * 2.0;
   head_sw = (x > 0.4935) && (x < 0.496) && head_sw;

   float buildup = dot (retval.rgb, B_W);
   float noise = frac (sin (dot (xy, float2 (N_1, N_3)) + _Progress) * (S_1));

   retval = (VTRmode == 0) ? lerp (retval, noise.xxxx, 0.1)
                           : lerp (retval, noise.xxxx, 0.05 / (VTRmode * VTRmode));

   if ((Brush * 0.00625) > noise) return WHITE;

   noise   = frac (sin (dot (xy, float2 (N_2, N_4)) + noise) * (S_2));
   buildup = (noise < 0.5) ? saturate (2.0 * buildup * noise)
                           : saturate (1.0 - 2.0 * (1.0 - buildup) * (1.0 - noise));
   if (head_sw) retval = saturate (noise * 3.0).xxxx;

   retval = lerp (retval, buildup.xxxx, min (head, 1.0));
   retval = lerp (retval, noise.xxxx, max (head - 1.0, 0.0));
   retval.a = 1.0;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Black and white

DeclarePass (InpMono)
{ return ReadPixel (Inp, uv1); }

DeclarePass (SharpMono)
{ return fn_sharpen (InpMono, uv2); }

DeclarePass (Mono)
{
   float tip, tip_adj;

   if (Mode == TV_525) {
      tip = NTSC * (uv2.y + NTSC_OFFS);
      tip_adj = NTSC_T_ADJ * min (Tip, 0.0);
      tip_adj += NTSC_G_ADJ * (1.0 - abs (Tip)) * min (Guide, 0.0);
   }
   else {
      tip = PAL * (uv2.y + PAL_OFFS);
      tip_adj = PAL_T_ADJ * min (Tip, 0.0);
      tip_adj += PAL_G_ADJ * (1.0 - abs (Tip)) * min (Guide, 0.0);
   }

   float phase = frac (tip);
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE) - tip_adj;

   float2 xy1 = uv2 + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   if (Crop) xy2.x *= _OutputAspectRatio * 0.75;

   if (max (xy2.x, xy2.y) > 0.5) return kTransparentBlack;

   return float4 (dot (tex2D (SharpMono, xy1).rgb, B_W).xxx, 0.0);
}

DeclareEntryPoint (QuadVTR_Mono)
{ return fn_main (Mono, SharpMono, uv2); }

//-----------------------------------------------------------------------------------------//

// NTSC colour (Ampex)

DeclarePass (InpNTSC)
{ return ReadPixel (Inp, uv1); }

DeclarePass (SharpNTSC)
{ return fn_sharpen (InpNTSC, uv2); }

DeclarePass (NTSCvid)
{
   float tip, tip_adj, ph1, ph2;

   if (Mode == TV_525) {
      ph1 = 35.0;
      ph2 = 36.0;
      tip = NTSC * (uv2.y + NTSC_OFFS);
      tip_adj = NTSC_T_ADJ * min (Tip, 0.0);
      tip_adj += NTSC_G_ADJ * (1.0 - abs (Tip)) * min (Guide, 0.0);
   }
   else {
      ph1 = 41.0;
      ph2 = 42.0;
      tip = PAL * (uv2.y + PAL_OFFS);
      tip_adj = PAL_T_ADJ * min (Tip, 0.0);
      tip_adj += PAL_G_ADJ * (1.0 - abs (Tip)) * min (Guide, 0.0);
   }

   float phase = frac (tip);
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE) - tip_adj;
   phase = Phase * ((phase * ph1) + uv2.x) / ph2;

   float2 xy1 = uv2 + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   if (Crop) xy2.x *= _OutputAspectRatio * 0.75;

   if (max (xy2.x, xy2.y) > 0.5) return BLACK;

   float4 retval = float4 (tex2D (SharpNTSC, xy1).rgb, 1.0);

   return (phase < 0.0) ? lerp (retval, retval.gbra, abs (phase))
                        : lerp (retval, retval.brga, phase);
}

DeclareEntryPoint (QuadVTR_NTSC)
{ return fn_main (NTSCvid, SharpNTSC, uv2); }

//-----------------------------------------------------------------------------------------//

// PAL colour (Ampex)

DeclarePass (InpPAL)
{ return ReadPixel (Inp, uv1); }

DeclarePass (SharpPAL)
{ return fn_sharpen (InpPAL, uv2); }

DeclarePass (PALvid)
{
   float tip, tip_adj;

   if (Mode == TV_525) {
      tip = NTSC * (uv2.y + NTSC_OFFS);
      tip_adj = NTSC_T_ADJ * min (Tip, 0.0);
      tip_adj += NTSC_G_ADJ * (1.0 - abs (Tip)) * min (Guide, 0.0);
   }
   else {
      tip = PAL * (uv2.y + PAL_OFFS);
      tip_adj = PAL_T_ADJ * min (Tip, 0.0);
      tip_adj += PAL_G_ADJ * (1.0 - abs (Tip)) * min (Guide, 0.0);
   }

   float phase = frac (tip);
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE) - tip_adj;

   float2 xy1 = uv2 + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   if (Crop) xy2.x *= _OutputAspectRatio * 0.75;

   if (max (xy2.x, xy2.y) > 0.5) return BLACK;

   float3 retval = tex2D (SharpPAL, xy1).rgb;

   float luma = dot (retval, B_W);

   return float4 (lerp (retval, luma.xxx, abs (Phase * phase)).rgb, 1.0);
}

DeclareEntryPoint (QuadVTR_PAL)
{ return fn_main (PALvid, SharpPAL, uv2); }

//-----------------------------------------------------------------------------------------//

// PAL with Hanover bars (Ampex)

DeclarePass (InpHanover)
{ return ReadPixel (Inp, uv1); }

DeclarePass (SharpHanover)
{ return fn_sharpen (InpHanover, uv2); }

DeclarePass (Hanover)
{
   float tip, tip_adj, ph1, ph2, hanover;

   if (Mode == TV_525) {
      ph1 = 35.0;
      ph2 = 36.0;
      tip = NTSC * (uv2.y + NTSC_OFFS);
      tip_adj = NTSC_T_ADJ * min (Tip, 0.0);
      tip_adj += NTSC_G_ADJ * (1.0 - abs (Tip)) * min (Guide, 0.0);
      hanover = frac (241.5 * uv2.y);
   }
   else {
      ph1 = 41.0;
      ph2 = 42.0;
      tip = PAL * (uv2.y + PAL_OFFS);
      tip_adj = PAL_T_ADJ * min (Tip, 0.0);
      tip_adj += PAL_G_ADJ * (1.0 - abs (Tip)) * min (Guide, 0.0);
      hanover = frac (288.0 * uv2.y);
   }

   float phase = frac (tip);
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE) - tip_adj;
   phase = Phase * ((phase * ph1) + uv2.x) / ph2;

   if (hanover >= 0.5) phase = -phase;

   float2 xy1 = uv2 + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   if (Crop) xy2.x *= _OutputAspectRatio * 0.75;

   if (max (xy2.x, xy2.y) > 0.5) return BLACK;

   float4 retval = float4 (tex2D (SharpHanover, xy1).rgb, 1.0);

   return (phase < 0.0) ? lerp (retval, retval.gbra, abs (phase))
                        : lerp (retval, retval.brga, phase);
}

DeclareEntryPoint (QuadVTR_Hanover)
{ return fn_main (Hanover, SharpHanover, uv2); }

//-----------------------------------------------------------------------------------------//

// Colour offset (RCA)

DeclarePass (InpRCA)
{ return ReadPixel (Inp, uv1); }

DeclarePass (SharpRCA)
{ return fn_sharpen (InpRCA, uv2); }

DeclarePass (RCA)
{
   float tip, tip_adj;

   if (Mode == TV_525) {
      tip = NTSC * (uv2.y + NTSC_OFFS);
      tip_adj = NTSC_T_ADJ * min (Tip, 0.0);
      tip_adj += NTSC_G_ADJ * (1.0 - abs (Tip)) * min (Guide, 0.0);
   }
   else {
      tip = PAL * (uv2.y + PAL_OFFS);
      tip_adj = PAL_T_ADJ * min (Tip, 0.0);
      tip_adj += PAL_G_ADJ * (1.0 - abs (Tip)) * min (Guide, 0.0);
   }

   float phase = frac (tip);
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE) - tip_adj;

   float2 xy1 = uv2 + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   if (Crop) xy2.x *= _OutputAspectRatio * 0.75;

   if (max (xy2.x, xy2.y) > 0.5) return BLACK;

   xy2 = xy1 - float2 (Phase * 0.005, 0.0);

   float4 retval = ReadPixel (InpRCA, xy2);

   float luma = dot (retval.rgb, B_W);

   retval -= luma.xxxx;
   luma = dot (tex2D (SharpRCA, xy1).rgb, B_W);
   retval += luma.xxxx;

   return float4 (retval.rgb, 1.0);
}

DeclareEntryPoint (QuadVTR_RCA)
{ return fn_main (RCA, SharpRCA, uv2); }

