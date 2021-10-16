// @Maintainer jwrl
// @Released 2021-07-25
// @Author Robert Schütze
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Fractal_Dx_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/FractalDissolve.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Fractal.mp4

/**
 This effect uses a fractal-like pattern to transition between two sources.  It operates
 in the same way as a normal dissolve or wipe transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fractal_Dx.fx
//
// The fractal component is a conversion of GLSL sandbox effect #308888 created by Robert
// Schütze (trirop) 07.12.2015.  This effect is a rebuild of an earlier effect,
// Fractals_Dx.fx.
//
// Version history:
//
// Rewrite 2021-07-25 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fractal dissolve";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "Uses a fractal-like pattern to transition between two sources";
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

#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);
DefineTarget (FracOut, s_Fractals);

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

float fractalOffset
<
   string Group = "Fractal settings";
   string Description = "Offset";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Rate
<
   string Group = "Fractal settings";
   string Description = "Rate";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Border
<
   string Group = "Fractal settings";
   string Description = "Edge size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Feather
<
   string Group = "Fractal settings";
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_RawBg, uv); }

float4 ps_fractal (float2 uv : TEXCOORD0) : COLOR
{
   float3 offset  = float3 (1.0.xx, Amount * Rate * 0.5);
   float3 fractal = float3 (uv.x / _OutputAspectRatio, uv.y, fractalOffset);

   for (int i = 0; i < 75; i++) {
      fractal.xzy = float3 (1.3, 0.999, 0.7) * (abs ((abs (fractal) / dot (fractal, fractal) - offset)));
   }

   return float4 (saturate (fractal), 1.0);
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float amt_in   = min (1.0, Amount * 20.0);
   float amt_body = (Amount * 0.5) + 0.5;
   float amt_out  = max (0.0, (Amount * 20.0) - 19.0);

   float4 retval = tex2D (s_Fractals, uv);
   float4 Fgd = tex2D (s_Foreground, uv);
   float4 Bgd = tex2D (s_Background, uv);

   float fractal = max (retval.g, max (retval.r, retval.b));
   float bdWidth = Border * 0.1;
   float FthrRng = amt_body + Feather;
   float fracAmt = (fractal - amt_body) / Feather;

   if (fractal <= FthrRng) {
      if (fractal > (amt_body - bdWidth)) { retval = lerp (Bgd, retval, fracAmt); }
      else retval = Bgd;

      if (fractal > (amt_body + bdWidth)) { retval = lerp (retval, Fgd, fracAmt); }
   }
   else retval = Fgd;

   return lerp (lerp (Fgd, retval, amt_in), Bgd, amt_out);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Fractal_Dx
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = FracOut;"; > ExecuteShader (ps_fractal)
   pass P_2 ExecuteShader (ps_main)
}

