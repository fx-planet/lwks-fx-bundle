// @Maintainer jwrl
// @Released 2021-08-31
// @Author jwrl
// @Created 2021-08-31
// @see https://www.lwks.com/media/kunena/attachments/6375/BevelCrop_640.png

/**
 This is a crop tool that provides a bevelled border.  The lighting of the bevel can be
 adjusted in intensity, and the lighting angle can be changed.  Fill lighting is also
 included to soften the shaded areas of the bevel.  A hard-edged drop shadow is provided
 which simply shades the background by an adjustable amount.

 X-Y positioning of the border and its contents has been included, but since this is not
 intended as a comprehensive DVE replacement that's as far as it goes.  There isn't any
 scaling or rotation provided, nor is there intended to be.  It's complex enough for the
 user as it is!!!

 NOTE:  Any alpha information in the foreground is discarded by this effect.  It would
 be hard to maintain in a way that would make sense for all possible needs in any case.
 This means that wherever the foreground and bevelled border appears will be completely
 opaque.  The background alpha is preserved, even in areas covered by the drop shadow.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BevelCrop.fx
//
// This is all original work, so it probably could be done more efficiently than I have.
//
// Version history:
//
// Rewrite 2021-08-31 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bevel edged crop";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "This provides a simple crop with a bevelled border and a hard-edged drop shadow";
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

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define SCALE  0.1
#define SHADOW 0.025

float _OutputAspectRatio;

float _BgXScale = 1.0;
float _BgYScale = 1.0;
float _FgXScale = 1.0;
float _FgYScale = 1.0;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);
DefineTarget (Bvl, s_Bevel);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CropLeft
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float CropTop
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropRight
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropBottom
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float PosX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Border
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.125;

float4 Colour
<
   string Group = "Border";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.375, 0.625, 0.75, 0.0 };

float Bevel
<
   string Group = "Bevel";
   string Description = "Percent width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.6;

float Intensity
<
   string Group = "Bevel";
   string Description = "Light level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Angle
<
   string Group = "Bevel";
   string Description = "Light angle";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 80.0;

float Fill
<
   string Group = "Bevel";
   string Description = "Fill light";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

float4 Light
<
   string Group = "Bevel";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.375, 0.625, 0.75, 0.0 };

float Strength
<
   string Group = "Drop shadow";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float ShadowX
<
   string Group = "Drop shadow";
   string Description = "Offset";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.25;

float ShadowY
<
   string Group = "Drop shadow";
   string Description = "Offset";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.25;

float4 Shade
<
   string Group = "Drop shadow";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.125, 0.2, 0.25, 0.0 };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 fn_rgb2hsv (float3 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float3 hsv  = float3 (0.0.xx, Cmax);

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float3 fn_hsv2rgb (float3 hsv)
{
   if (hsv.y == 0.0) return hsv.zzz;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (2.0 - hsv.y) - q;

   if (i == 0) return float3 (hsv.z, r, p);
   if (i == 1) return float3 (q, hsv.z, p);
   if (i == 2) return float3 (p, hsv.z, r);
   if (i == 3) return float3 (p, q, hsv.z);
   if (i == 4) return float3 (r, p, hsv.z);

   return float3 (hsv.z, p, q);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These two passes map the foreground and background clips to TEXCOORD3, so that
// variations in clip geometry and rotation are handled without too much effort.

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_crop (float2 uv : TEXCOORD3) : COLOR
{
   // Get the foreground but discard the alpha channel

   float3 retval = GetPixel (s_Foreground, uv).rgb;

   // Now set up the crop boundaries, the size of the border and the percentage of the
   // border that we want to be bevelled.

   float2 cropSize   = float2 (abs (CropRight - CropLeft), abs (CropTop - CropBottom));
   float2 cropBevel  = float2 (1.0, _OutputAspectRatio) * Border * SCALE;
   float2 cropBorder = cropBevel + cropSize;

   // Because we have to be able to obtain an accurate 45 degree angle at the corners
   // of the bevel we need to set up several xy coordinates.  For ease of later maths
   // we swing uv around the mid point of the crop and put that value in xy1.  This
   // will be used later to determine which quadrant we're working in.

   float2 xy1 = uv - float2 (CropRight + CropLeft, 2.0 - CropTop - CropBottom) / 2.0;

   // The absolute value of xy1 is doubled and stored in xy2.  This can be used to
   // simply produce the crop later.

   float2 xy2 = abs (xy1) * 2.0;

   // The crop size is then subtracted from xy2 and clamped between 0 and 1.  By
   // doing this we can reliably calculate the corner angle without resorting to
   // trig functions or distance calculations.

   float2 xy3 = saturate (xy2 - cropSize);

   // The X coordinate of xy3 must be corrected for the project aspect ratio, and
   // the bevel thickness is also calculated as a percentage of the border width.

   xy3.x *= _OutputAspectRatio;
   cropBevel = cropBorder - (cropBevel * saturate (Bevel));

   // The border colour is now applied.  If either component of xy2 exceeds the crop
   // size we replace the foreground already in retval with our border colour.

   if ((xy2.x > cropSize.x) || (xy2.y > cropSize.y)) retval = Colour.rgb;

   // The next section calculates the bevel colours.  If either component of xy2 exceeds
   // the bevel bounary we replace the border colour in retval with our derived bevel
   // colour.  This is reasonably complex to do because we need to be able to change the
   // angle of the bevel lighting in a way logical for the user.

   if ((xy2.x > cropBevel.x) || (xy2.y > cropBevel.y)) {

      // Bevel lighting is calculated in the hue/sat/value domain.  While it would be
      // possible to do this in the RGB domain, this way is much simpler.

      float3 hsv = fn_rgb2hsv (Light.rgb);

      // The lit values of the X and Y planes are calulated trigonometrically.  This
      // is the only time that a trig function is required in this routine.  Instead of
      // swinging between +1 and -1 we need to swing from 0 to 1 for later level maths.

      float2 lit;

      sincos (radians (Angle), lit.x, lit.y);
      lit = (lit + 1.0.xx) * 0.5;

      // This sets up the amount by which to adjust the bevel colour.  If xy1.y is less
      // than zero we're in the lower half of the border, and the bevel amt can be set
      // to lit.y.  Otherwise it is inverted by subtracting lit.y from 1.0.

      float amt = (xy1.y > 0.0) ? 1.0 - lit.y : lit.y;

      // The values of amt at either side are now set up.  If we're on the left hand
      // side and if xy3.x is greater than xy3.y we invert the value in lit.x and put
      // it in amt.  Because of the earlier clamping and scaling of xy3 this gives us
      // an accurate 45 degree angle at top and bottom right the corners.  A similar
      // test is used to replace amt with the value in lit.x on the right hand side.

      if (xy1.x > 0.0) {
         if (xy3.x > xy3.y) {
            amt = lit.x;
         }
      }
      else if (xy3.x > xy3.y) amt = 1.0 - lit.x;

      // The border amount is now scaled by the intensity and the fill is added.  Both
      // are adjusted before application so that the parameter settings make sense to
      // the user.  The result is then inverted, clamped and scaled by 6.

      amt = (amt * Intensity * 2.0) + Fill;
      amt = saturate (1.5 - amt) * 6.0;

      // This test converts amt to swing between 0.25 and 1.0 for positive exposure
      // values, and between 1.0 and 4.0 for negative exposure.

      amt = (amt >= 3.0) ? amt - 2.0 : 1.0 / (4.0 - amt);

      // The border value is halved and amt is used as the power to raise it to.  It's
      // then checked for overflow to see if we also need to desaturate then doubled.
      // Both value and saturation are clamped between 0 and 1 after adjustment.

      hsv.z = pow (hsv.z * 0.5, amt);

      if (hsv.z > 0.5) hsv.y = saturate (hsv.y - hsv.z + 0.5);

      hsv.z = saturate (hsv.z * 2.0);

      // The complete border including the bevel is converted and placed in retval.

      retval = fn_hsv2rgb (hsv);
   }

   // We now turn the alpha channel on and blank anything outside the border boundary.

   return ((xy2.x > cropBorder.x) || (xy2.y > cropBorder.y)) ? EMPTY : float4 (retval, 1.0);
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   // First we calculate the position offset and put it in xy1.  A further offset is
   // calculated for the drop shadow and placed in xy2.  While it would be possible
   // to use the bevel angle parameter to do this, it's much simpler this way.

   float2 xy1 = uv + float2 (0.5 - PosX, PosY - 0.5);
   float2 xy2 = xy1 - float2 (ShadowX, -ShadowY * _OutputAspectRatio) * SHADOW;

   // The alpha channel in s_Bevel is obtained using xy2 and scaled by the drop shadow
   // strength parameter.  This is used later to create our drop shadow.

   float alpha = GetPixel (s_Bevel, xy2).a * Strength;

   // The foreground is recovered from s_Bevel using the position corrected xy1 and the
   // background is recovered using the uv coordinates directly.

   float4 Fgnd = GetPixel (s_Bevel, xy1);
   float4 Bgnd = GetPixel (s_Background, uv);

   // The background now has the drop shadow applied.  Note that opacity is preserved.

   Bgnd.rgb = lerp (Bgnd.rgb, Shade.rgb, alpha);

   // Finally the bevelled cropped image is overlaid and the whole thing is returned.

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique BevelCrop
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = Bvl;"; > ExecuteShader (ps_crop)
   pass P_2 ExecuteShader (ps_main)
}

