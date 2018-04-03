// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Dx_Blurs.fx
//
// Written by LW user jwrl October 2015
// @Author jwrl
// @Created "October 2015"
//
// This effect performs a transition between two sources,
// During the process it also applies a directional blur,
// the angle and strength of which can be independently set
// for both the incoming and outgoing vision sources.
//
// This version of May 6 2016 has a changed blur engine and
// offsets the incoming blur by 180 degrees so that the
// incoming and outgoing blurs are perceived to match
// direction.  A setting to tie both incoming and outgoing
// blurs together has also been added.
//
// Update August 4 2017 by jwrl.
// All samplers fully defined to avoid differences in their
// default states between Windows and Linux/Mac compilers.
//
// Update August 10 2017 by jwrl - renamed from BlurDissolve.fx
// for consistency across the dissolve range.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Blur dissolve";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture FgBlur : RenderColorTarget;
texture BgBlur : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state
{ 
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FbSampler = sampler_state
{ 
   Texture   = <FgBlur>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BbSampler = sampler_state
{ 
   Texture   = <BgBlur>;
   AddressU  = Mirror;
   AddressV  = Mirror;
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

float Spread
<
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float o_Angle
<
   string Group = "Outgoing blur";
   string Description = "Angle";
   float MinVal = -180.00;
   float MaxVal = 180.0;
> = 0.0;

float o_Strength
<
   string Group = "Outgoing blur";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int SetTechnique
<
   string Group = "Incoming blur";
   string Description = "Settings";
   string Enum = "Use outgoing settings,Use settings below";
> = 0;

float i_Angle
<
   string Group = "Incoming blur";
   string Description = "Angle";
   float MinVal = -180.00;
   float MaxVal = 180.0;
> = 0.0;

float i_Strength
<
   string Group = "Incoming blur";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define SAMPLES   60

#define SAMPSCALE 61

#define STRENGTH  0.01

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_blur (float2 uv : TEXCOORD1, uniform sampler bSamp, uniform float bStrn, uniform float bAng, uniform int bOffs) : COLOR
{
   if (bStrn == 0.0) return tex2D (bSamp, uv);

   float2 blurOffset, xy = uv;
   float4 retval = 0.0;

   sincos (radians (bAng + (bOffs * 180)), blurOffset.y, blurOffset.x);
   blurOffset *= (bStrn * abs (bOffs - Amount) * STRENGTH);

   for (int i = 0; i < SAMPLES; i++) {
      retval += tex2D (bSamp, xy);
      xy += blurOffset;
      }
    
   retval /= SAMPSCALE;

   return saturate (retval);
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 outBlur = tex2D (FbSampler, xy);
   float4 in_Blur = tex2D (BbSampler, xy);

   float Mix = saturate (((Amount - 0.5) * ((Spread * 3) + 1.5)) + 0.5);

   return lerp (outBlur, in_Blur, Mix);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique blurDiss_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = FgBlur;"; >
   { PixelShader = compile PROFILE ps_blur (FgSampler, o_Strength, o_Angle, 0); }

   pass P_2
   < string Script = "RenderColorTarget0 = BgBlur;"; >
   { PixelShader = compile PROFILE ps_blur (BgSampler, o_Strength, o_Angle, 1); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique blurDiss_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = FgBlur;"; >
   { PixelShader = compile PROFILE ps_blur (FgSampler, o_Strength, o_Angle, 0); }

   pass P_2
   < string Script = "RenderColorTarget0 = BgBlur;"; >
   { PixelShader = compile PROFILE ps_blur (BgSampler, i_Strength, i_Angle, 1); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

