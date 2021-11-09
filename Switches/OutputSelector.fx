// @Maintainer jwrl
// @Released 2021-11-09
// @Author baopao
// @Author jwrl
// @Created 2014-02-06
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
// by baopao (http://www.alessandrodallafontana.com/) and posted here in 2014-02-06.
//
// Version history:
//
// Update 2021-11-09 jwrl.
// Restored baopao's original SetTechnique switching instead of my conditionals.
// Also changed the output selection to read "Input 1" and so on for clarity.
// Finally, restored baopao's original creation date in the header.  It should never
// have been changed.
//
// Rewrite 2021-10-24 jwrl.
// Rewrite of the original effect to better support LW v2021 and later.
// Main visible change is inputs are now "In_1", "In_2" and so on instead of baopao's
// original "Inp_Out_1", "Inp_Out_2" etc.  The longer names corrupt the routing display.
// Correct TEXCOORD numbers have been used instead of TEXCOORD1 for all inputs.  This
// is important because we cannot guarantee all inputs will have the same coordinates.
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

int SetTechnique
<
   string Description = "Output";
   string Enum = "Input 1,Input 2,Input 3,Input 4";
> = 0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Input_1, uv) }

float4 ps_main_2 (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_Input_2, uv) }

float4 ps_main_3 (float2 uv : TEXCOORD3) : COLOR { return GetPixel (s_Input_3, uv) }

float4 ps_main_4 (float2 uv : TEXCOORD4) : COLOR { return GetPixel (s_Input_4, uv) }

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique OutputSelector_1 { Pass P_1 ExecuteShader (ps_main_1) }

technique OutputSelector_2 { Pass P_2 ExecuteShader (ps_main_2) }

technique OutputSelector_3 { Pass P_3 ExecuteShader (ps_main_3) }

technique OutputSelector_4 { Pass P_4 ExecuteShader (ps_main_4) }

