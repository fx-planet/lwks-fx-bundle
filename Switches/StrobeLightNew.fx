// @Maintainer jwrl
// @Released 2021-10-24
// @Author jwrl
// @Created 2021-10-24
// @see https://www.lwks.com/media/kunena/attachments/6375/StrobeLightNew_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Newstrobe.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/Newstrobe1.mp4

/**
 Development of this effect was triggered by khaver's "Strobe light" effect, but uses
 the newer Lightworks variables to set the strobe rate accurately in frames, not as a
 percentage of progress.  This means that flash timing will be accurate regardless of
 the actual length of the clips to which it is applied.  It also handles foreground
 and background components at their native resolutions if the Lightworks version used
 supports that.

 Because this version is designed specifically for Lightworks versions 2021 and higher
 it does not support versions prior to 14.5 at all.  StrobeLight.fx by khaver will do
 that if you need to work with earlier Lightworks versions.
*/

//-------------------------------------------------------------------------------------//
// Lightworks user effect StrobeLightNew.fx
//
// Version history:
//
// Rewrite 2021-10-24 jwrl.
// Complete rewrite of original pre-2021 effect to better support LW v2021 and later.
//-------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Strobe light new";
   string Category    = "User";
   string SubCategory = "Switches";
   string Notes       = "This strobe effect is for LW 2021 or later";
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _Progress;
float _LengthFrames;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

//-------------------------------------------------------------------------------------//
// Parameters
//-------------------------------------------------------------------------------------//

int SetBgd
<
   string Description = "Vision seen when flash is off";
   string Enum = "Background,Black";
> = 0;

float FrameRate
<
   string Description = "Flash frame rate";
   float MinVal = 1.0;
   float MaxVal = 60.0;
> = 1.0;

bool SwapStart
<
   string Description = "Swap start frame";
> = false;

//-------------------------------------------------------------------------------------//
// Shader
//-------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float frame = floor ((_LengthFrames * _Progress) + 0.5);

   bool flash = frac (floor (frame / max (round (FrameRate), 1.0)) * 0.5);

   flash = ((flash && SwapStart) || (!flash && !SwapStart));

   return flash ? GetPixel (s_Foreground, uv1)
                : SetBgd ? BLACK : GetPixel (s_Background, uv2);
}

//-------------------------------------------------------------------------------------//
// Technique
//-------------------------------------------------------------------------------------//

technique StrobeLightNew { pass P_1 ExecuteShader (ps_main) }

