// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2021-08-01

/**
 This is a wipe that uses a trig distortion to perform a single simple twist to transition
 between two images, either horizontally or vertically.  It does not have any of the bells
 and whistles such as adjustable blending and softness.  If you need that have a look at
 Twister_Dx.fx instead.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TwistTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Twist transition", "Mix", "Special Fx transitions", "Twists one image to another vertically or horizontally", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Transition profile", kNoGroup, 0, "Left > right|Right > left|Top > bottom|Bottom > top"); 

DeclareFloatParam (Spread, "Twist width", kNoGroup, kNoFlags, 0.1, 0.0, 1.0);

DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI 3.1415926536

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Twistit_LR

DeclarePass (Fg_LR)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_LR)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Twistit_LR)
{
   float twist = (9.0 * Spread) + 3.0;
   float pos_n = ((1.0 - Amount) / twist) - Amount;

   twist *= pos_n + uv3.x;
   twist  = cos (saturate (twist) * PI);

   float2 xy = float2 (uv3.x, ((uv3.y - 0.5) / twist) + 0.5);

   float4 retval = twist > 0.0 ? ReadPixel (Bg_LR, xy) : ReadPixel (Fg_LR, float2 (xy.x, 1.0 - xy.y));

   return lerp (tex2D (Fg_LR, uv3), retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique Twistit_RL

DeclarePass (Fg_RL)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_RL)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Twistit_RL)
{
   float twist = (9.0 * Spread) + 3.0;
   float pos_n = ((1.0 - Amount) / twist) - Amount;

   twist *= pos_n - uv3.x + 1.0;
   twist  = cos (saturate (twist) * PI);

   float2 xy = float2 (uv3.x, ((uv3.y - 0.5) / twist) + 0.5);

   float4 retval = twist > 0.0 ? ReadPixel (Bg_RL, xy) : ReadPixel (Fg_RL, float2 (xy.x, 1.0 - xy.y));

   return lerp (tex2D (Fg_RL, uv3), retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique Twistit_TB

DeclarePass (Fg_TB)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_TB)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Twistit_TB)
{
   float twist = (9.0 * Spread) + 3.0;
   float pos_n = ((1.0 - Amount) / twist) - Amount;

   twist *= pos_n + uv3.y;
   twist  = cos (saturate (twist) * PI);

   float2 xy = float2 (((uv3.x - 0.5) / twist) + 0.5, uv3.y);

   float4 retval = twist > 0.0 ? ReadPixel (Bg_TB, xy) : ReadPixel (Fg_TB, float2 (1.0 - xy.x, xy.y));

   return lerp (tex2D (Fg_TB, uv3), retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique Twistit_BT

DeclarePass (Fg_BT)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_BT)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Twistit_BT)
{
   float twist = (9.0 * Spread) + 3.0;
   float pos_n = ((1.0 - Amount) / twist) - Amount;

   twist *= pos_n - uv3.y + 1.0;
   twist  = cos (saturate (twist) * PI);

   float2 xy = float2 (((uv3.x - 0.5) / twist) + 0.5, uv3.y);

   float4 retval = twist > 0.0 ? ReadPixel (Bg_BT, xy) : ReadPixel (Fg_BT, float2 (1.0 - xy.x, xy.y));

   return lerp (tex2D (Fg_BT, uv3), retval, tex2D (Mask, uv3).x);
}

