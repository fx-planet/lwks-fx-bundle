// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Granular_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/GranularDissolve.mp4

/**
 This effect was created to provide a granular noise driven dissolve.  The noise
 component is based on work by users khaver and windsturm.  The radial gradient part
 is from an effect provided by LWKS Software Ltd.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Granular_Dx.fx
//
// Version history:
//
// Rewrite 2021-07-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Granular dissolve";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "This effect provides a granular noise driven dissolve between shots";
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

#define DefineTarget(TEXTURE, SAMPLER) \
                                       \
 texture TEXTURE : RenderColorTarget;  \
                                       \
 sampler SAMPLER = sampler_state       \
 {                                     \
   Texture   = <TEXTURE>;              \
   AddressU  = Mirror;                 \
   AddressV  = Mirror;                 \
   MinFilter = Linear;                 \
   MagFilter = Linear;                 \
   MipFilter = Linear;                 \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

// Pascal's triangle magic numbers for blur

#define BLUR_0  0.3125
#define BLUR_1  0.2344
#define BLUR_2  0.09375
#define BLUR_3  0.01563

#define B_SCALE 0.000545

float _Progress;
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);
DefineTarget (Buffer_0, s_Buffer_0);
DefineTarget (Buffer_1, s_Buffer_1);
DefineTarget (Buffer_2, s_Buffer_2);
DefineTarget (Buffer_3, s_Buffer_3);

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
   string Group       = "Particles";
   string Description = "Type";
   string Enum = "Top to bottom,Left to right,Radial,No gradient";
> = 1;

bool TransDir
<
   string Description = "Invert transition direction";
> = false;

float gWidth
<
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float pSize
<
   string Group       = "Particles";
   string Description = "Size";
   float MinVal = 1.00;
   float MaxVal = 10.0;
> = 5.5;

float pSoftness
<
   string Group       = "Particles";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool TransVar
<
   string Group       = "Particles";
   string Description = "Static particle pattern";
> = false;

bool Sparkles
<
   string Group       = "Particles";
   string Description = "Sparkle";
> = false;

float4 starColour
<
   string Group       = "Particles";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.9, 0.75, 0.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_vert_grad (float2 uv : TEXCOORD3) : COLOR
{
   float retval = lerp (0.0, 1.0, uv.y);

   if (TransDir) retval = 1.0 - retval;

   return saturate ((5 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0)).xxxx;
}

float4 ps_horiz_grad (float2 uv : TEXCOORD3) : COLOR
{
   float retval = lerp (0.0, 1.0, uv.x);

   if (TransDir) retval = 1.0 - retval;

   return saturate ((5 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0)).xxxx;
}

float4 ps_radial_grad (float2 uv : TEXCOORD3) : COLOR
{
   float progress = abs (distance (uv, float2 (0.5, 0.5))) * 1.414;
   float4 pixel = tex2D (s_Foreground, uv);

   float colOneAmt = 1.0 - progress;
   float colTwoAmt = progress;

   float retval = (lerp (pixel, 0.0, 1.0) * colOneAmt) +
                  (lerp (pixel, 1.0, 1.0) * colTwoAmt) +
                  (pixel * (1.0 - (colOneAmt + colTwoAmt)));

   if (TransDir) retval = 1.0 - retval;

   return saturate ((5 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0)).xxxx;
}

float4 ps_noise (float2 uv : TEXCOORD3) : COLOR
{
   float4 source = (0.0).xxxx;

   float2 xy = saturate (uv + float2 (0.00013, 0.00123));

   float seed = (TransVar) ? 0.0 : Amount;

   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + seed) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + rndval * 1000.0;

   return saturate (frac (fmod (rndval, 17.0) * fmod (rndval, 94.0)) * 3.0).xxxx;
}

float4 ps_soft_1 (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval   = tex2D (s_Buffer_1, uv);

   float2 offset_X1 = float2 (pSoftness * B_SCALE, 0.0);
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

float4 ps_soft_2 (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval   = tex2D (s_Buffer_2, uv);

   float2 offset_Y1 = float2 (0.0, pSoftness * _OutputAspectRatio * B_SCALE);
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

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgnd  = tex2D (s_Foreground, uv);
   float4 Bgnd  = tex2D (s_Background, uv);

   float4 grad  = tex2D (s_Buffer_0, uv);
   float4 noise = tex2D (s_Buffer_3, ((uv - 0.5) / pSize) + 0.5);

   float level  = saturate (((0.5 - grad.x) * 2) + noise);

   float4 retval = lerp (Fgnd, Bgnd, level);

   if (!Sparkles) return retval;

   if (level > 0.5) level = 0.5 - level;

   float stars = saturate ((pow (level, 3) * 4) + level);

   return lerp (retval, starColour, stars);
}

float4 ps_flat (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, uv);
   float4 Bgnd = tex2D (s_Background, uv);

   float4 noise = tex2D (s_Buffer_3, ((uv - 0.5) / pSize) + 0.5);

   float level = saturate (((Amount - 0.5) * 2) + noise);

   float4 retval = lerp (Fgnd, Bgnd, level);

   if (!Sparkles) return retval;

   if (level > 0.5) level = 0.5 - level;

   float stars = saturate ((pow (level, 3) * 4) + level);

   return lerp (retval, starColour, stars);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique TopToBottom
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pfg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = Buffer_0;"; > ExecuteShader (ps_vert_grad)
   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_noise)
   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (ps_soft_1)
   pass P_4 < string Script = "RenderColorTarget0 = Buffer_3;"; > ExecuteShader (ps_soft_2)
   pass P_5 ExecuteShader (ps_main)
}

technique LeftToRight
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pfg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = Buffer_0;"; > ExecuteShader (ps_horiz_grad)
   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_noise)
   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (ps_soft_1)
   pass P_4 < string Script = "RenderColorTarget0 = Buffer_3;"; > ExecuteShader (ps_soft_2)
   pass P_5 ExecuteShader (ps_main)
}

technique Radial
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pfg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = Buffer_0;"; > ExecuteShader (ps_radial_grad)
   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_noise)
   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (ps_soft_1)
   pass P_4 < string Script = "RenderColorTarget0 = Buffer_3;"; > ExecuteShader (ps_soft_2)
   pass P_5 ExecuteShader (ps_main)
}

technique Flat
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pfg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_noise)
   pass P_2 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (ps_soft_1)
   pass P_3 < string Script = "RenderColorTarget0 = Buffer_3;"; > ExecuteShader (ps_soft_2)
   pass P_4 ExecuteShader (ps_flat)
}
