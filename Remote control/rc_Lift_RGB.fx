// @Released 2019-01-06
// @Author schrauber
// @Created 2017-02-01
// @see https://www.lwks.com/media/kunena/attachments/348533/RC_RGB-Lift.png


/**
This is a RGB luminance lift control.
This effect can only be influenced by a remote control.
In the effect settings of this remotely controllable effect
the channel number should be adjusted, which should control this effect. <br>
Default is:         <br>
   Red:   Channel 1 <br>
   Green: Channel 2 <br>
   Blue:  Channel 3 <br>
Please note the description of the connected remote control effect
in order to determine the relevant remote control channel.
*/


//--------------------------------------------------------------//
// Lightworks user effect rc_Lift_RGB.fx
//
// Updates:
//
// 06 January 2018 by LW user schrauber:
//    File renamed from "RC_Lift_RGB_20180421.fx"  to "rc_Lift_RGB.fx"
//    Renamed effect from "RC RGB_Lift" to "rc Lift (RGB)"
//    Category changed from "Colour" to "User"
//    Subcategory changed from "Requires remote control" to "Remote control"
//    Option for the future: Measurement option extended: fn_receiving05 (more channels, such as channel 100)
//
// 21 April 2018 by LW users schrauber: Now this effect sets the black level (dark tones or shadows).
//                                      Older versions set the offset, which does not match the definition of "lift". 
// 15 April 2018 by LW users schrauber: Lightworks category and subcategory changed
// 19 Feb 2017   by LW users schrauber: If Channel 0 is set in the effect settings, the remote control is now disabled.
// 17 Feb 2017   by LW user jwrl:       The effect now preserves the alpha channel
// 17 Feb 2017   by LW user jwrl:       Prevention of potential override of the values.
// 
//
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "rc Lift (RGB)";
   string Category    = "User";
   string SubCategory = "Remote control";
> = 0;


//-----------------------------------------------------------------------------------------//
// Inputs and Samplers
//-----------------------------------------------------------------------------------------//

texture Input;
sampler FgSampler = sampler_state
{
   Texture = <Input>;
};



texture RC;
sampler RcSampler = sampler_state
{
   Texture = <RC>;
   AddressU = Border; // If a channel position is set outside the texture (e.g., channel 0), a black border turns off the remote control
   AddressV = Border; // If a channel position is set outside the texture (e.g., channel 0), a black border turns off the remote control
   MinFilter = Point;
   MagFilter = Point;
   MipFilter = Point;
};



//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//


 
float ChRed
<
   string Description =  "Channel Red";
   float MinVal = 0.0;
   float MaxVal = 5000.0;
> = 1.0;


float ChGreen
<
   string Description =  "Channel Green";
   float MinVal = 0.0;
   float MaxVal = 5000.0;
> = 2.0;


float ChBlue
<
   string Description =  "ChannelBlue";
   float MinVal = 0.0;
   float MaxVal = 5000.0;
> = 3.0;






//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//
// The code is documented in the developer repository.
// The link to this repository can be found in the forum:
// https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=143678&Itemid=81#ftop


float fn_receiving05 (float Ch)    // Return value range: -1.0 to +1.0
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





//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//



float4 ps_main( float2 xy : TEXCOORD1 ) : COLOR
{
   float4 retval = tex2D (FgSampler, xy);

  // The following code is an inverted direction of the "RC-gain" code.
   retval.r = 1.0 - ( 
                       (1.0 - retval.r)
                      *((fn_receiving05(ChRed) * -1.0) + 1.0)
                    );


   retval.g = 1.0 - ( 
                       (1.0 - retval.g)
                      *((fn_receiving05(ChGreen) * -1.0) + 1.0)
                    );


   retval.b = 1.0 - ( 
                       (1.0 - retval.b)
                      *((fn_receiving05(ChBlue) * -1.0) + 1.0)
                    );


   return  float4(max(retval.rgb , 0.0), retval.a);
}





//--------------------------------------------------------------
// Technique
//--------------------------------------------------------------

technique main
{
   pass P_1
   {
      PixelShader = compile PROFILE ps_main();
   }
}

