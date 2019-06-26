// @Maintainer jwrl
// @Released 2019-04-10
// @Author jwrl
// @Created 2019-04-10
// @see https://www.lwks.com/media/kunena/attachments/6375/LightningFlash_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LightningFlash.mp4

/**
 As the name says, this is a lightning flash effect.  The number of flash cycles can be
 adjusted from one to five and the flash duration can bet set from one to three frames.
 A colour cast can be added to the flash - blue for high energy, purple for even higher
 energy would probably be good - and the duration of the fade back to normal can be set
 from two to thirty frames.  Although decimal numbers of frames can be entered they will
 always round to the nearest available whole number.

 This is not designed as a transition so it is up to the user to ensure that there is
 room for the effect to function fully.  The required duration will be double the number
 of flashes times the flash duration plus the fade duration minus one.  For example,
 three one frame flashes with a fade duration of six frames will need eleven frames to
 fully function.  Once the flash sequence fade ends it will not affect the image further
 and can be left in place.

 NOTE: THIS EFFECT WILL ONLY COMPILE ON VERSIONS OF LIGHTWORKS LATER THAN 14.0.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LightningFlash.fx
//
// Original version - no amendments (yet).
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lightning flash";
   string Category    = "Stylize";
   string SubCategory = "Special Effects";
   string Notes       = "Simulates a high energy lightning flash at the cut point";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int FlashCycle
<
   string Description = "Number of flash cycles";
   string Enum = "1 flash,2 flashes,3 flashes,4 flashes,5 flashes"; 
> = 2;

int FlashDuration
<
   string Description = "Duration of flashes";
   string Enum = "1 frame,2 frames,3 frames"; 
> = 0;

float FadeAmount
<
   string Description = "Fade (in frames)";
   float MinVal = 2.0;
   float MaxVal = 30.0;
> = 6.0;

float4 ColourCast
<
   string Description = "Colour cast";
   bool SupportsAlpha = false;
> = { 0.33, 0.67, 1.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH            // Only available in version 14.5 and up
Wrong_LW_version           // Forces a compiler error if the Lightworks version is wrong.
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0     // Not really necessary, but a better profile for Windows.
#endif

float _LengthFrames;
float _Progress;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 video = tex2D (s_Input, uv);
   float4 flash = float4 ((ColourCast.rgb * 0.2) + 0.8.xxx, 1.0);
   float4 ngtve = float4 (flash.rgb - pow ((video.r + video.g + video.b) / 3.0, 1.5).xxx, 1.0);

   float frame = floor ((_LengthFrames * _Progress) + 0.5);
   float durtn = FlashDuration + 1.0;
   float cycle = (FlashCycle * (durtn * 2.0)) + durtn;

   if (cycle > frame) {
      frame = floor (frame / durtn);

      return ((floor (frame / 2.0) * 2.0) == frame) ? flash : ngtve;
   }

   float fade = saturate ((frame - cycle) / floor (FadeAmount + 0.5));

   return lerp (ngtve, video, fade);
/*
   float fade = max (1.0 + (cycle - frame) / floor (FadeAmount + 0.5), 0.0);

   return lerp (video, ngtve, fade);
*/
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Lightning
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

