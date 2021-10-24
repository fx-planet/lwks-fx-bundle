// @Maintainer jwrl
// @Released 2021-10-24
// @Author khaver
// @Created 2014-11-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Strobe_640.png

/**
 Strobe is a two-input effect which switches rapidly between two video layers.  The switch
 rate is dependent on the length of the clip.  There should be enough adjustment range of
 strobe spacing to allow any reasonable clip size to be used, but if you need more range
 break the clip into sections and repeat the effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect StrobeLight.fx
//
// Version history:
//
// Update 2021-10-24 jwrl.
// Update of the original effect to better support LW v2021 and later.  It will still
// work with earlier versions.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Strobe light";
   string Category    = "User";
   string SubCategory = "Switches";
   string Notes       = "Strobe is a two-input effect which switches rapidly between two video layers";
   bool CanSize       = false;
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

float _Progress;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (fg, s_Foreground);
DefineInput (bg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool swap
<
   string Description = "Swap";
> = false;

float strobe
<
   string Description = "Strobe Spacing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 FG, BG;

   if (swap) {
      FG = GetPixel (s_Foreground, uv1);
      BG = GetPixel (s_Background, uv2);
   }
   else {
      BG = GetPixel (s_Foreground, uv1);
      FG = GetPixel (s_Background, uv2);
   }

   return (frac (ceil (_Progress / strobe) / 2.0) == 0.0) ? FG : BG;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique StrobeLight { Pass P_1 ExecuteShader (ps_main) }

