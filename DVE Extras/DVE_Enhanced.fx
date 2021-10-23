// @Maintainer jwrl
// @Released 2021-10-23
// @Author jwrl
// @Created 2021-09-10
// @see https://www.lwks.com/media/kunena/attachments/6375/DVE_Enhanced_640.png

/**
 This is a 2D DVE for the 21st century.  It performs in almost the same way as the
 Lightworks version does, with some major differences.  The most obvious change is
 the nonlinear scaling.  This makes the adjustment of size reduction easier and
 more precise.  Instead of the size reduction occupying the bottom 10% of the
 scaling faders in this effect it occupies the bottom third.  The maximum scale
 factor gives the same enlargement as the 10x setting in the Lightworks' original.

 Next, some antialiasing is applied to the image as it is scaled.  This gives a
 more natural image softening as the image is enlarged, rather than the jagged edges
 that can normally appear.  It also smooths the image during reduction.  It can of
 course be disabled if necessary.  Note that it isn't designed to remove aliasing
 already present in your video, only to reduce any aliasing contributed by the DVE.

 Another difference is in the way that cropping is handled.  In this version the
 crop order is laid out differently to the Lightworks effect.  Instead of left, top,
 right, bottom it's now left, right, top, bottom.  A further difference is in the
 way that they function.  The right and top crops operate from -100% to 0%, to give
 them a more natural feel.  The default for all crops is still 0%.

 There is also a difference in the way that the drop shadow is produced.  Instead
 of it being derived from the cropped edges of the frame as it is in the Lightworks
 2D DVE the cropped foreground alpha channel is used.  This means that the drop
 shadow will only appear where it should and not just at the edge of frame, as it
 does with the Lightworks effect.

 Next, as part of the resolution independence support two further changes have
 been made when compared to the Lightworks effect.  You may have noticed that if
 you apply the LW DVE over images with differing aspect ratios that the foreground
 can change position unpredicatbly.  The situation is even much worse with rotated
 footage, where changing position vertically moves the image horizontally and vice
 versa.  This effect corrects those issues.  Additionally it's also now possible
 to optionally crop the foreground to the boundaries of the background.  This can
 be extremely useful if you need to maintain DVE overlays inside portrait and
 letterboxed backgrounds, for example.

 Finally, Z-axis rotation has been added.  Because I don't have access to the
 widgets that Lightworks uses for rotation I have had to use faders to set that.
 It is at best a workaround, and has the unfortunate side effect that complete
 revolutions can't be set as integer values.  If you need that degree of accuracy
 you must type in the number of revolutions that you need manually.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DVE_Enhanced.fx
//
// Version history:
//
// Modified jwrl 2021-10-23.
// Added Z-axis rotation to the DVE.
//
// Rebuilt jwrl 2021-09-10.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "2D DVE (enhanced)";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "An enhanced 2D DVE for the 21st century with Z-axis rotation.";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define BadPos(P, p1, p2) (P < max (0.0, p1)) || (P > min (1.0, 1.0 - p2))
#define CropXY(XY, L, R, T, B)  (BadPos (XY.x, L, -R) || BadPos (XY.y, -T, B))

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

// Definitions used by this shader

#define SCALE_POWER  2.0            // These two give a scale range from 0 to
#define SCALE_RANGE  3.16227766     // 10x (the same as Lightworks does)
#define SHADOW_MAX 0.1

#define OUTER_LOOP   8
#define INNER_LOOP   4
#define DIVIDE       65
#define RADIUS       0.0005
#define ANGLE        0.3927

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Degrees
<
   string Group = "Rotation";
   string Description = "Degrees";
   float MinVal = -360.0;
   float MaxVal = 360.0;
> = 0.0;

float Revolutions
<
   string Group = "Rotation";
   string Description = "Revolutions";
   float MinVal = -20.0;
   float MaxVal = 20.0;
> = 0.0;

float Xpos
<
   string Group = "Position";
   string Description = "X";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float Ypos
<
   string Group = "Position";
   string Description = "Y";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

bool Antialias
<
   string Group = "Square law scaling";
   string Description = "Antialiasing";
> = true;

float MasterScale
<
   string Group = "Square law scaling";
   string Description = "Master";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = SCALE_RANGE;
> = 1.0;

float XScale
<
   string Group = "Square law scaling";
   string Description = "X";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = SCALE_RANGE;
> = 1.0;

float YScale
<
   string Group = "Square law scaling";
   string Description = "Y";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = SCALE_RANGE;
> = 1.0;

float CropL
<
   string Description = "Left";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropR
<
   string Description = "Right";
   string Group = "Crop";
   string Flags = "DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 0.0;
> = 0.0;

float CropT
<
   string Description = "Top";
   string Group = "Crop";
   string Flags = "DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 0.0;
> = 0.0;

float CropB
<
   string Description = "Bottom";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float ShadowTransparency
<
   string Description = "Transparency";
   string Group = "Shadow";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float ShadowX
<
   string Description = "X Offset";
   string Group = "Shadow";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ShadowY
<
   string Description = "Y Offset";
   string Group = "Shadow";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

bool CropToBgd
<
   string Description = "Crop to background";
> = false;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   // First we recover the raw (scale) and square law (XYscale) scale factors.
   // We then adjust the foreground size and position addresses and put them
   // in xy1.  Finally, calculate the drop shadow offset and put that in xy2.

   float2 scale = MasterScale * float2 (XScale, YScale);
   float2 XYscale = pow (max (0.0001.xx, scale), SCALE_POWER);
   float2 xy1 = uv3 - 0.5.xx;

   xy1.x *= _OutputAspectRatio;

   // Now we perform the rotation of the foreground coordinates

   float c, s, angle = radians (Revolutions * 360.0 + Degrees);
   
   sincos (-angle, s, c);

   float2 xy2 = float2 ((xy1.x * c - xy1.y * s), (xy1.x * s + xy1.y * c)); 

   xy2.x /= _OutputAspectRatio;
   xy2 += 0.5.xx;
   xy1 = ((xy2 - float2 (Xpos, 1.0 - Ypos)) / XYscale) + 0.5.xx;
   xy2 = xy1 - (float2 (ShadowX, ShadowY * _OutputAspectRatio) * SHADOW_MAX);

   // Recover foreground and background images and the drop shadow alpha

   float4 Fgnd = GetPixel (s_Foreground, xy1);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float shadow = Overflow (xy2) ? 0.0 : tex2D (s_Foreground, xy2).a;

   // Check whether we need to do any antialiasing at all

   if (Antialias && any (scale != 1.0)) {

      float2 xy, xy0;

      angle = 0.0;

      // Adjust the antialias blur scale factor so that it's 0 at 1x scaling and limited
      // to 1.0 maximum.  If it's less than 1x scaling the max blur radius is very small.
      // Finally the scale is squared and corrected for aspect ratio and preset radius.

      scale.x = scale.x < 1.0 ? (1.0 - max (0.0, scale.x)) / 3.0 : pow (scale.x - 1.0, 2.0);
      scale.y = scale.y < 1.0 ? (1.0 - max (0.0, scale.y)) / 3.0 : pow (scale.y - 1.0, 2.0);
      scale   = float2 (1.0, _OutputAspectRatio) * scale * RADIUS;

      // The antialias is a sixteen by 22.5 degrees rotary blur at four samples deep.
      // The outer loop achieves sixteen steps in 8 passes by using both positive and
      // negative offsets.

      for (int i = 0; i < OUTER_LOOP; i++) {
         sincos (angle, xy.x, xy.y);
         xy *= scale;
         xy0 = xy;

         for (int j = 0; j < INNER_LOOP; j++) {
            Fgnd += GetPixel (s_Foreground, xy1 + xy);
            Fgnd += GetPixel (s_Foreground, xy1 - xy);
            shadow += GetPixel (s_Foreground, xy2 + xy).a;
            shadow += GetPixel (s_Foreground, xy2 - xy).a;
            xy += xy0;
         }

         angle += ANGLE;
      }

      Fgnd = Overflow (xy1) ? EMPTY : Fgnd / DIVIDE;
      shadow = Overflow (xy2) ? 0.0 : shadow / DIVIDE;
   }

   // Now we apply the crop AFTER any antialias to both foreground and shadow

   if (CropXY (xy1, CropL, CropR, CropT, CropB)) Fgnd = EMPTY;
   if (CropXY (xy2, CropL, CropR, CropT, CropB)) shadow = 0.0;

   Fgnd.rgb *= Fgnd.a;                    // Blank the foreground if alpha is zero
   shadow *= 1.0 - ShadowTransparency;    // Adjust the drop shadow alpha data
   Fgnd.a = lerp (shadow, 1.0, Fgnd.a);   // Combine foreground and drop shadow

   // Return the foreground, drop shadow and background composite

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DVE_Enhanced
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 ExecuteShader (ps_main)
}

