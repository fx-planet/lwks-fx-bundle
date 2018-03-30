//--------------------------------------------------------------//
// User effect Cx_Push.fx
// Created by jwrl 25 August 2017.
//
// This mimics Editshare's push effect, but is customised
// to suit use with three or four-layer keying operations
// and similar composite effects.  The mechanism used is
// an adaption of the Editshare original.
//
// V2 is unused, and is provided to help automatic routing.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Composite push";
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
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler V3sampler = sampler_state
{
   Texture   = <V3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler V2sampler = sampler_state { Texture = <V2>; };

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
   string Enum = "Push right,Push left,Push up,Push down";
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

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 push_right (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = float2 (uv.x - Amount, uv.y);
   float2 xy2 = float2 (uv.x - Amount + 1.0, uv.y);

   if (Swapped) { return (uv.x > Amount) ? tex2D (V3sampler, xy1) : tex2D (V1sampler, xy2); }

   return (uv.x > Amount) ? tex2D (V1sampler, xy1) : tex2D (V3sampler, xy2);
}

float4 push_left (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;

   float2 xy1 = float2 (uv.x - negAmt, uv.y);
   float2 xy2 = float2 (uv.x + Amount, uv.y);

   if (Swapped) { return (uv.x > negAmt) ? tex2D (V1sampler, xy1) : tex2D (V3sampler, xy2); }

   return (uv.x > negAmt) ? tex2D (V3sampler, xy1) : tex2D (V1sampler, xy2);
}

float4 push_up (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;

   float2 xy1 = float2 (uv.x, uv.y - negAmt);
   float2 xy2 = float2 (uv.x, uv.y + Amount);

   if (Swapped) { return (uv.y > negAmt) ? tex2D (V1sampler, xy1) : tex2D (V3sampler, xy2); }

   return (uv.y > negAmt) ? tex2D (V3sampler, xy1) : tex2D (V1sampler, xy2);
}

float4 push_down (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = float2 (uv.x, uv.y - Amount);
   float2 xy2 = float2 (uv.x, uv.y - Amount + 1.0);

   if (Swapped) { return (uv.y > Amount) ? tex2D (V3sampler, xy1) : tex2D (V1sampler, xy2); }

   return (uv.y > Amount) ? tex2D (V1sampler, xy1) : tex2D (V3sampler, xy2);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique pushRight
{
   pass P_1
   { PixelShader = compile PROFILE push_right (); }
}

technique pushLeft
{
   pass P_1
   { PixelShader = compile PROFILE push_left (); }
}

technique pushUp
{
   pass P_1
   { PixelShader = compile PROFILE push_up (); }
}

technique pushDown
{
   pass P_1
   { PixelShader = compile PROFILE push_down (); }
}

