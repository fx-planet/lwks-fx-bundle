// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// User effect Cx_Squeeze.fx
// Created by jwrl 25 August 2017.
// @Author jwrl
// @Created "25 August 2017"
//
// This mimics Editshare's squeeze effect, customised to
// suit its use with three or four-layer keying operations
// and similar composite effects.  The mechanism used is an
// adaption of the Editshare original.
//
// V2 is unused, and is provided to help automatic routing.
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
   string Description = "Composite squeeze";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture V1;
texture V2;
texture V3;

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

sampler V2sampler = sampler_state
{
   Texture   = <V2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

bool Swapped
<
   string Description = "Make V3 and not V1 the outgoing image";
> = false;

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Squeeze right,Squeeze left,Squeeze up,Squeeze down";
> = 0;

float Amount
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define EMPTY    (0.0).xxxx

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

float4 squeeze_right (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = float2 ((uv.x - Amount) / (1.0 - Amount), uv.y);
   float2 xy2 = float2 (uv.x / Amount, uv.y);

   if (Swapped) {
      if (uv.x > Amount) return fn_illegal (xy1) ? EMPTY : tex2D (V3sampler, xy1);
      return fn_illegal (xy2) ? EMPTY : tex2D (V1sampler, xy2);
   }

   if (uv.x > Amount) return fn_illegal (xy1) ? EMPTY : tex2D (V1sampler, xy1);

   return fn_illegal (xy2) ? EMPTY : tex2D (V3sampler, xy2);
}

float4 squeeze_left (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;

   float2 xy1 = float2 ((uv.x - negAmt) / Amount, uv.y);
   float2 xy2 = float2 (uv.x / negAmt, uv.y);

   if (Swapped) {
      if (uv.x > negAmt) return fn_illegal (xy1) ? EMPTY : tex2D (V1sampler, xy1);
      return fn_illegal (xy2) ? EMPTY : tex2D (V3sampler, xy2);
   }

   if (uv.x > negAmt) return fn_illegal (xy1) ? EMPTY : tex2D (V3sampler, xy1);

   return fn_illegal (xy2) ? EMPTY : tex2D (V1sampler, xy2);
}

float4 squeeze_up (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;

   float2 xy1 = float2 (uv.x, (uv.y - negAmt) / Amount);
   float2 xy2 = float2 (uv.x, uv.y / negAmt);

   if (Swapped) {
      if (uv.y > negAmt) return fn_illegal (xy1) ? EMPTY : tex2D (V1sampler, xy1);
      return fn_illegal (xy2) ? EMPTY : tex2D (V3sampler, xy2);
   }

   if (uv.y > negAmt) return fn_illegal (xy1) ? EMPTY : tex2D (V3sampler, xy1);

   return fn_illegal (xy2) ? EMPTY : tex2D (V1sampler, xy2);
}

float4 squeeze_down (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = float2 (uv.x, (uv.y - Amount) / (1.0 - Amount));
   float2 xy2 = float2 (uv.x, uv.y / Amount);

   if (Swapped) {
      if (uv.y > Amount) return fn_illegal (xy1) ? EMPTY : tex2D (V3sampler, xy1);
      return fn_illegal (xy2) ? EMPTY : tex2D (V1sampler, xy2);
   }

   if (uv.y > Amount) return fn_illegal (xy1) ? EMPTY : tex2D (V1sampler, xy1);

   return fn_illegal (xy2) ? EMPTY : tex2D (V3sampler, xy2);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique squeezeRight
{
   pass P_1
   { PixelShader = compile PROFILE squeeze_right (); }
}

technique squeezeLeft
{
   pass P_1
   { PixelShader = compile PROFILE squeeze_left (); }
}

technique squeezeUp
{
   pass P_1
   { PixelShader = compile PROFILE squeeze_up (); }
}

technique squeezeDown
{
   pass P_1
   { PixelShader = compile PROFILE squeeze_down (); }
}

