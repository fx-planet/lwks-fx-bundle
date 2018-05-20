// @Maintainer jwrl
// @Released 2018-05-20
// @Author khaver
// 
// @see https://www.lwks.com/media/kunena/attachments/6375/IrisBokeh_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect IrisBokeh.fx
// (c) 2012 - Gary Hango
//
// Iris Bokeh is similar to Bokeh.fx, but provides control of the iris (5 to 8 segments
// or round).  It also controls the size, rotation, threshold and pretty much anything
// else that you're likely to need to adjust.
//
// Cross platform version 24 July 2017 by jwrl.
// This has had considerable work done on it to make it Linux/Mac compatible.  The
// compatibility of the previous version was poor due to the inability to pass pointers
// to shaders conditionally on those platforms.  As a result this has become largely a
// rewrite of Gary Hango's original to support the Cg compiler used on the Linux/Mac
// platforms.  The variables, functions, shaders and techniques are operationally the
// same as those in the Windows original and as much as possible try to use the same
// names.  The code used to implement them may be different.
//
// The major differences are:
//    The original LittleBlur() function has now become a shader.
//    Both BokehPS() and BlurPS() have been split in three and merged with the
//    functions they called.
//
// The changes have reduced conditional execution and function calls significantly.
// With fourteen passes, anything that we can do to reduce overheads is worth it.
//
// Version 14.5 update 5 December 2017 by jwrl.
// Added LINUX and MAC test to allow support for changing "Clamp" to "ClampToEdge"
// on those platforms.  It will now function correctly when used with Lightworks
// versions 14.5 and higher under Linux or OS-X and fixes a bug associated with using
// this effect with transitions on those platforms.  The bug still exists when using
// older versions of Lightworks.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//
// Modified by LW user jwrl 20 May 2018.
// This version will only run on versions of Lightworks better than version 14 if it is
// compile on a Windows system.  There is a legacy version available for older Windows
// Lightworks versions.  This restriction doesn't apply to Windows or Mac.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Iris Bokeh";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;
texture Depth;

texture Mask : RenderColorTarget;

texture Pass1 : RenderColorTarget;
texture Pass2 : RenderColorTarget;

texture Bokeh1 : RenderColorTarget;
texture Bokeh2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef OSX
#define Clamp ClampToEdge
#endif

