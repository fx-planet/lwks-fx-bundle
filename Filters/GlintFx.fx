// @Maintainer jwrl
// @Released 2021-10-05
// @Author khaver
// @Created 2012-10-03
// @see https://www.lwks.com/media/kunena/attachments/6375/Glint_640.png

/**
 Glint Effect creates star filter-like highlights, with 4, 6 or 8 points selectable.  The
 glints/stars can be rotated and may be normal or rainbow coloured.  They may also be
 blurred, and the "Show Glint" checkbox will display the glints over a black background.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GlintFx.fx by Gary Hango (khaver)
//
// Version history:
//
// Update 2021-10-05 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//
// Update 2020-11-12 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 23 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Cross platform compatibility check 1 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Fully defined float3 and float4 variables to bypass the behavioural differences
// between the D3D and Cg compilers.
//
// Bug fix 26 February 2017 by jwrl.
// Corrected for a problem with the way that Lightworks handles interlaced media.
// Added subcategory to effect header for version 14.
//
// Cross-platform conversion 1 May 2016 by jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Glint";
   string Category    = "Stylize";
   string SubCategory = "Filters";
   string Notes       = "Creates rotatable star filter-like highlights, with 4, 6 or 8 points selectable";
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
#define ExecuteParam(SHD,PRM) { PixelShader = compile PROFILE SHD (PRM); }
#define Execute2param(SHD,P1,P2) { PixelShader = compile PROFILE SHD (P1, P2); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

# define ROTATE_0    0.0      // 0.0, 1.0
# define ROTATE_30   0.5236   // 30.0, 1.0
# define ROTATE_45   0.7854   // 45.0, 1.0
# define ROTATE_90   1.5708   // 90.0, 1.0
# define ROTATE_135  2.35619  // 135.0, 1.0
# define ROTATE_150  2.61799  // 150.0, 1.0
# define ROTATE_180  3.14159  // 180.0, 1.0
# define ROTATE_210  3.66519  // 30.0, -1.0
# define ROTATE_225  3.92699  // 45.0, -1.0
# define ROTATE_270  4.71239  // 90.0, -1.0
# define ROTATE_315  5.49779  // 135.0, -1.0
# define ROTATE_330  5.75959  // 150.0, -1.0

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, InputSampler);

DefineTarget (Sample1, Samp1);
DefineTarget (Sample2, Samp2);
DefineTarget (Sample3, Samp3);
DefineTarget (Sample4, Samp4);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Star Points";
   string Enum = "4,6,8";
> = 0;

float adjust
<
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float bright
<
   string Description = "Brightness";
   float MinVal = 1.0;
   float MaxVal = 10.0;
> = 1.0;

float BlurAmount
<
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 20.0;
> = 5.0;

float Rotation
<
   string Description = "Rotation";
   float MinVal = 0.0;
   float MaxVal = 360.0;
> = 0.0;

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool colorit
<
   string Description = "Rainbow Glint";
> = false;

bool blurry
<
   string Description = "Blur Glint";
> = false;

bool flare
<
   string Description = "Show Glint";
> = false;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_adjust (float2 xy : TEXCOORD1) : COLOR
{
   float4 Color = GetPixel (InputSampler, xy);

   return float4 (!((Color.r + Color.g + Color.b) / 3.0 > 1.0 - adjust) ? 0.0 : (colorit) ? 1.0 : Color);
}

float4 ps_stretch_1 (float2 xy1 : TEXCOORD2, uniform float rn_angle) : COLOR
{
   float3 delt, ret = 0.0.xxx;
   float3 bow = float2 (1.0, 0.0).xxy;

   float2 offset;

   float pixel = 0.5 / _OutputWidth;
   float bluramount = BlurAmount * pixel;

   float MapAngle = rn_angle + radians (Rotation);

   sincos (MapAngle, offset.y, offset.x);

   offset *= bluramount;
   offset.y *= _OutputAspectRatio;

   for (int count = 0; count < 16; count++) {
      bow.g = count / 16.0;
      delt = tex2D (Samp1, xy1 - (offset * count)).rgb;
      delt *= 1.0 - (count / 36.0);
      ret += (colorit) ? delt * bow : delt;
   }

   bow.g = 1.0;

   for (int count = 16; count < 22; count++) {
      bow.r = (21.0 - count) / 6.0;
      delt = tex2D (Samp1, xy1 - (offset * count)).rgb;
      delt *= 1.0 - (count / 36.0);
      ret += (colorit) ? delt * bow : delt;
   }

   return float4 (ret, 1.0);
}

float4 ps_stretch_2 (float2 xy1 : TEXCOORD2, uniform float rn_angle, uniform int samp) : COLOR
{
   float3 delt, ret = 0.0.xxx;
   float3 bow = float3 (0.0, 1.0, 1.0);

   float2 offset;

   float pixel = 0.5 / _OutputWidth;
   float bluramount = BlurAmount * pixel;

   float MapAngle = rn_angle + radians (Rotation);

   sincos (MapAngle, offset.y, offset.x);

   offset *= bluramount;
   offset.y *= _OutputAspectRatio;

   float4 insamp = (samp == 0) ? tex2D (Samp3, xy1) : (samp != -1) ? tex2D (Samp4, xy1) : 0.0.xxxx;

   for (int count = 22; count < 36; count++) {
      bow.b = (36.0 - count) / 15.0;
      delt = tex2D (Samp1, xy1 - (offset * count)).rgb;
      delt *= 1.0 - (count / 36.0);
      ret += (colorit) ? delt * bow : delt;
   }

   ret = (ret + tex2D (Samp2, xy1).rgb) / 36;

   return max (float4 (ret * bright, 1.0), insamp);
}

float4 Poisson (float2 xy : TEXCOORD2) : COLOR
{
   float2 coord, pixelSize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;

   float2 poisson [24] = { float2 ( 0.326212,  0.40581),
                           float2 ( 0.840144,  0.07358),
                           float2 ( 0.695914, -0.457137),
                           float2 ( 0.203345, -0.620716),
                           float2 (-0.96234,   0.194983),
                           float2 (-0.473434,  0.480026),
                           float2 (-0.519456, -0.767022),
                           float2 (-0.185461,  0.893124),
                           float2 (-0.507431, -0.064425),
                           float2 (-0.89642,  -0.412458),
                           float2 ( 0.32194,   0.932615),
                           float2 ( 0.791559,  0.59771),
                           float2 (-0.326212, -0.40581),
                           float2 (-0.840144, -0.07358),
                           float2 (-0.695914,  0.457137),
                           float2 (-0.203345,  0.620716),
                           float2 ( 0.96234,  -0.194983),
                           float2 ( 0.473434, -0.480026),
                           float2 ( 0.519456,  0.767022),
                           float2 ( 0.185461, -0.893124),
                           float2 ( 0.507431,  0.064425),
                           float2 ( 0.89642,   0.412458),
                           float2 (-0.32194,  -0.932615),
                           float2 (-0.791559, -0.59771)};

   float4 cOut = tex2D (Samp4, xy);

   if (!blurry) return cOut;

   for (int tap = 0; tap < 24; tap++) {
      coord = xy + (pixelSize * poisson [tap] * (BlurAmount / 3.0));
      cOut += tex2D (Samp4, coord);
   }

   for (int tap2 = 0; tap2 < 24; tap2++) {
      coord = xy + (pixelSize * poisson [tap2].yx * (BlurAmount / 3.0));
      cOut += tex2D (Samp4, coord);
   }

   cOut /= 49.0;

   return cOut;
}

float4 ps_combine (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 blr = GetPixel (Samp2, xy2);

   if (flare) return blr;

   float4 source = GetPixel (InputSampler, xy1);
   float4 comb = source + (blr * (1.0 - source));

   return lerp (source, comb, Strength);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique One
{
   pass P_1 < string Script = "RenderColorTarget0 = Sample1;"; > ExecuteShader (ps_adjust)

   pass A_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_45)
   pass A_2 < string Script = "RenderColorTarget0 = Sample3;"; > Execute2param (ps_stretch_2, ROTATE_45, -1)
   pass B_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_135)
   pass B_2 < string Script = "RenderColorTarget0 = Sample4;"; > Execute2param (ps_stretch_2, ROTATE_135, 0)
   pass C_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_225)
   pass C_2 < string Script = "RenderColorTarget0 = Sample3;"; > Execute2param (ps_stretch_2, ROTATE_225, 1)
   pass D_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_315)
   pass D_2 < string Script = "RenderColorTarget0 = Sample4;"; > Execute2param (ps_stretch_2, ROTATE_315, 0)

   pass P_2 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteShader (Poisson)
   pass P_2 ExecuteShader (ps_combine)
}
 		 	   		  
technique Two
{
   pass P_1 < string Script = "RenderColorTarget0 = Sample1;"; > ExecuteShader (ps_adjust)

   pass A_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_30)
   pass A_2 < string Script = "RenderColorTarget0 = Sample3;"; > Execute2param (ps_stretch_2, ROTATE_30, -1)
   pass B_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_90)
   pass B_2 < string Script = "RenderColorTarget0 = Sample4;"; > Execute2param (ps_stretch_2, ROTATE_90, 0)
   pass C_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_150)
   pass C_2 < string Script = "RenderColorTarget0 = Sample3;"; > Execute2param (ps_stretch_2, ROTATE_150, 1)
   pass D_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_210)
   pass D_2 < string Script = "RenderColorTarget0 = Sample4;"; > Execute2param (ps_stretch_2, ROTATE_210, 0)
   pass E_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_270)
   pass E_2 < string Script = "RenderColorTarget0 = Sample3;"; > Execute2param (ps_stretch_2, ROTATE_270, 1)
   pass F_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_330)
   pass F_2 < string Script = "RenderColorTarget0 = Sample4;"; > Execute2param (ps_stretch_2, ROTATE_330, 0)

   pass P_2 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteShader (Poisson)
   pass P_3 ExecuteShader (ps_combine)
}

technique Three
{
   pass P_1 < string Script = "RenderColorTarget0 = Sample1;"; > ExecuteShader (ps_adjust)

   pass A_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_0)
   pass A_2 < string Script = "RenderColorTarget0 = Sample3;"; > Execute2param (ps_stretch_2, ROTATE_0, -1)
   pass B_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_45)
   pass B_2 < string Script = "RenderColorTarget0 = Sample4;"; > Execute2param (ps_stretch_2, ROTATE_45, 0)
   pass C_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_90)
   pass C_2 < string Script = "RenderColorTarget0 = Sample3;"; > Execute2param (ps_stretch_2, ROTATE_90, 1)
   pass D_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_135)
   pass D_2 < string Script = "RenderColorTarget0 = Sample4;"; > Execute2param (ps_stretch_2, ROTATE_135, 0)
   pass E_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_180)
   pass E_2 < string Script = "RenderColorTarget0 = Sample3;"; > Execute2param (ps_stretch_2, ROTATE_180, 1)
   pass F_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_225)
   pass F_2 < string Script = "RenderColorTarget0 = Sample4;"; > Execute2param (ps_stretch_2, ROTATE_225, 0)
   pass G_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_270)
   pass G_2 < string Script = "RenderColorTarget0 = Sample3;"; > Execute2param (ps_stretch_2, ROTATE_270, 1)
   pass H_1 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteParam (ps_stretch_1, ROTATE_315)
   pass H_2 < string Script = "RenderColorTarget0 = Sample4;"; > Execute2param (ps_stretch_2, ROTATE_315, 0)

   pass P_2 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteShader (Poisson)
   pass P_3 ExecuteShader (ps_combine)
}

