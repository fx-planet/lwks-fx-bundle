// @Maintainer jwrl
// @Released 2023-01-27
// @Author jwrl
// @Created 2023-01-27

/**
 This effect is designed to generate a key from the foreground video and use that key
 to superimpose the foreground over the background or fill the foreground key shape
 with a flat matte colour.  It has been designed with text supers in mind.  The key
 can be produced from a white on black image or inverted.  Alternatively the alpha
 channel can be used instead of the video to provide the key.  The same controls apply
 to the alpha channel in this mode as do to the video.

 A coloured border can also be generated from the key.  Border opacity, width and
 colour are all adjustable.  A drop shadow with the same range of adjustments can also
 be produced, and the position of that shadow can be adjusted.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LumakeyAndMatte.fx
//
// Version history:
//
// Built 2023-01-27 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Lumakey and matte", "Key", "Key Extras", "Generates a key from video, fills it with colour or other video and generates a border and/or drop shadow.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Key, V_1, V_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam (K_alpha, "Use key alpha channel", kNoGroup, false);
DeclareBoolParam (K_invert, "Invert key", kNoGroup, false);

DeclareFloatParam (K_clip, "Clip level", "Key", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (K_range, "Tolerance", "Key", kNoFlags, 0.5, 0.0, 1.0);
DeclareIntParam (K_fill, "Fill key with:", "Key", 2, "Key video|Video 1|Matte colour");
DeclareColourParam (K_matte, "Matte colour", "Key", kNoFlags, 1.0, 1.0, 1.0);

DeclareFloatParam (B_amount, "Opacity", "Border", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (B_width, "Width", "Border", kNoFlags, 0.05, 0.0, 1.0);
DeclareColourParam (B_colour, "Colour", "Border", kNoFlags, 0.0, 0.0, 0.0);

DeclareFloatParam (S_amount, "Opacity", "Shadow", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (S_feather, "Feather", "Shadow", kNoFlags, 0.33333333, 0.0, 1.0);
DeclareFloatParam (S_offset_X, "X offset", "Shadow", kNoFlags, 0.2, -1.0, 1.0);
DeclareFloatParam (S_offset_Y, "Y offset", "Shadow", kNoFlags, -0.2, -1.0, 1.0);
DeclareColourParam (S_colour, "Colour", "Shadow", kNoFlags, 0.0, 0.0, 0.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define BrdrPixel(SHADER,XY) (IsOutOfBounds(XY) ? BLACK : tex2D(SHADER, XY))

#define X_SCALE 0.005
#define OFFSET  0.04

#define INVSQR2 0.7071067812

float2 _rot_0 [] = { { 0.0, 1.0 }, { 0.2588190451, 0.9659258263 }, { 0.5, 0.8660254038 },
                     { 0.7071067812, 0.7071067812 }, { 0.8660254038, 0.5 },
                     { 0.9659258263, 0.2588190451 }, { 1.0, 0.0 } };

float2 _rot_1 [] = { { 0.1305261922, 0.9914448614 }, { 0.3826834324, 0.9238795325 },
                     { 0.6087614290, 0.7933533403 }, { 0.7933533403, 0.6087614290 },
                     { 0.9238795325, 0.3826834324 }, { 0.9914448614, 0.1305261922 } };

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (KeyFgd)
{
   float4 Fgnd   = ReadPixel (Key, uv1);
   float4 retval = (K_fill == 2) ? K_matte
                 : (K_fill == 1) ? BrdrPixel (V_1, uv2) : Fgnd;

   float2 half_pix = 0.5 / float2 (_OutputWidth, _OutputHeight);
   float2 quad_pix = half_pix * INVSQR2;

   Fgnd += tex2D (Key, uv1 + float2 (half_pix.x, 0.0));
   Fgnd += tex2D (Key, uv1 - float2 (half_pix.x, 0.0));
   Fgnd += tex2D (Key, uv1 + quad_pix);
   Fgnd += tex2D (Key, uv1 - quad_pix);
   half_pix.x = 0.0;
   quad_pix.x = -quad_pix.x;
   Fgnd += tex2D (Key, uv1 + half_pix);
   Fgnd += tex2D (Key, uv1 - half_pix);
   Fgnd += tex2D (Key, uv1 + quad_pix);
   Fgnd += tex2D (Key, uv1 - quad_pix);

   Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : Fgnd / 9.0;

   if (K_alpha) { retval.a = Fgnd.a; }
   else {
      float keyMin = max (0.0, K_clip - K_range);
      float keyMax = min (1.0, K_clip + K_range);

      retval.a = smoothstep (keyMin, keyMax, (Fgnd.r + Fgnd.g + Fgnd.b) / 3.0);
   }

   if (K_invert) retval.a = 1.0 - retval.a;

   return IsOutOfBounds (uv1) ? kTransparentBlack : retval;
}

DeclarePass (Border_A)
{
   float2 edge = float2 (1.0, _OutputAspectRatio) * B_width * X_SCALE;
   float2 offset;

   if (B_amount <= 0.0) return tex2D (KeyFgd, uv4);

   float alpha = tex2D (KeyFgd, uv4).a;

   for (int i = 0; i < 7; i++) {
      offset = edge * _rot_0 [i];

      alpha += tex2D (KeyFgd, uv4 + offset).a;
      alpha += tex2D (KeyFgd, uv4 - offset).a;

      offset.y = -offset.y;

      alpha += tex2D (KeyFgd, uv4 + offset).a;
      alpha += tex2D (KeyFgd, uv4 - offset).a;
   }

   return saturate (alpha).xxxx;
}

DeclarePass (Border_B)
{
   float2 edge = float2 (1.0, _OutputAspectRatio) * B_width * X_SCALE;
   float2 offset;

   if (B_amount <= 0.0) return tex2D (KeyFgd, uv4);

   float alpha = tex2D (Border_A, uv4).a;

   for (int i = 0; i < 6; i++) {
      offset = edge * _rot_1 [i];

      alpha += tex2D (Border_A, uv4 + offset).a;
      alpha += tex2D (Border_A, uv4 - offset).a;

      offset.y = -offset.y;

      alpha += tex2D (Border_A, uv4 + offset).a;
      alpha += tex2D (Border_A, uv4 - offset).a;
   }

   return saturate (alpha).xxxx;
}

DeclarePass (Border_C)
{
   float4 Fgnd = tex2D (KeyFgd, uv4);

   if (B_amount <= 0.0) return Fgnd;

   float3 xyz = float3 (1.0, 0.0, _OutputAspectRatio) / _OutputWidth;

   float2 xy = xyz.xz * INVSQR2;

   float alpha = tex2D (Border_B, uv4).a;

   alpha += tex2D (Border_B, uv4 + xyz.xy).a;
   alpha += tex2D (Border_B, uv4 - xyz.xy).a;
   alpha += tex2D (Border_B, uv4 + xyz.yz).a;
   alpha += tex2D (Border_B, uv4 - xyz.yz).a;

   alpha += tex2D (Border_B, uv4 + xy).a;
   alpha += tex2D (Border_B, uv4 - xy).a;

   xy.x = -xy.x;

   alpha += tex2D (Border_B, uv4 + xy).a;
   alpha += tex2D (Border_B, uv4 - xy).a;
   alpha /= 9.0;

   alpha = max (Fgnd.a, alpha * B_amount);
   Fgnd  = lerp (B_colour, Fgnd, Fgnd.a);

   return float4 (Fgnd.rgb, alpha);
}

DeclarePass (Shadow)
{
   float2 scale = float2 (1.0, _OutputAspectRatio) * S_feather * X_SCALE;
   float2 xy2, xy1 = uv4 - float2 (S_offset_X / _OutputAspectRatio, -S_offset_Y) * OFFSET;

   float alpha = tex2D (Border_C, xy1).a;

   if ((S_amount > 0.0) && (S_feather > 0.0)) {
      for (int i = 0; i < 7; i++) {
         xy2 = scale * _rot_0 [i];

         alpha += tex2D (Border_C, xy1 + xy2).a;
         alpha += tex2D (Border_C, xy1 - xy2).a;

         xy2.y = -xy2.y;

         alpha += tex2D (Border_C, xy1 + xy2).a;
         alpha += tex2D (Border_C, xy1 - xy2).a;
      }

   alpha /= 29.0;
   }

   return alpha.xxxx;
}

DeclareEntryPoint (LumakeyAndMatte)
{
   float4 retval = tex2D (Shadow, uv4);

   float2 xy, scale = float2 (1.0, _OutputAspectRatio) * S_feather * X_SCALE;

   float alpha = retval.a;

   if ((S_amount > 0.0) && (S_feather > 0.0)) {
      for (int i = 0; i < 6; i++) {
         xy = scale * _rot_1 [i];

         alpha += tex2D (Shadow, uv4 + xy).a;
         alpha += tex2D (Shadow, uv4 - xy).a;

         xy.y = -xy.y;

         alpha += tex2D (Shadow, uv4 + xy).a;
         alpha += tex2D (Shadow, uv4 - xy).a;
      }

   alpha /= 25.0;
   }

   alpha *= S_amount;

   retval = tex2D (Border_C, uv4);
   alpha  = max (alpha, retval.a);
   retval = lerp (S_colour, retval, retval.a);

   float4 Bgnd = (K_fill == 1) ? BrdrPixel (V_2, uv3) : BrdrPixel (V_1, uv2);

   retval = lerp (Bgnd, retval, alpha * Amount);

   return float4 (retval.rgb, Bgnd.a);
}

