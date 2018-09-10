// @Maintainer jwrl
// @Released 2018-09-10
// @Author jwrl
// @Created 2018-09-07
// @see https://www.lwks.com/media/kunena/attachments/6375/QuadVTR_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadVTR.fx
//
// This effect emulates the faults that could occur with Quad video tape playback.  Tip
// penetration and guide height are both emulated, and colortec phase is also included.
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

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Inp>; };

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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLACK     float2(0.0,1.0).xxxy

#define R_LUMA    0.2989
#define G_LUMA    0.5866
#define B_LUMA    0.1145

#define SQRT_2    0.7071067812

#define TV_525    0

#define PAL       14.6944
#define PAL_OFFS  1.0768

#define NTSC      14.72
#define NTSC_OFFS 1.0914285714

#define TIP       0.02
#define GUIDE     0.02125

#define HALF_PI   1.5707963268

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_mono (float2 uv : TEXCOORD1) : COLOR
{
   float tip = (Mode == TV_525) ? NTSC * (NTSC_OFFS - uv.y) : PAL * (PAL_OFFS - uv.y);
   float phase = (tip - floor (tip));
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE);

   float2 xy1 = uv - float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   float4 retval = max (xy2.x, xy2.y) > 0.5 ? BLACK : tex2D (s_Input, xy1);

   float luma = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));

   return float4 (luma.xxx, retval.a);
}

float4 ps_main_ntsc (float2 uv : TEXCOORD1) : COLOR
{
   float tip, ph1, ph2;

   if (Mode == TV_525) {
      ph1 = 35.0;
      ph2 = 36.0;
      tip = NTSC * (NTSC_OFFS - uv.y);
   }
   else {
      ph1 = 41.0;
      ph2 = 42.0;
      tip = PAL * (PAL_OFFS - uv.y);
   }

   float phase = (tip - floor (tip));
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE);

   float2 xy1 = uv - float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   float4 retval = max (xy2.x, xy2.y) > 0.5 ? BLACK : tex2D (s_Input, xy1);

   phase = Phase * ((phase * ph1) + uv.x) / ph2;
   retval.rgb = phase < 0.0 ? lerp (retval.rgb, retval.gbr, abs (phase))
                            : lerp (retval.rgb, retval.brg, phase);

   return retval;
}

float4 ps_main_pal (float2 uv : TEXCOORD1) : COLOR
{
   float tip = (Mode == TV_525) ? NTSC * (NTSC_OFFS - uv.y) : PAL * (PAL_OFFS - uv.y);
   float phase = (tip - floor (tip));
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE);

   float2 xy1 = uv - float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   float4 retval = max (xy2.x, xy2.y) > 0.5 ? BLACK : tex2D (s_Input, xy1);

   float luma = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));

   retval.rgb = lerp (retval.rgb, luma.xxx, abs (Phase * phase));

   return retval;
}

float4 ps_main_bars (float2 uv : TEXCOORD1) : COLOR
{
   float tip, ph1, ph2;

   if (Mode == TV_525) {
      ph1 = 35.0;
      ph2 = 36.0;
      tip = NTSC * (NTSC_OFFS - uv.y);
   }
   else {
      ph1 = 41.0;
      ph2 = 42.0;
      tip = PAL * (PAL_OFFS - uv.y);
   }

   float hanover = frac (288.0 * uv.y);
   float phase = (tip - floor (tip));
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE);

   float2 xy1 = uv - float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   float4 retval = max (xy2.x, xy2.y) > 0.5 ? BLACK : tex2D (s_Input, xy1);

   phase = Phase * ((phase * ph1) + uv.x) / ph2;

   if (hanover >= 0.5) phase = -phase;

   retval.rgb = phase < 0.0 ? lerp (retval.rgb, retval.gbr, abs (phase))
                            : lerp (retval.rgb, retval.brg, phase);

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique QuadVTR_Mono
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_mono (); }
}

technique QuadVTR_NTSC
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_ntsc (); }
}

technique QuadVTR_PAL
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_pal (); }
}

technique QuadVTR_Hanover
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_bars (); }
}
