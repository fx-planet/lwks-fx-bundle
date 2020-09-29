// @Maintainer jwrl
// @Released 2020-09-29
// @Author jwrl
// @Created 2017-06-06
// @see https://www.lwks.com/media/kunena/attachments/6375/UnsharpMask_640.png

/**
 A simple unsharp mask.  Probably redundant, since the Lightworks effect does the same thing.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Unsharp_mask.fx
//
// *********************************** ORIGINAL HEADER **************************************
//
// Unsharp Mask by Jerker (Sound and Vision Unit) - was based on Big Blur by khaver,
// see below - borrowed the main blur algorithm but simplified it by taking away the
// individual color settings.  http://software.soundandvision.se
//
// Original description: Big Blur by khaver
//
// Smooth blur using a 12 tap circular kernel that rotates 5 degrees for each of 6
// passes.  There's a checkbox for a 10 fold increase in the blur amount.  (This was
// actually reduced to 5 in Jerker's effect - jwrl)
//
// ******************************** END OF ORIGINAL HEADER **********************************
//
// Version history:
//
// Modified jwrl 2020-09-29:
// Reformatted the effect header.
//
// Modified by LW user jwrl 23 December 2018.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
// Renamed "Edge gamma" to "Edge contrast".  While strictly speaking incorrect, it feels
// more like what's happening with that control to an uneducated user.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//
// Totally rewritten 19 July 2017 by jwrl.
// I didn't understand how the original effect could ever have worked correctly and didn't
// work at all in Linux, and therefore was unlikely to do so in OS/X.  The main issue was
// with the actual unsharp shader, which made assumptions about the way that shaders
// functioned in Lightworks which at best could only be described as coincidental if it
// was at all true.
//
// The original also did five passes through the blur code, but only ever used three
// of them.  This meant that the blur could never have been smooth, and in the version
// that was tested on Windows, visibly wasn't.
//
// In the light of all that I decided to completely rewrite the effect from the ground
// up.  This includes the blur section which took khaver's original big blur effect
// and heavily optimised it to reduce GPU loading.  Any overheads in an effect of this
// complexity should be kept as low as possible, and we had a total of six passes to
// execute.
//
// I have discarded the five / ten times sample radius scaling of the original because
// I really didn't see the point when the blur was used in this context.
//
// The original unsharpen shader has been discarded all together. I have gone back to
// first principles and created an algorithm that produces the sharpening using
// luminance.  To my eye it gives a cleaner result and is much closer to the way that
// the original film optical technique functioned.  As far as I know the actual method
// that I have used is an original one, but feel free to use it if you find it useful.
//
// I have added a mask gamma adjustment to the unsharp section.  Called somewhat
// misleadingly "Edge gamma", that plus the range of the original blur gives more than
// enough sharpness adjustment for any reasonable purpose.  The parameter as used will
// run from a mask gamma value of 3.67 (EdgeGamma 0.0) to a value of 0.007 (EdgeGamma
// 1.0).  The default EdgeGamma setting of 0.5 will give a unity mask gamma value.
//
// I've also included a mask gain parameter called, as you might have expected, "Edge
// gain"  Again, 0.5 corresponds to a unity setting.
//
// The finished effect functions cross-platform and has been tested to confirm that.
// As a result the old effect has been retired.  It really was too broken to repair.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Unsharp mask";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "Try the Lightworks sharpen effects first and use this only if those don't have enough range";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Pass1 : RenderColorTarget;
texture Pass2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

sampler s0 = sampler_state {
	Texture   = <Input>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Point;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s1 = sampler_state {
	Texture   = <Pass1>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Point;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s2 = sampler_state {
	Texture   = <Pass2>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Point;
	MagFilter = Linear;
	MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float BlurAmt
<
   string Description = "Unsharp radius";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float Threshold
<
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float EdgeGain
<
   string Description = "Edge gain";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float EdgeGamma
<
   string Description = "Edge contrast";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Amount
<
   string Description = "Mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LUMA_DOT  float3(1.1955,2.3464,0.4581)
#define GAMMA_VAL 1.666666667

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_blur_1 (float2 uv : TEXCOORD1) : COLOR
{  
   float4 orig = tex2D (s0, uv);

   if (BlurAmt <= 0.0) return orig;

   float angle, radius = BlurAmt * 100.0;

   float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 halfpix = pixsize / 2.0;
   float2 xy2, xy1 = uv + halfpix;

   float4 cOut = tex2D (s0, xy1);

   for (int tap = 0; tap < 12; tap++) {
      angle = radians (float (tap) * 30.0);
      sincos (angle, xy2.y, xy2.x);                             
      xy1 = uv + (halfpix * xy2 * radius);

      cOut += tex2D (s0, xy1);
   }

   cOut /= 13.0;

   return cOut;
}

float4 ps_blur_2 (float2 uv : TEXCOORD1, uniform float ang) : COLOR
{  
   float4 orig = tex2D (s1, uv);

   if (BlurAmt <= 0.0) return orig;

   float angle, radius = BlurAmt * 100.0;

   float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 halfpix = pixsize / 2.0;
   float2 xy2, xy1 = uv + halfpix;

   float4 cOut = tex2D (s1, xy1);

   for (int tap = 0; tap < 12; tap++) {
      angle = radians ((float (tap) * 30.0) + (ang * 5.0));
      sincos (angle, xy2.y, xy2.x);                             
      xy1 = uv + (halfpix * xy2 * radius);

      cOut += tex2D (s1, xy1);
   }

   cOut /= 13.0;

   return cOut;
}

float4 ps_blur_3 (float2 uv : TEXCOORD1, uniform float ang) : COLOR
{  
   float4 orig = tex2D (s2, uv);

   if (BlurAmt <= 0.0) return orig;

   float angle, radius = BlurAmt * 100.0;

   float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 halfpix = pixsize / 2.0;
   float2 xy2, xy1 = uv + halfpix;

   float4 cOut = tex2D (s2, xy1);

   for (int tap = 0; tap < 12; tap++) {
      angle = radians ((float (tap) * 30.0) + (ang * 10.0));
      sincos (angle, xy2.y, xy2.x);                             
      xy1 = uv + (halfpix * xy2 * radius);

      cOut += tex2D (s2, xy1);
   }

   cOut /= 13.0;

   return cOut;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s0, uv);

   if (Amount <= 0.0) return retval;

   float sharpMask = dot (retval.rgb, LUMA_DOT);
   float maskGamma = min (1.15, 1.1 - min (1.05, EdgeGamma)) * GAMMA_VAL;
   float maskGain  = EdgeGain * 2.0;

   sharpMask -= dot (tex2D (s1, uv).rgb, LUMA_DOT);
   maskGamma *= maskGamma;

   float sharp_pos = pow (max (0.0, sharpMask - Threshold), maskGamma) * maskGain;
   float sharp_neg = pow (max (0.0, -sharpMask - Threshold), maskGamma) * maskGain;

   float4 sharp = float4 (retval.rgb + (sharp_pos - sharp_neg).xxx, retval.a);

   return lerp (retval, sharp, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass PassA
   < string Script = "RenderColorTarget0 = Pass1;"; >
   { PixelShader = compile PROFILE ps_blur_1 (); }

   pass PassB
   < string Script = "RenderColorTarget0 = Pass2;"; >
   { PixelShader = compile PROFILE ps_blur_2 (1); }

   pass PassC
   < string Script = "RenderColorTarget0 = Pass1;"; >
   { PixelShader = compile PROFILE ps_blur_3 (1); }

   pass PassD
   < string Script = "RenderColorTarget0 = Pass2;"; >
   { PixelShader = compile PROFILE ps_blur_2 (3); }

   pass PassE
   < string Script = "RenderColorTarget0 = Pass1;"; >
   { PixelShader = compile PROFILE ps_blur_3 (2); }

   pass PassF
   < string Script = "RenderColorTarget0 = Pass2;"; >
   { PixelShader = compile PROFILE ps_blur_2 (5); }

   pass PassG
   { PixelShader = compile PROFILE ps_main (); }
}
