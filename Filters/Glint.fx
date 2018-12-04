// @Maintainer jwrl
// @Released 2018-12-04
// @Author khaver
// @Created 2012-10-03
// @see https://www.lwks.com/media/kunena/attachments/6375/Glint_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Glint.fx
//
// Glint Effect by Gary Hango (khaver) creates star filter-like highlights, with 4, 6
// or 8 points selectable.  The glints/stars can be rotated and may be normal or
// rainbow coloured.  They may also be blurred, and the "Show Glint" checkbox will
// display the glints over a black background.
//
// Cross-platform conversion 1 May 2016 by jwrl.
//
// Bug fix 26 February 2017 by jwrl.
// Corrected for a problem with the way that Lightworks handles interlaced media.
// Added subcategory to effect header for version 14.
//
// Cross platform compatibility check 1 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Fully defined float3 and float4 variables to bypass the behavioural differences
// between the D3D and Cg compilers.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 4 December 2018 jwrl.
// Added creation date.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Glint";
   string Category    = "Stylize";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Sample1 : RenderColorTarget;
texture Sample2 : RenderColorTarget;
texture Sample3 : RenderColorTarget;
texture Sample4 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp1 = sampler_state
{
   Texture   = <Sample1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp2 = sampler_state
{
   Texture   = <Sample2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp3 = sampler_state
{
   Texture   = <Sample3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp4 = sampler_state
{
   Texture   = <Sample4>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_adjust (float2 xy : TEXCOORD1) : COLOR
{
   float4 Color = tex2D (InputSampler, xy);

   return float4 (!((Color.r + Color.g + Color.b) / 3.0 > 1.0 - adjust) ? 0.0 : (colorit) ? 1.0 : Color);
}

float4 ps_stretch_1 (float2 xy1 : TEXCOORD1, uniform float rn_angle) : COLOR
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
      delt = tex2D (Samp1, xy1 - (offset * count));
      delt *= 1.0 - (count / 36.0);
      ret += (colorit) ? delt * bow : delt;
   }

   bow.g = 1.0;

   for (int count = 16; count < 22; count++) {
      bow.r = (21.0 - count) / 6.0;
      delt = tex2D (Samp1, xy1 - (offset * count));
      delt *= 1.0 - (count / 36.0);
      ret += (colorit) ? delt * bow : delt;
   }

   return float4 (ret, 1.0);
}

float4 ps_stretch_2 (float2 xy1 : TEXCOORD1, uniform float rn_angle, uniform int samp) : COLOR
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
      delt = tex2D (Samp1, xy1 - (offset * count));
      delt *= 1.0 - (count / 36.0);
      ret += (colorit) ? delt * bow : delt;
   }

   ret = (ret + tex2D (Samp2, xy1).rgb) / 36;

   return max (float4 (ret * bright, 1.0), insamp);
}

float4 Poisson (float2 xy : TEXCOORD1) : COLOR
{
   float2 coord, pixelSize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;

   float2 poisson [24] = { float2 ( 0.326212,  0.40581),
                           float2 ( 0.840144,  0.07358f),
                           float2 ( 0.695914, -0.457137f),
                           float2 ( 0.203345, -0.620716f),
                           float2 (-0.96234,   0.194983f),
                           float2 (-0.473434,  0.480026f),
                           float2 (-0.519456, -0.767022f),
                           float2 (-0.185461,  0.893124f),
                           float2 (-0.507431, -0.064425f),
                           float2 (-0.89642,  -0.412458f),
                           float2 ( 0.32194,   0.932615f),
                           float2 ( 0.791559,  0.59771f),
                           float2 (-0.326212, -0.40581f),
                           float2 (-0.840144, -0.07358f),
                           float2 (-0.695914,  0.457137f),
                           float2 (-0.203345,  0.620716f),
                           float2 ( 0.96234,  -0.194983f),
                           float2 ( 0.473434, -0.480026f),
                           float2 ( 0.519456,  0.767022f),
                           float2 ( 0.185461, -0.893124f),
                           float2 ( 0.507431,  0.064425f),
                           float2 ( 0.89642,   0.412458f),
                           float2 (-0.32194,  -0.932615f),
                           float2 (-0.791559, -0.59771f)};

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

float4 ps_combine (float2 xy : TEXCOORD1) : COLOR
{
   float4 blr = tex2D (Samp2, xy);

   if (flare) return blr;

   float4 source = tex2D (InputSampler, xy);
   float4 comb = source + (blr * (1.0 - source));

   return lerp (source, comb, Strength);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique One
{
   pass Pass_0
   <
      string Script = "RenderColorTarget0 = Sample1;";
   >
   {
      PixelShader = compile PROFILE ps_adjust ();
   }

   pass Pass_a_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_45);
   }

   pass Pass_a_2
   <
      string Script = "RenderColorTarget0 = Sample3;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_45, -1);
   }

   pass Pass_b_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_135);
   }

   pass Pass_b_2
   <
      string Script = "RenderColorTarget0 = Sample4;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_135, 0);
   }

   pass Pass_c_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_225);
   }

   pass Pass_c_2
   <
      string Script = "RenderColorTarget0 = Sample3;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_225, 1);
   }

   pass Pass_d_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_315);
   }

   pass Pass_d_2
   <
      string Script = "RenderColorTarget0 = Sample4;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_315, 0);
   }

   pass Pass_4
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE Poisson ();
   }

   pass Pass_5
   {
      PixelShader = compile PROFILE ps_combine ();
   }
}
 		 	   		  
