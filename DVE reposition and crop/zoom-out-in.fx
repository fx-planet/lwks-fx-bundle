// @Maintainer jwrl
// @Released 2018-04-07
// @Author schrauber
// @see https://www.lwks.com/media/kunena/attachments/348533/temp0823410.PNG
//-----------------------------------------------------------------------------------------//
// Lightworks user effect zoom-out-in.fx
//
// This is a zoom effect designed to allow zooming at frame edge without going outside
// the frame.  With this effect it should be unnecessary to dynamically adjust the
// effect position to prevent overrun because the interface is extremely simple.  You
// should do any fine adjustment of position at maximum zoom used to prevent centring
// problems.
//
// Modified 20 July 2017 by jwrl.
// Changed category to DVE, added subcategory.
//
// Modified 7 April 2018 by jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "zoom out, zoom in ";
   string Category    = "DVE";
   string SubCategory = "User Effects";
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
