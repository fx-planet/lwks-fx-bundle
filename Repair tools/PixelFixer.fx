// @Maintainer jwrl
// @Released 2021-10-07
// @Author khaver
// @Created 2013-02-14
// @see https://www.lwks.com/media/kunena/attachments/6375/PixelFixer_640.png

/**
 Pixel Fixer is designed to repair dead pixels.  Add a clip to be corrected to a sequence
 and add the Pixel Fixer effect to the clip.  It will show a magnified area of the frame
 with a green target pixel in the middle.  It defaults to a single pixel but you can select
 a pixel pattern of up to 4 pixels in a group.  The green pixels will change as you select
 the different patterns.

 Using the on-screen cross-hairs, move the magnified area to the dead pixels and use the X
 Adjust and Y Adjust to fine tune the target over the dead pixel(s).  Check the "Fix" box
 to hide the dead pixel(s), then un-check "Magnify".

 Note that this effect destroys resolution independence.  What leaves the effect is video
 the size and aspect ratio of the sequence that it's used in.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PixelFixer.fx
//
// Version history:
//
// Update 2021-10-07 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//
// Modified 26 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 2018-12-05 jwrl.
// Changed subcategory.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Cross platform compatibility check 29 July 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Bug fix 26 February 2017 by jwrl:
// Added workaround for the interlaced media height bug in Lightworks effects.
//
// This cross platform conversion by jwrl April 29 2016.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Pixel Fixer";
   string Category    = "Stylize";
   string SubCategory = "Repair tools";
   string Notes       = "Pixel Fixer repairs dead pixels based on adjacent pixel content";
   bool CanSize       = false;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

float _OutputAspectRatio;
float _OutputWidth;

float4 _red = float4 (0.0, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, InputSampler);
DefineTarget (Bars1, BarSampler1);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool Glass
<
   string Description = "Magnify";
> = true;

float mag
<
   string Description = "Magnification";
   float MinVal = 1.0;
   float MaxVal = 10.0;
> = 2.0;

bool Proc //Fix
<
   string Description = "Fix";
> = false;

int SetTechnique
<
   string Description = "Pixel Pattern";
   string Enum = "1,2H,2V,2DF,2DB,3A,3B,3C,3D,4";
> = 0;

float c1x
<
   string Description = "Pixel";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float c1y
<
   string Description = "Pixel";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float fineX
<
   string Description = "X Adjust";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float fineY
<
   string Description = "Y Adjust";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main_1 (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 pixels = tex2D (InputSampler, uv2);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y));
   float4 A3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y + pixY));
   float4 B2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY));

   pixels.a = 0.0;

   if (uv2.x >= pixA1l.x && uv2.x <= pixA1r.x && uv2.y <= pixA1l.y && uv2.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + A2 + B0 + B1 + B2) / 8.0 : _red;
      pixels.a = 1.0;
   }

   return Overflow (uv1) ? EMPTY : pixels;
}

float4 ps_main_2H (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 pixels = tex2D (InputSampler, uv2);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixA2l = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA2r = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 a3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y + pixY));
   float4 B2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));

   pixels.a = 0.0;

   if (uv2.x >= pixA1l.x && uv2.x <= pixA1r.x && uv2.y <= pixA1l.y && uv2.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + A0 + B0 + B1) / 5.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixA2l.x && uv2.x <= pixA2r.x && uv2.y <= pixA2l.y && uv2.y >= pixA2r.y) {
      pixels = (Proc) ? (a2 + a3 + A3 + B2 + B3) / 5.0 : _red;
      pixels.a = 1.0;
   }

   return Overflow (uv1) ? EMPTY : pixels;
}

float4 ps_main_2V (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 pixels = tex2D (InputSampler, uv2);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB1l = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB1r = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY));
   float4 b0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY + pixY));
   float4 b1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv2.x >= pixA1l.x && uv2.x <= pixA1r.x && uv2.y <= pixA1l.y && uv2.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + A2) / 5.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixB1l.x && uv2.x <= pixB1r.x && uv2.y <= pixB1l.y && uv2.y >= pixB1r.y) {
      pixels = (Proc) ? (B0 + B2 + b0 + b1 + b2) / 5.0 : _red;
      pixels.a = 1.0;
   }

   return Overflow (uv1) ? EMPTY : pixels;
}

float4 ps_main_2DF (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 pixels = tex2D (InputSampler, uv2);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA2l = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA2r = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB1l = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB1r = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 a3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y));
   float4 A3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY + pixY));
   float4 b1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv2.x >= pixA2l.x && uv2.x <= pixA2r.x && uv2.y <= pixA2l.y && uv2.y >= pixA2r.y) {
      pixels = (Proc) ? (a1 + a2 + a3 + A1 + A3 + B2 + B3) / 7.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixB1l.x && uv2.x <= pixB1r.x && uv2.y <= pixB1l.y && uv2.y >= pixB1r.y) {
      pixels = (Proc) ? (A0 + A1 + B0 + B2 + b0 + b1 + b2) / 7.0 : _red;
      pixels.a = 1.0;
   }

   return Overflow (uv1) ? EMPTY : pixels;
}

float4 ps_main_2DB (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 pixels = tex2D (InputSampler, uv2);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB2l = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB2r = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y));
   float4 A3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));
   float4 b3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv2.x >= pixA1l.x && uv2.x <= pixA1r.x && uv2.y <= pixA1l.y && uv2.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + A2 + B0 + B1) / 7.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixB2l.x && uv2.x <= pixB2r.x && uv2.y <= pixB2l.y && uv2.y >= pixB2r.y) {
      pixels = (Proc) ? (A2 + A3 + B1 + B3 + b1 + b2 + b3) / 7.0 : _red;
      pixels.a = 1.0;
   }

   return Overflow (uv1) ? EMPTY : pixels;
}

float4 ps_main_3A (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 pixels = tex2D (InputSampler, uv2);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixA2l = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA2r = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB2l = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB2r = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 a3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));
   float4 b3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv2.x >= pixA1l.x && uv2.x <= pixA1r.x && uv2.y <= pixA1l.y && uv2.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + B0 + B1) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixA2l.x && uv2.x <= pixA2r.x && uv2.y <= pixA2l.y && uv2.y >= pixA2r.y) {
      pixels = (Proc) ? (a1 + a2 + a3 + A3 + B1 + B3) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixB2l.x && uv2.x <= pixB2r.x && uv2.y <= pixB2l.y && uv2.y >= pixB2r.y) {
      pixels = (Proc) ? (A3 + B1 + B3 + b1 + b2 + b3) / 6.0 : _red;
      pixels.a = 1.0;
   }

   return Overflow (uv1) ? EMPTY : pixels;
}

float4 ps_main_3B (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 pixels = tex2D (InputSampler, uv2);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA2l = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA2r = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB1l = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB1r = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB2l = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB2r = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 a3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y));
   float4 A3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY + pixY));
   float4 b1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));
   float4 b3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv2.x >= pixA2l.x && uv2.x <= pixA2r.x && uv2.y <= pixA2l.y && uv2.y >= pixA2r.y) {
      pixels = (Proc) ? (a1 + a2 + a3 + A1 + A3 + B3) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixB1l.x && uv2.x <= pixB1r.x && uv2.y <= pixB1l.y && uv2.y >= pixB1r.y) {
      pixels = (Proc) ? (A0 + A1 + B0 + b0 + b1 + b2) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixB2l.x && uv2.x <= pixB2r.x && uv2.y <= pixB2l.y && uv2.y >= pixB2r.y) {
      pixels = (Proc) ? (A1 + A3 + B3 + b1 + b2 + b3) / 6.0 : _red;
      pixels.a = 1.0;
   }

   return Overflow (uv1) ? EMPTY : pixels;
}

float4 ps_main_3C (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 pixels = tex2D (InputSampler, uv2);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB1l = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB1r = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB2l = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB2r = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y));
   float4 A3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY + pixY));
   float4 b1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));
   float4 b3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv2.x >= pixA1l.x && uv2.x <= pixA1r.x && uv2.y <= pixA1l.y && uv2.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + A2 + B0) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixB1l.x && uv2.x <= pixB1r.x && uv2.y <= pixB1l.y && uv2.y >= pixB1r.y) {
      pixels = (Proc) ? (A0 + A2 + B0 + b0 + b1 + b2) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixB2l.x && uv2.x <= pixB2r.x && uv2.y <= pixB2l.y && uv2.y >= pixB2r.y) {
      pixels = (Proc) ? (A2 + A3 + B3 + b1 + b2 + b3) / 6.0 : _red;
      pixels.a = 1.0;
   }

   return Overflow (uv1) ? EMPTY : pixels;
}

float4 ps_main_3D (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 pixels = tex2D (InputSampler, uv2);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixA2l = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA2r = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB1l = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB1r = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 a3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY + pixY));
   float4 b1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv2.x >= pixA1l.x && uv2.x <= pixA1r.x && uv2.y <= pixA1l.y && uv2.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + B0 + B2) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixA2l.x && uv2.x <= pixA2r.x && uv2.y <= pixA2l.y && uv2.y >= pixA2r.y) {
      pixels = (Proc) ? (a1 + a2 + a3 + A3 + B2 + B3) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixB1l.x && uv2.x <= pixB1r.x && uv2.y <= pixB1l.y && uv2.y >= pixB1r.y) {
      pixels = (Proc) ? (A0 + B0 + B2 + b0 + b1 + b2) / 6.0 : _red;
      pixels.a = 1.0;
   }

   return Overflow (uv1) ? EMPTY : pixels;
}

float4 ps_main_4 (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 pixels = tex2D (InputSampler, uv2);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixA2l = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA2r = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB1l = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB1r = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB2l = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB2r = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 a3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b0 = tex2D (InputSampler, float2 (C1X - pixX, 1.0 - C1Y + pixY + pixY));
   float4 b1 = tex2D (InputSampler, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (InputSampler, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));
   float4 b3 = tex2D (InputSampler, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv2.x >= pixA1l.x && uv2.x <= pixA1r.x && uv2.y <= pixA1l.y && uv2.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + B0) / 5.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixA2l.x && uv2.x <= pixA2r.x && uv2.y <= pixA2l.y && uv2.y >= pixA2r.y) {
      pixels = (Proc) ? (a1 + a2 + a3 + A3 + B3) / 5.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixB1l.x && uv2.x <= pixB1r.x && uv2.y <= pixB1l.y && uv2.y >= pixB1r.y) {
      pixels = (Proc) ? (A0 + B0 + b0 + b1 + b2) / 5.0 : _red;
      pixels.a = 1.0;
   }

   if (uv2.x >= pixB2l.x && uv2.x <= pixB2r.x && uv2.y <= pixB2l.y && uv2.y >= pixB2r.y) {
      pixels = (Proc) ? (A3 + B3 + b1 + b2 + b3) / 5.0 : _red;
      pixels.a = 1.0;
   }

   return Overflow (uv1) ? EMPTY : pixels;
}

float4 last (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float2 Center = float2 (c1x, 1.0 - c1y);
   float2 xy = uv2;

   float Radius = 50.0 / _OutputWidth * mag;
   float Magnification = mag * 10.0;

   if (Glass) {
      float2 centerToPixel = uv2 - Center;
      float dist = length (centerToPixel / float2 (1, _OutputAspectRatio));

      if (dist < Radius) { xy = Center + centerToPixel / Magnification; }
   }

   return Overflow (uv1) ? EMPTY : tex2D (BarSampler1, xy);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique pnum1
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Bars1;"; > ExecuteShader (ps_main_1)
   pass P_3 ExecuteShader (last)
}

technique pnum2H
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Bars1;"; > ExecuteShader (ps_main_2H)
   pass P_3 ExecuteShader (last)
}

technique pnum2V
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Bars1;"; > ExecuteShader (ps_main_2V)
   pass P_3 ExecuteShader (last)
}

technique pnum2DF
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Bars1;"; > ExecuteShader (ps_main_2DF)
   pass P_3 ExecuteShader (last)
}

technique pnum2DB
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Bars1;"; > ExecuteShader (ps_main_2DB)
   pass P_3 ExecuteShader (last)
}

technique pnum3A
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Bars1;"; > ExecuteShader (ps_main_3A)
   pass P_3 ExecuteShader (last)
}

technique pnum3B
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Bars1;"; > ExecuteShader (ps_main_3B)
   pass P_3 ExecuteShader (last)
}

technique pnum3C
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Bars1;"; > ExecuteShader (ps_main_3C)
   pass P_3 ExecuteShader (last)
}

technique pnum3D
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Bars1;"; > ExecuteShader (ps_main_3D)
   pass P_3 ExecuteShader (last)
}

technique pnum4
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Bars1;"; > ExecuteShader (ps_main_4)
   pass P_3 ExecuteShader (last)
}

