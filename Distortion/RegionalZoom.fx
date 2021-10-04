// @Maintainer jwrl
// @Released 2021-08-30
// @Author schrauber
// @Created 2016-03-14
// @see https://www.lwks.com/media/kunena/attachments/6375/RegionalZoom_640.jpg

/**
 Regional zoom is designed to allow you to apply localised (focussed) distortion to a
 region of the frame.  Either zoom in or zoom out can be applied, the area covered can
 be varied, and the amount of distortion can be adjusted.  The edges of the image after
 distortion can optionally be mirrored out to fill the frame.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RegionalZoom.fx
//
// Version history.
//
// Update 2021-08-30 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Regional zoom";
   string Category    = "DVE";
   string SubCategory = "Distortion";
   string Notes       = "This is designed to allow you to apply localised distortion to any region of the frame";
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

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputAspectRatio;
	
#define AREA  (200-Area*201)

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

SetTargetMode (Fg, FgSampler, Mirror);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Parameters, which can be changed by the user in the effects settings.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




float Zoom
<
	string Description = "zoom";
	float MinVal = -1.00;
	float MaxVal = 1.00;
> = 0.00;



float Area
<
	string Description = "Area";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.95;



float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;


int Mode
<
   string Description = "Flip edge";
   string Enum = "No,Yes";
> = 1;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This preamble pass means that we handle rotated video correctly.

float4 ps_init (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_Input, uv); }

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   float2 xydist = float2 (Xcentre, 1.0 - Ycentre) - uv; 			 // XY Distance between the current position to the adjusted effect centering

   float distance = length (float2 (xydist.x, xydist.y / _OutputAspectRatio));   // Hypotenuse of xydistance, the shortest distance between the currently processed pixels to the center of the distortion.
   float distortion = (distance * ((distance * AREA) + 1.0) + 1);		 // Creates the distortion.  AREA is a macro that limits the range of the Area setting.
   float zoom = Zoom;

   if (Area != 1) zoom = zoom / max (distortion, 0.1);	 			 // If the area = 1, then normal zoom works. Otherwise, a local zoom is active.   "0.1" prevents a division by zero

   float2 xy = uv + (zoom * xydist);						 // Get the distorted address.  It's the same whether mirrored or bordered.

   return Mode ? tex2D (FgSampler, xy) : GetPixel (FgSampler, xy);		 // GetPixel() blanks anything outside legal addresses, which adds a border to the distorted but mirrored video
} 

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique RegionalZoom
{
   pass P_init < string Script = "RenderColorTarget0 = Fg;"; > ExecuteShader (ps_init)
   pass SinglePass ExecuteShader (ps_main)
}

