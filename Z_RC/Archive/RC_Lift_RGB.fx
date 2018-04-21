// @Maintainer jwrl
// @Released 2017-02-19
// @Author schrauber
// @Created 2017-02-01
// @Version: 1.2
//--------------------------------------------------------------//
// Lightworks user effect RC_Lift_RGB.fx
//
// Warning: This effect of 19 February 2017 has been withdrawn.
//
// Reason: Instead of a black value setting,
// this effect sets the offset of the RGB values,
// which does not match the definition of "lift".
//
// Using this outdated file only makes sense to restore the effect in old projects.
// Otherwise, please use the current version of this effect.
// 
//
//--------------------------------------------------------------//
// Information for Effect Developer:
// 
// This version modified by jwrl to preserve the alpha channel
// and range limit the returned levels 17 February 2017.
//
// 19 Febuary 2017; modified by user "schrauber": RcSampler settings, Clamp changed to Border
//                  and the setting range of the sliders changed from "MinVal = 1.0" to 0.0.
//
// 21 April 2018 modified for archive by LW users schrauber:
//  Effectname, category and subcategory, @Released etc.


//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RC RGB-Lift -old-";
   string Category    = "Colour";
   string SubCategory = "Withdrawn";
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

   return  float4 (min (retval.r + RECEIVING(ChRed), 1.0),
                   min (retval.g + RECEIVING(ChGreen), 1.0),
                   min (retval.b + RECEIVING(ChBlue), 1.0),
                   retval.a);
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

