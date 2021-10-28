// @Maintainer jwrl
// @Released 2021-10-28
// @Author khaver
// @Created 2011-05-05
// @see https://www.lwks.com/media/kunena/attachments/6375/Expand16_235_640.png

/**
 This is one of three tools to manage broadcast colour space.  The names are self-explanatory.
 They install into the custom category "User", subcategory "Technical".
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Expand_16_235.fx
//
// Version history:
//
// Update 2021-10-28 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Expand 16-235 to 0-255";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "Expands legal video levels to full gamut RGB";
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
// Parameters
//-----------------------------------------------------------------------------------------//

bool superwhite
<
	string Description = "Keep super whites";
> = false;

bool superblack
<
	string Description = "Keep super blacks";
> = false;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float highc = 20.0 / 255.0;
   float lowc = 16.0 / 255.0;
   float scale = 255.0 / 219.0;

   float4 color = GetPixel (s_Input, uv);
   float4 newcolor = (color-lowc) * scale;

   if (superwhite && !superblack) {
      scale = 255.0 / 239.0;
      newcolor = (color - lowc) * scale;
   }

   if (!superwhite && superblack) {
      scale = scale = 255.0 / 235.0;
      newcolor = ((color - highc) * scale) + highc;
   }

   if (superwhite && superblack) newcolor = color;

   if (newcolor.r > 1.0) newcolor.r = 1.0;
   if (newcolor.g > 1.0) newcolor.g = 1.0;
   if (newcolor.b > 1.0) newcolor.b = 1.0;
   if (newcolor.a > 1.0) newcolor.a = 1.0;
   if (newcolor.r < 0.0) newcolor.r = 0.0;
   if (newcolor.g < 0.0) newcolor.g = 0.0;
   if (newcolor.b < 0.0) newcolor.b = 0.0;
   if (newcolor.a < 0.0) newcolor.a = 0.0;

   return newcolor;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Expand16_235 { pass p0 ExecuteShader (ps_main) }

