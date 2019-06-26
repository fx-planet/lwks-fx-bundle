// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Ripples_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Ripples.mp4

/**
This effect ripples the outgoing or incoming delta key as it dissolves.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dreams_Adx.fx
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dream sequence (delta)";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Separates foreground from background then ripples the outgoing or incoming title as it dissolves";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;
texture BlurXinput : RenderColorTarget;
texture BlurYinput : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Title = sampler_state
{
   Texture   = <Title>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blur_X = sampler_state {
   Texture   = <BlurXinput>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blur_Y = sampler_state {
   Texture   = <BlurYinput>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
   string Description = "Transition mode";
   string Enum = "Delta key in,Delta key out";
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

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

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

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (s_Sampler, uv);
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

float4 ps_keygen_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
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

float4 ps_dissolve_I (float2 uv : TEXCOORD1) : COLOR
{
   float2 waves = float (Frequency * 200.0).xx;
   float2 xy = fn_wave (uv, waves, cos (Amount * HALF_PI));

   return fn_tex2D (s_Title, xy) * Amount;
}

float4 ps_dissolve_O (float2 uv : TEXCOORD1) : COLOR
{
   float2 waves = float (Frequency * 200.0).xx;
   float2 xy = fn_wave (uv, waves, sin (Amount * HALF_PI));

   return fn_tex2D (s_Title, xy) * (1.0 - Amount);
}

float4 ps_blur_I (float2 uv : TEXCOORD1) : COLOR
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

float4 ps_blur_O (float2 uv : TEXCOORD1) : COLOR
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

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd   = tex2D (s_Foreground, uv);
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

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd   = tex2D (s_Background, uv);
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

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dreams_Adx_I
{
   pass P_0 < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_1 < string Script = "RenderColorTarget0 = BlurXinput;"; >
   { PixelShader = compile PROFILE ps_dissolve_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = BlurYinput;"; >
   { PixelShader = compile PROFILE ps_blur_I (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Dreams_Adx_O
{
   pass P_0 < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_1 < string Script = "RenderColorTarget0 = BlurXinput;"; >
   { PixelShader = compile PROFILE ps_dissolve_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = BlurYinput;"; >
   { PixelShader = compile PROFILE ps_blur_O (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_O (); }
}

