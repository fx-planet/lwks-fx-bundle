// @Maintainer jwrl
// @Released 2021-01-01
// @Author jwrl
// @Created 2021-01-01
// @see https://www.lwks.com/media/kunena/attachments/6375/DVE_Enhanced_640.png

/**
 This is a 2D DVE for the 21st century.  It performs in almost the same way as the
 Lightworks version does, with some major differences.  The most obvious change is
 the nonlinear scaling.  This makes the adjustment of size reduction easier and
 more precise.  Instead of the size reduction occupying the bottom 10% of the
 scaling faders in this effect it occupies the bottom half.  The maximum 200% scale
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

 The final difference is in the way that the drop shadow is produced.  Instead of it
 being derived from the cropped edges of the frame as it is in the Lightworks 2D DVE
 the cropped foreground alpha channel is used.  This means that the drop shadow will
 only appear where it should and not just at the edge of frame, as it does with the
 Lightworks effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DVE_Enhanced.fx
//
// Version history:
//
// Built jwrl 2021-01-01.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "2D DVE (enhanced)";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "An enhanced 2D DVE for the 21st century";
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

#define DeclareTarget( TARGET, TSAMPLE ) \
                                         \
   texture TARGET : RenderColorTarget;   \
                                         \
   sampler TSAMPLE = sampler_state       \
   {                                     \
      Texture   = <TARGET>;              \
      AddressU  = Mirror;                \
      AddressV  = Mirror;                \
      MinFilter = Linear;                \
      MagFilter = Linear;                \
      MipFilter = Linear;                \
   }

#define CompileShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define BadPos(P, p1, p2) (P < max (0.0, p1)) || (P > min (1.0, 1.0 - p2))
#define Bad_XY(XY, L, R, T, B)  (BadPos (XY.x, L, R) || BadPos (XY.y, T, B))

#define EMPTY 0.0.xxxx

#define GetPixel(SHADER,XY)  (any (XY < 0.0) || any (XY > 1.0) ? EMPTY : tex2D (SHADER, XY))

#define SCALE_RANGE  2.0            // Gives a scale range from 0 to roughly 10x
#define SCALE_POWER  3.32193
#define SHADOW_SCALE 0.2            // Carryover from the Lightworks original

#define OUTER_LOOP   8
#define INNER_LOOP   6
#define DIVIDE       97
#define RADIUS       0.0005
#define ANGLE        0.3926990817

float _OutputAspectRatio;

float _BgXScale = 1.0;
float _BgYScale = 1.0;
float _FgXScale = 1.0;
float _FgYScale = 1.0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DeclareTarget (dve, s_DVE);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CentreX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float CentreY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

bool Antialias
<
   string Group = "Nonlinear scaling";
   string Description = "Antialiasing";
> = true;

float MasterScale
<
   string Group = "Nonlinear scaling";
   string Description = "Master";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = SCALE_RANGE;
> = 1.0;

float XScale
<
   string Group = "Nonlinear scaling";
   string Description = "X";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = SCALE_RANGE;
> = 1.0;

float YScale
<
   string Group = "Nonlinear scaling";
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

float ShadowXOffset
<
   string Description = "X Offset";
   string Group = "Shadow";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ShadowYOffset
<
   string Description = "Y Offset";
   string Group = "Shadow";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_dve (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   // Standard position adjustment to cope with resolution independence

   float Xpos = (0.5 - CentreX) * _BgXScale / _FgXScale;
   float Ypos = (CentreY - 0.5) * _BgYScale / _FgYScale;

   // Now calculate the square law scale factors and correct for res. independence

   float scaleX = pow (max (0.0001, MasterScale * XScale), SCALE_POWER) / _FgXScale;
   float scaleY = pow (max (0.0001, MasterScale * YScale), SCALE_POWER) / _FgYScale;

   // Adjust the foreground size and position addresses

   float2 xy1 = uv1 + float2 (Xpos, Ypos);

   xy1.x = ((xy1.x - 0.5) / scaleX) + 0.5;
   xy1.y = ((xy1.y - 0.5) / scaleY) + 0.5;

   // Calculate the drop shadow offset

   float2 xy2 = xy1 - (float2 (ShadowXOffset, ShadowYOffset * _OutputAspectRatio) * SHADOW_SCALE);

   // Recover foreground image, ensuring edges are cropped

   float4 Fgnd = Bad_XY (xy1, CropL, -CropR, -CropT, CropB) ? EMPTY : tex2D (s_Foreground, xy1);

   // Blank the foreground if its alpha is zero

   Fgnd.rgb *= Fgnd.a;

   // Recover the drop shadow alpha data

   float alpha = Bad_XY (xy2, CropL, -CropR, -CropT, CropB) ? 0.0 : tex2D (s_Foreground, xy2).a;

   alpha *= 1.0 - ShadowTransparency;

   // Combine the foreground with its drop shadow

   Fgnd.a = lerp (alpha, 1.0, Fgnd.a);

   // Return the foreground and drop shadow composite

   return Fgnd;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   // First get the already processed DVE and the background

   float4 Fgnd = tex2D (s_DVE, uv3);
   float4 Bgnd = GetPixel (s_Background, uv2);

   if (Antialias) {

      // Recover the linear scale factor to use for antialiassing

      float scale = max (0.0001, MasterScale * max (XScale, YScale));

      scale = scale < 1.0 ? (1.0 - scale) / 6.0 : scale - 1.0;
      scale = saturate (scale * scale);

      // The antialias is a rotary blur at 22.5 degrees by twelve samples

      if (scale > 0.0) {
         float2 xy, radius = float2 (1.0, _OutputAspectRatio) * scale * RADIUS;

         for (int i = 0; i < OUTER_LOOP; i++) {

            sincos ((i * ANGLE), xy.x, xy.y);
            xy *= radius;

            for (int j = 0; j < INNER_LOOP; j++) {
               Fgnd += tex2D (s_DVE, uv3 + xy);
               Fgnd += tex2D (s_DVE, uv3 - xy);
               xy   += xy;
            }
         }

         Fgnd /= DIVIDE;
      }
   }

   // Return the foreground, drop shadow and background composite

   return lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DVE_Enhanced
{
   pass P_1 < string Script = "RenderColorTarget0 = dve;"; > CompileShader (ps_dve)
   pass P_2 CompileShader (ps_main)
}
