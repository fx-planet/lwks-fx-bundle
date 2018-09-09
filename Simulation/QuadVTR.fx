// @Maintainer jwrl
// @Released 2018-09-08
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

int SetTechnique
<
   string Description = "Television standard";
   string Enum = "NTSC,PAL,PAL with Hanover bars";
> = 1;

int Mode
<
   string Description = "Recording mode";
   string Enum = "Black and white,Colour";
> = 1;

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

#define MONO      0

#define PAL       13.824
#define PAL_OFFS  1.072

#define NTSC      13.8
#define NTSC_OFFS 1.0857142857

#define HALF_PI   1.5707963268

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_ntsc (float2 uv : TEXCOORD1) : COLOR
{
   float tip   = NTSC * (NTSC_OFFS - uv.y);
   float phase = (tip - floor (tip));
   float guide = 1.0 - cos (phase * HALF_PI);

   tip = (Tip * phase * 0.005) + (Guide * guide * 0.01);

   float2 xy1 = uv - float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   float4 retval = max (xy2.x, xy2.y) > 0.5 ? BLACK : tex2D (s_Input, xy1);

   if (Mode == MONO) {
      float luma = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));

      return float4 (luma.xxx, retval.a);
   }

   phase = Phase * ((phase * 35.0) + uv.x) / 36.0;
   retval.rgb = phase < 0.0 ? lerp (retval.rgb, retval.gbr, abs (phase))
                            : lerp (retval.rgb, retval.brg, phase);

   return retval;
}

float4 ps_main_pal (float2 uv : TEXCOORD1) : COLOR
{
   float tip   = PAL * (PAL_OFFS - uv.y);
   float phase = (tip - floor (tip));
   float guide = 1.0 - cos (phase * HALF_PI);

   tip = (Tip * phase * 0.005) + (Guide * guide * 0.01);

   float2 xy1 = uv - float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   float4 retval = max (xy2.x, xy2.y) > 0.5 ? BLACK : tex2D (s_Input, xy1);

   float luma = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));

   if (Mode == MONO) { return float4 (luma.xxx, retval.a); }

   retval.rgb = lerp (retval.rgb, luma.xxx, abs (Phase * phase));

   return retval;
}

float4 ps_main_bars (float2 uv : TEXCOORD1) : COLOR
{
   float tip = PAL * (PAL_OFFS - uv.y);
   float hanover = frac (288.0 * uv.y);
   float phase = (tip - floor (tip));
   float guide = 1.0 - cos (phase * HALF_PI);

   tip = (Tip * phase * 0.005) + (Guide * guide * 0.01);

   float2 xy1 = uv - float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   float4 retval = max (xy2.x, xy2.y) > 0.5 ? BLACK : tex2D (s_Input, xy1);

   if (Mode == MONO) {
      float luma = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));

      return float4 (luma.xxx, retval.a);
   }

   phase = Phase * ((phase * 41.0) + uv.x) / 42.0;

   if (hanover >= 0.5) phase = -phase;

   retval.rgb = phase < 0.0 ? lerp (retval.rgb, retval.gbr, abs (phase))
                            : lerp (retval.rgb, retval.brg, phase);

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

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
