// @Maintainer jwrl
// @Released 2021-06-30
// @Author jwrl
// @Created 2021-06-30
// @see https://www.lwks.com/media/kunena/attachments/6375/2dDVEnlScale_ref.png
// @see https://www.lwks.com/media/kunena/attachments/6375/2dDVEnlScale_640.png

/**
 This is a 2D DVE that performs in the same way as the Lightworks version does,
 with three major differences.  The most obvious change is the square law scaling.
 This makes the adjustment of scaling much simpler, especially when it comes to
 size reduction.  Instead of the size reduction occupying the bottom 10% of the
 scaling faders in this effect it occupies the bottom third.

 The maximum scaling factor is a compromise, and allows enlargement to a little
 over the 10x maximum that the Lightworks original provides.  By combining the
 master scaling with the X and Y scale factors, a total of just under 105% size
 increase is possible, compared to the 100% of the Lightworks version.  This is
 unlikely to be much noticed in practice.

 The next difference is the way that cropping is handled.  In this version it
 will be noticed that the order is laid out differently to the Lightworks effect.
 First both horizontal crops are provided, then both vertical crops.  A further
 difference is the way that they function.  The right and top crops operate from
 -100% to 0%, to give them a more natural feel.  The default for all crops is 0%.

 The final difference relates to the way that the alpha channel is handled.  The
 most obvious difference will be apparent with drop shadow generation from a
 transparent foreground.  Instead of the drop shadow being derived from the
 cropped frame edges as it is in the Lightworks 2D DVE the cropped foreground
 alpha channel is used.  This means that the drop shadow will only appear where
 it should and not at the edge of frame, as it does with the Lightworks effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 2dDVEnlScale.fx
//
// Version history:
//
// Built jwrl 2021-06-30.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "2D DVE with nonlinear scaling";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "A 2D DVE that uses square law image scaling to give better size adjustment linearity";
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

#define CompileShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define BadPos(P, p1, p2) (P < max (0.0, p1)) || (P > min (1.0, 1.0 - p2))
#define Bad_XY(XY, L, R, T, B)  (BadPos (XY.x, L, R) || BadPos (XY.y, T, B))

#define EMPTY        0.0.xxxx                // Transparent black

#define GetPixel(SHADER,XY)  (any (XY < 0.0) || any (XY > 1.0) ? EMPTY : tex2D (SHADER, XY))

#define BLACK        float4(0.0.xxx, 1.0)    // Opaque black

#define SCALE_RANGE  3.2                     // Gives a scale range from 0 to roughly 10x
#define SCALE_POWER  2.0
#define SHADOW_SCALE 0.2                     // Carryover from the Lightworks original

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

float MasterScale
<
   string Description = "Master";
   string Group = "Square law scaling";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = SCALE_RANGE;
> = 1.0;

float XScale
<
   string Description = "X";
   string Group = "Square law scaling";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = SCALE_RANGE;
> = 1.0;

float YScale
<
   string Description = "Y";
   string Group = "Square law scaling";
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

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   // Standard position adjustment to cope with resolution independence

   float Xpos = (0.5 - CentreX) * _BgXScale / _FgXScale;
   float Ypos = (CentreY - 0.5) * _BgYScale / _FgYScale;

   // Now calculate the square law scale factors and correct for res. independence

   float Mscale = pow (max (0.001, MasterScale), SCALE_POWER);
   float scaleX = Mscale * pow (max (0.001, XScale), SCALE_POWER) / _FgXScale;
   float scaleY = Mscale * pow (max (0.001, YScale), SCALE_POWER) / _FgYScale;

   // Adjust the foreground size and position addresses

   float2 xy1 = uv1 + float2 (Xpos, Ypos);

   xy1.x = ((xy1.x - 0.5) / scaleX) + 0.5;
   xy1.y = ((xy1.y - 0.5) / scaleY) + 0.5;

   // Calculate the drop shadow offset

   float2 xy2 = xy1 - (float2 (ShadowXOffset, ShadowYOffset * _OutputAspectRatio) * SHADOW_SCALE);

   // Recover foreground and background images, ensuring edges are cropped

   float4 Fgnd = Bad_XY (xy1, CropL, -CropR, -CropT, CropB) ? EMPTY : tex2D (s_Foreground, xy1);
   float4 Bgnd = GetPixel (s_Background, uv2);

   // Blank the foreground if its alpha is zero

   Fgnd.rgb *= Fgnd.a;

   // Recover the drop shadow alpha data

   float alpha = Bad_XY (xy2, CropL, -CropR, -CropT, CropB) ? 0.0 : tex2D (s_Foreground, xy2).a;

   alpha *= 1.0 - ShadowTransparency;

   // Combine the foreground with its drop shadow

   Fgnd.a = lerp (alpha, 1.0, Fgnd.a);

   // Return the foreground, drop shadow and background composite

   return lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DVEnlScale { pass P_1 CompileShader (ps_main) }
