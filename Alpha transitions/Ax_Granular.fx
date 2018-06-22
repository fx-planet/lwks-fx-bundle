// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Granular_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Granular.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Granular.fx
//
// This effect uses a granular noise driven dissolve to transition into or out of a
// title.  It also composites the result over a background layer.  Alpha levels are
// boosted to support Lightworks titles, which is the default setting.
//
// This is a revision of an earlier effect, Adx_Granular.fx, which also had the ability
// to wipe between two titles.  That added needless complexity, when the same result
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha granular dissolve";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Uses a granular noise driven pattern to transition into or out of a title";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Buffer_0 : RenderColorTarget;
texture Buffer_1 : RenderColorTarget;
texture Buffer_2 : RenderColorTarget;
texture Buffer_3 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Super = sampler_state { Texture = <Sup>; };
sampler s_Video = sampler_state { Texture = <Vid>; };

sampler s_Buffer_0  = sampler_state {
   Texture   = <Buffer_0>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Buffer_1  = sampler_state {
   Texture   = <Buffer_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Buffer_2  = sampler_state {
   Texture   = <Buffer_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Buffer_3  = sampler_state {
   Texture   = <Buffer_3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "If using a Lightworks text effect disconnect its input and set this first";
   string Enum = "Crawl/Roll/Titles,Video/External image";
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
   string Description = "Transition";
   string Enum = "Fade in,Fade out";
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

float _OutputAspectRatio;
float _OutputWidth;

#define FX_OUT  1

// Pascal's triangle magic numbers for blur

#define BLUR_0  0.3125
#define BLUR_1  0.2344
#define BLUR_2  0.09375
#define BLUR_3  0.01563

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 vertical_grad (float2 uv : TEXCOORD0) : COLOR
{
   float retval = lerp (0.0, 1.0, uv.y);

   if (TransDir) retval = 1.0 - retval;

   retval = saturate ((5 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

float4 horizontal_grad (float2 uv : TEXCOORD0) : COLOR
{
   float retval = lerp (0.0, 1.0, uv.x);

   if (TransDir) retval = 1.0 - retval;

   retval = saturate ((5 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

float4 radial_grad (float2 uv : TEXCOORD1) : COLOR
{
   float progress = abs (distance (uv, float2 (0.5, 0.5))) * 1.414;
   float4 pixel = tex2D (s_Super, uv);

   float colOneAmt = 1.0 - progress;
   float colTwoAmt = progress;

   float retval = (lerp (pixel, 0.0, 1.0) * colOneAmt) +
                  (lerp (pixel, 1.0, 1.0) * colTwoAmt) +
                  (pixel * (1.0 - (colOneAmt + colTwoAmt)));

   if (TransDir) retval = 1.0 - retval;

   retval = saturate ((5 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

float4 noise_gen (float2 uv : TEXCOORD0) : COLOR
{
   float2 xy = saturate (uv + float2 (0.00013, 0.00123));

   float seed = (TransVar) ? 0.0 : Amount;
   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + seed) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + rndval * 1000;

   float retval = saturate (frac (fmod (rndval, 17) * fmod (rndval, 94)) * 3);

   return retval.xxxx;
}

float4 Soften_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Buffer_1, uv);

   float2 offset_X1 = float2 (pSoftness / _OutputWidth, 0.0);
   float2 offset_X2 = offset_X1 * 2.0;
   float2 offset_X3 = offset_X1 * 3.0;

   retval *= BLUR_0;
   retval += tex2D (s_Buffer_1, uv + offset_X1) * BLUR_1;
   retval += tex2D (s_Buffer_1, uv - offset_X1) * BLUR_1;
   retval += tex2D (s_Buffer_1, uv + offset_X2) * BLUR_2;
   retval += tex2D (s_Buffer_1, uv - offset_X2) * BLUR_2;
   retval += tex2D (s_Buffer_1, uv + offset_X3) * BLUR_3;
   retval += tex2D (s_Buffer_1, uv - offset_X3) * BLUR_3;

   return retval;
}

float4 Soften_2 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Buffer_2, uv);

   float2 offset_Y1 = float2 (0.0, pSoftness * _OutputAspectRatio / _OutputWidth);
   float2 offset_Y2 = offset_Y1 * 2.0;
   float2 offset_Y3 = offset_Y1 * 3.0;

   retval *= BLUR_0;
   retval += tex2D (s_Buffer_2, uv + offset_Y1) * BLUR_1;
   retval += tex2D (s_Buffer_2, uv - offset_Y1) * BLUR_1;
   retval += tex2D (s_Buffer_2, uv + offset_Y2) * BLUR_2;
   retval += tex2D (s_Buffer_2, uv - offset_Y2) * BLUR_2;
   retval += tex2D (s_Buffer_2, uv + offset_Y3) * BLUR_3;
   retval += tex2D (s_Buffer_2, uv - offset_Y3) * BLUR_3;

   return retval;
}

float4 Combine (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   if (Boost == 0) {
      Fgnd.a    = pow (Fgnd.a, 0.5);
      Fgnd.rgb /= Fgnd.a;
   }

   float noise = tex2D (s_Buffer_3, ((uv - 0.5) / pSize) + 0.5).x;
   float grad  = tex2D (s_Buffer_0, uv).x;
   float level = saturate (((0.5 - grad) * 2) + noise);

   float4 retval = (Ttype == FX_OUT) ? lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - level))
                                     : lerp (Bgnd, Fgnd, Fgnd.a * level);
   if (!Sparkling) return retval;

   level = 0.5 - abs (level - 0.5);

   float stars = saturate ((pow (level, 3.0) * 4.0) + level);

   return lerp (retval, starColour, stars * Fgnd.a);
}

float4 Combine_flat (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   if (Boost == 0) {
      Fgnd.a    = pow (Fgnd.a, 0.5);
      Fgnd.rgb /= Fgnd.a;
   }

   float noise = tex2D (s_Buffer_3, ((uv - 0.5) / pSize) + 0.5).x;
   float level = saturate (((Amount - 0.5) * 2.0) + noise);

   float4 retval = (Ttype == FX_OUT) ? lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - level))
                                     : lerp (Bgnd, Fgnd, Fgnd.a * level);
   if (!Sparkling) return retval;

   level = 0.5 - abs (level - 0.5);

   float stars = saturate ((pow (level, 3.0) * 4.0) + level);

   return lerp (retval, starColour, stars * Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique TopToBottom
{
   pass P_1 < string Script = "RenderColorTarget0 = Buffer_0;"; >
   { PixelShader = compile PROFILE vertical_grad (); }

   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE noise_gen (); }

   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE Soften_1 (); }

   pass P_4 < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE Soften_2 (); }

   pass P_5
   { PixelShader = compile PROFILE Combine (); }
}

technique LeftToRight
{
   pass P_1 < string Script = "RenderColorTarget0 = Buffer_0;"; >
   { PixelShader = compile PROFILE horizontal_grad (); }

   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE noise_gen (); }

   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE Soften_1 (); }

   pass P_4 < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE Soften_2 (); }

   pass P_5
   { PixelShader = compile PROFILE Combine (); }
}

technique Radial
{
   pass P_1 < string Script = "RenderColorTarget0 = Buffer_0;"; >
   { PixelShader = compile PROFILE radial_grad (); }

   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE noise_gen (); }

   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE Soften_1 (); }

   pass P_4 < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE Soften_2 (); }

   pass P_5
   { PixelShader = compile PROFILE Combine (); }
}

technique Flat
{
   pass P_1 < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE noise_gen (); }

   pass P_2 < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE Soften_1 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE Soften_2 (); }

   pass P_4
   { PixelShader = compile PROFILE Combine_flat (); }
}
