// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2017-08-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Cx_Push_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Cx_push.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Cx_Push.fx
//
// This mimics Editshare's push effect, but is customised to suit use with three or
// four-layer keying operations and similar composite effects.  The mechanism used is
// an adaption of the Editshare original.  V2 is unused, and is provided to help
// automatic routing.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Composite push";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture V1;
texture V2;
texture V3;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

float4 push_right (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = float2 (uv.x - Amount, uv.y);
   float2 xy2 = float2 (uv.x - Amount + 1.0, uv.y);

   if (Swapped) {
      if (uv.x > Amount) return fn_illegal (xy1) ? EMPTY : tex2D (V3sampler, xy1);
      return fn_illegal (xy2) ? EMPTY : tex2D (V1sampler, xy2);
   }

   if (uv.x > Amount) return fn_illegal (xy1) ? EMPTY : tex2D (V1sampler, xy1);

   return fn_illegal (xy2) ? EMPTY : tex2D (V3sampler, xy2);
}

float4 push_left (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;

   float2 xy1 = float2 (uv.x - negAmt, uv.y);
   float2 xy2 = float2 (uv.x + Amount, uv.y);

   if (Swapped) {
      if (uv.x > negAmt) return fn_illegal (xy1) ? EMPTY : tex2D (V1sampler, xy1);
      return fn_illegal (xy2) ? EMPTY : tex2D (V3sampler, xy2);
   }

   if (uv.x > negAmt) return fn_illegal (xy1) ? EMPTY : tex2D (V3sampler, xy1);

   return fn_illegal (xy2) ? EMPTY : tex2D (V1sampler, xy2);
}

float4 push_up (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;

   float2 xy1 = float2 (uv.x, uv.y - negAmt);
   float2 xy2 = float2 (uv.x, uv.y + Amount);

   if (Swapped) {
      if (uv.y > negAmt) return fn_illegal (xy1) ? EMPTY : tex2D (V1sampler, xy1);
      return fn_illegal (xy2) ? EMPTY : tex2D (V3sampler, xy2);
   }

   if (uv.y > negAmt) return fn_illegal (xy1) ? EMPTY : tex2D (V3sampler, xy1);

   return fn_illegal (xy2) ? EMPTY : tex2D (V1sampler, xy2);
}

float4 push_down (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = float2 (uv.x, uv.y - Amount);
   float2 xy2 = float2 (uv.x, uv.y - Amount + 1.0);

   if (Swapped) {
      if (uv.y > Amount) return fn_illegal (xy1) ? EMPTY : tex2D (V3sampler, xy1);
      return fn_illegal (xy2) ? EMPTY : tex2D (V1sampler, xy2);
   }

   if (uv.y > Amount) return fn_illegal (xy1) ? EMPTY : tex2D (V1sampler, xy1);

   return fn_illegal (xy2) ? EMPTY : tex2D (V3sampler, xy2);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

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
