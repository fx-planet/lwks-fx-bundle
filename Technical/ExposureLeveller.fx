// @Maintainer jwrl
// @Released 2021-10-28
// @Author khaver
// @Created 2016-06-10
// @see https://www.lwks.com/media/kunena/attachments/6375/ExposureLeveler_640.png

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
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ExpoLeveller.fx
//
// Version history:
//
// Update 2021-10-28 jwrl.
// Updated the original effect to work with LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Exposure leveller";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "This corrects the levels of shots where the exposure varies over time";
   bool CanSize       = true;
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
#define ExecuteParam(SHD,PRM) { PixelShader = compile PROFILE SHD (PRM); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawFg);
DefineInput (Frame, s_RawBg);

DefineTarget (RawFg, s0);
DefineTarget (RawBg, f0);
DefineTarget (IPass, s1);
DefineTarget (FPass, f1);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float TUNE
<
   string Description = "Tune";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float BLUR
<
   string Description = "Blur Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool SWAP
<
   string Description = "Swap Tracks";
> = false;

bool ShowE
<
   string Description = "Show Example Frame";
> = false;

bool ShowVB
<
   string Description = "Show Video Blur";
> = false;

bool ShowFB
<
   string Description = "Show Example Blur";
> = false;

bool COMBINE
<
   string Description = "Use Example Points for Video";
> = true;

float F1X
<
   string Description = "E1";
   string Group = "Example Samples";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float F1Y
<
   string Description = "E1";
   string Group = "Example Samples";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float F2X
<
   string Description = "E2";
   string Group = "Example Samples";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float F2Y
<
   string Description = "E2";
   string Group = "Example Samples";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float F3X
<
   string Description = "E3";
   string Group = "Example Samples";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float F3Y
<
   string Description = "E3";
   string Group = "Example Samples";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float V1X
<
   string Description = "V1";
   string Group = "Video Samples";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float V1Y
<
   string Description = "V1";
   string Group = "Video Samples";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float V2X
<
   string Description = "V2";
   string Group = "Video Samples";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float V2Y
<
   string Description = "V2";
   string Group = "Video Samples";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float V3X
<
   string Description = "V3";
   string Group = "Video Samples";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float V3Y
<
   string Description = "V3";
   string Group = "Video Samples";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

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
   float3 col = GetPixel (samp, xy).rgb;

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

   return Overflow (texCoord) ? EMPTY : cOut / 13.0;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 I_main (float2 uv : TEXCOORD3, uniform int test) : COLOR
{
   return (test == 0) ? GrowablePoissonDisc13FilterRGBA (s0, uv, test)
                      : GrowablePoissonDisc13FilterRGBA (s1, uv, test);
}

float4 F_main (float2 uv : TEXCOORD3, uniform int test) : COLOR
{
   return (test == 0) ? GrowablePoissonDisc13FilterRGBA (f0, uv, test)
                      : GrowablePoissonDisc13FilterRGBA (f1, uv, test);
}

float4 Process (float2 uv : TEXCOORD3) : COLOR
{
   float4 video, frame, cout;

   if (SWAP) {
      video = GetPixel (f0, uv);
      frame = GetPixel (s0, uv);
   }
   else {
      video = GetPixel (s0, uv);
      frame = GetPixel (f0, uv);
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
      if (ShowVB) return tex2D (f1, uv);
      if (ShowFB) return tex2D (s1, uv);

      flum1 = colorsep (s1, fp1);
      flum2 = colorsep (s1, fp2);
      flum3 = colorsep (s1, fp3);
      vlum1 = colorsep (f1, vp1);
      vlum2 = colorsep (f1, vp2);
      vlum3 = colorsep (f1, vp3);
   }
   else {
      if (ShowVB) return tex2D (s1, uv);
      if (ShowFB) return tex2D (f1, uv);

      flum1 = colorsep (f1, fp1);
      flum2 = colorsep (f1, fp2);
      flum3 = colorsep (f1, fp3);
      vlum1 = colorsep (s1, vp1);
      vlum2 = colorsep (s1, vp2);
      vlum3 = colorsep (s1, vp3);
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

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ExpoLeveler
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass IPassA < string Script = "RenderColorTarget0 = IPass;"; > ExecuteParam (I_main, 0)
   pass IPassB < string Script = "RenderColorTarget0 = IPass;"; > ExecuteParam (I_main, 1)
   pass IPassC < string Script = "RenderColorTarget0 = IPass;"; > ExecuteParam (I_main, 2)
   pass IPassD < string Script = "RenderColorTarget0 = IPass;"; > ExecuteParam (I_main, 3)
   pass IPassE < string Script = "RenderColorTarget0 = IPass;"; > ExecuteParam (I_main, 4)
   pass IPassF < string Script = "RenderColorTarget0 = IPass;"; > ExecuteParam (I_main, 5)
   pass FPassA < string Script = "RenderColorTarget0 = FPass;"; > ExecuteParam (F_main, 0)
   pass FPassB < string Script = "RenderColorTarget0 = FPass;"; > ExecuteParam (F_main, 1)
   pass FPassC < string Script = "RenderColorTarget0 = FPass;"; > ExecuteParam (F_main, 2)
   pass FPassD < string Script = "RenderColorTarget0 = FPass;"; > ExecuteParam (F_main, 3)
   pass FPassE < string Script = "RenderColorTarget0 = FPass;"; > ExecuteParam (F_main, 4)
   pass FPassF < string Script = "RenderColorTarget0 = FPass;"; > ExecuteParam (F_main, 5)
   pass Final ExecuteShader (Process)
}

