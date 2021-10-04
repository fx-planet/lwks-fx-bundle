// @Maintainer jwrl
// @Released 2021-08-31
// @Author khaver
// @Created 2012-04-12
// @see https://www.lwks.com/media/kunena/attachments/6375/IrisBokeh_640.png

/**
 Iris Bokeh is similar to Bokeh.fx, but provides control of the iris (5 to 8 segments or
 round).  It also controls the size, rotation, threshold and pretty much anything else
 that you're likely to need to adjust.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect IrisBokehFx.fx
// (c) 2012 - Gary Hango
//
// Version history:
//
// Updated 2021-08-31 jwrl:
// Partial rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 2020-11-09:
// Various updates mainly to improve cross-platform performance.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Iris bokeh";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This is similar to Bokeh.fx, but provides control of the iris (5 to 8 segments or round)";
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

#define SetInputMode(TEX, SMPL, MODE) \
                                      \
 texture TEX;                         \
                                      \
 sampler SMPL = sampler_state         \
 {                                    \
   Texture   = <TEX>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define SetTargetMode(TGT, SMP, MODE) \
                                      \
 texture TGT : RenderColorTarget;     \
                                      \
 sampler SMP = sampler_state          \
 {                                    \
   Texture   = <TGT>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }
#define Execute2param(SHD,P1,P2) { PixelShader = compile PROFILE SHD (P1, P2); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

float _OutputWidth;
float _OutputHeight;

float2 _bokeh[120] = 
{
	//Round
	{0,1},
	{-0.2588,0.9659},
	{-0.5,0.866},
	{-0.7071,0.7071},
	{-0.866,0.5},
	{-0.9659,0.2588},
	{-1,0},
	{-0.2588,-0.9659},
	{-0.5,-0.866},
	{-0.7071,-0.7071},
	{-0.866,-0.5},
	{-0.9659,-0.2588},
	{0,-1},
	{0.2588,-0.9659},
	{0.5,-0.866},
	{0.7071,-0.7071},
	{0.866,-0.5},
	{0.9659,-0.2588},
	{1,0},
	{0.2588,0.9659},
	{0.5,0.866},
	{0.7071,0.7071},
	{0.866,0.5},
	{0.9659,0.2588},
	//Eight
	{0,1},
	{-0.2242,0.8747},
	{-0.4599,0.777},
	{-0.7071,0.7071},
	{-0.777,0.4599},
	{-0.8747,0.2242},
	{-1,0},
	{-0.8747,-0.2242},
	{-0.777,-0.4599},
	{-0.7071,-0.7071},
	{-0.4599,-0.777},
	{-0.2242,-0.8747},
	{0,-1},
	{0.2242,-0.8747},
	{0.4599,-0.777},
	{0.7071,-0.7071},
	{0.777,-0.4599},
	{0.8747,-0.2242},
	{1,0},
	{0.8747,0.2242},
	{0.777,0.4599},
	{0.7071,0.7071},
	{0.4599,0.777},
	{0.2242,0.8747},
	//Seven
	{0,1},
	{-0.1905,0.7286},
	{-0.4509,0.6033},
	{-0.7818,0.6235},
	{-0.6973,0.3935},
	{-0.6939,0.1584},
	{-0.799,-0.052},
	{-0.9749,-0.2225},
	{-0.668,-0.3479},
	{-0.4878,-0.5738},
	{-0.4339,-0.901},
	{-0.2284,-0.7674},
	{0,-0.7118},
	{0.1905,0.7286},
	{0.4509,0.6033},
	{0.7818,0.6235},
	{0.6973,0.3935},
	{0.6939,0.1584},
	{0.799,-0.052},
	{0.9749,-0.2225},
	{0.668,-0.3479},
	{0.4878,-0.5738},
	{0.4339,-0.901},
	{0.2284,-0.7674},
	//Six
	{0,1},
	{-0.1707,0.7741},
	{-0.3464,0.6},
	{-0.585,0.5349},
	{-0.866,0.5},
	{-0.7557,0.2392},
	{-0.6928,0},
	{-0.7557,-0.2392},
	{-0.866,-0.5},
	{-0.585,-0.5349},
	{-0.3464,-0.6},
	{-0.1707,-0.7741},
	{0,-1},
	{0.1707,0.7741},
	{0.3464,0.6},
	{0.585,0.5349},
	{0.866,0.5},
	{0.7557,0.2392},
	{0.6928,0},
	{0.7557,-0.2392},
	{0.866,-0.5},
	{0.585,-0.5349},
	{0.3464,-0.6},
	{0.1707,-0.7741},
	//Five
	{0,1},
	{-0.1097,0.8018},
	{-0.2957,0.6218},
	{-0.5,0.4734},
	{-0.5,0.4734},
	{-0.9511,0.309},
	{-0.7965,0.1435},
	{-0.6827,-0.089},
	{-0.6047,-0.3293},
	{-0.56,-0.5842},
	{-0.5878,-0.809},
	{-0.3045,-0.7061},
	{-0.3045,-0.7061},
	{0.1097,0.8018},
	{0.2957,0.6218},
	{0.5,0.4734},
	{0.5,0.4734},
	{0.9511,0.309},
	{0.7965,0.1435},
	{0.6827,-0.089},
	{0.6047,-0.3293},
	{0.56,-0.5842},
	{0.5878,-0.809},
	{0.3045,-0.7061}
};

float2 _Kernel[13] = {
	{-6,0.002216},
	{-5,0.008764},
	{-4,0.026995},
	{-3,0.064759},
	{-2,0.120985},
	{-1,0.176033},
	{0,0.199471},
	{1,0.176033},
	{2,0.120985},
	{3,0.064759},
	{4,0.026995},
	{5,0.008764},
	{6,0.002216},
};

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

SetInputMode (Input, s_Input, Mirror);
SetInputMode (Depth, s_Depth, Mirror);

SetTargetMode (FixInp, s0, Mirror);
SetTargetMode (FixDep, dm, Mirror);
SetTargetMode (Mask, m0, Mirror);

SetTargetMode (Pass1, b1, Mirror);
SetTargetMode (Pass2, b2, Mirror);

SetTargetMode (Bokeh1, m1, Mirror);
SetTargetMode (Bokeh2, m2, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Iris Shape";
   string Enum = "Round,Eight,Seven,Six,Five";
> = 0;

float size
<
   string Description = "Bokeh Size";
   float MinVal = 0.0;
   float MaxVal = 100.0;
> = 50.0;

float rotate
<
   string Description = "Bokeh Rotation";
   float MinVal = 0.0;
   float MaxVal = 360.0;
> = 0.0;

float thresh
<
   string Description = "Bokeh Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float strength
<
   string Description = "Bokeh Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float gamma
<
   string Description = "Bokeh Gamma";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

int alpha
<
   string Description = "Mask Type";
   string Enum = "None,Source_Alpha,Source_Luma,Mask_Alpha,Mask_Luma";
> = 0;

float adjust
<
   string Description = "Mask Brightness";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float contrast
<
   string Description = "Mask Contrast";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

bool invert
<
   string Description = "Invert Mask";
> = false;

bool show
<
   string Description = "Show Mask";
> = false;

float focus
<
   string Description = "Source Focus";
   float MinVal = 0.0;
   float MaxVal = 100.0;
> = 50.0;

float mix
<
   string Description = "Source Mix";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 Rotation (float2 pt)
{
   float S, C;

   sincos (radians (rotate), S, C);

   return (pt * C) - (float2 (pt.y, -pt.x) * S);
}

float4 BokehFilterRGBA (sampler tSource, float2 texCoord, float2 pixelSize, float discRadius, int blades, float dep)
{
   float4 cOut = EMPTY;
   float4 color = EMPTY;

   float delt = 1.0 - dep;

   blades = blades * 24;

   for (int tap = blades; tap < blades+24; tap++) {
      float2 coord = texCoord.xy + (pixelSize * Rotation (_bokeh [tap]) * discRadius * delt);
      color = tex2D (tSource, coord);
      cOut = max (color, cOut);
   }
   cOut.a = dep;

   return cOut;
}

float4 BlurFilterRGBA (sampler tSource, float2 texCoord, float2 pixelSize, float discRadius, int blades, float dep)
{
   float4 cOut = EMPTY;

   float delt = 1.0 - dep;

   int blds = blades * 24;

   for (int tap = blds; tap < blds+24; tap++) {
      float2 coord = texCoord.xy + (pixelSize * _bokeh [tap] * discRadius * delt);
      cOut += tex2D (tSource, coord);
   }

   cOut = cOut / 24.0;
   cOut.a = dep;

   return cOut;
}

float4 LittleBlur (sampler tSource, float2 texCoord, float2 pixelSize, float discRadius, int blades)
{
   float4 cOut = tex2D (tSource, texCoord);

   float ac = cOut.a;

   float2 coord = texCoord;

   for (int tap = 0; tap < 13; tap++) {
      if (blades == 1) coord.x = texCoord.x + (pixelSize.x * _Kernel [tap].x * discRadius);
      if (blades == 2) coord.y = texCoord.y + (pixelSize.y * _Kernel [tap].x * discRadius);

      // Sample pixel

      cOut += tex2D (tSource, coord) * _Kernel [tap].y;
   }

   return float4 (cOut.rgb / 2.0, ac);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These two passes map the input and depth timelines to TEXCOORD3, so that
// variations in clip geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_Input, uv); }
float4 ps_initDpt (float2 uv : TEXCOORD2) : COLOR { return tex2D (s_Depth, uv); }

float4 FindBokehPS (float2 Tex : TEXCOORD3) : COLOR
{
   float4 orig = tex2D (s0, Tex);
   float4 aff = tex2D (dm, Tex);

   float ac = (alpha == 1) ? orig.a
            : (alpha == 2) ? dot (orig.rgb, float3 (0.33, 0.34, 0.33))
            : (alpha == 3) ? aff.a
            : (alpha == 4) ? dot (aff.rgb, float3 (0.33, 0.34, 0.33)) : 0.0;

   ac *= adjust;
   ac  = lerp (0.5, ac, contrast);

   if (invert) ac = 1.0 - ac;

   float4 color = EMPTY;

   if (any (orig.rgb > thresh)) color = pow (orig, 3.0 / gamma);

   return float4 (color.rgb, ac);
}

float4 BokehPS (float2 Tex : TEXCOORD3, uniform int test, uniform int blades) : COLOR
{  
   float2 pixsize = float2 (1.0 / _OutputWidth, 1.0 / _OutputHeight);

   float aff = tex2D (m0, Tex).a;

   if (test == 1) return BokehFilterRGBA (m0, Tex, pixsize, (size / 6.0), blades, aff);
   if (test == 2) return BokehFilterRGBA (m1, Tex, pixsize, (size / 5.0), blades, aff);
   if (test == 3) return BokehFilterRGBA (m2, Tex, pixsize, (size / 4.0), blades, aff);
   if (test == 4) return BokehFilterRGBA (m1, Tex, pixsize, (size / 3.0), blades, aff);

   return BokehFilterRGBA (m2, Tex, pixsize, (size / 2.0), blades, aff);
}

float4 BlurPS (float2 Tex : TEXCOORD3, uniform int test, uniform int blades) : COLOR
{
   float2 pixsize = float2 (1.0 / _OutputWidth, 1.0 / _OutputHeight);

   float aff = tex2D (m0, Tex).a;

   if (test == 1) return BlurFilterRGBA (s0, Tex, pixsize, focus / 6.0, blades, aff);
   if (test == 2) return BlurFilterRGBA (b1, Tex, pixsize, focus / 5.0, blades, aff);
   if (test == 3) return BlurFilterRGBA (b2, Tex, pixsize, focus / 4.0, blades, aff);
   if (test == 4) return BlurFilterRGBA (b1, Tex, pixsize, focus / 3.0, blades, aff);
   if (test == 5) return BlurFilterRGBA (b2, Tex, pixsize, focus / 2.0, blades, aff);

   return (test == 6) ? LittleBlur (m1, Tex, pixsize, strength * 5.0, 1)
                      : LittleBlur (m2, Tex, pixsize, strength * 5.0, 2);
}

float4 CombinePS (float2 uv : TEXCOORD1, float2 Tex : TEXCOORD3) : COLOR
{
   if (Overflow (uv)) return EMPTY;

   float4 orig = tex2D (s0, Tex);
   float4 bokeh = tex2D (m1, Tex);
   float4 blurred = tex2D (b1, Tex);

   float ac = bokeh.a;
   float bomix = (mix > 0.0) ? 1.0 : 1.0 + mix;
   float blmix = (mix < 0.0) ? 1.0 : 1.0 - mix;

   float4 cout;

   if (!show) {
      cout = (focus > 0.0) || (size > 0.0) ? 1.0 - ((1.0 - (bokeh * bomix)) * (1.0 - (blurred * blmix)))
                                           : orig;
   }
   else cout = ac.xxxx;

   return cout;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Round
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pdp < string Script = "RenderColorTarget0 = FixDep;"; > ExecuteShader (ps_initDpt)

   pass Mpass < string Script = "RenderColorTarget0 = Mask;"; > ExecuteShader (FindBokehPS)

   pass BPass1 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 1, 0)
   pass BPass2 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BokehPS, 2, 0)
   pass BPass3 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 3, 0)
   pass BPass4 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BokehPS, 4, 0)
   pass BPass5 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 5, 0)

   pass Pass1 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 1, 0)
   pass Pass2 < string Script = "RenderColorTarget0 = Pass2;"; > Execute2param (BlurPS, 2, 0)
   pass Pass3 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 3, 0)
   pass Pass4 < string Script = "RenderColorTarget0 = Pass2;"; > Execute2param (BlurPS, 4, 0)
   pass Pass5 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 5, 0)
   pass Pass6 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BlurPS, 6, 0)
   pass Pass7 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BlurPS, 7, 0)

   pass Pass8 ExecuteShader (CombinePS)
}

technique Eight
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pdp < string Script = "RenderColorTarget0 = FixDep;"; > ExecuteShader (ps_initDpt)

   pass Mpass < string Script = "RenderColorTarget0 = Mask;"; > ExecuteShader (FindBokehPS)

   pass BPass1 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 1, 1)
   pass BPass2 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BokehPS, 2, 1)
   pass BPass3 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 3, 1)
   pass BPass4 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BokehPS, 4, 1)
   pass BPass5 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 5, 1)

   pass Pass1 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 1, 1)
   pass Pass2 < string Script = "RenderColorTarget0 = Pass2;"; > Execute2param (BlurPS, 2, 1)
   pass Pass3 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 3, 1)
   pass Pass4 < string Script = "RenderColorTarget0 = Pass2;"; > Execute2param (BlurPS, 4, 1)
   pass Pass5 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 5, 1)
   pass Pass6 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BlurPS, 6, 1)
   pass Pass7 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BlurPS, 7, 1)

   pass Pass8 ExecuteShader (CombinePS)
}

technique Seven
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pdp < string Script = "RenderColorTarget0 = FixDep;"; > ExecuteShader (ps_initDpt)

   pass Mpass < string Script = "RenderColorTarget0 = Mask;"; > ExecuteShader (FindBokehPS)

   pass BPass1 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 1, 2)
   pass BPass2 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BokehPS, 2, 2)
   pass BPass3 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 3, 2)
   pass BPass4 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BokehPS, 4, 2)
   pass BPass5 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 5, 2)

   pass Pass1 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 1, 2)
   pass Pass2 < string Script = "RenderColorTarget0 = Pass2;"; > Execute2param (BlurPS, 2, 2)
   pass Pass3 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 3, 2)
   pass Pass4 < string Script = "RenderColorTarget0 = Pass2;"; > Execute2param (BlurPS, 4, 2)
   pass Pass5 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 5, 2)
   pass Pass6 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BlurPS, 6, 2)
   pass Pass7 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BlurPS, 7, 2)

   pass Pass8 ExecuteShader (CombinePS)
}

technique Six
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pdp < string Script = "RenderColorTarget0 = FixDep;"; > ExecuteShader (ps_initDpt)

   pass Mpass < string Script = "RenderColorTarget0 = Mask;"; > ExecuteShader (FindBokehPS)

   pass BPass1 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 1, 3)
   pass BPass2 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BokehPS, 2, 3)
   pass BPass3 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 3, 3)
   pass BPass4 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BokehPS, 4, 3)
   pass BPass5 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 5, 3)

   pass Pass1 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 1, 3)
   pass Pass2 < string Script = "RenderColorTarget0 = Pass2;"; > Execute2param (BlurPS, 2, 3)
   pass Pass3 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 3, 3)
   pass Pass4 < string Script = "RenderColorTarget0 = Pass2;"; > Execute2param (BlurPS, 4, 3)
   pass Pass5 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 5, 3)
   pass Pass6 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BlurPS, 6, 3)
   pass Pass7 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BlurPS, 7, 3)

   pass Pass8 ExecuteShader (CombinePS)
}

technique Five
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pdp < string Script = "RenderColorTarget0 = FixDep;"; > ExecuteShader (ps_initDpt)

   pass Mpass < string Script = "RenderColorTarget0 = Mask;"; > ExecuteShader (FindBokehPS)

   pass BPass1 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 1, 4)
   pass BPass2 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BokehPS, 2, 4)
   pass BPass3 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 3, 4)
   pass BPass4 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BokehPS, 4, 4)
   pass BPass5 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BokehPS, 5, 4)

   pass Pass1 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 1, 4)
   pass Pass2 < string Script = "RenderColorTarget0 = Pass2;"; > Execute2param (BlurPS, 2, 4)
   pass Pass3 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 3, 4)
   pass Pass4 < string Script = "RenderColorTarget0 = Pass2;"; > Execute2param (BlurPS, 4, 4)
   pass Pass5 < string Script = "RenderColorTarget0 = Pass1;"; > Execute2param (BlurPS, 5, 4)
   pass Pass6 < string Script = "RenderColorTarget0 = Bokeh2;"; > Execute2param (BlurPS, 6, 4)
   pass Pass7 < string Script = "RenderColorTarget0 = Bokeh1;"; > Execute2param (BlurPS, 7, 4)

   pass Pass8 ExecuteShader (CombinePS)
}

