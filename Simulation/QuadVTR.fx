// @Maintainer jwrl
// @Released 2018-09-11
// @Author jwrl
// @Created 2018-09-07
// @see https://www.lwks.com/media/kunena/attachments/6375/QuadVTR_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadVTR.fx
//
// This effect emulates the faults that could occur with Quadruplex videotape playback.
// Tip penetration and guide height are both emulated, and chroma timebase errors are
// also simulated.  Note: the alpha channel is discarded with this effect.
//
// Modified jwrl 2018-09-08:
// Corrected some maths issues affecting the number of bands displayed.
// Added desaturation to PAL chroma correction.
// Added PAL Hanover bars setting.
// Used SetTechnique to select modes, bypassing the conditionals previously used.
// Added monochrome mode.
//
// Modified jwrl 2018-09-09:
// Rearranged techniques to allow support for PAL-M and other rarer formats.
//
// Modified jwrl 2018-09-10:
// Corrected guide height adjustment to be closer to actual effect.
//
// Modified jwrl 2018-09-11:
// Added oxide build up effect.  That meant a further slight reworking of the maths.
//
// Possible future projects:
// Add noise displacement when build up occurs.
// Display the head switching dots that were visible in the Ampex VR-1000 series.
// Show sparkle caused by the brushes in early Ampex heads.
// Work out a convincing way to make the image lose lock as it would with severe build up.
// Create tracking errors.  That might just be one for the "too hard" basket.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Quad VTR simulator";
   string Category    = "Stylize";
   string SubCategory = "Simulation";
   string Notes       = "Emulates the faults that could occur with Quadruplex videotape playback";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture VTR : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Inp>; };

sampler s_QuadVTR = sampler_state { Texture = <VTR>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Mode
<
   string Description = "Television standard";
   string Enum = "525 line,625 line";
> = 1;

int SetTechnique
<
   string Description = "Colour format";
   string Enum = "Black and white,NTSC colour,PAL colour,PAL with Hanover bars";
> = 2;

float Tip
<
   string Description = "Tip penetration";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float Guide
<
   string Description = "Guide height";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float Phase
<
   string Description = "Chroma errors";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float Head_1
<
   string Group = "Oxide build up";
   string Description = "Head 1";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Head_2
<
   string Group = "Oxide build up";
   string Description = "Head 2";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Head_3
<
   string Group = "Oxide build up";
   string Description = "Head 3";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Head_4
<
   string Group = "Oxide build up";
   string Description = "Head 4";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY     (0.0).xxxx

#define R_LUMA    0.2989
#define G_LUMA    0.5866
#define B_LUMA    0.1145

#define SQRT_2    0.7071067812

#define TV_525    0

#define PAL       14.6944
#define PAL_OFFS  0.0063

#define NTSC      14.72
#define NTSC_OFFS 0.0060619048

#define TIP       0.02
#define GUIDE     0.02125

#define HALF_PI   1.5707963268

#define N_1       12.1053
#define N_2       13.7838
#define N_3       75.7143
#define N_4       75.4545

#define S_1       51538.462
#define S_2       53846.153

float _Progress;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mono (float2 uv : TEXCOORD1) : COLOR
{
   float tip = (Mode == TV_525) ? NTSC * (uv.y + NTSC_OFFS) : PAL * (uv.y + PAL_OFFS);
   float phase = (tip - floor (tip));
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE);

   float2 xy1 = uv + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   float3 retval = max (xy2.x, xy2.y) > 0.5 ? EMPTY : tex2D (s_Input, xy1).rgb;

   return dot (retval, float3 (R_LUMA, G_LUMA, B_LUMA)).xxxx;
}

float4 ps_ntsc (float2 uv : TEXCOORD1) : COLOR
{
   float tip, ph1, ph2;

   if (Mode == TV_525) {
      ph1 = 35.0;
      ph2 = 36.0;
      tip = NTSC * (uv.y + NTSC_OFFS);
   }
   else {
      ph1 = 41.0;
      ph2 = 42.0;
      tip = PAL * (uv.y + PAL_OFFS);
   }

   float phase = (tip + floor (tip));
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE);

   float2 xy1 = uv - float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   float3 retval = max (xy2.x, xy2.y) > 0.5 ? EMPTY : tex2D (s_Input, xy1).rgb;

   phase = Phase * ((phase * ph1) + uv.x) / ph2;
   retval = phase < 0.0 ? lerp (retval, retval.gbr, abs (phase))
                        : lerp (retval, retval.brg, phase);
   return retval.rgbg;
}

