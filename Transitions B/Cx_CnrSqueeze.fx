// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2017-08-26
// @see https://www.lwks.com/media/kunena/attachments/6375/Cx_CnrSqueeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Cx_CnrSqueeze.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Cx_CnrSqueeze.fx
//
// This is similar to the corner squeeze effect, customised to suit its use with three
// or four-layer keying operations and similar composite effects.  V2 is unused, and is
// provided to help automatic routing.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Composite corner squeeze";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture V1;
texture V2;
texture V3;

texture Hc : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool Swapped
<
   string Description = "Make V3 and not V1 the outgoing image";
> = false;

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Squeeze to corners,Expand from corners";
> = 0;

float Amount
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY (0.0).xxxx

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 sqz_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 ((uv.x - Amount) / negAmt, uv.y);
   float2 xy2 = float2 (uv.x / negAmt, uv.y);

   negAmt /= 2.0;

   if (Swapped) {
      return (uv.x > posAmt) ? tex2D (V3sampler, xy1) : (uv.x < negAmt) ? tex2D (V3sampler, xy2) : EMPTY;
   }

   return (uv.x > posAmt) ? tex2D (V1sampler, xy1) : (uv.x < negAmt) ? tex2D (V1sampler, xy2) : EMPTY;
}

float4 sqz_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv.x, (uv.y - Amount) / negAmt);
   float2 xy2 = float2 (uv.x, uv.y / negAmt);

   negAmt /= 2.0;

   float4 retval = (uv.y > posAmt) ? tex2D (HcSampler, xy1) : (uv.y < negAmt) ? tex2D (HcSampler, xy2) : EMPTY;

   if (Swapped) {
      return lerp (tex2D (V1sampler, uv), retval, retval.a);
   }

   return lerp (tex2D (V3sampler, uv), retval, retval.a);
}

float4 exp_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 ((uv.x + Amount - 1.0) / Amount, uv.y);
   float2 xy2 = float2 (uv.x / Amount, uv.y);

   if (Swapped) {
      return (uv.x > posAmt) ? tex2D (V1sampler, xy1) : (uv.x < negAmt) ? tex2D (V1sampler, xy2) : EMPTY;
   }

   return (uv.x > posAmt) ? tex2D (V3sampler, xy1) : (uv.x < negAmt) ? tex2D (V3sampler, xy2) : EMPTY;
}

float4 exp_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv.x, (uv.y + Amount - 1.0) / Amount);
   float2 xy2 = float2 (uv.x, uv.y / Amount);

   float4 retval = (uv.y > posAmt) ? tex2D (HcSampler, xy1) : (uv.y < negAmt) ? tex2D (HcSampler, xy2) : EMPTY;

   if (!Swapped) {
      return lerp (tex2D (V1sampler, uv), retval, retval.a);
   }

   return lerp (tex2D (V3sampler, uv), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique squeezeCorner
{
   pass P_1
   < string Script = "RenderColorTarget0 = Hc;"; >
   { PixelShader = compile PROFILE sqz_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE sqz_main (); }
}

technique expandCorner
{
   pass P_1
   < string Script = "RenderColorTarget0 = Hc;"; >
   { PixelShader = compile PROFILE exp_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE exp_main (); }
}
