//--------------------------------------------------------------//
// User effect Cx_Split.fx
// Created by jwrl 25 August 2017.
//
// This is really the classic barn door effect, but since a
// wipe with that name already exists in Lightworks another
// name had to be found.  The Editshare wipe is just that, a
// wipe.  It doesn't move the separated image parts apart.
//
// This version has been customised to suit use with three
// or four-layer keying operations and other composite types
// of effects.  V2 is unused, and is just provided to help
// the automatic routing.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Composite split";
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
   string Enum = "Horizontal open,Horizontal close,Vertical open,Vertical close";
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

float4 open_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x - posAmt + 0.5, uv.y);
   float2 xy2 = float2 (uv.x - negAmt + 0.5, uv.y);

   if (Swapped) {
      return (uv.x > posAmt) ? tex2D (V3sampler, xy1) : (uv.x < negAmt) ? tex2D (V3sampler, xy2) : tex2D (V1sampler, uv);
   }

   return (uv.x > posAmt) ? tex2D (V1sampler, xy1) : (uv.x < negAmt) ? tex2D (V1sampler, xy2) : tex2D (V3sampler, uv);
}

float4 shut_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv.x - posAmt + 0.5, uv.y);
   float2 xy2 = float2 (uv.x - negAmt + 0.5, uv.y);

   if (Swapped) {
      return (uv.x > posAmt) ? tex2D (V1sampler, xy1) : (uv.x < negAmt) ? tex2D (V1sampler, xy2) : tex2D (V3sampler, uv);
   }

   return (uv.x > posAmt) ? tex2D (V3sampler, xy1) : (uv.x < negAmt) ? tex2D (V3sampler, xy2) : tex2D (V1sampler, uv);
}

float4 open_vert (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   if (Swapped) {
      return (uv.y > posAmt) ? tex2D (V3sampler, xy1) : (uv.y < negAmt) ? tex2D (V3sampler, xy2) : tex2D (V1sampler, uv);
   }

   return (uv.y > posAmt) ? tex2D (V1sampler, xy1) : (uv.y < negAmt) ? tex2D (V1sampler, xy2) : tex2D (V3sampler, uv);
}

float4 shut_vert (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   if (Swapped) {
      return (uv.y > posAmt) ? tex2D (V1sampler, xy1) : (uv.y < negAmt) ? tex2D (V1sampler, xy2) : tex2D (V3sampler, uv);
   }

   return (uv.y > posAmt) ? tex2D (V3sampler, xy1) : (uv.y < negAmt) ? tex2D (V3sampler, xy2) : tex2D (V1sampler, uv);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique openHoriz
{
   pass P_1
   { PixelShader = compile PROFILE open_horiz (); }
}

technique shutHoriz
{
   pass P_1
   { PixelShader = compile PROFILE shut_horiz (); }
}

technique openVert
{
   pass P_1
   { PixelShader = compile PROFILE open_vert (); }
}

technique shutVert
{
   pass P_1
   { PixelShader = compile PROFILE shut_vert (); }
}

