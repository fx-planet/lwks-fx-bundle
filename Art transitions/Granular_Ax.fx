// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Granular_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Granular.mp4

/**
 This effect uses a granular noise driven dissolve to transition into or out of a title.  It
 also composites the result over a background layer.  Alpha levels are boosted to support
 Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Granular_Ax.fx
//
// This is a revision of an earlier effect, Adx_Granular.fx, which also had the ability
// to wipe between two titles.  That added needless complexity, when the same result
// can be obtained by overlaying two effects.
//
// Version history:
//
// Modified 2020-07-23 jwrl:
// Changed Transition to Transition position.
// Reworded Boost text to match requirements for 2020.1 and up.
// Implemented Boost as a separate pass ahead of the main code to avoid the function call
// overhead while applying the blur.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed title.
// Changed subcategory.
//
// Modified 2018-07-09 jwrl:
// Removed dependence on pixel size.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Granular dissolve (alpha)";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "Uses a granular noise driven pattern to transition into or out of a title";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Key : RenderColorTarget;

texture Buffer_1 : RenderColorTarget;
texture Buffer_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Sup>; };
sampler s_Background = sampler_state { Texture = <Vid>; };

sampler s_Key = sampler_state { Texture = <Key>; };

sampler s_Buffer_1  = sampler_state {
   Texture   = <Buffer_1>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Buffer_2  = sampler_state {
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

int Boost
<
   string Description = "Lightworks effects: Disconnect the input and select";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image";
> = 0;

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
   string Enum = "At start of clip,At end of clip";
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

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
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

   float4 retval = (Ttype == 0) ? lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * amount)
                                : lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - amount));

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
   float4 retval = (Ttype == 0) ? lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * amount)
                                : lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - amount));

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
// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Granular_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Granular.mp4

/**
 This effect uses a granular noise driven dissolve to transition into or out of a title.  It
 also composites the result over a background layer.  Alpha levels are boosted to support
 Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Granular_Ax.fx
//
// This is a revision of an earlier effect, Adx_Granular.fx, which also had the ability
// to wipe between two titles.  That added needless complexity, when the same result
// can be obtained by overlaying two effects.
//
// Version history:
//
// Modified 2020-07-23 jwrl:
// Changed Transition to Transition position.
// Reworded Boost text to match requirements for 2020.1 and up.
// Implemented Boost as a separate pass ahead of the main code to avoid the function call
// overhead while applying the blur.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed title.
// Changed subcategory.
//
// Modified 2018-07-09 jwrl:
// Removed dependence on pixel size.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Granular dissolve (alpha)";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "Uses a granular noise driven pattern to transition into or out of a title";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Key : RenderColorTarget;

texture Buffer_1 : RenderColorTarget;
texture Buffer_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Sup>; };
sampler s_Background = sampler_state { Texture = <Vid>; };

sampler s_Key = sampler_state { Texture = <Key>; };

sampler s_Buffer_1  = sampler_state {
   Texture   = <Buffer_1>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Buffer_2  = sampler_state {
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

int Boost
<
   string Description = "Lightworks effects: Disconnect the input and select";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image";
> = 0;

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
   string Enum = "At start of clip,At end of clip";
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

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
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

   float4 retval = (Ttype == 0) ? lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * amount)
                                : lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - amount));

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
   float4 retval = (Ttype == 0) ? lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * amount)
                                : lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - amount));

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
