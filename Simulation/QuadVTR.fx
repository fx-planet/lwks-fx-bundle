// @Maintainer jwrl
// @Released 2018-09-07
// @Author jwrl
// @Created 2018-09-07
// @see https://www.lwks.com/media/kunena/attachments/6375/QuadVTR_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadVTR.fx
//
// This effect emulates the faults that could occur with Quad video tape playback.  Tip
// penetration and guide height are both emulated, and colortec phase is also included.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Quad VTR simulator";
   string Category    = "Stylize";
   string SubCategory = "Simulation";
   string Notes       = "Emulates the faults that could occur with Quad video tape playback";
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

int TVstd
<
   string Description = "Television standard";
   string Enum = "NTSC,PAL";
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

#define PAL_TV    1

#define PAL       14.7456
#define PAL_OFFS  1.0784

#define NTSC      14.811428571
#define NTSC_OFFS 1.0802469136

#define HALF_PI   1.5707963268

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float tip   = TVstd == PAL_TV ? PAL * (PAL_OFFS - uv.y) : NTSC * (NTSC_OFFS - uv.y);
   float phase = (tip - floor (tip));
   float guide = Guide > 0.0 ? 1.0 - cos (phase * HALF_PI) : sin (phase * HALF_PI);

   tip = (Tip * phase * 0.005) + (Guide * guide * 0.01);
   phase = Phase * (phase + uv.x) * 0.25;

   float2 xy1 = uv - float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   float4 retval = max (xy2.x, xy2.y) > 0.5 ? BLACK : tex2D (s_Input, xy1);

   retval.rgb = phase < 0.0 ? lerp (retval.rgb, retval.gbr, abs (phase))
                            : lerp (retval.rgb, retval.brg, phase);

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique QuadVTR
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

