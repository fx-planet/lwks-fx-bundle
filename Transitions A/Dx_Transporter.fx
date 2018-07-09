// @maintainer jwrl
// @released 2018-07-09
// @author jwrl
// @created 2018-07-09
// @see https://www.lwks.com/media/kunena/attachments/6375/Transporter_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Transporter.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_Transporter.fx
//
// This is a difference key controlling a Star Trek-like transporter-style transition.
// It is definitely not intended to be a copy of any of the Star Trek versions of that
// effect.  At most it should be regarded as an interpretation of the idea behind it.
// Unlike Transporter I, this is set up to be used in the same way as a dissolve.
//
// The transition is quite complex.  The key is only ever used to control the area that
// the sparkles/stars occupy.  During the first part of the transition's progress the
// sparkles or stars build, then hold for the middle section.  They then decay to zero.
// Under that, after the first 30% of the transition the foreground starts a linear fade
// in, reaching full value at 70% of the transition progress.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Transporter transition";
   string Category    = "Mix";
   string SubCategory = "Special Fx";
   string Notes       = "A difference key used to create a Star Trek-like transporter effect";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Sparkles : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Sparkles = sampler_state
{
   Texture   = <Sparkles>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool SwapDirection
<
   string Description = "Swap direction";
> = false;

float Transition
<
   string Description = "Transition";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 1.0;

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
   string Enum = "Use the effect,Show foreground over black,Show key over black";
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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI       3.1415926536

#define S_SCALE  0.000868
#define FADER    0.9333333333
#define FADE_DEC 0.0666666667

#define EMPTY    (0.0).xxxx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float left = max (0.0, CropLeft);
   float top = max (0.0, 1.0 - CropTop);
   float right = min (1.0, CropRight);
   float bottom = min (1.0, 1.0 - CropBottom);

   if ((xy1.x < left) || (xy1.x > right) || (xy1.y < top) || (xy1.y > bottom)) return EMPTY;

   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   float4 retval = smoothstep (KeyClip, KeyClip + KeyGain, kDiff).xxxx;

   float scale = (1.0 - starSize) * 800.0;
   float seed = Transition;
   float Y = saturate ((round (xy1.y * scale) / scale) + 0.000123);

   scale *= _OutputAspectRatio;

   float X = saturate ((round (xy1.x * scale) / scale) + 0.00013);
   float rndval = frac (sin ((X * 13.9898) + (Y * 79.233) + seed) * 43758.5453);

   rndval = sin (X) + cos (Y) + rndval * 1000.0;

   float amt = frac (fmod (rndval, 17.0) * fmod (rndval, 94.0));
   float alpha = abs (cos (Transition * PI));

   amt = smoothstep (0.975 - (starStrength * 0.375), 1.0, amt);
   retval.z *= (amt <= alpha) ? 0.0 : amt;

   return retval;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float fader = FADER;

   float2 key = tex2D (s_Sparkles, uv1).zy;
   float2 xy1 = float2 (starLength * S_SCALE, 0.0);
   float2 xy2 = xy1.yx * _OutputAspectRatio;
   float2 xy3 = xy1;
   float2 xy4 = xy2;

   for (int i = 0; i <= 15; i++) {
      key.x += tex2D (s_Sparkles, uv1 + xy1).z * fader;
      key.x += tex2D (s_Sparkles, uv1 - xy1).z * fader;
      key.x += tex2D (s_Sparkles, uv1 + xy2).z * fader;
      key.x += tex2D (s_Sparkles, uv1 - xy2).z * fader;

      xy1 += xy3;
      xy2 += xy4;
      fader -= FADE_DEC;
   }

   float4 Fgd = tex2D (s_Foreground, uv1);

   if (KeySetup > 0) {
      float mix = saturate (2.0 - (key.y * Fgd.a * 2.0));

      if (KeySetup == 1) return lerp (Fgd, EMPTY, mix);

      return lerp (1.0.xxxx, EMPTY, mix);
   }

   float Amount = (cos (smoothstep (0.3, 0.7, Transition) * PI) * 0.5) + 0.5;

   float4 retval = SwapDirection
                 ? lerp (Fgd, tex2D (s_Background, uv2), Amount)
                 : lerp (tex2D (s_Background, uv2), Fgd, Amount);

   return lerp (retval, starColour, saturate (key.x));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Transporter_II
{
   pass P_1
   < string Script = "RenderColorTarget0 = Sparkles;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
