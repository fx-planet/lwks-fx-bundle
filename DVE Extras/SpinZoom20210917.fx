// @Maintainer jwrl
// @Released 2021-09-17
// @Author schrauber
// @Created 2017-10-22
// @see https://www.lwks.com/media/kunena/attachments/6375/Spin_Zoom_640.png

/**
 This has some of the same functions as the 3D DVE, but the settings menu does not look
 as interesting as that effect.  It is actually more interesting.  It gives you a simple
 functionality, and adds the ability to mirror or duplicate the image as you zoom out.
 If you only need rotation and zoom, then you only need this effect.  The rotation axis
 is automatically adjusted in the same way as the 3D DVE does.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SpinZoom20210917
//
// ... More details:
// Setting characteristics of the zoom slider
//         The dimensions will be doubled or halved in setting steps of 10%:
//         -40% Dimensions / 16
//         -30% Dimensions / 8
//         -20% Dimensions / 4
//         -10% Half dimensions
//           0% No change
//          10% Double dimensions
//          20% Dimensions * 4
//          30% Dimensions * 8
//          40% Dimensions * 16
//
//        Center of rotation:
//        Zoom >= 0: rotation center = center of the output texture
//        Zoom <  0: rotation center = center of the input textur
//        For this purpose, the program sections ZOOM and ROTATION are run through in
//        different order.
//        Zoom >= 0: first ZOOM, then ROTATION
//        Zoom <  0: first ROTATION, then ZOOM
//
// Information for Effect Developer:
// 16 May 2018 by LW user schrauber: Subcategory defined, and data relevant to the homepage.
// The rotation code is based on the spin-dissolve effects of the user "jwrl".
// The zoom code is based on the zoom out, zoom in effect of the user "schrauber".
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Update 2021-09-17 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Spin Zoom";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "Has some of the same functions as the 3D DVE, but the settings are much easier to use";
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
#define ExecuteParam(SHD,PRM) { PixelShader = compile PROFILE SHD (PRM); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputAspectRatio;

#define ZOOM (Zoom * 10 + ZoomFine / 10)
#define FRAMECENTER 0.5
     
//-----------------------------------------------------------------------------------------//
// Inputs and Samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

SetTargetMode (Bordered, BorderSampler, Border);
SetTargetMode (Mirrored, MirrorSampler, Mirror);
SetTargetMode (Wrapped, WrapSampler, Wrap);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Spin
<
   string Group = "Rotation";
   string Description = "Revolutions";
   float MinVal = -62.0;
   float MaxVal = 62.0;
> = 0.0;

float Angle
<
   string Group = "Rotation";
   string Description = "Angle";
   float MinVal = -360.0;
   float MaxVal = 360.0;
> = 0.0;

float AngleFine
<
   string Group = "Rotation";
   string Description = "Angle Fine";
   float MinVal = -12.0;
   float MaxVal = 12.0;
> = 0.0;

float Zoom
<
   string Group = "Zoom";
   string Description = "Strength";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ZoomFine
<
   string Group = "Zoom";
   string Description = "Fine";
   float MinVal = -5.0;
   float MaxVal = 5.0;
> = 0.0;

float XzoomPos
<
   string Group = "Zoom";
   string Description = "Zoom centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float YzoomPos
<
   string Group = "Zoom";
   string Description = "Zoom centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Edge mode";
   string Enum = "Bordered/transparent,Reflected image,Tiled image"; 
> = 0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_edge_mode (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Input, uv); }

float4 ps_main (float2 uv : TEXCOORD2, uniform sampler FgSampler) : COLOR
{ 
 
   // ----Shader definitions and declarations ----

   float Tsin, Tcos;    // Sine and cosine of the set angle.
   float angle;

   // Position vectors
   float2 centreZoom = float2 (XzoomPos, 1.0 - YzoomPos);  // Zoom cernter
   float2 centreSpin = FRAMECENTER;                        // Position of the rotation axis
   float2 posZoom, posSpin, posFlip, posOut;

   // Direction vectors
   float2 vCrT;              // Vector between Center(rotation) and Texel
   float2 vCzT;              // Vector between Center(zoom) and Texel

  
   // ------ negative ZOOM -------
   // Used only for negative zoom settings

   vCzT = centreZoom - uv;
   posZoom = ( (1- (exp2( ZOOM * -1))) * vCzT ) + uv;      // The set value Zoom has been replaced by the formula  (1- (exp2( Zoom * -1)))   to get the setting characteristic described in the header.



   // ------ ROTATION --------

   angle = radians( (Spin * 360  +  Angle + AngleFine ) * -1.0);
   
   vCrT = uv - centreSpin;
   if (ZOOM < 0.0) vCrT = posZoom - centreSpin;
   vCrT = float2(vCrT.x * _OutputAspectRatio, vCrT.y );

   sincos (angle, Tsin , Tcos);
   posSpin = float2 ((vCrT.x * Tcos - vCrT.y * Tsin), (vCrT.x * Tsin + vCrT.y * Tcos)); 
   posSpin = float2(posSpin.x / _OutputAspectRatio, posSpin.y ) + centreSpin;



   // ------ positive ZOOM -------
   // Used only for positive zoom settings.

   vCzT = centreZoom - posSpin;
   posOut = ( (1- (exp2( ZOOM * -1))) * vCzT ) + posSpin;  // The set value Zoom has been replaced by the formula  (1- (exp2( Zoom * -1)))   to get the setting characteristic described in the header. 


 
   // ------ OUTPUT-------

   if(ZOOM < 0.0) posOut = posSpin;     // Skips the program section "positive ZOOM"
   return tex2D (FgSampler, posOut);

}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SpinZoomBorder
{
   pass P_1 < string Script = "RenderColorTarget0 = Bordered;"; > ExecuteShader (ps_edge_mode)
   pass P_2 ExecuteParam (ps_main, BorderSampler)
}

technique SpinZoomReflect
{
   pass P_1 < string Script = "RenderColorTarget0 = Mirrored;"; > ExecuteShader (ps_edge_mode)
   pass P_2 ExecuteParam (ps_main, MirrorSampler)
}

technique SpinZoomTile
{
   pass P_1 < string Script = "RenderColorTarget0 = Wrapped;"; > ExecuteShader (ps_edge_mode)
   pass P_2 ExecuteParam (ps_main, WrapSampler)
}

