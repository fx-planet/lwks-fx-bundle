// @Maintainer jwrl
// @Released 2021-07-28
// @Author jwrl
// @Created 2021-07-28
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_Twister_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_Twister.mp4

/**
 This is a dissolve/wipe that uses sine & cos distortions to perform a rippling twist to
 transition between two images.  This does not preserve the alpha channels, so if you need
 that use Twister_Ax.fx.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Twister_Dx.fx
//
// Version history:
//
// Rewrite 2021-07-28 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "The twister";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Performs a rippling twist to transition between two video images";
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

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

int TransProfile
<
   string Description = "Transition profile";
   string Enum = "Left > right,Right > left"; 
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

float Twist_Axis
<
   string Group = "Twists";
   string Description = "Twist axis";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_RawBg, uv); }

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float range  = max (0.0, Width * SOFTNESS) + OFFSET;                 // Calculate softness range of the effect
   float maxVis = (TransProfile == 0) ? uv.x : 1.0 - uv.x;
   float minVis = range + maxVis - (Amount * (1.0 + range));            // The sense of the Amount parameter also has to change

   maxVis = range - minVis;                                             // Set up the maximum visibility

   float amount = saturate (maxVis / range);                            // Calculate the visibility
   float twistAxis = 1.0 - Twist_Axis;                                  // Invert the twist axis setting
   float T_Axis = uv.y - twistAxis;                                     // Calculate the normalised twist axis

   float ripple_1 = max (0.0, RIPPLES * minVis);                        // Correct the ripples of the final effect
   float ripple_2 = max (0.0, RIPPLES * maxVis);
   float spread_1 = ripple_1 * Spread * SCALE;                          // Correct the spread
   float spread_2 = ripple_2 * Spread * SCALE;
   float modult_1 = pow (max (0.0, Ripples), 5.0) * ripple_1;           // Calculate the modulation factor
   float modult_2 = pow (max (0.0, Ripples), 5.0) * ripple_2;

   float offs_1 = sin (modult_1) * spread_1;                            // Calculate the vertical offset from the modulation and spread
   float offs_2 = sin (modult_2) * spread_2;
   float twst_1 = cos (modult_1 * Twists * 4.0);                        // Calculate the twists using cos () instead of sin ()
   float twst_2 = cos (modult_2 * Twists * 4.0);

   float2 xy1 = float2 (uv.x, twistAxis + (T_Axis / twst_1) - offs_1);  // Foreground X is uv.x, foreground Y is modulated uv.y
   float2 xy2 = float2 (uv.x, twistAxis + (T_Axis / twst_2) - offs_2);

   float4 Bgnd = GetPixel (s_Background, xy1);                          // This version of the background has the modulation applied
   float4 Fgnd = GetPixel (s_Foreground, xy2);                          // Get the second partial composite
   float4 retval = lerp (Fgnd, Bgnd, amount);                           // Dissolve between the halves

   if (Show_Axis) {

      // To help with line-up this section produces a two-pixel wide line from the twist axis.  It's added to the output, and the
      // result is folded if it exceeds peak white.  This ensures that the line will remain visible regardless of the video content.

      retval.rgb -= max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0).xxx;
      retval.rgb  = max (0.0.xxx, retval.rgb) - min (0.0.xxx, retval.rgb);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Twister_Dx
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_main)
}

