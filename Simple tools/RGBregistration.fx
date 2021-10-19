// @Maintainer jwrl
// @Released 2021-10-19
// @Author jwrl
// @Created 2021-10-19
// @see https://www.lwks.com/media/kunena/attachments/6375/RGBregistration_640.png

/**
 This is a simple effect to allow removal or addition of the sorts of colour registration
 errors that you can get with the poor debayering of cheap single chip cameras.  It can
 also be used if you want to emulate some of the colour registration problems that older
 analogue cameras and TVs produced.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBregistration.fx
//
// Version history:
//
// Rewrite 2021-10-19 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RGB registration";
   string Category    = "Stylize";
   string SubCategory = "Simple tools";
   string Notes       = "Adjusts the X-Y registration of the RGB channels of a video stream";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Input and shader
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);

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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   float2 xy = float2 (Xdisplace, Ydisplace);

   float4 Input  = tex2D (s_Input, uv);
   float4 retval = Input;

   retval.rb = float2 (tex2D (s_Input, uv - xy).r, tex2D (s_Input, uv + xy).b);

   return lerp (Input, retval, Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique RGBregistration
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main)
}

