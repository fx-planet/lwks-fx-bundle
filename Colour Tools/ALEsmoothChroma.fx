// @Maintainer jwrl
// @Released 2021-08-18
// @Author baopao
// @Created 2013-06-03
// @see https://www.lwks.com/media/kunena/attachments/6375/ALE_SmoothChroma_640.png

/**
 This smooths the colour component of video media.  Its most appropriate use is probably
 to smooth chroma in 4:2:0 footage.  It works by converting the RGB signal to YCbCr then
 blurs just the chroma Cb/Cr components.  The result is then converted back to RGB using
 the original Y channel.  This ensures that luminance sharpness is maintained and just
 the colour component is softened.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ALEsmoothChroma.fx
//
// Feedback should be to http://www.alessandrodallafontana.com/ 
//
// Version history:
//
// Update 2021-08-18 jwrl:
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//


int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "ALE smooth chroma";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "This smooths the colour component of video media leaving the luminance unaffected";
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
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (fg, s_Foreground);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float BlurAmount
<
   string Description = "BlurAmount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1 ) : COLOR
{
   float4 ret = saturate (GetPixel (s_Foreground, xy1));
   float4 ret_NoBlur = ret;

   float amount = BlurAmount * 0.01;

   float4 blurred = ret;

   blurred += GetPixel (s_Foreground, xy1 + float2 (-amount,  0.0));
   blurred += GetPixel (s_Foreground, xy1 + float2 ( amount,  0.0));
   blurred += GetPixel (s_Foreground, xy1 + float2 ( 0.0, -amount));
   blurred += GetPixel (s_Foreground, xy1 + float2 ( 0.0,  amount));
   blurred += GetPixel (s_Foreground, xy1 + float2 (-amount * 2.0,  0.0));
   blurred += GetPixel (s_Foreground, xy1 + float2 ( amount * 2.0,  0.0));
   blurred += GetPixel (s_Foreground, xy1 + float2 ( 0.0, -amount*2));
   blurred += GetPixel (s_Foreground, xy1 + float2 ( 0.0,  amount*2));
   blurred /= 9.0;

   ret = blurred;

   //RGB2YCbCr
  
   float Y = 0.065 +  (ret_NoBlur.r * 0.257) +  (ret_NoBlur.g * 0.504) +  (ret_NoBlur.b * 0.098);
   float Cb = 0.5 -  (ret.r * 0.148) -  (ret.g * 0.291) +  (ret.b * 0.439);
   float Cr = 0.5 +  (ret.r * 0.439) -  (ret.g * 0.368) -  (ret.b * 0.071);

   //YCbCr2RGB   

   float4 o_color;

   o_color.r = 1.164 * (Y - 0.065) + 1.596 * (Cr - 0.5);
   o_color.g = 1.164 * (Y - 0.065) - 0.813 * (Cr - 0.5) - 0.392 * (Cb - 0.5);
   o_color.b = 1.164 * (Y - 0.065) + 2.017 * (Cb - 0.5);
   o_color.a = 1.0;

   return saturate (o_color);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique singletechnique { pass Single_Pass ExecuteShader (ps_main) }

