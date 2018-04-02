// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Cx_Twister.fx
// Created by LW user jwrl 8 September 2017.
// @Author jwrl
// @CreationDate "8 September 2017"
//
// This is a dissolve/wipe that uses sine & cos distortions to
// perform a rippling twist to transition between two images.
// It's the triple layer version of Wx_Twister.fx.  This does
// not preserve the alpha channels, so if you need that use
// Adx_Twister.fx.
//
// Version 14.5 update 24 March 2018 by jwrl.
//
// Legality checking has been added to correct for a bug
// in XY sampler addressing on Linux and OS-X platforms.
// This effect should now function correctly when used with
// all current and previous Lightworks versions.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Composite twister";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture V1;
texture V2;
texture V3;

texture Fg : RenderColorTarget;
texture Bg : RenderColorTarget;

texture Halfway : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler V1sampler = sampler_state
{
   Texture   = <V1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler V3sampler = sampler_state
{
   Texture   = <V3>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler V2sampler = sampler_state { Texture = <V2>; };

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int SetTechnique
<
   string Description = "Make V3 and not V1 the outgoing image";
   string Enum = "No,Yes";
> = 0;

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

float4 ps_set_V1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (V1sampler, uv);

   // We cannot assume that V1 has the composite of V1 and V2, so we now blend them.

   retval.a = max (retval.a, tex2D (V2sampler, uv).a);

   return retval;
}

float4 ps_set_V3 (float2 uv : TEXCOORD1) : COLOR
{
   // We require V3 to be the composite of V3 and V4.  If it isn't this effect will fail.

   return tex2D (V3sampler, uv);
}

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

technique CxTwister_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Fg;"; >
   { PixelShader = compile PROFILE ps_set_V1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_set_V3 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Halfway;"; > 
   { PixelShader = compile PROFILE ps_main_in (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique CxTwister_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_set_V1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Fg;"; >
   { PixelShader = compile PROFILE ps_set_V3 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Halfway;"; > 
   { PixelShader = compile PROFILE ps_main_in (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_out (); }
}

