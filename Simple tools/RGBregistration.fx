// @Maintainer jwrl
// @Released 2020-05-18
// @Author jwrl
// @Created 2020-05-18
// @see https://www.lwks.com/media/kunena/attachments/6375/RGBregistration_640.png

/**
 This is a simple effect to allow removal or addition of the sorts of colour registration
 errors that you can get with the poor debayering of cheap single chip cameras.  It can
 also be used if you want to emulate some of the colour registration problems that older
 analogue cameras and TVs produced.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBregistration.fx
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RGB registration";
   string Category    = "Stylize";
   string SubCategory = "Simple tools";
   string Notes       = "Adjusts the X-Y registration of the RGB channels of a video stream";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and shader
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input  = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Xdisplace
<
   string Description = "R-B displacement";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -0.05;
   float MaxVal = 0.05;
> = 0.0;

float Ydisplace
<
   string Description = "R-B displacement";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -0.05;
   float MaxVal = 0.05;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY   0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler S, float2 p)
{
   return (p.x < 0.0) || (p.y < 0.0) || (p.x > 1.0) || (p.y > 1.0) ? EMPTY : tex2D (S, p);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = float2 (Xdisplace, Ydisplace);

   float4 Input  = tex2D (s_Input, uv);
   float4 retval = float4 (fn_tex2D (s_Input, uv - xy).r, Input.g,
                           fn_tex2D (s_Input, uv + xy).b, Input.a);

   return lerp (Input, retval, Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique RGBregistration
{
   pass P1
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
