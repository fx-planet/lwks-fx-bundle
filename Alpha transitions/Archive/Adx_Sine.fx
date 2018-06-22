// @Maintainer jwrl
// @Released 2018-05-28
// @Author jwrl
// @Created 2017-10-30
// @see https://www.lwks.com/media/kunena/attachments/6375/Adx_Sine_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Adx_Sine.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Adx_Sine.fx
//
// This is an alpha dissolve/wipe that uses sine distortion to perform a left-right or
// right-left transition between the alpha components.  Phase can be offset by 180 degrees.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 28 May 2018 jwrl.
// Fixed bug with alpha boost parameters.  Only Boost_O would ever have done anything.
// Simplified mode switching to a maximum of two passes at the expense of passing the
// samplers required to the shaders.  This also reduced the number of samplers required
// from seven to four.
// Corrected an implicit cast of float2 to float in ps_main_out(), which broke the
// outgoing and dissolve transitions in Linux and Mac.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha sine mix";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture In_1;
texture In_2;
texture In_3;

texture In_4 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler In1Sampler = sampler_state
{
   Texture = <In_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In2Sampler = sampler_state
{
   Texture = <In_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In3Sampler = sampler_state { Texture = <In_3>; };
sampler In4Sampler = sampler_state { Texture = <In_4>; };

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

int Direction
<
   string Description = "Direction";
   string Enum = "Left to right,Right to left"; 
> = 0;

int Mode
<
   string Group = "Ripples";
   string Description = "Distortion";
   string Enum = "Upwards,Downwards"; 
> = 0;

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
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Spread
<
   string Group = "Ripples";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
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

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

#define EMPTY    (0.0).xxxx

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

float4 ps_main_in (float2 uv : TEXCOORD1, uniform sampler FgSampler, uniform sampler BgSampler) : COLOR
{
   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = Amount * (1.0 + range);
   float minVis = maxVis - range;

   float x = (Direction == 0) ? uv.x : 1.0 - uv.x;

   float amount = (x <= minVis) ? 1.0
                : (x >= maxVis) ? 0.0 : (maxVis - x) / range;

   float ripples = max (0.0, RIPPLES * (x - minVis));
   float spread  = ripples * Spread * SCALE;
   float offset  = sin (pow (max (0.0, Ripples), 5.0) * ripples) * spread;

   float2 xy = (Mode == 0) ? float2 (uv.x, uv.y + offset) : float2 (uv.x, uv.y - offset);

   float4 Fgd = fn_illegal (xy) ? EMPTY : tex2D (FgSampler, xy);
   float4 Bgd = tex2D (BgSampler, uv);

   if (Boost_On) Fgd.a = pow (Fgd.a, 1.0 / max (1.0, Boost_I + 1.0));

   return lerp (Bgd, Fgd, Fgd.a * amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1, uniform sampler FgSampler, uniform sampler BgSampler) : COLOR
{
   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (1.0 - Amount) * (1.0 + range);
   float minVis = maxVis - range;

   float x = (Direction == 0) ? 1.0 - uv.x : uv.x;

   float amount = (x <= minVis) ? 1.0
                : (x >= maxVis) ? 0.0 : (maxVis - x) / range;

   float ripples = max (0.0, RIPPLES * (x - minVis));
   float spread  = ripples * Spread * SCALE;
   float offset  = sin (pow (max (0.0, Ripples), 5.0) * ripples) * spread;

   float2 xy = (Mode == 0) ? float2 (uv.x, uv.y + offset) : float2 (uv.x, uv.y - offset);

   float4 Fgd = fn_illegal (xy) ? EMPTY : tex2D (FgSampler, xy);
   float4 Bgd = tex2D (BgSampler, uv);

   if (Boost_On) Fgd.a = pow (Fgd.a, 1.0 / max (1.0, Boost_O + 1.0));

   return lerp (Bgd, Fgd, Fgd.a * amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WarpDissIn
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_in (In1Sampler, In2Sampler); }
}

technique WarpDissOut
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_out (In1Sampler, In2Sampler); }
}

technique WarpDissFX1_FX2
{
   pass P_1
   < string Script = "RenderColorTarget0 = In_4;"; >
   { PixelShader = compile PROFILE ps_main_out (In1Sampler, In3Sampler); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_in (In2Sampler, In4Sampler); }
}

technique WarpDissFX2_FX1
{
   pass P_1
   < string Script = "RenderColorTarget0 = In_4;"; >
   { PixelShader = compile PROFILE ps_main_out (In2Sampler, In3Sampler); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_in (In1Sampler, In4Sampler); }
}
