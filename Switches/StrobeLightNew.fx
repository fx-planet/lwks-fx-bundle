// @Maintainer jwrl
// @Released 2020-09-28
// @Author jwrl
// @Created 2018-03-31
// @see https://www.lwks.com/media/kunena/attachments/6375/NewStrobe_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Newstrobe.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/Newstrobe1.mp4

/**
 Development of this effect was triggered by khaver's "Strobe light" effect, but uses
 the newer Lightworks variables to set the strobe rate accurately in frames, not as a
 percentage of progress.  While the logic for the older versions is similar to that in
 khaver's effect, the implementation is entirely my own.

 The legacy version incorporated in this effect can never be truly frame accurate,
 since it operates by scaling the effect's progress.  This makes the effect forward
 compatible, i.e., if it is compiled in version 14.0 then subsequently used in 14.5 it
 will work, but without frame accuracy.  It isn't fully backward compatible because it
 won't work at all if it is compiled under 14.5 then used in 14.0.
*/

//-------------------------------------------------------------------------------------//
// Lightworks user effect StrobeLightNew.fx
//
// Version history:
//
// Update 2020-09-28 jwrl.
// Revised header block.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 6 December 2018 jwrl.
// Changed effect name from "New strobe" to "Strobe light new".
// Changed category and subcategory.
//
// Modified 29 September 2018 jwrl.
// Added notes to header.
//
// Updated 2018-05-23:
// Added a means of turning the background off and replacing it with black.  This
// should help the drag and drop multitrack editors.
//
// Moderated 2018-05-02:
// Changed user interface to refer to "Flash" settings rather than "Strobe".  This
// more accurately reflects what's going on.  This required a change to the .PNG
// files referenced in the header.  They are now a single file incorporating both
// user interfaces.  Finally, the effect has been posted on the main forums.
//-------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Strobe light new";
   string Category    = "User";
   string SubCategory = "Switches";
   string Notes       = "This strobe effect when compiled and run in version 14.5 or higher is frame accurate";
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

int SetBgd
<
   string Description = "Vision seen when flash is off";
   string Enum = "Background,Black";
> = 0;

float FrameRate
<
   string Description = "Flash frame rate";
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

   return SetBgd == 0 ? tex2D (s_Bgnd, uv) : float2 (0.0, 1.0).xxxy;
}

#else

//-------------------------------------------------------------------------------------//
// Parameters for legacy version
//-------------------------------------------------------------------------------------//

int StrobeBgd
<
   string Description = "Flash off vision";
   string Enum = "Background input,Black";
> = 0;

float StrobeDuration
<
	string Description = "Flash duration";
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

   return StrobeBgd == 0 ? tex2D (s_Bgnd, uv) : float2 (0.0, 1.0).xxxy;
}

#endif

//-------------------------------------------------------------------------------------//
// Technique
//-------------------------------------------------------------------------------------//

technique StrobeLightNew
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}