technique Two
{
   pass Pass_0
   <
      string Script = "RenderColorTarget0 = Sample1;";
   >
   {
      PixelShader = compile PROFILE ps_adjust ();
   }

   pass Pass_a_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_30);
   }

   pass Pass_a_2
   <
      string Script = "RenderColorTarget0 = Sample3;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_30, -1);
   }

   pass Pass_b_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_90);
   }

   pass Pass_b_2
   <
      string Script = "RenderColorTarget0 = Sample4;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_90, 0);
   }

   pass Pass_c_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_150);
   }

   pass Pass_c_2
   <
      string Script = "RenderColorTarget0 = Sample3;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_150, 1);
   }

   pass Pass_d_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_210);
   }

   pass Pass_d_2
   <
      string Script = "RenderColorTarget0 = Sample4;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_210, 0);
   }

   pass Pass_e_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_270);
   }

   pass Pass_e_2
   <
      string Script = "RenderColorTarget0 = Sample3;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_270, 1);
   }

   pass Pass_f_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_330);
   }

   pass Pass_f_2
   <
      string Script = "RenderColorTarget0 = Sample4;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_330, 0);
   }

   pass Pass_4
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE Poisson ();
   }

   pass Pass_5
   {
      PixelShader = compile PROFILE ps_combine ();
   }
}

technique Three
{
   pass Pass_0
   <
      string Script = "RenderColorTarget0 = Sample1;";
   >
   {
      PixelShader = compile PROFILE ps_adjust ();
   }

   pass Pass_a_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_0);
   }

   pass Pass_a_2
   <
      string Script = "RenderColorTarget0 = Sample3;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_0, -1);
   }

   pass Pass_b_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_45);
   }

   pass Pass_b_2
   <
      string Script = "RenderColorTarget0 = Sample4;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_45, 0);
   }

   pass Pass_c_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_90);
   }

   pass Pass_c_2
   <
      string Script = "RenderColorTarget0 = Sample3;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_90, 1);
   }

   pass Pass_d_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_135);
   }

   pass Pass_d_2
   <
      string Script = "RenderColorTarget0 = Sample4;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_135, 0);
   }

   pass Pass_e_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_180);
   }

   pass Pass_e_2
   <
      string Script = "RenderColorTarget0 = Sample3;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_180, 1);
   }

   pass Pass_f_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_225);
   }

   pass Pass_f_2
   <
      string Script = "RenderColorTarget0 = Sample4;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_225, 0);
   }

   pass Pass_g_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_270);
   }

   pass Pass_g_2
   <
      string Script = "RenderColorTarget0 = Sample3;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_270, 1);
   }

   pass Pass_h_1
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_315);
   }

   pass Pass_h_2
   <
      string Script = "RenderColorTarget0 = Sample4;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_315, 0);
   }

   pass Pass_4
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE Poisson ();
   }

   pass Pass_5
   {
      PixelShader = compile PROFILE ps_combine ();
   }
}
