// @Maintainer jwrl
// @Released 2021-10-28
// @Author khaver
// @Created 2011-05-05
// @see https://www.lwks.com/media/kunena/attachments/6375/Shrink16_235_640.png

/**
 This is one of three tools to manage broadcast colour space.  The names are self-explanatory.
 They install into the custom category "User", subcategory "Technical".
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Shrink_16_235.fx
//
// Version history:
//
// Update 2021-10-28 jwrl.
// Updated the original effect to better support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Shrink 0-255 to 16-235";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "Shrinks full gamut RGB signals to broadcast legal video";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Input and shader
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float highc = 235.0 / 255.0;
   float lowc = 16.0 / 255.0;
   float scale = 255.0 / 219.0;

   float4 color = GetPixel (s_Input, uv);

   color = (color / scale) + lowc;

   if (color.r > highc) color.r = highc;
   if (color.g > highc) color.g = highc;
   if (color.b > highc) color.b = highc;
   if (color.a > highc) color.a = highc;
   if (color.r < lowc) color.r = lowc;
   if (color.g < lowc) color.g = lowc;
   if (color.b < lowc) color.b = lowc;
   if (color.a < lowc) color.a = lowc;

   return color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Shrink16_235 { pass p0 ExecuteShader (ps_main) }