sampler s0 = sampler_state {
   Texture = <Input>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler dm = sampler_state {
   Texture = <Depth>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler m0 = sampler_state {
   Texture = <Mask>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler b1 = sampler_state {
   Texture = <Pass1>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler b2 = sampler_state {
   Texture = <Pass2>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler m1 = sampler_state {
   Texture = <Bokeh1>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler m2 = sampler_state {
   Texture = <Bokeh2>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

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

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 Rotation (float2 pt)
{
   float S, C;

   sincos (radians (rotate), S, C);

   return (pt * C) - (float2 (pt.y, -pt.x) * S);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 FindBokehPS (float2 Tex : TEXCOORD1) : COLOR
{
   float4 orig = tex2D (s0, Tex);
   float4 aff = tex2D (dm, Tex);

   float ac = 0.0;

   if (alpha == 1) ac = orig.a;

   if (alpha == 2) ac = (orig.r + orig.g + orig.b) / 3.0;

   if (alpha == 3) ac = aff.a;

   if (alpha == 4) ac = (aff.r + aff.g + aff.b) / 3.0;

   ac *= adjust;
   ac  = lerp (0.5, ac, contrast);

   if (invert) ac = 1.0 - ac;

   float4 color = 0.0.xxxx;

   if ((orig.r > thresh) || (orig.g > thresh) || (orig.b > thresh)) color = pow (orig, 3.0 / gamma);

   return float4 (color.rgb, ac);
}

float4 BokehPS_1 (float2 Tex : TEXCOORD1, uniform int blades) : COLOR
{  
   float4 color, cOut = 0.0.xxxx;

   float aff = tex2D (m0, Tex).a;

   float2 coord;
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * size * (1.0 - aff) / (_OutputWidth * 6.0);

   int tap = blades * 24;

   for (int i = 0; i < 24; i++) {
      coord = Tex + (pixsize * Rotation (_bokeh [tap]));
      color = tex2D (m0, coord);
      cOut = max (color, cOut);
      tap++;
   }

   return float4 (cOut.rgb, aff);
}

float4 BokehPS_2 (float2 Tex : TEXCOORD1, uniform int test, uniform int blades) : COLOR
{  
   float4 color, cOut = 0.0.xxxx;

   float aff = tex2D (m0, Tex).a;
   float width = (test == 1) ? _OutputWidth * 5.0 : _OutputWidth * 3.0;

   float2 coord;
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * size * (1.0 - aff) / width;

   int tap = blades * 24;

   for (int i = 0; i < 24; i++) {
      coord = Tex + (pixsize * Rotation (_bokeh [tap]));
      color = tex2D (m1, coord);
      cOut = max (color, cOut);
      tap++;
   }

   return float4 (cOut.rgb, aff);
}

float4 BokehPS_3 (float2 Tex : TEXCOORD1, uniform int test, uniform int blades) : COLOR
{  
   float4 color, cOut = 0.0.xxxx;

   float aff = tex2D (m0, Tex).a;
   float width = (test == 1) ? _OutputWidth * 4.0 : _OutputWidth * 2.0;

   float2 coord;
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * size * (1.0 - aff) / width;

   int tap = blades * 24;

   for (int i = 0; i < 24; i++) {
      coord = Tex + (pixsize * Rotation (_bokeh [tap]));
      color = tex2D (m2, coord);
      cOut = max (color, cOut);
      tap++;
   }

   return float4 (cOut.rgb, aff);
}

float4 LittleBlur (float2 Tex : TEXCOORD1, uniform int blades) : COLOR
{
   float Kernel [7] = { 0.199471, 0.176033, 0.120985, 0.064759, 0.026995, 0.008764, 0.002216 };
   float discRadius = strength * 5.0;
   float ac, ix = -6.0;

   float2 pixelSize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 coord = Tex;

   float4 cOut;

   if (blades == 1) {
      cOut = tex2D (m1, Tex);
      ac = cOut.a;

      for (int tap = 0; tap < 13; tap++) {
         coord.x = Tex.x + (pixelSize.x * discRadius * ix);
         cOut += tex2D (m1, coord) * Kernel [abs (ix)];
         ix++;
     }
   }
   else {
      cOut = tex2D (m2, Tex);
      ac = cOut.a;

      for (int tap = 0; tap < 13; tap++) {
         coord.y = Tex.y + (pixelSize.y * discRadius * ix);
         cOut += tex2D (m2, coord) * Kernel [abs (ix)];
         ix++;
     }
  }

   return float4 (cOut.rgb / 2.0, ac);
}

float4 BlurPS_1 (float2 Tex : TEXCOORD1, uniform int blades) : COLOR
{
   float4 cOut = 0.0.xxxx;

   float aff = tex2D (m0, Tex).a;

   float2 coord;
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * focus * (1.0 - aff) / (_OutputWidth * 6.0);

   int tap = blades * 24;

   for (int i = 0; i < 24; i++) {
      coord = Tex + (pixsize * _bokeh [tap]);
      cOut += tex2D (s0, coord);
      tap++;
   }

   return float4 (cOut.rgb / 24.0, aff);
}

float4 BlurPS_2 (float2 Tex : TEXCOORD1, uniform int test, uniform int blades) : COLOR
{
   float4 cOut = 0.0.xxxx;

   float aff = tex2D (m0, Tex).a;
   float width = (test == 1) ? _OutputWidth * 5.0 : _OutputWidth * 3.0;

   float2 coord;
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * focus * (1.0 - aff) / width;

   int tap = blades * 24;

   for (int i = 0; i < 24; i++) {
      coord = Tex + (pixsize * _bokeh [tap]);
      cOut += tex2D (b1, coord);
      tap++;
   }

   return float4 (cOut.rgb / 24.0, aff);
}

float4 BlurPS_3 (float2 Tex : TEXCOORD1, uniform int test, uniform int blades) : COLOR
{
   float4 cOut = 0.0.xxxx;

   float aff = tex2D (m0, Tex).a;
   float width = (test == 1) ? _OutputWidth * 4.0 : _OutputWidth * 2.0;

   float2 coord;
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * focus * (1.0 - aff) / width;

   int tap = blades * 24;

   for (int i = 0; i < 24; i++) {
      coord = Tex + (pixsize * _bokeh [tap]);
      cOut += tex2D (b2, coord);
      tap++;
   }

   return float4 (cOut.rgb / 24.0, aff);
}

float4 CombinePS (float2 Tex : TEXCOORD1) : COLOR
{
   float4 bokeh = tex2D (m1, Tex);

   if (show) return bokeh.aaaa;

   if ((focus <= 0.0) && (size <= 0.0)) return tex2D (s0, Tex);

   float4 blurred = tex2D (b1, Tex);

   float bomix = (mix > 0.0) ? 1.0 : 1.0 + mix;
   float blmix = (mix < 0.0) ? 1.0 : 1.0 - mix;

   return (1.0.xxxx - ((1.0.xxxx - (bokeh * bomix)) * (1.0.xxxx - (blurred * blmix))));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Round
{
   pass Mpass
   <
      string Script = "RenderColorTarget0 = Mask;";
   >
   {
      PixelShader = compile PROFILE FindBokehPS ();
   }

    pass BPass1
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_1 (0);
   }

   pass BPass2
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE BokehPS_2 (1, 0);
   }

   pass BPass3
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_3 (1, 0);
   }

   pass BPass4
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE BokehPS_2 (2, 0);
   }

   pass BPass5
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_3 (2, 0);
   }

   pass BPass6
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE LittleBlur (1);
   }

   pass BPass7
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE LittleBlur (2);
   }

   pass Pass1
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_1 (0);
   }

   pass Pass2
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE BlurPS_2 (1, 0);
   }

   pass Pass3
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_3 (1, 0);
   }

   pass Pass4
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE BlurPS_2 (2, 0);
   }

   pass Pass5
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_3 (2, 0);
   }

   pass Pass6
   {
      PixelShader = compile PROFILE CombinePS ();
   }
}

