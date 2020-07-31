// @Maintainer jwrl
// @Released 2020-07-31
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Twister_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Twister.mp4

/**
 This is a dissolve/wipe that uses sine & cosine distortions to perform a rippling twist to
 establish or remove a delta key.  The range of possible effect variations possible with
 different combinations of settings is almost inifinite.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Twister_Adx.fx
//
// Version history:
//
// Modified 2020-07-31 jwrl.
// Moved folded effect support into "Transition position".
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//
// Modified jwrl 2018-12-28
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "The twister (delta)";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Separates foreground from background and performs a rippling twist to establish or remove it";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Super : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Super = sampler_state
{
   Texture   = <Super>;
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
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip,At start (unfolded)";
> = 0;

int TransProfile
<
   string Description = "Transition profile";
   string Enum = "Left > right profile A,Left > right profile B,Right > left profile A,Right > left profile B"; 
> = 1;

float Width
<
   string Group = "Ripples";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ripples
<
   string Group = "Ripples";
   string Description = "Ripple amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.6;

float Spread
<
   string Group = "Ripples";
   string Description = "Ripple width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

float Twists
<
   string Group = "Twists";
   string Description = "Twist amount";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

bool Show_Axis
<
   string Group = "Twists";
   string Description = "Show twist axis";
> = false;

float Axis
<
   string Group = "Twists";
   string Description = "Set axis";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputHeight;

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

#define EMPTY (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (s_Sampler, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_F (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_main_F (float2 uv : TEXCOORD1) : COLOR
{
   int Mode = (int) fmod ((float)TransProfile, 2.0);

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (Mode == TransProfile) ? uv.x : 1.0 - uv.x;

   maxVis = Amount * (1.0 + range) - maxVis;

   float amount = saturate (maxVis / range);
   float T_Axis = uv.y - Axis;

   float ripples = max (0.0, RIPPLES * (range - maxVis));
   float spread  = ripples * Spread * SCALE;
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;
   float offset  = sin (modultn) * spread;
   float twists  = cos (modultn * Twists * 4.0);

   float2 xy = float2 (uv.x, Axis + (T_Axis / twists) - offset);

   xy.y += offset * float (Mode * 2);

   float4 Fgd = fn_tex2D (s_Super, xy);
   float4 Bgd = lerp (tex2D (s_Foreground, uv), Fgd, Fgd.a * amount);

   if (Show_Axis) {
      float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

      Fgd.rgb = Bgd.rgb + AxisLine.xxx;
      Bgd.rgb = min (1.0.xxx, Fgd.rgb) - max (0.0.xxx, Fgd.rgb - 1.0.xxx);
   }

   return Bgd;
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   int Mode = (int) fmod ((float)TransProfile, 2.0);

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (Mode == TransProfile) ? 1.0 - uv.x : uv.x;

   maxVis = (1.0 - Amount) * (1.0 + range) - maxVis;

   float amount = saturate (maxVis / range);
   float T_Axis = uv.y - Axis;

   float ripples = max (0.0, RIPPLES * (range - maxVis));
   float spread  = ripples * Spread * SCALE;
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;
   float offset  = sin (modultn) * spread;
   float twists  = cos (modultn * Twists * 4.0);

   float2 xy = float2 (uv.x, Axis + (T_Axis / twists) - offset);

   xy.y += offset * float (Mode * 2);

   float4 Fgd = fn_tex2D (s_Super, xy);
   float4 Bgd = lerp (tex2D (s_Background, uv), Fgd, Fgd.a * amount);

   if (Show_Axis) {
      float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

      Fgd.rgb = Bgd.rgb + AxisLine.xxx;
      Bgd.rgb = min (1.0.xxx, Fgd.rgb) - max (0.0.xxx, Fgd.rgb - 1.0.xxx);
   }

   return Bgd;
}

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
{
   int Mode = (int) fmod ((float)TransProfile, 2.0);

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (Mode == TransProfile) ? uv.x : 1.0 - uv.x;

   maxVis = Amount * (1.0 + range) - maxVis;

   float amount = saturate (maxVis / range);
   float T_Axis = uv.y - Axis;

   float ripples = max (0.0, RIPPLES * (range - maxVis));
   float spread  = ripples * Spread * SCALE;
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;
   float offset  = sin (modultn) * spread;
   float twists  = cos (modultn * Twists * 4.0);

   float2 xy = float2 (uv.x, Axis + (T_Axis / twists) - offset);

   xy.y += offset * float (Mode * 2);

   float4 Fgd = fn_tex2D (s_Super, xy);
   float4 Bgd = lerp (tex2D (s_Background, uv), Fgd, Fgd.a * amount);

   if (Show_Axis) {
      float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

      Fgd.rgb = Bgd.rgb + AxisLine.xxx;
      Bgd.rgb = min (1.0.xxx, Fgd.rgb) - max (0.0.xxx, Fgd.rgb - 1.0.xxx);
   }

   return Bgd;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Twister_Adx_F
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen_F (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_F (); }
}

technique Twister_Adx_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}

technique Twister_Adx_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}
