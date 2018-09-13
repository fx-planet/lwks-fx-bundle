// @Maintainer jwrl
// @Released 2018-09-13
// @Author jwrl
// @Created 2018-09-07
// @see https://www.lwks.com/media/kunena/attachments/6375/Quad_VTR_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/QuadVTR.mp4
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
// Modified jwrl 2018-09-12:
// Added sparkle caused by the brushes in early Ampex heads.  It sort of works, but it's
// not exactly great.
// Added head switching dots visible in the Ampex VR-1000 series.
// Added crop to 4:3 aspect ratio.  The alpha channel is set to one inside the crop zone
// and zero outside it.  The crop is reasonably dumb and assumes that the image isn't in
// portrait format.
//
// Modified jwrl 2018-09-13:
// Added Hi-band/lo-band selection.  Two low band modes are provided, because the type
// of modulator used differed between valve and solid state signal systems, resulting
// in differing noise levels and edge artefacts.
// Improved head switch simulation so that unmodified video follows switch pulse.  This
// also improves the buildup simulation.
// Some code cleanup performed.
//
// Possible future projects:
// Add noise displacement when build up occurs.
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

texture Shp : RenderColorTarget;
texture VTR : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Sharpen = sampler_state { Texture = <Shp>; };
sampler s_QuadVTR = sampler_state { Texture = <VTR>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Mode
<
   string Description = "Television standard";
   string Enum = "525 line,625 line";
> = 1;

int VTRmode
<
   string Description = "VTR mode";
   string Enum = "Low band (valve),Low band (solid state),High band";
> = 0;

int SetTechnique
<
   string Description = "Colour format";
   string Enum = "Black and white,NTSC colour,PAL colour,PAL with Hanover bars";
> = 2;

bool Crop
<
   string Description = "Crop frame to 4x3 aspect ratio";
> = true;

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

float Brush
<
   string Description = "Brush noise";
   float MinVal = 0.0;
   float MaxVal = 1.0;
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

bool HeadSwitch
<
   string Description = "Show head switching dots";
> = false;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLACK     float4((0.0).xxx, 1.0)
#define WHITE     (1.0).xxxx
#define EMPTY     (0.0).xxxx

#define B_W       float3(0.2989, 0.5866, 0.1145)

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
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_sharpen (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   float2 xy1 = (Mode == TV_525) ? float2 (1.0 / _OutputAspectRatio, 1.0) / (483.0 * max (1, VTRmode))
                                 : float2 (1.0 / _OutputAspectRatio, 1.0) / (576.0 * max (1, VTRmode));
   float2 xy2 = float2 (0.0, xy1.y);
   float2 xy3 = float2 (xy1.x, -xy1.y);
   float2 xy4 = float2 (xy1.x, 0.0);

   float setband = (VTRmode == 0) ? 0.0 : 0.5;
   float sharpen = 0.25 - (setband * 0.125);

   retval *= 3.0 - setband;
   retval -= tex2D (s_Input, uv - xy1) * sharpen;
   retval -= tex2D (s_Input, uv - xy2) * sharpen;
   retval -= tex2D (s_Input, uv + xy3) * sharpen;
   retval -= tex2D (s_Input, uv - xy4) * sharpen;
   retval -= tex2D (s_Input, uv + xy4) * sharpen;
   retval -= tex2D (s_Input, uv - xy3) * sharpen;
   retval -= tex2D (s_Input, uv + xy2) * sharpen;
   retval -= tex2D (s_Input, uv + xy1) * sharpen;

   return retval;
}

float4 ps_mono (float2 uv : TEXCOORD1) : COLOR
{
   float tip = (Mode == TV_525) ? NTSC * (uv.y + NTSC_OFFS) : PAL * (uv.y + PAL_OFFS);
   float phase = (tip - floor (tip));
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE);

   float2 xy1 = uv + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   if (Crop) xy2.x *= _OutputAspectRatio * 0.75;

   if (max (xy2.x, xy2.y) > 0.5) return EMPTY;

   return float4 (dot (tex2D (s_Sharpen, xy1).rgb, B_W).xxx, 0.0);
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

   float phase = (tip - floor (tip));
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE);
   phase = Phase * ((phase * ph1) + uv.x) / ph2;

   float2 xy1 = uv + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   if (Crop) xy2.x *= _OutputAspectRatio * 0.75;

   if (max (xy2.x, xy2.y) > 0.5) return BLACK;

   float4 retval = float4 (tex2D (s_Sharpen, xy1).rgb, 1.0);

   return (phase < 0.0) ? lerp (retval, retval.gbra, abs (phase))
                        : lerp (retval, retval.brga, phase);
}