technique Eight
{
   pass Mpass
   <
      string Script = "RenderColorTarget0 = Mask;";
   >
   {
      PixelShader = compile PROFILE FindBokehPS ();
   }

    pass BPass1
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_1 (1);
   }

   pass BPass2
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE BokehPS_2 (1, 1);
   }

   pass BPass3
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_3 (1, 1);
   }
   
   pass BPass4
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE BokehPS_2 (2, 1);
   }

   pass BPass5
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_3 (2, 1);
   }
   
   pass BPass6
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE LittleBlur (1);
   }

   pass BPass7
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE LittleBlur (2);
   }

   pass Pass1
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_1 (1);
   }

   pass Pass2
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE BlurPS_2 (1, 1);
   }

   pass Pass3
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_3 (1, 1);
   }

   pass Pass4
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE BlurPS_2 (2, 1);
   }

   pass Pass5
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_3 (2, 1);
   }

   pass Pass6
   {
      PixelShader = compile PROFILE CombinePS ();
   }
}

technique Seven
{
   pass Mpass
   <
      string Script = "RenderColorTarget0 = Mask;";
   >
   {
      PixelShader = compile PROFILE FindBokehPS ();
   }

    pass BPass1
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_1 (2);
   }

   pass BPass2
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE BokehPS_2 (1, 2);
   }

   pass BPass3
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_3 (1, 2);
   }
   
   pass BPass4
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE BokehPS_2 (2, 2);
   }

   pass BPass5
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_3 (2, 2);
   }
   
   pass BPass6
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE LittleBlur (1);
   }

   pass BPass7
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE LittleBlur (2);
   }

   pass Pass1
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_1 (2);
   }

   pass Pass2
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE BlurPS_2 (1, 2);
   }

   pass Pass3
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_3 (1, 2);
   }

   pass Pass4
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE BlurPS_2 (2, 2);
   }

   pass Pass5
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_3 (2, 2);
   }

   pass Pass6
   {
      PixelShader = compile PROFILE CombinePS ();
   }
}

technique Six
{
   pass Mpass
   <
      string Script = "RenderColorTarget0 = Mask;";
   >
   {
      PixelShader = compile PROFILE FindBokehPS ();
   }

    pass BPass1
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_1 (3);
   }

   pass BPass2
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE BokehPS_2 (1, 3);
   }

   pass BPass3
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_3 (1, 3);
   }
   
   pass BPass4
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE BokehPS_2 (2, 3);
   }

   pass BPass5
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_3 (2, 3);
   }
   
   pass BPass6
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE LittleBlur (1);
   }

   pass BPass7
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE LittleBlur (2);
   }

   pass Pass1
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_1 (3);
   }

   pass Pass2
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE BlurPS_2 (1, 3);
   }

   pass Pass3
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_3 (1, 3);
   }

   pass Pass4
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE BlurPS_2 (2, 3);
   }

   pass Pass5
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_3 (2, 3);
   }

   pass Pass6
   {
      PixelShader = compile PROFILE CombinePS ();
   }
}

technique Five
{
   pass Mpass
   <
      string Script = "RenderColorTarget0 = Mask;";
   >
   {
      PixelShader = compile PROFILE FindBokehPS ();
   }

    pass BPass1
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_1 (4);
   }

   pass BPass2
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE BokehPS_2 (1, 4);
   }

   pass BPass3
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_3 (1, 4);
   }
   
   pass BPass4
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE BokehPS_2 (2, 4);
   }

   pass BPass5
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE BokehPS_3 (2, 4);
   }
   
   pass BPass6
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE LittleBlur (1);
   }

   pass BPass7
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE LittleBlur (2);
   }

   pass Pass1
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_1 (4);
   }

   pass Pass2
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE BlurPS_2 (1, 4);
   }

   pass Pass3
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_3 (1, 4);
   }
   
   pass Pass4
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE BlurPS_2 (2, 4);
   }

   pass Pass5
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE BlurPS_3 (2, 4);
   }
   
   pass Pass6
   {
      PixelShader = compile PROFILE CombinePS ();
   }
}
