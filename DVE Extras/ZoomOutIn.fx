// @Maintainer jwrl
// @Released 2018-12-23
// @Author schrauber
// @Created 2016-07-01
// @see https://www.lwks.com/media/kunena/attachments/6375/zoom-out-in_640.png
// @see https://www.lwks.com/media/kunena/attachments/348533/temp0823410.PNG
// @see https://www.youtube.com/watch?v=weSAKIDkWwk

/**
This is a zoom effect designed to allow zooming at frame edge without going outside
the frame.  With this effect it should be unnecessary to dynamically adjust the effect
position to prevent overrun because the interface is extremely simple.  You should do
any fine adjustment of position at maximum zoom used to prevent centring problems.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ZoomOutIn.fx
//
// Update 20 July 2017 jwrl:
// Changed category to DVE, added subcategory.
//
// Modified 7 April 2018 by jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// GitHub-relevant modification, 18 April 2018 schrauber
//
// Modified jwrl 2018-12-23:
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Zoom out, zoom in ";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "This is an effect which allows zooming without going outside the frame boundary";
> = 0;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float zoom
<
   string Description = "zoom";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float Xpos
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ypos
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

//-----------------------------------------------------------------------------------------//
// Input and shader
//-----------------------------------------------------------------------------------------//

texture Input;

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 universal (float2 xy : TEXCOORD1) : COLOR 
{ 

 float2 XYc = float2 (Xpos, 1.0 - Ypos);
 float2 xy1 = XYc - xy;

 xy1 = zoom * xy1 + xy;   

 return tex2D (FgSampler, xy1); 
} 

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique ZoomOutIn
{
   pass SinglePass
   {
      PixelShader = compile PROFILE universal();
   }
}
