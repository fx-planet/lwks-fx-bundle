// @maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_SwirlMix_640.png

/**
 This is a swirl effect similar to schrauber's swirl mix, but optimised for use with
 blended effects.  It has an adjustable axis of rotation and no matter how the spin axis
 and swirl settings are adjusted the distorted image will always stay within the frame
 boundaries.  If the swirl setting is set to zero the image will simply rotate around
 the spin axis.  The spin axis may be set using faders, or may be dragged interactively
 with the mouse in the sequence viewer.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SwirlMix_Kx.fx
//
// This effect is a combination of two previous effects, SwirlMix_Ax and SwirlMix_Adx.
//
// Version history:
//
// Built 2021-07-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Swirl mix (keyed)";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "A swirl mix effect that transitions in or out of the foreground";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Bad_Lightworks_version
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

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = Mirror;                \
   AddressV  = Mirror;                \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
}

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY)  (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow (XY) ? EMPTY : tex2D (SHADER, XY))

#define TWO_PI  6.2831853072
#define PI      3.1415926536
#define HALF_PI 1.5707963268

float _Length;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Title, s_Title);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Source
<
   string Description = "Source";
   string Enum = "Extracted foreground (delta key),Crawl/Roll/Title/Image key,Video/External image";
> = 0;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start if delta key folded,At start of clip,At end of clip";
> = 1;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

float Amplitude
<
   string Group = "Swirl settings";
   string Description = "Swirl depth";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

float Rate
<
   string Group = "Swirl settings";
   string Description = "Revolutions";
   float MinVal = -10.0;
   float MaxVal = 10.0;
> = 0.0;

float Start
<
   string Group = "Swirl settings";
   string Description = "Start angle";
   float MinVal = -360.0;
   float MaxVal = 360.0;
> = 0.0;

float CentreX
<
   string Description = "Spin axis";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CentreY
<
   string Description = "Spin axis";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float KeyGain
<
   string Description = "Key trim";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_keygen (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 xy, xy1 = uv3 - centre;

   float3 spin = float3 (Amplitude, Start, Rate) * (1.0 - Amount);

   float amount = sin (Amount * HALF_PI);
   float angle = (length (xy1) * spin.x * TWO_PI) + radians (spin.y);
   float scale0, scale90;

   sincos (angle + (spin.z * _Length * PI), scale90, scale0);
   xy = (xy1 * scale0) - (float2 (xy1.y, -xy1.x) * scale90) + centre;

   float4 Fgnd = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Title, xy);

   return lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a * amount);
}

float4 ps_main_I (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 xy, xy1 = uv3 - centre;

   float3 spin = float3 (Amplitude, Start, Rate) * (1.0 - Amount);

   float amount = sin (Amount * HALF_PI);
   float angle = (length (xy1) * spin.x * TWO_PI) + radians (spin.y);
   float scale0, scale90;

   sincos (angle + (spin.z * _Length * PI), scale90, scale0);
   xy = (xy1 * scale0) - (float2 (xy1.y, -xy1.x) * scale90) + centre;

   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Title, xy);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * amount);
}

float4 ps_main_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 xy, xy1 = uv3 - centre;

   float3 spin = float3 (Amplitude, Start, Rate) * Amount;

   float amount = sin ((1.0 - Amount) * HALF_PI);
   float angle = (length (xy1) * spin.x * TWO_PI) + radians (spin.y);
   float scale0, scale90;

   sincos (angle + (spin.z * _Length * PI), scale90, scale0);
   xy = (xy1 * scale0) - (float2 (xy1.y, -xy1.x) * scale90) + centre;

   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Title, xy);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SwirlMix_Kx_0
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen_F)
   pass P_2 ExecuteShader (ps_main_F)
}

technique SwirlMix_Kx_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_I)
}

technique SwirlMix_Kx_2
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_O)
}