float4 ps_pal (float2 uv : TEXCOORD1) : COLOR
{
   float tip = (Mode == TV_525) ? NTSC * (uv.y + NTSC_OFFS) : PAL * (uv.y + PAL_OFFS);
   float phase = (tip - floor (tip));
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE);

   float2 xy1 = uv + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   if (Crop) xy2.x *= _OutputAspectRatio * 0.75;

   if (max (xy2.x, xy2.y) > 0.5) return BLACK;

   float3 retval = tex2D (s_Sharpen, xy1).rgb;

   float luma = dot (retval, B_W);

   return float4 (lerp (retval, luma.xxx, abs (Phase * phase)).rgb, 1.0);
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
   phase = Phase * ((phase * ph1) + uv.x) / ph2;

   if (hanover >= 0.5) phase = -phase;

   float2 xy1 = uv + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   if (Crop) xy2.x *= _OutputAspectRatio * 0.75;

   if (max (xy2.x, xy2.y) > 0.5) return BLACK;

   float4 retval = float4 (tex2D (s_Sharpen, xy1).rgb, 1.0);

   return (phase < 0.0) ? lerp (retval, retval.gbra, abs (phase))
                        : lerp (retval, retval.brga, phase);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_QuadVTR, uv);

   float head, x = abs (uv.x - 0.5);

   if (Crop) x *= _OutputAspectRatio * 0.75;

   if (x > 0.5) { return EMPTY; }

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
      retval.rgb = tex2D (s_Sharpen, uv).rgb;

      if (retval.a == 0.0) retval = dot (retval.rgb, B_W).xxxx;
   }

   head = head_idx [head] * 2.0;
   head_sw = (x > 0.4935) && (x < 0.496) && head_sw;

   float buildup = dot (retval.rgb, B_W);
   float noise = frac (sin (dot (xy, float2 (N_1, N_3)) + _Progress) * (S_1));

   retval = (VTRmode == 0) ? lerp (retval, noise.xxxx, 0.1)
          : (VTRmode == 1) ? lerp (retval, noise.xxxx, 0.05)
                           : lerp (retval, noise.xxxx, 0.0125);

   if ((min (noise * 50.0, 1.0) - (Brush * 0.5)) < 0.0) return WHITE;

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
// Techniques
//-----------------------------------------------------------------------------------------//

technique QuadVTR_Mono
{
   pass P_1
   < string Script = "RenderColorTarget0 = Shp;"; > 
   { PixelShader = compile PROFILE ps_sharpen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = VTR;"; > 
   { PixelShader = compile PROFILE ps_mono (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique QuadVTR_NTSC
{
   pass P_1
   < string Script = "RenderColorTarget0 = Shp;"; > 
   { PixelShader = compile PROFILE ps_sharpen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = VTR;"; > 
   { PixelShader = compile PROFILE ps_ntsc (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique QuadVTR_PAL
{
   pass P_1
   < string Script = "RenderColorTarget0 = Shp;"; > 
   { PixelShader = compile PROFILE ps_sharpen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = VTR;"; > 
   { PixelShader = compile PROFILE ps_pal (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique QuadVTR_Hanover
{
   pass P_1
   < string Script = "RenderColorTarget0 = Shp;"; > 
   { PixelShader = compile PROFILE ps_sharpen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = VTR;"; > 
   { PixelShader = compile PROFILE ps_hanover_bars (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}
