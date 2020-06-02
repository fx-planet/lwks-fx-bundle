// @maintainer jwrl
// @Released 2020-06-02
// @author jwrl
// @created 2019-07-30
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_SwirlMix_640.png

/**
 This is a swirl effect similar to schrauber's swirl mix, but optimised for use with
 delta or difference keys.  It has an adjustable axis of rotation and no matter how
 the spin axis and swirl settings are adjusted the distorted image will always stay
 within the frame boundaries.  If the swirl setting is set to zero the image will
 simply rotate around the spin axis.  The spin axis may be set using faders, or may
 be dragged interactively with the mouse in the sequence viewer.

 THIS EFFECT IS DESIGNED FOR LIGHTWORKS VERSION 14.5 AND UP.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SwirlMix_Adx.fx
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Swirl mix (delta)";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "A swirl mix effect using a difference key to transition between the two sources";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Title = sampler_state { Texture = <Title>; };

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

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
> = 0;

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
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

bool Ftype
<
   string Description = "Folded effect";
> = true;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH   // This effect is only available for version 14.5 and up
Bad_LW_version    // Forces a compiler error if the Lightworks version is less.
#endif

#define TWO_PI  6.2831853072
#define PI      3.1415926536
#define HALF_PI 1.5707963268

float _Length;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return Ftype ? float4 (Bgd, smoothstep (0.0, KeyGain, kDiff))
                : float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
{
   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 xy, xy1 = uv - centre;

   float3 spin = float3 (Amplitude, Start, Rate) * (1.0 - Amount);

   float amount = sin (Amount * HALF_PI);
   float angle = (length (xy1) * spin.x * TWO_PI) + radians (spin.y);
   float scale0, scale90;

   sincos (angle + (spin.z * _Length * PI), scale90, scale0);
   xy = (xy1 * scale0) - (float2 (xy1.y, -xy1.x) * scale90) + centre;

   float4 Fgnd = tex2D (s_Title, xy);
   float4 Bgnd = Ftype ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a * amount);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 xy, xy1 = uv - centre;

   float3 spin = float3 (Amplitude, Start, Rate) * Amount;

   float amount = sin ((1.0 - Amount) * HALF_PI);
   float angle = (length (xy1) * spin.x * TWO_PI) + radians (spin.y);
   float scale0, scale90;

   sincos (angle + (spin.z * _Length * PI), scale90, scale0);
   xy = (xy1 * scale0) - (float2 (xy1.y, -xy1.x) * scale90) + centre;

   float4 Fgnd = tex2D (s_Title, xy);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SwirlMix_Adx_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique SwirlMix_Adx_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}
