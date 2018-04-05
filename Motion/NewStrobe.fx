// @Maintainer jwrl
// @Released 5 April 2018
// @Author jwrl
// @Created 31 March 2018
// @see https://www.lwks.com/media/kunena/attachments/6375/NewStrobe_UI.png
// @see https://www.lwks.com/media/kunena/attachments/6375/NewStrobe_oldUI.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Newstrobe.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/Newstrobe1.mp4
//-------------------------------------------------------------------------------------//
// Lightworks user effect NewStrobe.fx
//
// Development of this effect was triggered by khaver's "Strobe" effect, but uses the
// newer Lightworks variables to set the strobe rate accurately in frames, not as a
// percentage of progress.  While the logic in some respects is similar to khaver's
// the implementation is entirely my own.
//
// Legacy support for older versions has been provided by incorporating a version
// loosely based on the algorithm that khaver used, but again, the implementation is
// my own.  This legacy version can never be truly frame accurate, since it operates
// by scaling the effect's progress.  This makes the effect forward compatible, i.e.,
// if it is compiled in version 14.0 then subsequently used in 14.5 it will work, but
// without frame accuracy.  It isn't fully backward compatible because it won't work
// at all if it is compiled under 14.5 then used in 14.0.
//-------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "New strobe";
   string Category    = "Stylize";
   string SubCategory = "User Effects";
> = 0;

//-------------------------------------------------------------------------------------//
// Preamble - sets version flag
//-------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define LW_14_5_PLUS
#endif

#ifdef LINUX
#define LW_14_5_PLUS
#endif

#ifdef OSX
#define LW_14_5_PLUS
#endif

//-------------------------------------------------------------------------------------//
// Inputs
//-------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-------------------------------------------------------------------------------------//
// Samplers
//-------------------------------------------------------------------------------------//

sampler s_Fgnd = sampler_state {
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Bgnd = sampler_state {
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-------------------------------------------------------------------------------------//
// Definitions and declarations
//-------------------------------------------------------------------------------------//

float _Progress;

#ifdef LW_14_5_PLUS

float _LengthFrames;

//-------------------------------------------------------------------------------------//
// Parameters for version 14.5+
//-------------------------------------------------------------------------------------//

float FrameRate
<
   string Description = "Strobe frame rate";
   float MinVal = 1;
   float MaxVal = 60;
> = 1.0;

bool SwapStart
<
   string Description = "Swap start frame";
> = false;

//-------------------------------------------------------------------------------------//
// Shader for version 14.5+
//-------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float frame = floor ((_LengthFrames * _Progress) + 0.5);

   bool flash = frac (floor (frame / max (round (FrameRate), 1.0)) * 0.5) == 0.0;

   if ((SwapStart && !flash) || (flash && !SwapStart)) return tex2D (s_Fgnd, uv);

   return tex2D (s_Bgnd, uv);
}

#else

//-------------------------------------------------------------------------------------//
// Parameters for legacy version
//-------------------------------------------------------------------------------------//

float StrobeDuration
<
	string Description = "Strobe duration";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.1;

bool SwapFirst
<
   string Description = "Swap start frame";
> = false;

//-------------------------------------------------------------------------------------//
// Shader for legacy version
//-------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   bool strobe = frac (ceil (_Progress / StrobeDuration) * 0.5) == 0.0;

   if ((SwapFirst && !strobe) || (strobe && !SwapFirst)) return tex2D (s_Fgnd, uv);

   return tex2D (s_Bgnd, uv);
}

#endif

//-------------------------------------------------------------------------------------//
// Technique
//-------------------------------------------------------------------------------------//

technique NewStrobe
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}

