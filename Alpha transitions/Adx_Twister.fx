// @Maintainer jwrl
// @Released 2018-04-06
// @Author jwrl
// @Created 2017-11-05
// @see https://www.lwks.com/media/kunena/attachments/6375/Adx_Twister_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Adx_Twister.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Adx_Twister.fx
//
// This is a dissolve/wipe that uses sine & cos distortions to perform a rippling twist
// to establish or remove an alpha image.  The range of possible effect variations
// obtainable with differing combinations of settings is almost inifinite.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha twister";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp_1;
texture Inp_2;
texture Inp_3;

texture In_1 : RenderColorTarget;
texture In_2 : RenderColorTarget;

texture Bgd : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler In1Sampler = sampler_state
{
   Texture = <Inp_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In2Sampler = sampler_state
{
   Texture = <Inp_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In3Sampler = sampler_state
{
   Texture   = <Inp_3>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FgdSampler = sampler_state
{
   Texture   = <In_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg2Sampler = sampler_state
{
   Texture   = <In_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Bgd>;
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

bool Show_Out_Axis
<
   string Group = "Twists";
   string Description = "Show outgoing twist axis";
> = false;

float Out_Axis
<
   string Group = "Twists";
   string Description = "Out axis";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

bool Show_In_Axis
<
   string Group = "Twists";
   string Description = "Show incoming twist axis";
> = false;

float In_Axis
<
   string Group = "Twists";
   string Description = "In axis";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

int SetTechnique
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Transition";
   string Enum = "Wipe in,Wipe out,Wipe FX1 > FX2,Wipe FX2 > FX1";
> = 0;

bool Boost_On
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Enable alpha boost";
> = false;

float Boost_O
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Boost outgoing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Boost_I
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Boost incoming";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputHeight;

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

#define EMPTY    (0.0).xxxx

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_inp_1 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In1Sampler, uv);
}

float4 ps_inp_2 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In2Sampler, uv);
}

float4 ps_inp_3 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In3Sampler, uv);
}

float4 ps_fg_2 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (Fg2Sampler, uv);
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   int  Mode = (int) fmod (TransProfile, 2);                            // If TransProfile is odd it's mode B

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;                 // Calculate softness range of the effect
   float maxVis = (Mode == TransProfile) ? uv.x : 1.0 - uv.x;           // If mode and profile match it's left > right

   maxVis = Amount * (1.0 + range) - maxVis;                            // Set up the maximum visibility

   float amount = saturate (maxVis / range);                            // Calculate the visibility
   float T_Axis = uv.y - In_Axis;                                       // Calculate the normalised twist axis

   float ripples = max (0.0, RIPPLES * (range - maxVis));               // Correct the ripples of the final effect
   float spread  = ripples * Spread * SCALE;                            // Correct the spread
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;             // Calculate the modulation factor
   float offset  = sin (modultn) * spread;                              // Calculate the vertical offset from the modulation and spread
   float twists  = cos (modultn * Twists * 4.0);                        // Calculate the twists using cos () instead of sin ()

   float2 xy = float2 (uv.x, In_Axis + (T_Axis / twists) - offset);     // Foreground X is uv.x, foreground Y is modulated uv.y

   xy.y += offset * float (Mode * 2);                                   // If the transition profile is positive correct Y

   float4 Fgd = fn_illegal (xy) ? EMPTY : tex2D (FgdSampler, xy);       // This version of the foreground has the modulation applied

   if (Boost_On) Fgd.a = pow (Fgd.a, 1.0 / max (1.0, Boost_I + 1.0));   // Apply the appropriate boost factor

   float4 Bgd = lerp (tex2D (BgdSampler, uv), Fgd, Fgd.a * amount);     // Produce the final composite blend

   if (!Show_In_Axis) { return Bgd; }                                   // Get out if we don't want to see the axis

   // To help with line-up this section produces a two-pixel wide line
   // from the twist axis.  That is then added to the output, and the
   // result is folded if it exceeds peak white.  This ensures that
   // the line will remain visible regardless of the video content.

   float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

   Fgd.rgb = Bgd.rgb + AxisLine.xxx;
   Bgd.rgb = min (1.0.xxx, Fgd.rgb) - max (0.0.xxx, Fgd.rgb - 1.0.xxx);

   return Bgd;
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   int  Mode = (int) fmod (TransProfile, 2);

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (Mode == TransProfile) ? 1.0 - uv.x : uv.x;           // Here the sense of the x position is opposite to above

   maxVis = (1.0 - Amount) * (1.0 + range) - maxVis;                    // The sense of the Amount parameter also has to change

   float amount = saturate (maxVis / range);
   float T_Axis = uv.y - Out_Axis;

   float ripples = max (0.0, RIPPLES * (range - maxVis));
   float spread  = ripples * Spread * SCALE;
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;
   float offset  = sin (modultn) * spread;
   float twists  = cos (modultn * Twists * 4.0);

   float2 xy = float2 (uv.x, Out_Axis + (T_Axis / twists) - offset);

   xy.y += offset * float (Mode * 2);

   float4 Fgd = fn_illegal (xy) ? EMPTY : tex2D (FgdSampler, xy);

   if (Boost_On) Fgd.a = pow (Fgd.a, 1.0 / max (1.0, Boost_O + 1.0));

   float4 Bgd = lerp (tex2D (BgdSampler, uv), Fgd, Fgd.a * amount);

   if (!Show_Out_Axis) { return Bgd; }

   // This section is different to the above to ensure that when both
   // coincide over white titles they will still be visible.  It also
   // uses folding, but uses subtraction rather than addition.  It has
   // been tested empirically and appears to be reliable.

   float AxisLine = max (0.0, 1.0 - (abs (T_Axis) * _OutputHeight * 0.25));

   Fgd.rgb = Bgd.rgb - AxisLine.xxx;
   Bgd.rgb = max (0.0.xxx, Fgd.rgb) - min (0.0.xxx, Fgd.rgb);

   return Bgd;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique AdxTwisterIn
{
   pass P_1
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique AdxTwisterOut
{
   pass P_1
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique AdxTwisterFX1_FX2
{
   pass P_1
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_3 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_main_out (); }

   pass P_4
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_5
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_fg_2 (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique AdxTwisterFX2_FX1
{
   pass P_1
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_3 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_main_out (); }

   pass P_4
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_5
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_fg_2 (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main_in (); }
}
