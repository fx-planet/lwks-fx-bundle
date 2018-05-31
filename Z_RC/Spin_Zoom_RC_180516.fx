// @Released 2018-05-16
// @Author schrauber
// @Created 2017-10-22
// @see https://www.lwks.com/media/kunena/attachments/6375/Spin_Zoom_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Spin_Zoom_RC_180516.fx
//
// This is a simple DVE tool that just does spins and zooms.
// Created in parallel with Spin Zoom, in this version some of the parameters can be remote controlled.
// If the remote control is not to be used, make sure that nothing or only black is connected in the "RC" input.
// Rotation centring can be either set automatically or manually.
// With automatic centring if a zoom out is performed the centre of the effect will be around the centre of input image,
// otherwise it's centred on the full frame of the output video.
//
// Limitations and Known Problems :
// GPU Precision Settings "16-bit Floating Point": Not recommended for remote control (jumping angles)
//
// Compatibility of GPU Precision Settings:
// 8-bit: Ok
// "16-bit" and "32-bit Floating Point": Perfect for precise angles and smooth rotation.
//
// Updates:
// 16 May 2018 by LW user schrauber:
//   - Remote control of the position of the effect center: The setting range now corresponds to the manual setting range.
//   - Subcategory defined, renamed file name and data relevant to the homepage.
// 20 December 2017 by LW user schrauber: 
//    - Fixed missing brackets added to the revolution calculation
//    - Fixed unclear parameter setting (rotation center)
//
//
// ... More details:
//
// Remote control channels:
//    Channel 1: Revolutions
//    Channel 2: Angle
//    Channel 3: Zoom, Strength
//    Channel 4: Zoom centre, vertical
//    Channel 5: Zoom centre, horizontal
// Suitable remote controls can be found in the category "User" / Subcategory "Remote Control"
// For this, the transmitting remote control is connected to the RC input. 
// The received remote control values are added to the values set within the effect.
// To minimize the complexity of the effects settings, changing the remote control channels is not possible.
// When selecting the optional remote control, please note that it transmits on the right channels
// (for example "RC 1, Five channel remote").
// If necessary, "RC 1, Five channel remote" can also be used as a channel converter
// by remotely controlling this remote control as well.
//
// Setting characteristics of the zoom slider
//    The dimensions will be doubled or halved in setting steps of 10%:
//    -40% Dimensions / 16
//    -30% Dimensions / 8
//    -20% Dimensions / 4
//    -10% Half dimensions
//      0% No change
//     10% Double dimensions
//     20% Dimensions * 4
//     30% Dimensions * 8
//     40% Dimensions * 16
//
// Center of rotation:
// Switch between automatic centering, and manually adjustable position of the axis of rotation.
//    Automaic:
//        Zoom >= 0: rotation center = center of the output texture
//        Zoom <  0: rotation center = center of the input textur
//        For this purpose, the program sections ZOOM and ROTATION are run through in different order.
//        Zoom >= 0: first ZOOM, then ROTATION
//        Zoom <  0: first ROTATION, then ZOOM
//
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Spin Zoom, RC";
   string Category    = "DVE";
   string SubCategory = "User Effects";
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


texture RC;
sampler RcSampler = sampler_state
{
   Texture = <RC>;
   AddressU = Border;
   AddressV = Border;
   MinFilter = Point;
   MagFilter = Point;
   MipFilter = Point;
};


//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//


float Spin
<
   string Group = "Rotation";
   string Description = "Revolutions+Ch1";
   float MinVal = -62.0;
   float MaxVal = 62.0;
> = 0.0;



float Angle
<
   string Group = "Rotation";
   string Description = "Angle + Ch2";
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


int SpinCenterMode
<
   string Group = "Rotation";
   string Description = "    Rotation center:";
   string Enum = "uses manual settings     ,"
                 "Automatic mode (slider deactivated)";
> = 0;



float Xpos
<
   string Group = "Rotation";
   string Description = "Rotation centre (Slider can be deactivated)";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;


float Ypos
<
   string Group = "Rotation";
   string Description = "Rotation centre (Slider can be deactivated)";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;




float Zoom
<
   string Group = "Zoom";
   string Description = "Strength + Ch3";
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
   string Description = "Zoom centre + RC-Channel 4 and 5";
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

#define ZOOM ((Zoom + RECEIVING(3.0)) * 10 + ZoomFine / 10)
#define FRAMECENTER 0.5
     

