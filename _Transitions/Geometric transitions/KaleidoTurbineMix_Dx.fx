// @Maintainer jwrl
// @Released 2021-07-25
// @Author schrauber
// @Created 2016-08-10
// @see https://www.lwks.com/media/kunena/attachments/6375/KaleidoTurbine_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Kaleido.mp4

/**
 This effect is based on the user effect Kaleido, converted to function as a transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect KaleidoTurbineMix_Dx.fx
//
// From Schrauber revised for transitions.  The transition effect is based on baopao's
// (and/or nouanda?)  "Kaleido".  In the "Kaleido" file was the following:
// Quote: ...................
// Kaleido   http://www.alessandrodallafontana.com/ based on the pixel shader of:
// http://pixelshaders.com/ corrected for HLSL by Lightworks user nouanda
// ..........................
//
// Version history:
//
// Modified 2021-07-25 jwrl.
// Added support for 2021 resolution independence.
// This date does not reflect the upload date because of forum upload problems.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
// Changed "FG" to "Fg" and "BG" to "Bg".
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Kaleido turbine mix";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Uses a kaleidoscope pattern to transition between two clips";
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

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = Mirror;                \
   AddressV  = Mirror;                \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define HALF_PI 1.5707963268
#define PI      3.1415926536
#define TWO_PI  6.2831853072

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, FGSampler);
DefineTarget (RawBg, BGSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float Zoom
<
   string Description = "Zoom";
   float MinVal = 0.0;
   float MaxVal = 2.00;
> = 1.0;

float PosX
<
   string Description = "Pan";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float PosY
<
   string Description = "Pan";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

bool fan
<
   string Description = "Fan";
> = false;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// This function added to mimic the GLSL mod() function

float mod (float x, float y)
{
   return x - y * floor (x/y);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_RawBg, uv); }

float4 main( float2 xy1 : TEXCOORD3 ) : COLOR 
{

     float4 color;                 // to output
     float scale = 1 - (1.8 * amount); 						// Phase 2, kaleido, tube (Z), strengthen
     float2 PosXY = float2 (PosX, 1.0 - PosY);
     float2 p = xy1-PosXY;
     float r = length(p);
     float a = atan2(p.y, p.x);  						// Changed from GLSL version - float a = atan(p.y, p.x)
     float amount_b = (amount - 0.4) *5; 

     float kaleido = amount * 50 + 0.1;						// Phase 1, kaleido,rotation, strengthen
     if (amount > 0.5 ) kaleido = 50.1 - (amount * 50);				// Phase 2, kaleido, rotation, weaken
     if (amount > 0.5 ) scale =  1.8 * (amount -0.5) + 0.1 ; 			// Phase 2, kaleido, tube (Z),  weaken

     float tau = 2.0 * 3.1416;
     a = mod(a, tau / kaleido);
     a = abs(a - tau / kaleido / 2);

 
     p = r * float2(cos(a), sin(a));  



     if(amount < 0.5) color = tex2D(FGSampler, (p/Zoom + PosXY)/scale);				// Kaleido phase 1a
     if((amount < 0.5) && (r <= amount_b)) color = tex2D(BGSampler, (p/Zoom + PosXY)/scale);	// Kaleido phase 1b (FB outside & BG inside)

     if(amount >= 0.5) color = tex2D(BGSampler, (p/Zoom + PosXY)/scale);			// Kaleido phase 2b
     if((amount >= 0.5) && (r > amount_b)) color = tex2D(FGSampler, (p/Zoom + PosXY)/scale);	// Kaleido phase 2a (FB outside & BG inside)

     if((a > amount) && (amount < 0.5) && (fan)) color = tex2D(FGSampler, xy1);			// Fan phase 1
     if((a > 1 - amount) && (amount > 0.5) && (fan)) color = tex2D(BGSampler, xy1);		// Fan phase 2
     return color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SimpleTechnique
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)

   pass MainPass ExecuteShader (main)
}

