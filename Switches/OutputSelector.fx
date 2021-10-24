// @Maintainer jwrl
// @Released 2021-10-24
// @Author baopao
// @Author jwrl
// @Created 2021-10-24
// @see https://www.lwks.com/media/kunena/attachments/6375/OutputSelect_640.png

/**
 This effect is a simple device to select from up to four different outputs.  It was designed
 for, and is extremely useful on complex effects builds to check the output of masking or
 cropping, the DVE setup, colour correction pass or whatever else you may need.

 Since it has very little overhead it may be safely left in situ when the effects setup
 process is complete.
*/
//-----------------------------------------------------------------------------------------//
// Lightworks user effect OutputSelector.fx
//
// This is a rewrite to support Lightworks v2021 and later of an original effect created
// by baopao (http://www.alessandrodallafontana.com/).
//
// Version history:
//
// Rewrite 2021-10-24 jwrl.
// Rewrite of the original effect to better support LW v2021 and later.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Output selector";
   string Category    = "User";
   string SubCategory = "Switches";
   string Notes       = "A simple effect to select from up to four different outputs for monitoring purposes";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (In_1, s_Input_1);
DefineInput (In_2, s_Input_2);
DefineInput (In_3, s_Input_3);
DefineInput (In_4, s_Input_4);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int GetInput
<
   string Description = "Output";
   string Enum = "In_1,In_2,In_3,In_4";
> = 0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2,
                float2 uv3 : TEXCOORD3, float2 uv4 : TEXCOORD4) : COLOR
{
   return (GetInput == 0) ? GetPixel (s_Input_1, uv1) :
          (GetInput == 1) ? GetPixel (s_Input_2, uv2) :
          (GetInput == 2) ? GetPixel (s_Input_3, uv3) : GetPixel (s_Input_4, uv4);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique OutputSelector { Pass P_1 ExecuteShader (ps_main) }

