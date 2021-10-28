// @Maintainer jwrl
// @Released 2021-10-28
// @Author jwrl
// @Created 2021-10-28
// @see https://www.lwks.com/media/kunena/attachments/6375/Zebra_640.png

/**
 This effect displays zebra patterning in over white and under black areas of the frame.
 The settings are adjustable but default to 16-239 (8 bit).  Settings display as 8 bit
 values to make setting up simpler, but in a 10-bit project they will be internally
 scaled to 10 bits.  This is consistent with other Lightworks level settings.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks effect Zebra_Stripes.fx
//
// Version history:
//
// Rewrite 2021-10-28 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Zebra pattern";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "Displays zebra patterning in over white and under black areas of the frame";
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

#define SCALE_PIXELS 66.666667   // 400.0

#define RED_LUMA     0.3
#define GREEN_LUMA   0.59
#define BLUE_LUMA    0.11

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float whites
<
   string Description = "White level";
   float MinVal = 0;
   float MaxVal = 255;
> = 235;

float blacks
<
   string Description = "Black level";
   float MinVal = 0;
   float MaxVal = 255;
> = 16;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   float4 retval = GetPixel (s_Input, uv);

   float luma = dot (retval.rgb, float3 (RED_LUMA, GREEN_LUMA, BLUE_LUMA));
   float peak_white = whites / 255.0;
   float full_black = blacks / 255.0;

   float2 xy = frac (uv * SCALE_PIXELS);

   if (luma >= peak_white) {
      retval.rgb += round (frac (xy.x + xy.y)).xxx;
      retval.rgb /= 2.0;
   }

   if (luma <= full_black) {
      retval.rgb += round (frac (xy.x + 1.0 - xy.y)).xxx;
      retval.rgb /= 2.0;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Zebra_Stripes
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main)
}

