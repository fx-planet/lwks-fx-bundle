// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Spin_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Spin.mp4

/**
The effect applies a rotary blur to transition into or out of a delta key and is based on
original shader code by rakusan (http://kuramo.ch/webgl/videoeffects/).  The direction,
aspect ratio, centring and strength of the blur can all be set.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Spin_Adx.fx
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Spin dissolve (delta)";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Separates foreground from background then dissolves it through a blurred spin";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Delta : RenderColorTarget;
texture Title : RenderColorTarget;
texture Spin  : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Delta = sampler_state
{
   Texture   = <Delta>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Title = sampler_state {
   Texture   = <Title>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Spin = sampler_state {
   Texture   = <Spin>;
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

int CW_CCW
<
   string Description = "Rotation direction";
   string Enum = "Anticlockwise,Clockwise";
> = 1;

float blurAmount
<
   string Group = "Spin";
   string Description = "Arc (degrees)";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 90.0;

float aspectRatio
<
   string Group = "Spin";
   string Description = "Aspect ratio 1:x";
   float MinVal = 0.01;
   float MaxVal = 10.00;
> = 1.0;

float centreX
<
   string Group = "Spin";
   string Description = "Centre";
   string Flags = "SpecifiesPointX";
   float MinVal = -0.50;
   float MaxVal = 1.50;
> = 0.5;

float centreY
<
   string Group = "Spin";
   string Description = "Centre";
   string Flags = "SpecifiesPointY";
   float MinVal = -0.50;
   float MaxVal = 1.50;
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

#define HALF_PI   1.5707963268

#define REDUCE    0.009375

#define CCW       0
#define CW        1

float _OutputAspectRatio;

float blur_idx []  = { 0, 20, 40, 60, 80 };
float redux_idx [] = { 1.0, 0.8125, 0.625, 0.4375, 0.25 };

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

float4 ps_main_I (float2 uv : TEXCOORD1, uniform int passNum) : COLOR
{
   float blurLen = (1.0 - sin (Amount * HALF_PI)) * blurAmount;

   if (blurLen == 0.0) return tex2D (s_Foreground, uv);

   float4 retval = (0.0).xxxx;

   float2 outputAspect = float2 (1.0, _OutputAspectRatio);
   float2 blurAspect = float2 (1.0, aspectRatio);
   float2 centre = float2 (centreX, 1.0 - centreY );
   float2 xy1, xy2 = (uv - centre) / outputAspect / blurAspect;

   float reduction = redux_idx [passNum];
   float amount = radians (blurLen) / 100.0;

   if (CW_CCW == CCW) amount = -amount;

   float Tcos, Tsin, ang = amount * blur_idx [passNum];

   for (int i = 0; i < 20; i++) {
      sincos (ang, Tsin, Tcos);
      xy1 = centre + float2 ((xy2.x * Tcos - xy2.y * Tsin),
                             (xy2.x * Tsin + xy2.y * Tcos) * outputAspect.y) * blurAspect;
      retval = max (retval, (tex2D (s_Delta, xy1) * reduction));
      reduction -= REDUCE;
      ang += amount;
   }

   if ((passNum == 1) || (passNum == 3)) { retval = max (retval, tex2D (s_Title, uv)); }
   else if (passNum != 0) retval = max (retval, tex2D (s_Spin, uv));

   if (passNum != 4) { return retval; }

   return lerp (tex2D (s_Foreground, uv), retval, retval.a * Amount);
}

float4 ps_main_O (float2 uv : TEXCOORD1, uniform int passNum) : COLOR
{
   float blurLen = (1.0 - cos (Amount * HALF_PI)) * blurAmount;

   if (blurLen == 0.0) return tex2D (s_Foreground, uv);

   float4 retval = (0.0).xxxx;

   float2 outputAspect = float2 (1.0, _OutputAspectRatio);
   float2 blurAspect = float2 (1.0, aspectRatio);
   float2 centre = float2 (centreX, 1.0 - centreY );
   float2 xy1, xy2 = (uv - centre) / outputAspect / blurAspect;

   float reduction = redux_idx [passNum];
   float amount = radians (blurLen) / 100.0;

   if (CW_CCW == CW) amount = -amount;

   float Tcos, Tsin, ang = amount * blur_idx [passNum];

   for (int i = 0; i < 20; i++) {
      sincos (ang, Tsin, Tcos);
      xy1 = centre + float2 ((xy2.x * Tcos - xy2.y * Tsin),
                             (xy2.x * Tsin + xy2.y * Tcos) * outputAspect.y) * blurAspect;
      retval = max (retval, (tex2D (s_Delta, xy1) * reduction));
      reduction -= REDUCE;
      ang += amount;
   }

   if ((passNum == 1) || (passNum == 3)) { retval = max (retval, tex2D (s_Title, uv)); }
   else if (passNum != 0) retval = max (retval, tex2D (s_Spin, uv));

   if (passNum != 4) { return retval; }

   return lerp (tex2D (s_Background, uv), retval, retval.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_Spin_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Delta;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2 < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_main_I (0); }

   pass P_3 < string Script = "RenderColorTarget0 = Spin;"; >
   { PixelShader = compile PROFILE ps_main_I (1); }

   pass P_4 < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_main_I (2); }

   pass P_5 < string Script = "RenderColorTarget0 = Spin;"; >
   { PixelShader = compile PROFILE ps_main_I (3); }

   pass P_6
   { PixelShader = compile PROFILE ps_main_I (4); }
}

technique Adx_Spin_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Delta;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2 < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_main_O (0); }

   pass P_3 < string Script = "RenderColorTarget0 = Spin;"; >
   { PixelShader = compile PROFILE ps_main_O (1); }

   pass P_4 < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_main_O (2); }

   pass P_5 < string Script = "RenderColorTarget0 = Spin;"; >
   { PixelShader = compile PROFILE ps_main_O (3); }

   pass P_6
   { PixelShader = compile PROFILE ps_main_O (4); }
}

