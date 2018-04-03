// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// User effect Cx_Corners.fx
// Created by jwrl 25 August 2017.
// @Author jwrl
// @Created "25 August 2017"
//
// This is a four-way split which moves the image to or from
// the corners of the frame.  It has been adapted for use
// with three or four-layer keying operations and other
// composite types of effects.
//
// V2 is unused, and is provided to help automatic routing.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Composite corner split";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture V1;
texture V2;
texture V3;

texture Hc : RenderColorTarget;

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

sampler HcSampler = sampler_state
{
   Texture   = <Hc>;
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
   string Enum = "Corner open,Corner close";
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

#define EMPTY (0.0).xxxx

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 open_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x - posAmt + 0.5, uv.y);
   float2 xy2 = float2 (uv.x - negAmt + 0.5, uv.y);

   if (Swapped) {
      return (uv.x > posAmt) ? tex2D (V3sampler, xy1) : (uv.x < negAmt) ? tex2D (V3sampler, xy2) : EMPTY;
   }

   return (uv.x > posAmt) ? tex2D (V1sampler, xy1) : (uv.x < negAmt) ? tex2D (V1sampler, xy2) : EMPTY;
}

float4 open_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   float4 retval = (uv.y > posAmt) ? tex2D (HcSampler, xy1) : (uv.y < negAmt) ? tex2D (HcSampler, xy2) : EMPTY;

   if (Swapped) {
      return lerp (tex2D (V1sampler, uv), retval, retval.a);
   }

   return lerp (tex2D (V3sampler, uv), retval, retval.a);
}

float4 shut_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv.x - posAmt + 0.5, uv.y);
   float2 xy2 = float2 (uv.x - negAmt + 0.5, uv.y);

   if (Swapped) {
      return (uv.x > posAmt) ? tex2D (V1sampler, xy1) : (uv.x < negAmt) ? tex2D (V1sampler, xy2) : EMPTY;
   }

   return (uv.x > posAmt) ? tex2D (V3sampler, xy1) : (uv.x < negAmt) ? tex2D (V3sampler, xy2) : EMPTY;
}

float4 shut_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   float4 retval = (uv.y > posAmt) ? tex2D (HcSampler, xy1) : (uv.y < negAmt) ? tex2D (HcSampler, xy2) : EMPTY;

   if (Swapped) {
      return lerp (tex2D (V3sampler, uv), retval, retval.a);
   }

   return lerp (tex2D (V1sampler, uv), retval, retval.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique openCorner
{
   pass P_1
   < string Script = "RenderColorTarget0 = Hc;"; >
   { PixelShader = compile PROFILE open_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE open_main (); }
}


technique shutCorner
{
   pass P_1
   < string Script = "RenderColorTarget0 = Hc;"; >
   { PixelShader = compile PROFILE shut_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE shut_main (); }
}