float4 ps_pal (float2 uv : TEXCOORD1) : COLOR
{
   float tip = (Mode == TV_525) ? NTSC * (uv.y + NTSC_OFFS) : PAL * (uv.y + PAL_OFFS);
   float phase = (tip - floor (tip));
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE);

   float2 xy1 = uv + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   float3 retval = max (xy2.x, xy2.y) > 0.5 ? EMPTY : tex2D (s_Input, xy1).rgb;

   float luma = dot (retval, float3 (R_LUMA, G_LUMA, B_LUMA));

   return lerp (retval, luma.xxx, abs (Phase * phase)).rgbg;
}

float4 ps_hanover_bars (float2 uv : TEXCOORD1) : COLOR
{
   float tip, ph1, ph2, hanover;

   if (Mode == TV_525) {
      ph1 = 35.0;
      ph2 = 36.0;
      tip = NTSC * (uv.y + NTSC_OFFS);
      hanover = frac (241.5 * uv.y);
   }
   else {
      ph1 = 41.0;
      ph2 = 42.0;
      tip = PAL * (uv.y + PAL_OFFS);
      hanover = frac (288.0 * uv.y);
   }

   float phase = (tip - floor (tip));
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE);

   float2 xy1 = uv + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   float3 retval = max (xy2.x, xy2.y) > 0.5 ? EMPTY : tex2D (s_Input, xy1).rgb;

   phase = Phase * ((phase * ph1) + uv.x) / ph2;

   if (hanover >= 0.5) phase = -phase;

   retval = phase < 0.0 ? lerp (retval, retval.gbr, abs (phase))
                        : lerp (retval, retval.brg, phase);
   return retval.rgbg;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_QuadVTR, uv);

   float2 xy;

   float head;
   float head_idx [] = { Head_2, Head_3, Head_4, Head_1, Head_2, Head_3, Head_4, Head_1,
                         Head_2, Head_3, Head_4, Head_1, Head_2, Head_3, Head_4 };

   if (Mode == TV_525) {
      head = head_idx [floor (NTSC * (uv.y + NTSC_OFFS))] * 2.0;
      xy = floor (uv * 483.0) / 483.0;
   }
   else {
      head = head_idx [floor (PAL * (uv.y + PAL_OFFS))] * 2.0;
      xy = floor (uv * 574.0) / 574.0;
   }

   float buildup = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   float noise = frac (sin (dot (xy, float2 (N_1, N_3)) + _Progress) * (S_1));

   noise = frac (sin (dot (xy, float2 (N_2, N_4)) + noise) * (S_2)).xxx;
   buildup = (noise < 0.5) ? saturate (2.0 * buildup * noise)
                           : saturate (1.0 - 2.0 * (1.0 - buildup) * (1.0 - noise));
   retval = lerp (retval, buildup.xxxx, min (head, 1.0));
   retval = lerp (retval, noise.xxxx, max (head - 1.0, 0.0));
   retval.a = 1.0;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique QuadVTR_Mono
{
   pass P_1
   < string Script = "RenderColorTarget0 = VTR;"; > 
   { PixelShader = compile PROFILE ps_mono (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique QuadVTR_NTSC
{
   pass P_1
   < string Script = "RenderColorTarget0 = VTR;"; > 
   { PixelShader = compile PROFILE ps_ntsc (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique QuadVTR_PAL
{
   pass P_1
   < string Script = "RenderColorTarget0 = VTR;"; > 
   { PixelShader = compile PROFILE ps_pal (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique QuadVTR_Hanover
{
   pass P_1
   < string Script = "RenderColorTarget0 = VTR;"; > 
   { PixelShader = compile PROFILE ps_hanover_bars (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
