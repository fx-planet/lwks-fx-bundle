// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Granular_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Granular.mp4

/**
 This effect uses a granular noise driven pattern to transition into or out of a delta key.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Granular_Adx.fx
//
// Version history:
//
// Modified jwrl 2020-07-23
// Improved support for unfolded effects.
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//
// Modified jwrl 2020-12-23
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Granular dissolve (delta)";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "Separates foreground from background then uses a granular noise driven pattern to transition into or out of it";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Key : RenderColorTarget;

texture Buffer_1 : RenderColorTarget;
texture Buffer_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Key = sampler_state { Texture = <Key>; };

sampler s_Buffer_1 = sampler_state {
   Texture   = <Buffer_1>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Buffer_2 = sampler_state {
   Texture   = <Buffer_2>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
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

int Ttype
<
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip,At start (unfolded)";
> = 0;

int SetTechnique
<
   string Description = "Transition type";
   string Enum = "Top to bottom,Left to right,Radial,No gradient";
> = 1;

bool TransDir
<
   string Description = "Invert transition direction";
> = false;

float gWidth
<
   string Group = "Granules";
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool TransVar
<
   string Group = "Granules";
   string Description = "Static pattern";
> = false;

bool Sparkling
<
   string Group       = "Sparkles";
   string Description = "Enable sparkle edge";
> = true;

float pSize
<
   string Group       = "Sparkles";
   string Description = "Size";
   float MinVal = 1.00;
   float MaxVal = 10.0;
> = 5.5;

float pSoftness
<
   string Group       = "Sparkles";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float4 starColour
<
   string Group       = "Sparkles";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 0.0, 1.0 };

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define B_SCALE 0.000545

// Pascal's triangle magic numbers for blur

float _pascal [] = { 0.3125, 0.2344, 0.09375, 0.01563 };

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd, Bgd;

   if (Ttype == 0) {
      Bgd = tex2D (s_Foreground, xy1).rgb;
      Fgd = tex2D (s_Background, xy2).rgb;
   }
   else {
      Fgd = tex2D (s_Foreground, xy1).rgb;
      Bgd = tex2D (s_Background, xy2).rgb;
   }

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_noise (float2 uv : TEXCOORD0) : COLOR
{
   float2 xy = saturate (uv + float2 (0.00013, 0.00123));

   float seed = (TransVar) ? 0.0 : Amount;
   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + seed) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + rndval * 1000;

   float retval = saturate (frac (fmod (rndval, 17) * fmod (rndval, 94)) * 3);

   return retval.xxxx;
}

float4 ps_blur_1 (float2 uv : TEXCOORD1) : COLOR
{
   float2 offset_X1 = float2 (pSoftness * B_SCALE, 0.0);
   float2 offset_X2 = offset_X1 * 2.0;
   float2 offset_X3 = offset_X1 * 3.0;

   float4 retval = tex2D (s_Buffer_1, uv) * _pascal [0];

   retval += tex2D (s_Buffer_1, uv + offset_X1) * _pascal [1];
   retval += tex2D (s_Buffer_1, uv - offset_X1) * _pascal [1];
   retval += tex2D (s_Buffer_1, uv + offset_X2) * _pascal [2];
   retval += tex2D (s_Buffer_1, uv - offset_X2) * _pascal [2];
   retval += tex2D (s_Buffer_1, uv + offset_X3) * _pascal [3];
   retval += tex2D (s_Buffer_1, uv - offset_X3) * _pascal [3];

   return retval;
}

float4 ps_blur_2 (float2 uv : TEXCOORD1) : COLOR
{
   float2 offset_Y1 = float2 (0.0, pSoftness * _OutputAspectRatio * B_SCALE);
   float2 offset_Y2 = offset_Y1 * 2.0;
   float2 offset_Y3 = offset_Y1 * 3.0;

   float4 retval = tex2D (s_Buffer_2, uv) * _pascal [0];

   retval += tex2D (s_Buffer_2, uv + offset_Y1) * _pascal [1];
   retval += tex2D (s_Buffer_2, uv - offset_Y1) * _pascal [1];
   retval += tex2D (s_Buffer_2, uv + offset_Y2) * _pascal [2];
   retval += tex2D (s_Buffer_2, uv - offset_Y2) * _pascal [2];
   retval += tex2D (s_Buffer_2, uv + offset_Y3) * _pascal [3];
   retval += tex2D (s_Buffer_2, uv - offset_Y3) * _pascal [3];

   return retval;
}

float4 ps_vertical (float2 uv : TEXCOORD0) : COLOR
{
   float retval = TransDir ? smoothstep (0.0, 1.0, 1.0 - uv.y) : smoothstep (0.0, 1.0, uv.y);

   retval = saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

float4 ps_horizontal (float2 uv : TEXCOORD0) : COLOR
{
   float retval = TransDir ? smoothstep (0.0, 1.0, 1.0 - uv.x) : smoothstep (0.0, 1.0, uv.x);

   retval = saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

float4 ps_radial (float2 uv : TEXCOORD0) : COLOR
{
   float retval = abs (distance (uv, 0.5.xx)) * 1.4142135624;

   if (TransDir) retval = 1.0 - retval;

   retval = saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float noise  = tex2D (s_Buffer_1, ((uv - 0.5) / pSize) + 0.5).x;
   float grad   = tex2D (s_Buffer_2, uv).x;
   float amount = saturate (((0.5 - grad) * 2) + noise);

   float4 Fgnd = tex2D (s_Key, uv);

   float4 retval = (Ttype == 0) ? lerp (tex2D (s_Foreground, uv), Fgnd, Fgnd.a * amount)
                 : (Ttype == 1) ? lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - amount))
                                : lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * amount);

   if (!Sparkling) return retval;

   amount = 0.5 - abs (amount - 0.5);

   float stars = saturate ((pow (amount, 3.0) * 4.0) + amount);

   return lerp (retval, starColour, stars * Fgnd.a);
}

float4 ps_flat (float2 uv : TEXCOORD1) : COLOR
{
   float noise  = tex2D (s_Buffer_1, ((uv - 0.5) / pSize) + 0.5).x;
   float amount = saturate (((Amount - 0.5) * 2.0) + noise);

   float4 Fgnd = tex2D (s_Key, uv);
   float4 retval = (Ttype == 0) ? lerp (tex2D (s_Foreground, uv), Fgnd, Fgnd.a * amount)
                 : (Ttype == 1) ? lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - amount))
                                : lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * amount);

   if (!Sparkling) return retval;

   amount = 0.5 - abs (amount - 0.5);

   float stars = saturate ((pow (amount, 3.0) * 4.0) + amount);

   return lerp (retval, starColour, stars * Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique TopToBottom
{
   pass P_1 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_blur_1 (); }

   pass P_4 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_blur_2 (); }

   pass P_5 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_vertical (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}

technique LeftToRight
{
   pass P_1 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_blur_1 (); }

   pass P_4 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_blur_2 (); }

   pass P_5 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_horizontal (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}

technique Radial
{
   pass P_1 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_blur_1 (); }

   pass P_4 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_blur_2 (); }

   pass P_5 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_radial (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}

technique Flat
{
   pass P_1 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_blur_1 (); }

   pass P_4 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_blur_2 (); }

   pass P_5
   { PixelShader = compile PROFILE ps_flat (); }
}