// ---- Receiving from the remote control input -------

      #define RECEIVING(Ch)    (    (   tex2D(RcSampler, POSCHANNEL(floor(Ch))).r				/* Receiving  Red = bit 1 to bit 8 of 16Bit     ,   The value of  "Ch" (receiving channel) is only passed to sub macros  */\
                                 + ((tex2D(RcSampler, POSCHANNEL(floor(Ch))).g) / 255)				/* Green = bit 9 to bit 16   */\
                                ) * 2 - step( 0.001 , STATUS_CH_IN(Ch))  )					// Adjustment of the numeral system from  ( 0 ... 1) to (-1 ... +1)   ,  "Step" prevents a change in the received value 0.0 if the channel can not be received.  If Status Channel > 0.001  (then the adjustemnd *2-1)  ,  If the Status = 0.0 then the adjustment *2-0 

      #define STATUS_CH_IN(Ch)     ((tex2D(RcSampler, POSCHANNEL(floor(Ch)))).b)				// Status of the receiving channel ,   blue 0.0  = OFF   ,    0.2 = only Data  ,   0.4   = ON  ,   1.0 = ON and the value of the remote control signal was limited by the sending effect.   ,    The value of ChannelInput is only passed to sub macros 

         // Position of the Channel
         #define POSCHANNEL(ch)       float2 ( frac(ch / 100.0) - 0.005  ,  POSyCHANNEL(ch) + 0.01 )		// Sub macro,   Position of the pixel to be converted.  (  - 0.005 and  + 0.01 ar the center of the respective position)    ,   "ch" is the receiving channel. 
            #define POSyCHANNEL(ch)        ( (floor( ch/100.0) )/ 50.0 )					// Sub macro,   y - position of the the color signal.    50 channel groups    ,     "ch" is the receiving channel. 
 








//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//


float4 ps_main (float2 uv : TEXCOORD1, uniform sampler FgSampler) : COLOR
{ 
 
   // ----Shader definitions and declarations ----

   float Tsin, Tcos;    // Sine and cosine of the set angle.
   float angle;

   // Position vectors
   float2 centreSpin = FRAMECENTER;  
   float2 centreZoom = float2 (XzoomPos, 1.0 - YzoomPos); 
   float2 posZoom, posSpin, posFlip, posOut;

   // Direction vectors
   float2 vCrT;              // Vector between Center(rotation) and Texel
   float2 vCzT;              // Vector between Center(zoom) and Texel

  
   // ------ negative ZOOM -------
   // Used only for negative zoom settings

   vCzT = (centreZoom + float2( RECEIVING(4.0), RECEIVING(5.0))) - uv;
   posZoom = ( (1- (exp2( (ZOOM) * -1))) * vCzT ) + uv;              // The set value Zoom has been replaced by the formula  (1- (exp2( Zoom * -1)))   to get the setting characteristic described in the header.



   // ------ ROTATION --------

   if(SpinCenterMode == 0) centreSpin = float2 (Xpos, 1.0 - Ypos);  
   angle = radians((
                    ((Spin + (20.0 *  RECEIVING(1.0))) * 360 )  
                  + Angle + (RECEIVING(2.0) * 360) 
                  + AngleFine ) 
                  * -1.0);
   vCrT = uv - centreSpin;
   if (ZOOM < 0.0 && SpinCenterMode == 1 ) vCrT = posZoom - centreSpin;
   vCrT = float2(vCrT.x * _OutputAspectRatio, vCrT.y );

   sincos (angle, Tsin , Tcos);
   posSpin = float2 ((vCrT.x * Tcos - vCrT.y * Tsin), (vCrT.x * Tsin + vCrT.y * Tcos)); 
   posSpin = float2(posSpin.x / _OutputAspectRatio, posSpin.y ) + centreSpin;



   // ------ positive ZOOM -------
   // Used only for positive zoom settings.

   vCzT = (centreZoom + float2( RECEIVING(4.0)/2.0, RECEIVING(5.0)/2.0 )) - posSpin;
   posOut = ( (1- (exp2( ZOOM * -1))) * vCzT ) + posSpin;            // The set value Zoom has been replaced by the formula  (1- (exp2( Zoom * -1)))   to get the setting characteristic described in the header. 


 
   // ------ OUTPUT-------

   if(ZOOM < 0.0 && SpinCenterMode == 1) posOut = posSpin;     // Skips the program section "positive ZOOM"
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
