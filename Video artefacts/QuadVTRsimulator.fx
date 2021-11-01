// @Maintainer jwrl
// @Released 2021-11-01
// @Author jwrl
// @Created 2021-11-01
// @see https://www.lwks.com/media/kunena/attachments/6375/QuadVTR_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/QuadVTR.mp4

/**
 This effect emulates the faults that could occur with Quadruplex videotape playback.
 Tip penetration and guide height are both emulated, and chroma timebase errors are
 also simulated.  A range of Ampex VTR types and modes can be emulated, as well as a
 generic RCA videotape recorder.

 NOTE: the alpha channel is turned fully on with this effect.  Also, because this
 needs to be able to precisely set line widths no matter what the original clip size
 or aspect ratio is it has not been possible to make it truly resolution independent.
 What it does is lock the clip resolution to sequence resolution instead.
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
// Rewrite 2021-11-01 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Quad VTR simulator";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Emulates the faults that could occur with Quadruplex videotape playback";
   bool CanSize       = false;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define WHITE     1.0.xxxx

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
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

DefineTarget (Shp, s_Sharpen);
DefineTarget (VTR, s_QuadVTR);

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

bool Crop
<
   string Description = "Crop frame to 4x3 aspect ratio";
> = true;

float Tip
<
   string Description = "Tip penetration";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Guide
<
   string Description = "Guide height";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

int SetTechnique
<
   string Description = "Colour format";
   string Enum = "Black and white,NTSC colour (Ampex),PAL colour (Ampex),PAL with Hanover bars (Ampex),Colour offset (RCA)";
> = 2;

float Phase
<
   string Description = "Chroma errors";
   float MinVal = -1.0;
   float MaxVal = 1.0;
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
   string Description = "Show head switching dots (Ampex VR-1000)";
> = false;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_sharpen (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = GetPixel (s_Input, uv);

   float setband = (Mode == TV_525) ? 483.0 : 576.0;

   setband *= (VTRmode * 0.5) + 1.0;

   float2 xy1 = float2 (1.0 / _OutputAspectRatio, 1.0) / setband;
   float2 xy2 = float2 (0.0, xy1.y);
   float2 xy3 = float2 (xy1.x, -xy1.y);
   float2 xy4 = float2 (xy1.x, 0.0);

   setband = max (VTRmode - 1.5, 0.0);

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

   return Overflow (uv) ? EMPTY : retval;
}

float4 ps_mono (float2 uv : TEXCOORD2) : COLOR
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

float4 ps_ntsc (float2 uv : TEXCOORD2) : COLOR
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

float4 ps_pal (float2 uv : TEXCOORD2) : COLOR
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

float4 ps_hanover_bars (float2 uv : TEXCOORD2) : COLOR
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

float4 ps_rca (float2 uv : TEXCOORD2) : COLOR
{
   float tip = (Mode == TV_525) ? NTSC * (uv.y + NTSC_OFFS) : PAL * (uv.y + PAL_OFFS);
   float phase = (tip - floor (tip));
   float guide = sin ((phase + 0.5) * HALF_PI) - SQRT_2;

   tip = (Tip * phase * TIP) + (Guide * guide * GUIDE);

   float2 xy1 = uv + float2 (tip, 0.0);
   float2 xy2 = abs (xy1 - 0.5.xx);

   if (Crop) xy2.x *= _OutputAspectRatio * 0.75;

   if (max (xy2.x, xy2.y) > 0.5) return BLACK;

   xy2 = xy1 - float2 (Phase * 0.005, 0.0);

   float4 retval = ((xy2.x < 0.0) || (xy2.x > 1.0)) ? EMPTY : tex2D (s_Input, xy2);

   float luma = dot (retval.rgb, B_W);

   retval -= luma.xxxx;
   luma = dot (tex2D (s_Sharpen, xy1).rgb, B_W);
   retval += luma.xxxx;

   return float4 (retval.rgb, 1.0);
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
// Techniques
//-----------------------------------------------------------------------------------------//

technique QuadVTR_Mono
{
   pass P_1 < string Script = "RenderColorTarget0 = Shp;"; >  ExecuteShader (ps_sharpen)
   pass P_2 < string Script = "RenderColorTarget0 = VTR;"; >  ExecuteShader (ps_mono)
   pass P_3 ExecuteShader (ps_main)
}

technique QuadVTR_NTSC
{
   pass P_1 < string Script = "RenderColorTarget0 = Shp;"; >  ExecuteShader (ps_sharpen)
   pass P_2 < string Script = "RenderColorTarget0 = VTR;"; >  ExecuteShader (ps_ntsc)
   pass P_3 ExecuteShader (ps_main)
}

technique QuadVTR_PAL
{
   pass P_1 < string Script = "RenderColorTarget0 = Shp;"; >  ExecuteShader (ps_sharpen)
   pass P_2 < string Script = "RenderColorTarget0 = VTR;"; >  ExecuteShader (ps_pal)
   pass P_3 ExecuteShader (ps_main)
}

technique QuadVTR_Hanover
{
   pass P_1 < string Script = "RenderColorTarget0 = Shp;"; >  ExecuteShader (ps_sharpen)
   pass P_2 < string Script = "RenderColorTarget0 = VTR;"; >  ExecuteShader (ps_hanover_bars)
   pass P_3 ExecuteShader (ps_main)
}

technique QuadVTR_RCA
{
   pass P_1 < string Script = "RenderColorTarget0 = Shp;"; >  ExecuteShader (ps_sharpen)
   pass P_2 < string Script = "RenderColorTarget0 = VTR;"; >  ExecuteShader (ps_rca)
   pass P_3 ExecuteShader (ps_main)
}

