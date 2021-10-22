// @maintainer jwrl
// @released 2021-10-22
// @author jwrl
// @created 2021-10-22
// @see https://www.lwks.com/media/kunena/attachments/6375/TransporterA_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Transporter.mp4

/**
 This is a difference key controlling a Star Trek-like transporter-style transition.  It
 is definitely not intended to be a copy of any of the Star Trek versions of that effect.
 At most it should be regarded as an interpretation of the idea behind it.  Unlike
 Transporter I, this is set up to be used in the same way as a dissolve.

 The transition is quite complex.  The key is only ever used to control the area that the
 sparkles/stars occupy.  During the first part of the transition's progress the sparkles
 or stars build, then hold for the middle section.  They then decay to zero.  Under that,
 after the first 30% of the transition the foreground starts a linear fade in, reaching
 full value at 70% of the transition progress.

 Because the key settings are of so little importance to the final effect they have been
 re-ordered to fall below the star settings, unlike those in the chromakey version.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Transporter2.fx
//
// Version history:
//
// Rewrite 2021-10-22 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Transporter 2";
   string Category    = "Mix";
   string SubCategory = "Special Effects";
   string Notes       = "A difference key used to create a Star Trek-like transporter effect";
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

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define PI       3.1415926536

#define S_SCALE  0.000868
#define FADER    0.9333333333
#define FADE_DEC 0.0666666667

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

DefineTarget (Sparkles, s_Sparkles);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Transition
<
   string Description = "Transition";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float starSize
<
   string Group = "Star settings";
   string Description = "Centre size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float starLength
<
   string Group = "Star settings";
   string Description = "Arm length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float starStrength
<
   string Group = "Star settings";
   string Description = "Density";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float4 starColour
<
   string Group = "Star settings";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.9, 0.75, 0.0, 1.0 };

int KeySetup
<
   string Group = "Key settings";
   string Description = "Set up key";
   string Enum = "Transition fade in,Transition fade out,Show foreground over black,Show key over black";
> = 0;

float KeyClip
<
   string Group = "Key settings";
   string Description = "Key threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float KeyGain
<
   string Group = "Key settings";
   string Description = "Key gain";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float CropLeft
<
   string Group = "Key crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropTop
<
   string Group = "Key crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CropRight
<
   string Group = "Key crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CropBottom
<
   string Group = "Key crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These first two shaders simply isolate the foreground and background nodes from the
// resolution.  It does this by mapping all shaders onto the same texture coordinates.

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return BdrPixel (s_RawBg, uv); }

//-----------------------------------------------------------------------------------------//
// ps_keygen
//
// This starts with a crop shader which masks the foreground so that anomalies with the
// inessential area of the frame can be ignored.  It then compares the foreground to the
// background and generates a difference key.  That then gates a random noise generator
// which creates the required noise for the sparkles that the effect needs for the final
// effect.
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD3) : COLOR
{
   // Calculate the image cropping.  If the uv address falls outside the crop area,
   // black with no alpha is returned.

   float left = max (0.0, CropLeft);
   float top = max (0.0, 1.0 - CropTop);
   float right = min (1.0, CropRight);
   float bottom = min (1.0, 1.0 - CropBottom);
   float Amount = KeySetup == 1 ? Transition : 1.0 - Transition;

   Amount = saturate (Amount);

   if ((uv.x < left) || (uv.x > right) || (uv.y < top) || (uv.y > bottom)) return EMPTY;

   // Now we generate the key by calculating the difference between foreground and
   // background.  We get the differences of R, G and B independently and use the
   // maximum value so obtained to get the cleanest key possible.  It doesn't have
   // to be fantastic, because it will only be used to gate the sparkle noise.

   float3 Fgd = tex2D (s_Foreground, uv).rgb;
   float3 Bgd = tex2D (s_Background, uv).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   float4 retval = smoothstep (KeyClip, KeyClip + KeyGain, kDiff).xxxx;

   // Produce the noise required for the stars.

   float scale = (1.0 - starSize) * 800.0;
   float seed = Amount;
   float Y = saturate ((round (uv.y * scale) / scale) + 0.000123);

   scale *= _OutputAspectRatio;

   float X = saturate ((round (uv.x * scale) / scale) + 0.00013);
   float rndval = frac (sin ((X * 13.9898) + (Y * 79.233) + seed) * 43758.5453);

   rndval = sin (X) + cos (Y) + rndval * 1000.0;

   // Now gate the noise for the stars, slicing the noise at variable values to
   // control the star density.

   float amt = frac (fmod (rndval, 17.0) * fmod (rndval, 94.0));
   float alpha = abs (cos (Amount * PI));

   amt = smoothstep (0.975 - (starStrength * 0.375), 1.0, amt);
   retval.z *= (amt <= alpha) ? 0.0 : amt;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// ps_main
//
// Blend the foreground with the background, and using the key from ps_keygen, apply the
// sparkle transition as we go.
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float fader = FADER;

   float2 key = tex2D (s_Sparkles, uv).zy;
   float2 xy1 = float2 (starLength * S_SCALE, 0.0);
   float2 xy2 = xy1.yx * _OutputAspectRatio;
   float2 xy3 = xy1;
   float2 xy4 = xy2;

   // Create four-pointed stars from the keyed noise.  Doing it this way ensures that the
   // points of the stars fall will overlap the image and won't be cut off.

   for (int i = 0; i <= 15; i++) {
      key.x += tex2D (s_Sparkles, uv + xy1).z * fader;
      key.x += tex2D (s_Sparkles, uv - xy1).z * fader;
      key.x += tex2D (s_Sparkles, uv + xy2).z * fader;
      key.x += tex2D (s_Sparkles, uv - xy2).z * fader;

      xy1 += xy3;
      xy2 += xy4;
      fader -= FADE_DEC;
   }

   // Recover the foreground, and if required, use it to generate the key setup display.

   float4 Fgd = tex2D (s_Foreground, uv);

   if (KeySetup > 1) {
      float mix = saturate (2.0 - (key.y * Fgd.a * 2.0));

      if (KeySetup == 2) return lerp (Fgd, EMPTY, mix);

      return lerp (1.0.xxxx, EMPTY, mix);
   }

   // Create a non-linear transition starting at 0.3 and ending at 0.7.  Using
   // the cosine function gives us a smooth start and end to the transition.

   float Amount = KeySetup == 1 ? Transition : 1.0 - Transition;

   Amount = (cos (smoothstep (0.3, 0.7, saturate (Amount)) * PI) * 0.5) + 0.5;

   float4 retval = lerp (tex2D (s_Background, uv), Fgd, Amount);

   // Key the star colour over the transition.  The stars already vary in
   // density as the transition progresses so no further action is needed.

   return lerp (retval, starColour, saturate (key.x));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Transporter2
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 < string Script = "RenderColorTarget0 = Sparkles;"; > ExecuteShader (ps_keygen)
   pass P_4 ExecuteShader (ps_main)
}

