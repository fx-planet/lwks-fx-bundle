// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Triple_DVE.fx
//  Created by LW user jwrl 6 June 2017
// @Author jwrl
// @CreationDate "6 June 2017"
//
//  Bug fix to correct ambiguous declaration affecting Linux
//  and Mac versions only 17 July 2017.
//
// This is a combination of three DVEs each of which has been
// reverse engineered to match Editshare's 2D DVE parameters.
// DVE 1 adjusts the foreground and DVE 2 adjusts the back-
// ground.  The foreground can be cropped with rounded corners
// and given a bi-colour border.  Both the edges and borders
// can be feathered, and a drop shadow is also provided.
//
// DVE 3 takes the cropped, bordered output of DVE 1 as its
// input.  This means that you can scale the background and
// foreground independently, then adjust position and size of
// the cropped foreground.
//
// Because of the way that the DVEs are created and applied
// they have exactly the same quality impact on the final
// result as a single DVE would.  In effect it's three DVEs
// for the price of one.
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
   string Description = "Triple DVE";
   string Category    = "DVE";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Dve1;
texture Dve2;

texture Msk : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgdSampler = sampler_state
{
   Texture   = <Dve1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Dve2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler MskSampler = sampler_state
{
   Texture   = <Msk>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float CropT
<
   string Group = "Crop";
   string Description = "Top";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float CropB
<
   string Group = "Crop";
   string Description = "Bottom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropL
<
   string Group = "Crop";
   string Description = "Left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float CropR
<
   string Group = "Crop";
   string Description = "Right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropRadius
<
   string Group = "Crop";
   string Description = "Rounding";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float BorderFeather
<
   string Group = "Crop";
   string Description = "Edge softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float BorderWidth
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float4 BorderColour_1
<
   string Group = "Border";
   string Description = "Colour 1";
> = { 0.855, 0.855, 0.855, 1.0 };

float4 BorderColour_2
<
   string Group = "Border";
   string Description = "Colour 2";
> = { 0.345, 0.655, 0.926, 1.0 };

float Shadow
<
   string Group = "Shadow";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

float ShadowSoft
<
   string Group = "Shadow";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float ShadowX
<
   string Group = "Shadow";
   string Description = "X offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

float ShadowY
<
   string Group = "Shadow";
   string Description = "Y offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.5;

float PosX_1
<
   string Group = "DVE 1";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float PosY_1
<
   string Group = "DVE 1";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float Scale_1
<
   string Group = "DVE 1";
   string Description = "Master scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float ScaleX_1
<
   string Group = "DVE 1";
   string Description = "Scale X";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float ScaleY_1
<
   string Group = "DVE 1";
   string Description = "Scale Y";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float PosX_2
<
   string Group = "DVE 2";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float PosY_2
<
   string Group = "DVE 2";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float Scale_2
<
   string Group = "DVE 2";
   string Description = "Master scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float ScaleX_2
<
   string Group = "DVE 2";
   string Description = "Scale X";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float ScaleY_2
<
   string Group = "DVE 2";
   string Description = "Scale Y";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float PosX_3
<
   string Group = "DVE 3";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float PosY_3
<
   string Group = "DVE 3";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float Scale_3
<
   string Group = "DVE 3";
   string Description = "Master scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float ScaleX_3
<
   string Group = "DVE 3";
   string Description = "Scale X";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float ScaleY_3
<
   string Group = "DVE 3";
   string Description = "Scale Y";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float Amt_3
<
   string Group = "DVE 3";
   string Description = "DVE 3 opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define HALF_PI       1.5707963

#define BORDER_SCALE  0.05
#define FEATHER_SCALE 0.05
#define RADIUS_SCALE  0.1

#define SHADOW_DEPTH  0.1
#define SHADOW_SCALE  0.05
#define SHADOW_SOFT   0.025
#define TRANSPARENCY  0.75

#define MINIMUM       0.0001.xx

#define CENTRE        0.5.xx

#define BLACK         float2(0.0, 1.0).xxxy
#define EMPTY         0.0.xxxx

float _OutputAspectRatio;

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

float4 ps_crop (float2 uv : TEXCOORD0) : COLOR
{
   float adjust = max (0.0, max (CropL - CropR, CropT - CropB));

   float2 aspect  = float2 (1.0, _OutputAspectRatio);
   float2 center  = float2 (CropL + CropR, CropT + CropB) / 2.0;
   float2 border  = max (0.0, BorderWidth * BORDER_SCALE - adjust) * aspect;
   float2 feather = max (0.0, BorderFeather * FEATHER_SCALE - adjust) * aspect;
   float2 F_scale = max (MINIMUM, feather * 2.0);
   float2 S_scale = F_scale + max (0.0, ShadowSoft * SHADOW_SOFT - adjust) * aspect;
   float2 outer_0 = float2 (CropR, CropB) - center;
   float2 outer_1 = max (0.0.xx, outer_0 + feather);
   float2 outer_2 = outer_1 + border;

   float radius_0 = CropRadius * RADIUS_SCALE;
   float radius_1 = min (radius_0 + feather.x, min (outer_1.x, outer_1.y / _OutputAspectRatio));
   float radius_2 = radius_1 + border.x;

   float2 inner   = max (0.0.xx, outer_1 - radius_1 * aspect);
   float2 xy = abs (uv - center);
   float2 XY = (xy - inner) / aspect;

   float scope = distance (XY, 0.0.xx);

   float4 Mask = EMPTY;

   if (all (xy < outer_1)) {
      Mask.r = min (1.0, min ((outer_1.y - xy.y) / F_scale.y, (outer_1.x - xy.x) / F_scale.x));

      if (all (xy >= inner)) {
         if (scope < radius_1) { Mask.r = min (1.0, (radius_1 - scope) / F_scale.x); }
         else Mask.r = 0.0;
      }
   }

   outer_0  = max (0.0.xx, outer_0 + border);
   radius_0 = min (radius_0 + border.x, min (outer_0.x, outer_0.y / _OutputAspectRatio));
   border   = max (MINIMUM, max (border, feather));
   adjust   = sin (min (1.0, CropRadius * 20.0) * HALF_PI);

   if (all (xy < outer_2)) {
      Mask.g = min (1.0, min ((outer_0.y - xy.y) / border.y, (outer_0.x - xy.x) / border.x));
      Mask.b = min (1.0, min ((outer_2.y - xy.y) / F_scale.y, (outer_2.x - xy.x) / F_scale.x));
      Mask.a = min (1.0, min ((outer_2.y - xy.y) / S_scale.y, (outer_2.x - xy.x) / S_scale.x));

      if (all (xy >= inner)) {
         if (scope < radius_2) {
            Mask.g = lerp (Mask.g, min (1.0, (radius_0 - scope) / border.x), adjust);
            Mask.b = lerp (Mask.b, min (1.0, (radius_2 - scope) / F_scale.x), adjust);
            Mask.a = lerp (Mask.a, min (1.0, (radius_2 - scope) / S_scale.x), adjust);
         }
         else Mask.gba = lerp (Mask.gba, 0.0.xxx, adjust);
      }
   }

   adjust  = sin (min (1.0, BorderWidth * 10.0) * HALF_PI);
   Mask.gb = lerp (0.0.xx, Mask.gb, adjust);
   Mask.a  = lerp (0.0, Mask.a, Shadow * TRANSPARENCY);

   return Mask;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 posn_Factor = float2 (PosX_3, 1.0 - PosY_3);
   float2 scaleFactor = max (MINIMUM, Scale_3 * float2 (ScaleX_3, ScaleY_3));

   float2 uv1 = (uv - posn_Factor) / scaleFactor + CENTRE;
   float2 uv2 = (uv - float2 (PosX_2, 1.0 - PosY_2)) / max (MINIMUM, Scale_2 * float2 (ScaleX_2, ScaleY_2)) + CENTRE;
   float2 xy1 = (uv - posn_Factor) / scaleFactor + CENTRE;
   float2 xy2 = xy1 - (float2 (ShadowX / _OutputAspectRatio, -ShadowY) * scaleFactor * SHADOW_DEPTH);

   uv1 = (uv1 - float2 (PosX_1, 1.0 - PosY_1)) / max (MINIMUM, Scale_1 * float2 (ScaleX_1, ScaleY_1)) + CENTRE;

   float4 Fgnd = fn_illegal (uv1) ? BLACK : tex2D (FgdSampler, uv1);
   float4 Bgnd = fn_illegal (uv2) ? EMPTY : tex2D (BgdSampler, uv2);
   float4 Mask = fn_illegal (xy1) ? EMPTY : tex2D (MskSampler, xy1);

   float3 Bgd = fn_illegal (xy2) ? Bgnd.rgb : Bgnd.rgb * (1.0 - tex2D (MskSampler, xy2).w);

   float4 Colour = lerp (BorderColour_2, BorderColour_1, Mask.y);
   float4 retval = lerp (float4 (Bgd, Bgnd.a), Colour, Mask.z);

   retval = lerp (retval, Fgnd, Mask.x);

   return lerp (Bgnd, retval, Amt_3);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Triple_DVE
{
   pass P_1
   < string Script = "RenderColorTarget0 = Msk;"; >
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

