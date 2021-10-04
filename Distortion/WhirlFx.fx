// @Maintainer jwrl
// @Released 2021-08-30
// @Author schrauber
// @Created 2017-11-06
// @see https://www.lwks.com/media/kunena/attachments/6375/whirl20171106_640.png
// @see https://www.youtube.com/watch?v=LB5-_cvkRb0

/**
 Visualise what happens when water empties out of a sink, and you have what this effect
 does.  Possibly you could regard it as adding the sort of sink error you want to your
 video!
*/ 

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhirlFx.fx
//
// Version history:
//
// Update 2021-08-30 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Whirl";  
   string Category    = "DVE";
   string SubCategory = "Distortion";
   string Notes       = "Simulates what happens when water empties out of a sink";
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

//-----------------------------------------------------------------------------------------//
// Inputs and Samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

SetTargetMode (FixInp, FgSampler, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float WhirlCenter
<
   string Description = "Whirl";
   float MinVal = -62.0;
   float MaxVal = 62.0;
> = 0.0;


float WhirlOutside
<
   string Description = "Whirl, outside";
   float MinVal = -62.0;
   float MaxVal = 62.0;
> = 0.0;





float Spin
<
   string Description = "Revolutions";
   float MinVal = -62.0;
   float MaxVal = 62.0;
> = 0.0;



float Zoom
<
   string Description = "Zoom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;


float XzoomPos
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float YzoomPos
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This preamble pass means that we handle rotated video correctly.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{ 

   // ----Shader definitions and declarations ----

   float Tsin, Tcos;    // Sine and cosine of the set angle.
   float angle;
   float distance;      //Distance from the center of rotation

   // Position vectors
   float2 centreEffect = float2 (XzoomPos, 1.0 - YzoomPos);
   float2 posZoom, posSpin;

   // Direction vectors
   float2 vCzT;              // Vector between Center(zoom) and Texel
   float2 vCrT;              // Vector between Center(rotation) and Texel




   // ------ ROTATION --------

   vCrT = uv - centreEffect;
   distance = length (float2 (vCrT.x, vCrT.y / _OutputAspectRatio)); 

   angle = radians
           (
              (Spin * 360.0)
            + (WhirlOutside * 360.0 * distance)
            + (WhirlCenter * 360.0 * (1.0 - distance))
              * -1.0
           );
   
   vCrT = float2(vCrT.x * _OutputAspectRatio, vCrT.y );

   sincos (angle, Tsin , Tcos);
   posSpin = float2 ((vCrT.x * Tcos - vCrT.y * Tsin), (vCrT.x * Tsin + vCrT.y * Tcos)); 
   posSpin = float2(posSpin.x / _OutputAspectRatio, posSpin.y ) + centreEffect;


   // ------ ZOOM -------

  
   vCzT = centreEffect - posSpin;
   posZoom = ( (1.0- (exp2( Zoom * 10.0 *-1.0))) * vCzT ) + posSpin;            // The set value Zoom has been replaced by the formula  (1- (exp2( Zoom * 10 -1)))   to get the setting characteristic described in the header.


   

 
   // ------ OUTPUT-------

   return tex2D (FgSampler, posZoom);

}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique main
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (ps_main)
}

