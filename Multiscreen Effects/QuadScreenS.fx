// @Maintainer jwrl
// @Released 2020-06-22
// @Author schrauber
// @Created 2020-06-08
// @see: https://www.lwks.com/media/kunena/attachments/6375/QuadSss_640.png

/**
 This s a single effect with 4 inputs.  It features:
 - Fast (low GPU load)
 - Easy handling if you only need a standardized layout without cropping etc.

 "Scale" changes the distance between the screens by scaling them, always keeping them
 fixed in their corners.  In this simple effect, this setting is designed for static
 purposes only. Slow keyframing would make 1-pixel jumps of the edges visible. For dynamic
 scaling I recommend the effect "Quad split screen, dynamic zoom", which uses a more
 sophisticated edge interpolation.

 The background color is adjustable. If Alpha is set to 0, the Background can be replaced
 in a subsequent effect (e.g. "Blend").  It should be possible to nest this effect to make
 larger arrays than 4x4.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Quad split screen, simply";  
   string Category    = "DVE";
   string SubCategory = "Multiscreen Effects";
   string Notes       = "Revised version of 8 June 2020";
> = 0;


//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//


float baseSkale
<
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.495;


float4 Bg
<
   string Description = "Background";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 0.0, 1.0 };




//-----------------------------------------------------------------------------------------//
// Common definitions, declarations, macros
//-----------------------------------------------------------------------------------------//

#define EMPTY         0.0.xxxx
#define THUMBNAILS    4



//-----------------------------------------------------------------------------------------//
// Inputs and Samplers 
//-----------------------------------------------------------------------------------------//

// Macros as short form of the sampler definitions: 

#ifdef _LENGTH                 
// Versions check Lightworks > 14.0
   // For current Lightworks versions ClampToEdge is used for low GPU load, but for versions prior to Ligtworks 14.5 Mirror is used for compatibility.
   #define CLAMP_OR_MIRROR \
      AddressU  = ClampToEdge;\
      AddressV  = ClampToEdge;\
      MinFilter = Linear;\
      MagFilter = Linear;\
      MipFilter = Linear;
#else
   #define CLAMP_OR_MIRROR \
      AddressU  = Mirror;\
      AddressV  = Mirror;\
      MinFilter = Linear;\
      MagFilter = Linear;\
      MipFilter = Linear;
#endif


texture a;
sampler s_Fg0 = sampler_state { Texture = <a>; CLAMP_OR_MIRROR };

texture b;
sampler s_Fg1 = sampler_state { Texture = <b>; CLAMP_OR_MIRROR };

texture c;
sampler s_Fg2 = sampler_state { Texture  = <c>; CLAMP_OR_MIRROR };

texture d;
sampler s_Fg3 = sampler_state { Texture  = <d>; CLAMP_OR_MIRROR };



//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_fn, float2 xy)
{
   if (xy.x < 0.0 || xy.x > 1.0 || xy.y < 0.0 || xy.y > 1.0) return EMPTY;
   return tex2D (s_fn, xy);
}


     
//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_splitScreen (float2 uv_  : TEXCOORD1,
                       float2 uv_1 : TEXCOORD2,
                       float2 uv_2 : TEXCOORD3,
                       float2 uv_3 : TEXCOORD4) : COLOR
{ 
   int i; // loop counter

   float2 uv[THUMBNAILS];
   uv[0] = uv_;
   uv[1] = uv_1;
   uv[2] = uv_2;
   uv[3] = uv_3;

  // Zoom positions:
   float2 pos[THUMBNAILS];
   pos[0] = float2 ( 0.0, 0.0);
   pos[1] = float2 ( 1.0, 0.0);
   pos[2] = float2 ( 0.0, 1.0);
   pos[3] = float2 ( 1.0, 1.0);

  // Direction vectors
   float2 vPt[THUMBNAILS];  
   for(i=0; i<THUMBNAILS; i++)
   { 
      vPt[i] = pos[i] - uv[i];   // Direction vector of the set position to the currently calculated texel.
   }

   // ------ ZOOM & samplers:
   float4 input[THUMBNAILS];
   float zoom = 1.0 + (-1.0 / max (1.0e-9, baseSkale));  // The zoom range from [0..1] is rescaled to [-1e-9 .. 0]   ( 0 = Dimensions 100%, -1 = Dimensions 50 %, -2 Dimensions 33.3 %, -1e-9 (approximately negative infinite) = size 0%)
   input[0] = fn_tex2D (s_Fg0, zoom * vPt[0] + uv[0]);   // Thumbnail top left. 
   input[1] = fn_tex2D (s_Fg1, zoom * vPt[1] + uv[1]);   // Thumbnail top right.
   input[2] = fn_tex2D (s_Fg2, zoom * vPt[2] + uv[2]);   // Thumbnail bottom left.
   input[3] = fn_tex2D (s_Fg3, zoom * vPt[3] + uv[3]);   // Thumbnail bottom right.

   // ------ Mix:
   float4 mix = max (input[0], input[1]);
          mix = max (mix, input[2]);
          mix = max (mix, input[3]);

   // ------ Mix Bg & Alpha:
   float4 retval = mix;
   retval = lerp (Bg, mix, mix.a);

   return retval;
}




//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//


technique tech_main
{
   pass P_1  { PixelShader = compile PROFILE ps_splitScreen (); }
}
