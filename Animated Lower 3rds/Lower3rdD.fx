// @Maintainer jwrl
// @Released 2022-12-28
// @Author jwrl
// @Created 2022-12-28

/**
 This effect pushes a text block on from the edge of frame to reveal the lower third text.
 The block has a coloured edge which can be adjusted in width, and which vanishes as the
 block reaches its final position.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rdD.fx
//
// Version history:
//
// Built 2022-12-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Lower third D", "Text", "Animated Lower 3rds", "Pushes a text block on from the edge of frame to reveal the lower third text", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (In_1, In_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Transition, "Transition", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Direction", kNoGroup, 0, "Bottom up|Top down|Left to right|Right to left");
DeclareIntParam (Masking, "Masking", kNoGroup, 0, "Show text and edge for setup|Mask controlled by transition");

DeclareIntParam (ArtAlpha, "Text type", "Text settings", 1, "Video/External image|Crawl/Roll/Title/Image key");

DeclareFloatParam (TxtPosX, "Position", "Text settings", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (TxtPosY, "Position", "Text settings", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareFloatParam (BlockLimit, "Limit of travel", "Block setting", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (BlockCrop_A, "Crop A", "Block setting", kNoFlags, 0.08, 0.0, 1.0);
DeclareFloatParam (BlockCrop_B, "Crop B", "Block setting", kNoFlags, 0.35, 0.0, 1.0);

DeclareColourParam (BlockColour, "Fill colour", "Block setting", kNoFlags, 1.0, 0.98, 0.9, 1.0);

DeclareFloatParam (EdgeWidth, "Width", "Edge setting", kNoFlags, 0.5, 0.0, 1.0);

DeclareColourParam (EdgeColour, "Colour", "Edge setting", kNoFlags, 0.73, 0.51, 0.84, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_ribbon (float2 uv)
{
   float limit = 1.0 - (BlockLimit * 0.32);
   float width = limit - (EdgeWidth * 0.125);

   if ((uv.x < BlockCrop_A) || (uv.x > BlockCrop_B) || (uv.y < width)) return kTransparentBlack;

   return uv.y < limit ? EdgeColour : BlockColour;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Bottom up

DeclarePass (Input_1_1)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Input_2_1)
{ return ReadPixel (In_2, uv2); }

DeclarePass (Ribbon_1)
{ return fn_ribbon (uv0); }

DeclareEntryPoint (Lower3rdD_BottomUp)
{
   float trans = 0.995 - sin (Transition * HALF_PI);
   float mask  = BlockLimit * 0.32;
   float range = ((EdgeWidth * 0.125) + mask) * trans;

   mask  = (Masking == 0) ? 0.0 : 1.0 - mask;

   float2 xy1 = float2 (uv3.x, uv3.y - range);
   float2 xy2 = uv3 - float2 (TxtPosX, range - TxtPosY);

   float4 L3rd = (uv3.y < mask) || IsOutOfBounds (xy1) ? kTransparentBlack : tex2D (Ribbon_1, xy1);
   float4 Fgnd = tex2D (Input_1_1, xy2);

   if (ArtAlpha == 1) {
      Fgnd.a = pow (Fgnd.a, 0.5);
      Fgnd.rgb *= Fgnd.a;
   }

   Fgnd = lerp (L3rd, Fgnd, Fgnd.a);

   return lerp (tex2D (Input_2_1, uv3), Fgnd, Fgnd.a * Opacity);
}


// Top down

DeclarePass (Input_1_2)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Input_2_2)
{ return ReadPixel (In_2, uv2); }

DeclarePass (Ribbon_2)
{ return fn_ribbon (uv0); }

DeclareEntryPoint (Lower3rdD_TopDown)
{
   float trans = 0.995 - sin (Transition * HALF_PI);
   float mask  = BlockLimit * 0.32;
   float range = ((EdgeWidth * 0.125) + mask) * trans;

   mask = (Masking == 0) ? 1.0 : mask - 0.001;

   float2 xy1 = float2 (uv3.x, 1.0 - uv3.y - range);
   float2 xy2 = uv3 + float2 (-TxtPosX, TxtPosY + range);

   float4 L3rd = (uv3.y > mask) || IsOutOfBounds (xy1) ? kTransparentBlack : tex2D (Ribbon_2, xy1);
   float4 Fgnd = tex2D (Input_1_2, xy2);

   if (ArtAlpha == 1) {
      Fgnd.a = pow (Fgnd.a, 0.5);
      Fgnd.rgb *= Fgnd.a;
   }

   Fgnd = lerp (L3rd, Fgnd, Fgnd.a);

   return lerp (tex2D (Input_2_2, uv3), Fgnd, Fgnd.a * Opacity);
}


// Left to right

DeclarePass (Input_1_3)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Input_2_3)
{ return ReadPixel (In_2, uv2); }

DeclarePass (Ribbon_3)
{ return fn_ribbon (uv0); }

DeclareEntryPoint (Lower3rdD_LeftRight)
{
   float trans = 0.995 - sin (Transition * HALF_PI);
   float mask  = BlockLimit * 0.32;
   float range = ((EdgeWidth * 0.125) + mask) * trans;

   mask = (Masking == 0) ? 1.0 : mask - 0.001;

   float2 xy1 = float2 (uv3.y, 1.0 - uv3.x - range);
   float2 xy2 = uv3 + float2 (range - TxtPosX, TxtPosY);

   float4 L3rd = (uv3.x > mask) || IsOutOfBounds (xy1) ? kTransparentBlack : tex2D (Ribbon_3, xy1);
   float4 Fgnd = (uv3.x > mask) || IsOutOfBounds (xy2) ? kTransparentBlack : tex2D (Input_1_3, xy2);

   if (ArtAlpha == 1) {
      Fgnd.a = pow (Fgnd.a, 0.5);
      Fgnd.rgb *= Fgnd.a;
   }

   Fgnd = lerp (L3rd, Fgnd, Fgnd.a);

   return lerp (tex2D (Input_2_3, uv3), Fgnd, Fgnd.a * Opacity);
}


// Right to left

DeclarePass (Input_1_4)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Input_2_4)
{ return ReadPixel (In_2, uv2); }

DeclarePass (Ribbon_4)
{ return fn_ribbon (uv0); }

DeclareEntryPoint (Lower3rdD_RightLeft)
{
   float trans = 0.995 - sin (Transition * HALF_PI);
   float mask  = BlockLimit * 0.32;
   float range = ((EdgeWidth * 0.125) + mask) * trans;

   mask  = (Masking == 0) ? 0.0 : 1.0 - mask;

   float2 xy1 = float2 (uv3.y, uv3.x - range);
   float2 xy2 = uv3 - float2 (TxtPosX + range, -TxtPosY);

   float4 L3rd = (uv3.x < mask) || IsOutOfBounds (xy1) ? kTransparentBlack : tex2D (Ribbon_4, xy1);
   float4 Fgnd = (uv3.x < mask) || IsOutOfBounds (xy2) ? kTransparentBlack : tex2D (Input_1_4, xy2);

   if (ArtAlpha == 1) {
      Fgnd.a = pow (Fgnd.a, 0.5);
      Fgnd.rgb *= Fgnd.a;
   }

   Fgnd = lerp (L3rd, Fgnd, Fgnd.a);

   return lerp (tex2D (Input_2_4, uv3), Fgnd, Fgnd.a * Opacity);
}

