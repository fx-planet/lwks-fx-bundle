// @Maintainer jwrl
// @Released 2020-07-31
// @Author jwrl
// @Created 2018-06-12
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Ripples_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Ripples.mp4

/**
 This effect starts off by rippling the outgoing title as it dissolves to the new one,
 on which it progressively loses the ripple.  By default alpha levels are boosted to
 better support Lightworks titles, but this may be disabled.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dreams_Ax.fx
//
// This is a revision of an earlier effect, Adx_Ripples.fx, which also had the ability to
// transition between two titles.  That adds needless complexity since the same result
// can be obtained by overlaying two effects.
//
// Version history:
//
// Modified 2020-07-31 jwrl.
// Reworded Boost text to match requirements for 2020.1 and up.
// Reworded Transition text to match requirements for 2020.1 and up.
// Move Boost code into dissolve shader so that the foreground is always correct.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dream sequence (alpha)";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Ripples a title as it dissolves in or out";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Super : RenderColorTarget;
texture BlurX : RenderColorTarget;
texture BlurY : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Sup>; };
sampler s_Background = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture   = <Super>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blur_X = sampler_state {
   Texture   = <BlurX>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blur_Y = sampler_state {
   Texture   = <BlurY>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "Lightworks effects: Disconnect the input and select";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image";
> = 0;

float Amount
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start,At end";
> = 0;

int WaveType
<
   string Description = "Wave type";
   string Enum = "Waves,Ripples";
> = 0;

float Frequency
<
   string Group = "Pattern";
   string Flags = "Frequency";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float Speed
<
   string Group = "Pattern";
   string Description = "Speed";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float BlurAmt
<
   string Group = "Pattern";
   string Description = "Blur";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float StrengthX
<
   string Group = "Pattern";
   string Description = "Strength";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float StrengthY
<
   string Group = "Pattern";
   string Description = "Strength";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SAMPLE  30
#define SAMPLES 60
#define OFFSET  0.0005

#define CENTRE  (0.5).xx

#define EMPTY   (0.0).xxxx

#define HALF_PI 1.5707963268

float _Progress;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (Vsample, uv);
}

float2 fn_wave (float2 uv, float2 waves, float levels)
{
   float waveRate = _Progress * Speed * 25.0;

   float2 xy = (uv - CENTRE) * waves;
   float2 strength  = float2 (StrengthX, StrengthY) * levels / 10.0;
   float2 retXY = (WaveType == 0) ? float2 (sin (waveRate + xy.y), cos (waveRate + xy.x))
                                  : float2 (sin (waveRate + xy.x), cos (waveRate + xy.y));

   return uv + (retXY * strength);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if (Boost == 0) {
      retval.a = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

float4 ps_dissolve_in (float2 uv : TEXCOORD1) : COLOR
{
   float waves = float (Frequency * 200.0);

   float2 xy = fn_wave (uv, waves.xx, cos (Amount * HALF_PI));

   return tex2D (s_Super, xy) * Amount;
}

float4 ps_dissolve_out (float2 uv : TEXCOORD1) : COLOR
{
   float waves = float (Frequency * 200.0);

   float2 xy = fn_wave (uv, waves.xx, sin (Amount * HALF_PI));

   return tex2D (s_Super, xy) * (1.0 - Amount);
}

float4 ps_blur_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 Inp = tex2D (s_Blur_X, uv);
   float4 retval = EMPTY;

   float BlurX = (StrengthY > StrengthX) ? WaveType ? BlurAmt : (BlurAmt / 2)
                                         : WaveType ? (BlurAmt / 2) : BlurAmt;
   if (BlurX <= 0.0) return Inp;

   float2 offset = float2 (BlurX, 0.0) * OFFSET;
   float2 blurriness = 0.0.xx;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (s_Blur_X, uv + blurriness);
      retval += tex2D (s_Blur_X, uv - blurriness);
      blurriness += offset;
   }
    
   retval = retval / SAMPLES;
    
   return lerp (Inp, retval, 1.0 - Amount);
}

float4 ps_blur_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Inp = tex2D (s_Blur_X, uv);
   float4 retval = EMPTY;

   float BlurY = (StrengthY > StrengthX) ? WaveType ? BlurAmt : (BlurAmt / 2)
                                         : WaveType ? (BlurAmt / 2) : BlurAmt;
   if (BlurY <= 0.0) return Inp;

   float2 offset = float2 (BlurY, 0.0) * OFFSET;
   float2 blurriness = 0.0.xx;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (s_Blur_X, uv + blurriness);
      retval += tex2D (s_Blur_X, uv - blurriness);
      blurriness += offset;
   }
    
   retval = retval / SAMPLES;
    
   return lerp (Inp, retval, Amount);
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd   = tex2D (s_Blur_Y, uv);
   float4 retval = EMPTY;

   float BlurY = (StrengthY > StrengthX) ? WaveType ? (BlurAmt / 2.0) : (BlurAmt * 2.0)
                                         : WaveType ? (BlurAmt * 2.0) : (BlurAmt / 2.0);
   if (BlurY > 0.0) {
      float2 offset = float2 (0.0, BlurY) * OFFSET;
      float2 blurriness = 0.0.xx;

      for (int i = 0; i < SAMPLE; i++) {
         retval += tex2D (s_Blur_Y, uv + blurriness);
         retval += tex2D (s_Blur_Y, uv - blurriness);
         blurriness += offset;
      }

      retval /= SAMPLES;

      Fgnd = lerp (Fgnd, retval, 1.0 - Amount);
   }

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd   = tex2D (s_Blur_Y, uv);
   float4 retval = EMPTY;

   float BlurY = (StrengthY > StrengthX) ? WaveType ? (BlurAmt / 2.0) : (BlurAmt * 2.0)
                                         : WaveType ? (BlurAmt * 2.0) : (BlurAmt / 2.0);
   if (BlurY > 0.0) {
      float2 offset = float2 (0.0, BlurY) * OFFSET;
      float2 blurriness = 0.0.xx;

      for (int i = 0; i < SAMPLE; i++) {
         retval += tex2D (s_Blur_Y, uv + blurriness);
         retval += tex2D (s_Blur_Y, uv - blurriness);
         blurriness += offset;
      }

      retval /= SAMPLES;

      Fgnd = lerp (Fgnd, retval, Amount);
   }

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dreams_Ax_in
{
   pass P_0
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_1 < string Script = "RenderColorTarget0 = BlurX;"; >
   { PixelShader = compile PROFILE ps_dissolve_in (); }

   pass P_2 < string Script = "RenderColorTarget0 = BlurY;"; >
   { PixelShader = compile PROFILE ps_blur_in (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Dreams_Ax_out
{
   pass P_0
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_1 < string Script = "RenderColorTarget0 = BlurX;"; >
   { PixelShader = compile PROFILE ps_dissolve_out (); }

   pass P_2 < string Script = "RenderColorTarget0 = BlurY;"; >
   { PixelShader = compile PROFILE ps_blur_out (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_out (); }
}
