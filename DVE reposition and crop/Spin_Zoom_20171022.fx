//--------------------------------------------------------------//
// Lightworks user effect Spin_Zoom_20171022
//
// Created by LW user schrauber 22 October 2017
// @Author: schrauber
// @CreationDate: "22 October 2017"
// 
// The rotation code is based on the spin-dissolve effects of the user "jwrl".
// The zoom code is based on the zoom out, zoom in effect of the user "schrauber".
//
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
//        For this purpose, the program sections ZOOM and ROTATION are run through in different order.
//        Zoom >= 0: first ZOOM, then ROTATION
//        Zoom <  0: first ROTATION, then ZOOM
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Spin Zoom";  
   string Category    = "DVE"; 
> = 0;





//--------------------------------------------------------------//
// Inputs und Samplers
//--------------------------------------------------------------//


texture Input;
sampler BorderSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Border;
   AddressV  = Border;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};


texture Mirrored : RenderColorTarget;
sampler MirrorSampler = sampler_state
{
   Texture   = <Mirrored>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};


texture Wrapped : RenderColorTarget;
sampler WrapSampler = sampler_state
{
   Texture   = <Wrapped>;
   AddressU  = Wrap;
   AddressV  = Wrap;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};




//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//


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






//--------------------------------------------------------------//
// Common definitions, declarations, macros
//--------------------------------------------------------------//

float _OutputAspectRatio;

#define ZOOM (Zoom * 10 + ZoomFine / 10)
#define FRAMECENTER 0.5
     








//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//


float4 ps_main (float2 uv : TEXCOORD1, uniform sampler FgSampler) : COLOR
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
   posZoom = ( (1- (exp2( ZOOM * -1))) * vCzT ) + uv;            // The set value Zoom has been replaced by the formula  (1- (exp2( Zoom * -1)))   to get the setting characteristic described in the header.



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
   posOut = ( (1- (exp2( ZOOM * -1))) * vCzT ) + posSpin;            // The set value Zoom has been replaced by the formula  (1- (exp2( Zoom * -1)))   to get the setting characteristic described in the header. 


 
   // ------ OUTPUT-------

   if(ZOOM < 0.0) posOut = posSpin;     // Skips the program section "positive ZOOM"
   return tex2D (FgSampler, posOut);

}




// .............................................................




float4 ps_edge_mode (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (BorderSampler, uv);
}




//--------------------------------------------------------------
// Technique
//--------------------------------------------------------------


technique SpinZoomBorder
{
   pass P_1 { PixelShader = compile PROFILE ps_main (BorderSampler); }
}

technique SpinZoomReflect
{
   pass P_1 < string Script = "RenderColorTarget0 = Mirrored;"; >    { PixelShader = compile PROFILE ps_edge_mode (); }
   pass P_2 { PixelShader = compile PROFILE ps_main (MirrorSampler); }
}

technique SpinZoomTile
{
   pass P_1 < string Script = "RenderColorTarget0 = Wrapped;"; >    { PixelShader = compile PROFILE ps_edge_mode (); }
   pass P_2 { PixelShader = compile PROFILE ps_main (WrapSampler); }
}

