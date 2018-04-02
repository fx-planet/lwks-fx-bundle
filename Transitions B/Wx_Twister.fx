//--------------------------------------------------------------//
// Lightworks user effect Wx_Twister.fx
// Created by LW user jwrl 8 November 2017
// @Author: jwrl
// @CreationDate: "8 November 2017"
//
// This is a dissolve/wipe that uses sine & cos distortions to
// perform a rippling twist to transition between two images.
// This does not preserve the alpha channels, so if you need
// that use Adx_Twister.fx.
//
// Version 14.1 update 5 December 2017 by jwrl.
//
// Added LINUX and OSX test to allow support for changing
// "Clamp" to "ClampToEdge" on those platforms.  It will now
// function correctly when used with Lightworks versions 14.5
// and higher under Linux or OS-X and fixes a bug associated
// with using this effect with transitions on those platforms.
//
// The bug still exists when using older versions of Lightworks.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "The twister";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture Halfway : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef OSX
#define Clamp ClampToEdge
#endif

sampler FgdSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Border;
   AddressV  = Border;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Border;
   AddressV  = Border;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler HW_Sampler = sampler_state
{
   Texture   = <Halfway>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

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

float Twist_Axis
<
   string Group = "Twists";
   string Description = "Twist axis";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

#define BLACK    float2(0.0,1.0).xxxy
#define EMPTY    (0.0).xxxx

float _OutputHeight;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   int  Mode = (int) fmod (TransProfile, 2);                            // If TransProfile is odd it's mode B

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;                 // Calculate softness range of the effect
   float maxVis = (Mode == TransProfile) ? uv.x : 1.0 - uv.x;           // If mode and profile match it's left > right

   maxVis = Amount * (1.0 + range) - maxVis;                            // Set up the maximum visibility

   float amount = saturate (maxVis / range);                            // Calculate the visibility
   float T_Axis = uv.y - Twist_Axis;                                    // Calculate the normalised twist axis

   float ripples = max (0.0, RIPPLES * (range - maxVis));               // Correct the ripples of the final effect
   float spread  = ripples * Spread * SCALE;                            // Correct the spread
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;             // Calculate the modulation factor
   float offset  = sin (modultn) * spread;                              // Calculate the vertical offset from the modulation and spread
   float twists  = cos (modultn * Twists * 4.0);                        // Calculate the twists using cos () instead of sin ()

   float2 xy = float2 (uv.x, Twist_Axis + (T_Axis / twists) - offset);  // Foreground X is uv.x, foreground Y is modulated uv.y

   xy.y += offset * float (Mode * 2);                                   // If the transition profile is positive correct Y

   float4 retval = fn_illegal (xy) ? EMPTY : tex2D (BgdSampler, xy);    // This version of the foreground has the modulation applied

   return lerp (BLACK, retval, retval.a * amount);                      // Return the first partial composite blend
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   int  Mode = (int) fmod (TransProfile, 2);

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (Mode == TransProfile) ? 1.0 - uv.x : uv.x;           // Here the sense of the x position is opposite to above

   maxVis = (1.0 - Amount) * (1.0 + range) - maxVis;                    // The sense of the Amount parameter also has to change

   float amount = saturate (maxVis / range);
   float T_Axis = uv.y - Twist_Axis;

   float ripples = max (0.0, RIPPLES * (range - maxVis));
   float spread  = ripples * Spread * SCALE;
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;
   float offset  = sin (modultn) * spread;
   float twists  = cos (modultn * Twists * 4.0);

   float2 xy = float2 (uv.x, Twist_Axis + (T_Axis / twists) - offset);

   xy.y += offset * float (Mode * 2);

   float4 Fgd = fn_illegal (xy) ? EMPTY : tex2D (FgdSampler, xy);
   float4 retval = lerp (tex2D (HW_Sampler, uv), Fgd, Fgd.a * amount);

   if (!Show_Axis) { return retval; }

   // To help with line-up this section produces a two-pixel wide line
   // from the twist axis.  That is then added to the output, and the
   // result is folded if it exceeds peak white.  This ensures that
   // the line will remain visible regardless of the video content.

   float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

   Fgd.rgb = retval.rgb - AxisLine.xxx;
   retval.rgb = max (0.0.xxx, Fgd.rgb) - min (0.0.xxx, Fgd.rgb);

   return retval;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique WxTwister
{
   pass P_1
   < string Script = "RenderColorTarget0 = Halfway;"; > 
   { PixelShader = compile PROFILE ps_main_in (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_out (); }
}

