// @Released 2019-01-06
// @Author schrauber
// @Created 2017-10-22
// @see https://www.lwks.com/media/kunena/attachments/6375/Spin_Zoom_640.png

/**
This is a simple DVE tool that just does spins and zooms.
Created in parallel with Spin Zoom, in this version some of the parameters can be remote controlled.
If the remote control is not to be used, make sure that nothing or only black is connected in the "RC" input.
Rotation centring can be either set automatically or manually.
With automatic centring if a zoom out is performed the centre of the effect will be around the centre of input image,
otherwise it's centred on the full frame of the output video.  <br>
 <br>
Remote control channels: <br>
   Channel 1: Revolutions <br>
   Channel 2: Angle <br>
   Channel 3: Zoom, Strength <br>
   Channel 4: Zoom centre, vertical <br>
   Channel 5: Zoom centre, horizontal <br>
The received remote control values are added to the values set within the effect.
In order to minimize the complexity of the effect settings, a change of the remote control channels is not possible.
When selecting the optional remote control, please note that it transmits on the right channels <br>
 <br>
Compatibility of GPU Precision (Project settings):  <br>
A higher precision than 8-bit is recommended to make angle changes precise and fluent. <br>
Version note: This revised version now better supports the new 
"16-bit floating point" GPU setting than before August 2018. 
This is especially true for remote-controlled rotation. 
*/



//-----------------------------------------------------------------------------------------//
// Lightworks user effect rc_SpinZoom.fx
//
// Updates:
//
// 06 January 2018 by LW user schrauber:
// File renamed from "Spin_Zoom_RC_180516.fx"  to "rc_SpinZoom.fx"
// Renamed effect from "Spin Zoom, RC" to "rc Spin zoom"
// Category changed from "DVE" to "User"
// Subcategory changed from "User Effects" to "Remote control"
//
// 30 August 2018 by LW user schrauber:
//   - Increased precision of remote control (GPU precision setting: "16-bit floating point")
//
// 16 May 2018 by LW user schrauber:
//   - Remote control of the position of the effect center: The setting range now corresponds to the manual setting range.
//   - Subcategory defined, renamed file name and data relevant to the homepage.
//
// 20 December 2017 by LW user schrauber: 
//    - Fixed missing brackets added to the revolution calculation
//    - Fixed unclear parameter setting (rotation center)
//
// Details:
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
   string Description = "rc Spin zoom";
   string Category    = "User";
   string SubCategory = "Remote control";
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
// Functions
//--------------------------------------------------------------//
// The code of this function is documented in the developer repository.
// The link to this repository can be found in the forum:
// https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=143678&Itemid=81#ftop

float fn_receiving05 (float Ch)
{
   float  ch    = floor(Ch) - 1.0;
   float  posY  = floor(ch/100.0) / 50.0;
   float2 pos   = float2 ( frac(ch / 100.0) + 0.005  ,  posY + 0.01 );
  
   float4 sample = tex2D (RcSampler, pos );
   float status = sample.b;
   float ret = round (sample.r * 255.0) / 255.0
             + sample.g / 255.0;
   ret = status > 0.001 ? ret * 2.0 -1.0 : 0.0;

   return ret;
}



//--------------------------------------------------------------//
// Common definitions, declarations, macros
//--------------------------------------------------------------//

float _OutputAspectRatio;

#define ZOOM ((Zoom + fn_receiving05(3.0)) * 10.0 + ZoomFine / 10.0)
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
   float2 centreSpin = FRAMECENTER;  
   float2 centreZoom = float2 (XzoomPos, 1.0 - YzoomPos); 
   float2 posZoom, posSpin, posFlip, posOut;

   // Direction vectors
   float2 vCrT;              // Vector between Center(rotation) and Texel
   float2 vCzT;              // Vector between Center(zoom) and Texel

  
   // ------ negative ZOOM -------
   // Used only for negative zoom settings

   vCzT = (centreZoom + float2( fn_receiving05(4.0), fn_receiving05(5.0))) - uv;
   posZoom = ( (1- (exp2( (ZOOM) * -1))) * vCzT ) + uv;              // The set value Zoom has been replaced by the formula  (1- (exp2( Zoom * -1)))   to get the setting characteristic described in the header.



   // ------ ROTATION --------

   if(SpinCenterMode == 0) centreSpin = float2 (Xpos, 1.0 - Ypos);  
   angle = radians((
                    ((Spin + (20.0 *  fn_receiving05(1.0))) * 360 )  
                  + Angle + (fn_receiving05(2.0) * 360) 
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

   vCzT = (centreZoom + float2( fn_receiving05(4.0)/2.0, fn_receiving05(5.0)/2.0 )) - posSpin;
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
