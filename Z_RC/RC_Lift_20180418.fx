// @Maintainer jwrl
// @Released 2018-04-18
// @Author schrauber
// @Created 2017-02-01
// @Version: 2.0
// exceptional aspect ratio. https://www.lwks.com/media/kunena/attachments/348533/RCLiftnew.JPG
//--------------------------------------------------------------//
// Lightworks user effect RC_Lift_20180418.fx
//
// This is a simple luminance lift control.
// This effect can only be influenced by a remote control.
//
// Suitable remote controls can be found in the category "User" / Subcategory "Remote Control"
// For this, the transmitting remote control is connected to the RC input. 
// In the effect settings of this remotely controllable effect
// the channel number should be adjusted, which should control this effect. 
// Please note the description of the connected remote control effect
// in order to determine the relevant remote control channel.
//
// Updates:
// 18 April 2018 by LW users schrauber: Now this effect sets the black level (dark tones or shadows).
//                                      Older versions set the offset, which does not match the definition of "lift". 
// 18 April 2018 by LW users schrauber: Lightworks category and subcategory changed
// 19 Feb 2017   by LW users schrauber: If Channel 0 is set in the effect settings, the remote control is now disabled.
// 17 Feb 2017   by LW user jwrl:       The effect now preserves the alpha channel
// 17 Feb 2017   by LW user jwrl:       Prevention of potential override of the values.
// 
//
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RC_Lift";
   string Category    = "Colour";
   string SubCategory = "Requires remote control";
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
   AddressU = Border; //If a channel position is set outside the texture (e.g., channel 0), a black border turns off the remote control
   AddressV = Border; //If a channel position is set outside the texture (e.g., channel 0), a black border turns off the remote control
   MinFilter = Point;
   MagFilter = Point;
   MipFilter = Point;
};




//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Ch
<
   string Description =  "Channel";
   float MinVal = 1.0;
   float MaxVal = 5000.0;
> = 1.0;








//-----------------------------------------------------------------------------------------//
// Macros
//-----------------------------------------------------------------------------------------//

// Receiving scalar value from the remote control input
// The documentation for the macro RECEIVING (Ch), and the associated sub-macros, can be found in the subcode repository.

   #define RECEIVING(Ch)    (    (   tex2D(RcSampler, POSCHANNEL(floor(Ch))).r \
                              + ((tex2D(RcSampler, POSCHANNEL(floor(Ch))).g) / 255) \
                             ) * 2 - step( 0.001 , STATUS_CH_IN(Ch))  )
                             
   #define STATUS_CH_IN(Ch)     ((tex2D(RcSampler, POSCHANNEL(floor(Ch)))).b)            
            
      #define POSCHANNEL(ch)       float2 ( frac(ch / 100.0) - 0.005  ,  POSyCHANNEL(ch) + 0.01 )        
         #define POSyCHANNEL(ch)        ( (floor( ch/100.0) )/ 50.0 )







//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//



float4 ps_main( float2 xy : TEXCOORD1 ) : COLOR
{
   float4 retval = tex2D (FgSampler, xy);

  // The following code is an inverted direction of the "RC-gain" code.
   return 
      saturate
         (
            float4(
                     1.0 - (
                              (1.0 - retval.rgb)
                             *((RECEIVING(Ch) * -1.0) + 1.0)
                           ), retval.a
                  )
         );
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
