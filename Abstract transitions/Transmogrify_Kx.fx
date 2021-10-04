// @Maintainer jwrl
// @Released 2021-08-29
// @Author jwrl
// @Created 2021-08-29
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Transmogrify_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Transmogrify.mp4

/**
 This is is a truly bizarre transition.  Sort of a stripy blurry dissolve, I guess.  It
 supports titles and other blended effects.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Transmogrify_Kx.fx
//
// This effect is a combination of two earlier effects, Transmogrify_Ax.fx and
// Transmogrify_Adx.fx.
//
// Version history:
//
// Rewrite 2021-08-29 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Transmogrify burst (keyed)";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "Breaks the outgoing effect into a cloud of particles which blow apart.";
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

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
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

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow (XY) ? EMPTY : tex2D (SHADER, XY))

#define SCALE 0.000545

float _OutputAspectRatio;
float _Progress;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Super, s_Super);

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
> = 0.0;

int Source
<
   string Description = "Source";
   string Enum = "Extracted foreground (delta key),Crawl/Roll/Title/Image key,Video/External image";
> = 0;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start if delta key folded,At start of effect,At end of effect";
> = 1;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

float KeyGain
<
   string Description = "Key trim";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_keygen (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 pixSize = uv3 * float2 (1.0, _OutputAspectRatio) * SCALE;

   pixSize += ((uv3 * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5).xx;

   float2 xy = saturate (pixSize + sqrt (1.0 - _Progress).xx);

   xy.y = 1.0 - xy.x;
   xy = lerp (xy, uv3, Amount);

   float4 Fgnd = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Super, xy);
   float4 Bgnd = GetPixel (s_Foreground, uv1);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_main_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 pixSize = uv3 * float2 (1.0, _OutputAspectRatio) * SCALE;

   pixSize += ((uv3 * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5).xx;

   float2 xy = saturate (pixSize + sqrt (1.0 - _Progress).xx);

   xy.y = 1.0 - xy.x;
   xy = lerp (xy, uv3, Amount);

   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy);
   float4 Bgnd = GetPixel (s_Background, uv2);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_main_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 pixSize = uv3 * float2 (1.0, _OutputAspectRatio) * SCALE;

   pixSize += ((uv3 * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5).xx;

   float2 xy = saturate (pixSize + sqrt (_Progress).xx);

   float amount = 1.0 - Amount;

   xy = lerp (xy, uv3, amount);

   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy);
   float4 Bgnd = GetPixel (s_Background, uv2);

   return lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Transmogrify_Kx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 ExecuteShader (ps_main_F)
}

technique Transmogrify_Kx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_I)
}

technique Transmogrify_Kx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_O)
}

